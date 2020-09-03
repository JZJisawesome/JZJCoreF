import JZJCoreFTypes::*;

module ControlLogic
(
	input clock, reset,
	
	/* Instruction Parameters In */
	input [6:0] opcode,
	input [2:0] funct3,
	
	/* Control Lines */
	//RegisterFile
	output rdWriteEnable,
	//MemoryController
	output MemoryMode_t memoryMode,
	//RDInputChooser//todo make a struct or enum for this
	output memoryOutputEnable,
	output aluOutputEnable,
	output immediateFormerOutputEnable,
	output branchALUOutputEnable,
	//ProgramCounter
	output programCounterWriteEnable,
	//InstructionAddressMux
	output InstructionAddressSource_t instructionAddressSource,
	//ALU
	output opImm,
	//ImmediateFormer
	output ImmediateFormerMode_t immediateFormerMode,
	//BranchALU
	output BranchALUMode_t branchALUMode,
	
	/* Error Flags */
	input branchALUBadFunct3,
	input programCounterMisaligned,
	input memoryUnalignedAccess,
	input memoryBadFunct3
);
/* Primitives */
logic halt;//Next state should be state halt
logic stop;//ecall/ebreak is signaling core to halt
logic controlError;//Bad opcode or something similar
assign halt = branchALUBadFunct3 | programCounterMisaligned | memoryUnalignedAccess | memoryBadFunct3 | stop | controlError | (opcode[1:0] != 2'b11);

logic isTwoCycleInstruction;//Updated on posedge after state change to determine next state change

//State Machine
typedef enum logic [4:0] {INITIAL_WAIT, INITIAL_FETCH, FETCH_EXECUTE, EXECUTE, HALT} State_t;//todo make sure this is onehot
State_t currentState, nextState;

/* State Machine Logic */

//State Change
always_ff @(negedge clock, posedge reset)
begin
	if (reset)
		currentState <= INITIAL_WAIT;
	else if (~clock)
		currentState <= nextState;//Latch new state
end

//Decide nextState
always_comb
begin
	if (halt)
		nextState = HALT;//Initial entry into halt
	else
	begin
		unique case (currentState)
			INITIAL_WAIT: nextState = INITIAL_FETCH;
			INITIAL_FETCH, FETCH_EXECUTE:
			begin
				if (isTwoCycleInstruction)
					nextState = EXECUTE;//First cycle of 2 cycle instruction
				else
					nextState = FETCH_EXECUTE;//Instruction only takes 1 cycle
			end
			EXECUTE: nextState = FETCH_EXECUTE;//Move to the second cycle of a 2 cycle instruction
			HALT: nextState = HALT;//Spin forever
			default: nextState = HALT;//Invalid state occured; halt core
		endcase
	end
end

//Determine if instruction takes 2 cycles or not
//Since opcode and funct3 update on the posedge, isTwoCycleInstruction also updates on the posedge (in time for the next state change)
always_comb
begin
	//unique case (opcode) inside//Quartus Prime does not support case inside
	unique casex (opcode)//Forced to do this instead
		7'b00000xx: isTwoCycleInstruction = 1'b1;//load instructions
		7'b01000xx: isTwoCycleInstruction = funct3 != 3'b010;//store instructions other than sw
		default: isTwoCycleInstruction = 1'b0;//Either the instruction only takes 1 cycle, or this is a bad opcode, in which case it is handled by Control Line Logic section
	endcase
end

/* Control Line Logic */
//Also handles controlError
always_comb
begin
	unique case (currentState)
		INITIAL_WAIT, INITIAL_FETCH, HALT:
		begin
			//RegisterFile
			rdWriteEnable = 1'b0;
			//MemoryController
			memoryMode = NOP;
			//RDInputChooser
			memoryOutputEnable = 1'bx;
			aluOutputEnable = 1'bx;
			immediateFormerOutputEnable = 1'bx;
			branchALUOutputEnable = 1'bx;
			//ProgramCounter
			programCounterWriteEnable = 1'b0;
			//InstructionAddressMux
			if (currentState == INITIAL_FETCH)
				instructionAddressSource = CURRENT_PC;//Only difference
			else//INITIAL_WAIT or HALT
				instructionAddressSource = InstructionAddressSource_t'('x);
			//ALU
			opImm = 1'bx;
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = BranchALUMode_t'('x);
			
			controlError = 1'b0;
			stop = 1'b0;
		end
		FETCH_EXECUTE:
		begin
			//Things that are the same for all instructions
			//InstructionAddressMux
			instructionAddressSource = NEXT_PC;//Note that for other modules the current instruction is still used, this is just for memory fetching
			//ProgramCounter
			programCounterWriteEnable = 1'b1;
			
			//unique case (opcode) inside//Quartus Prime does not support case inside
			unique casex (opcode)//Forced to do this instead
				7'b01101xx://lui
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save lui value
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'b0;
					aluOutputEnable = 1'b0;
					immediateFormerOutputEnable = 1'b1;//Get lui value
					branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = LUI;//Generate lui value
					//BranchALU
					branchALUMode = INCREMENT;//Go to next sequential pc
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b00101xx://auipc
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save auipc value
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'b0;
					aluOutputEnable = 1'b0;
					immediateFormerOutputEnable = 1'b1;//Get auipc value
					branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = AUIPC;//Generate auipc value
					//BranchALU
					branchALUMode = INCREMENT;//Go to next sequential pc
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b11011xx://jal
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Latch rd (next sequential pc)
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'b0;
					aluOutputEnable = 1'b0;
					immediateFormerOutputEnable = 1'b0;
					branchALUOutputEnable = 1'b1;//Get rd from BranchALU
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = JAL;//Go to new location
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b11001xx://jalr
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Latch rd (next sequential pc)
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'b0;
					aluOutputEnable = 1'b0;
					immediateFormerOutputEnable = 1'b0;
					branchALUOutputEnable = 1'b1;//Get rd from BranchALU
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = JALR;//Go to new location
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b11000xx://branch instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = BRANCH;//Go to new location, or next sequential pc if branch is false
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b00000xx://load instructions
				begin//This happens second
					//RegisterFile
					rdWriteEnable = 1'b1;//Latch the value at the address
					//MemoryController
					memoryMode = LOAD;//Hold the memoryMode in LOAD to ensure we get the rd value
					//RDInputChooser
					memoryOutputEnable = 1'b1;//Now we want the value from memory
					aluOutputEnable = 1'b0;
					immediateFormerOutputEnable = 1'b0;
					branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = INCREMENT;//Now we can move to the next instruction
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b00000xx://store instructions
				begin//This happens second (or is the only step for sw)
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = STORE;//Now that the old value in memory has been modified with (or overwritten with in the case of sw) rs2, write the data back
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = INCREMENT;//Now we can move to the next instruction
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b00100xx://OP-IMM alu instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save alu result
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'b0;
					aluOutputEnable = 1'b1;//Output alu result
					immediateFormerOutputEnable = 1'b0;
					branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'b1;//Is an OP-IMM type instruction
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = INCREMENT;//Go to next sequential pc
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b01100xx://Register-Register alu instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save alu result
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'b0;
					aluOutputEnable = 1'b1;//Output alu result
					immediateFormerOutputEnable = 1'b0;
					branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'b0;//Is not an OP-IMM type instruction
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = INCREMENT;//Go to next sequential pc
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b00011xx://fence/fence.i
				begin//Acts as a nop
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = INCREMENT;//Go to next sequential pc
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b11100xx://ecall/ebreak
				begin//Acts as a fatal trap (on purpose); nice way to stop cpu
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = BranchALUMode_t'('x);
					
					controlError = 1'b0;
					stop = 1'b1;//Halt cpu
				end
				default://Bad opcode
				begin
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					//ALU
					opImm = 1'bx;
					//ImmediateFormer
					immediateFormerMode = ImmediateFormerMode_t'('x);
					//BranchALU
					branchALUMode = BranchALUMode_t'('x);
					
					controlError = 1'b1;//Bad opcode
					stop = 1'bx;
				end
			endcase
		end
		EXECUTE://First cycle of 2 cycle instructions
		begin
			//Things that are the same for all instructions
			//InstructionAddressMux
			instructionAddressSource = CURRENT_PC;//Same for all instructions; since this is a 2 cycle instruction we can't move to the next one yet
			//ProgramCounter
			programCounterWriteEnable = 1'b0;
			//ALU
			opImm = 1'bx;
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = BranchALUMode_t'('x);
			
			//unique case (opcode) inside//Quartus Prime does not support case inside
			unique casex (opcode)//Forced to do this instead
				7'b00000xx://load instructions
				begin//This happens first
					//RegisterFile
					rdWriteEnable = 1'b0;//Don't need to write to the register yet, and can't mess up the value in the mean time because MemoryController might be referencing rs1
					//MemoryController
					memoryMode = LOAD;//Begin a memory load that will complete at the next posedge
					//RDInputChooser
					memoryOutputEnable = 1'bx;//No need to set this yet
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				7'b01000xx://store instructions
				begin//This happens first (only needed for sb and sh)
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = STORE_PRELOAD;//Fetch the old value from the address in memory to modify + write back in the second cycle
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					
					controlError = 1'b0;
					stop = 1'b0;
				end
				default://Bad opcode for a 2 cycle instruction
				begin
					//RegisterFile
					rdWriteEnable = 1'b0;
					//MemoryController
					memoryMode = NOP;
					//RDInputChooser
					memoryOutputEnable = 1'bx;
					aluOutputEnable = 1'bx;
					immediateFormerOutputEnable = 1'bx;
					branchALUOutputEnable = 1'bx;
					
					controlError = 1'b1;
					stop = 1'b0;
				end
			endcase
		end
	endcase
end

endmodule 