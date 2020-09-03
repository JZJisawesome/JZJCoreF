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
			instructionAddressSource = NEXT_PC;
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
				//todo: memory load instructions**************************************************************
				//todo: memory store instructions**************************************************************
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
				//todo: fence/ifencei, ecall, ebreak******************************************************
				default:
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
		/*EXECUTE://todo
		begin
			//Things that are the same for all instructions
			//InstructionAddressMux
			instructionAddressSource = CURRENT_PC;//Same for all instructions
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
			
			endcase
		end*/
	endcase
end

endmodule 
