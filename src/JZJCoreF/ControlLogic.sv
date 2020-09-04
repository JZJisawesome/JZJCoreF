import JZJCoreFTypes::*;

module ControlLogic
(
	input logic clock, reset,
	
	/* Instruction Parameters In */
	input Opcode_t opcode,
	input Funct3_t funct3,
	
	/* Control Lines */
	//RegisterFile
	output logic rdWriteEnable,
	//MemoryController
	output MemoryMode_t memoryMode,
	//RDInputChooser
	output RDSourceSelectLines_t rdSourceSelectLines,
	//ProgramCounter
	output logic programCounterWriteEnable,
	//InstructionAddressMux
	output InstructionAddressSource_t instructionAddressSource,
	//ALU
	output ALUMode_t aluMode,
	//ImmediateFormer
	output ImmediateFormerMode_t immediateFormerMode,
	//BranchALU
	output BranchALUMode_t branchALUMode,
	
	/* Error Flags */
	input logic programCounterMisaligned,
	input logic memoryUnalignedAccess
);
/* Primitives */
logic halt;//Next state should be state halt
logic stop;//ecall/ebreak is signaling core to halt
assign halt = programCounterMisaligned | memoryUnalignedAccess | stop;

logic isTwoCycleInstruction;//Updated on posedge after state change to determine next state change

//State machine things
typedef enum logic [3:0]
{
	//One-hot encoding
	INITIAL_FETCH = 4'b0001,
	FETCH_EXECUTE = 4'b0010,
	EXECUTE = 4'b0100,
	HALT = 4'b1000
} State_t;
State_t currentState = INITIAL_FETCH, nextState;

/* State Machine Logic */

//State Change
always_ff @(negedge clock, posedge reset)
begin
	if (reset)
		currentState <= INITIAL_FETCH;
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
			INITIAL_FETCH, FETCH_EXECUTE:
			begin
				if (isTwoCycleInstruction)
					nextState = EXECUTE;//First cycle of 2 cycle instruction
				else
					nextState = FETCH_EXECUTE;//Instruction only takes 1 cycle
			end
			EXECUTE: nextState = FETCH_EXECUTE;//Move to the second cycle of a 2 cycle instruction
			HALT: nextState = HALT;//Spin forever
			default: nextState = HALT;//Invalid state; halt core
		endcase
	end
end

//Determine if instruction takes 2 cycles or not
//Since opcode and funct3 update on the posedge, isTwoCycleInstruction also updates on the posedge (in time for the next state change)
always_comb
begin
	unique case (opcode)
		7'b00000_11: isTwoCycleInstruction = 1'b1;//load instructions
		7'b01000_11: isTwoCycleInstruction = funct3 != 3'b010;//store instructions other than sw
		default: isTwoCycleInstruction = 1'b0;//Either the instruction only takes 1 cycle, or this is a bad opcode so this value dosen't matter
	endcase
end

/* Control Line Logic */
//Also handles stop for ecall/ebreak
always_comb
begin
	unique case (currentState)
		default://INITIAL_FETCH, HALT, and invalid states (which will become HALT next state)
		begin
			//RegisterFile
			rdWriteEnable = 1'b0;//Do not affect register state
			//MemoryController
			memoryMode = NOP;//Do not affect memory state
			//RDInputChooser
			rdSourceSelectLines.memoryOutputEnable = 1'bx;
			rdSourceSelectLines.aluOutputEnable = 1'bx;
			rdSourceSelectLines.immediateFormerOutputEnable = 1'bx;
			rdSourceSelectLines.branchALUOutputEnable = 1'bx;
			//ProgramCounter
			programCounterWriteEnable = 1'b0;//Do not affect program counter state
			//InstructionAddressMux
			if (currentState == INITIAL_FETCH)
				instructionAddressSource = CURRENT_PC;
			else
				instructionAddressSource = InstructionAddressSource_t'('x);//Halted, so this dosen't matter
			//ALU
			aluMode = ALUMode_t'('x);
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = BranchALUMode_t'('x);
			
			if (currentState == INITIAL_FETCH)
				stop = 1'b0;
			else
				stop = 1'bx;//Halted, so this dosen't matter
		end
		FETCH_EXECUTE:
		begin
			//Defaults for control signals; changed for the specific instruction by the case statement
			//RegisterFile
			rdWriteEnable = 1'b0;
			//MemoryController
			memoryMode = NOP;
			//RDInputChooser
			rdSourceSelectLines.memoryOutputEnable = 1'bx;
			rdSourceSelectLines.aluOutputEnable = 1'bx;
			rdSourceSelectLines.immediateFormerOutputEnable = 1'bx;
			rdSourceSelectLines.branchALUOutputEnable = 1'bx;
			//ProgramCounter
			programCounterWriteEnable = 1'b1;
			//InstructionAddressMux
			instructionAddressSource = NEXT_PC;//Note that for other modules the current instruction is still used, this is just for memory fetching
			//ALU
			aluMode = ALUMode_t'('x);
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = INCREMENT;//Go to next sequential pc
			
			stop = 1'b0;
			
			//Instruction specific settings
			unique case (opcode)
				7'b01101_11://lui
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save lui value
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b0;
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b1;//Get lui value
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
					//ImmediateFormer
					immediateFormerMode = LUI;//Generate lui value
				end
				7'b00101_11://auipc
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save auipc value
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b0;
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b1;//Get auipc value
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
					//ImmediateFormer
					immediateFormerMode = AUIPC;//Generate auipc value
				end
				7'b11011_11://jal
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Latch rd (next sequential pc)
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b0;
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b1;//Get rd from BranchALU
					//BranchALU
					branchALUMode = JAL;//Go to new location
				end
				7'b11001_11://jalr
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Latch rd (next sequential pc)
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b0;
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b1;//Get rd from BranchALU
					//BranchALU
					branchALUMode = JALR;//Go to new location
				end
				7'b11000_11://branch instructions
				begin
					//BranchALU
					branchALUMode = BRANCH;//Go to new location, or next sequential pc if branch is false
				end
				7'b00000_11://load instructions
				begin//This happens second
					//RegisterFile
					rdWriteEnable = 1'b1;//Latch the value at the address
					//MemoryController
					memoryMode = LOAD;//Hold the memoryMode in LOAD to ensure we get the rd value
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b1;//Now we want the value from memory
					rdSourceSelectLines.aluOutputEnable = 1'b0;
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
				end
				7'b01000_11://store instructions
				begin//This happens second (or is the only step for sw)
					//MemoryController
					memoryMode = STORE;//Now that the old value in memory has been modified with (or overwritten with in the case of sw) rs2, write the data back
				end
				7'b00100_11://OP-IMM alu instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save alu result
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b1;//Output alu result
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
					//ALU
					aluMode = OP_IMM;
				end
				7'b01100_11://Register-Register alu instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save alu result
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b1;//Output alu result
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
					//ALU
					aluMode = REGISTER;
				end
				7'b00011_11: begin end//fence/fence.i (Acts as a nop)
				7'b11100_11://ecall/ebreak
				begin//Causes clean termination of the cpu (on purpose); the only implemented requested trap
					//ProgramCounter
					programCounterWriteEnable = 1'b0;//Avoid messing up state; we are stopping cleanly
					//InstructionAddressMux
					instructionAddressSource = InstructionAddressSource_t'('x);
					//BranchALU
					branchALUMode = BranchALUMode_t'('x);
					
					stop = 1'b1;//Requested trap halts cpu cleanly (does not affect register, pc, or memory state)
				end
				default://Bad opcode
				begin//Error occured; anything goes now
					//RegisterFile
					rdWriteEnable = 1'bx;
					//MemoryController
					memoryMode = MemoryMode_t'('x);
					//ProgramCounter
					programCounterWriteEnable = 1'bx;
					//InstructionAddressMux
					instructionAddressSource = InstructionAddressSource_t'('x);
					//BranchALU
					branchALUMode = BranchALUMode_t'('x);
					
					stop = 1'bx;
				end
			endcase
		end
		EXECUTE://First cycle of a 2 cycle instruction
		begin
			//Defaults for control signals; changed for the specific instruction by the case statement
			//RegisterFile
			rdWriteEnable = 1'b0;
			//MemoryController
			memoryMode = NOP;
			//RDInputChooser
			rdSourceSelectLines.memoryOutputEnable = 1'bx;
			rdSourceSelectLines.aluOutputEnable = 1'bx;
			rdSourceSelectLines.immediateFormerOutputEnable = 1'bx;
			rdSourceSelectLines.branchALUOutputEnable = 1'bx;
			//ProgramCounter
			programCounterWriteEnable = 1'b0;
			//InstructionAddressMux
			instructionAddressSource = CURRENT_PC;//Same for all instructions; since this is a 2 cycle instruction we can't move to the next one yet
			//ALU
			aluMode = ALUMode_t'('x);
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = BranchALUMode_t'('x);
			
			stop = 1'b0;
			
			//Instruction specific settings
			unique case (opcode)
				7'b00000_11://load instructions
				begin//This happens first
					//MemoryController
					memoryMode = LOAD;//Begin a memory load that will complete at the next posedge
				end
				7'b01000_11://store instructions
				begin//This happens first (only needed for sb and sh)
					//MemoryController
					memoryMode = STORE_PRELOAD;//Fetch the old value from the address in memory to modify + write back in the second cycle
				end
				default://Bad opcode for a 2 cycle instruction
				begin//Error occured; anything goes now
					//RegisterFile
					rdWriteEnable = 1'bx;
					//MemoryController
					memoryMode = MemoryMode_t'('x);
					//ProgramCounter
					programCounterWriteEnable = 1'bx;
					//InstructionAddressMux
					instructionAddressSource = InstructionAddressSource_t'('x);
					
					stop = 1'bx;
				end
			endcase
		end
	endcase
end

endmodule 
