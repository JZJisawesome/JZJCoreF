import JZJCoreFTypes::*;

module ControlLogic
(
	input logic clock, reset,
	
	/* Instruction Parameters In */
	input logic [6:0] opcode,
	input logic [2:0] funct3,
	
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
	output logic opImm,
	//ImmediateFormer
	output ImmediateFormerMode_t immediateFormerMode,
	//BranchALU
	output BranchALUMode_t branchALUMode,
	
	/* Error Flags */
	input logic branchALUBadBRANCHFunct3,
	input logic programCounterMisaligned,
	input logic memoryUnalignedAccess,
	input logic memoryBadFunct3
);
/* Primitives */
logic halt;//Next state should be state halt
logic controlError;//Bad opcode or something similar 
logic stop;//ecall/ebreak is signaling core to halt
logic branchALUBadFunct3;//same as branchALUBadBRANCHFunct3 but only when the opcode is BRANCH
assign halt = programCounterMisaligned | memoryUnalignedAccess | memoryBadFunct3 | controlError | stop;

logic isTwoCycleInstruction;//Updated on posedge after state change to determine next state change

//State machine things
typedef enum logic [3:0]
{//One-hot encoding
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
		7'b0000011: isTwoCycleInstruction = 1'b1;//load instructions
		7'b0100011: isTwoCycleInstruction = funct3 != 3'b010;//store instructions other than sw
		default: isTwoCycleInstruction = 1'b0;//Either the instruction only takes 1 cycle, or this is a bad opcode, in which case it is handled by Control Line Logic section
	endcase
end

/* Control Line Logic */
//Also handles controlError and stop
always_comb
begin
	unique case (currentState)
		default://INITIAL_FETCH, HALT, and invalid states (which will become HALT next state)
		begin
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
			instructionAddressSource = CURRENT_PC;//Only matters for INITIAL_FETCH, not HALT
			//ALU
			opImm = 1'bx;
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = BranchALUMode_t'('x);
			
			if (currentState == INITIAL_FETCH)
			begin
				controlError = 1'b0;
				stop = 1'b0;
			end
			else
			begin
				controlError = 1'bx;
				stop = 1'bx;
			end
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
			opImm = 1'bx;
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = INCREMENT;//Go to next sequential pc
			
			controlError = 1'b0;
			stop = 1'b0;
			
			//Instruction specific settings
			unique case (opcode)
				7'b0110111://lui
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
				7'b0010111://auipc
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
				7'b1101111://jal
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
				7'b1100111://jalr
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
				7'b1100011://branch instructions
				begin
					//BranchALU
					branchALUMode = BRANCH;//Go to new location, or next sequential pc if branch is false
				end
				7'b0000011://load instructions
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
				7'b0100011://store instructions
				begin//This happens second (or is the only step for sw)
					//MemoryController
					memoryMode = STORE;//Now that the old value in memory has been modified with (or overwritten with in the case of sw) rs2, write the data back
				end
				7'b0010011://OP-IMM alu instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save alu result
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b1;//Output alu result
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'b1;//Is an OP-IMM type instruction
				end
				7'b0110011://Register-Register alu instructions
				begin
					//RegisterFile
					rdWriteEnable = 1'b1;//Save alu result
					//RDInputChooser
					rdSourceSelectLines.memoryOutputEnable = 1'b0;
					rdSourceSelectLines.aluOutputEnable = 1'b1;//Output alu result
					rdSourceSelectLines.immediateFormerOutputEnable = 1'b0;
					rdSourceSelectLines.branchALUOutputEnable = 1'b0;
					//ALU
					opImm = 1'b0;//Is not an OP-IMM type instruction
				end
				7'b0001111: begin end//fence/fence.i (Acts as a nop)
				7'b1110011://ecall/ebreak
				begin//Acts as a fatal trap (on purpose); nice way to stop cpu
					//ProgramCounter
					programCounterWriteEnable = 1'b0;//Avoid messing up state; we are stopping cleanly
					//InstructionAddressMux
					instructionAddressSource = InstructionAddressSource_t'('x);
					//BranchALU
					branchALUMode = BranchALUMode_t'('x);
					
					controlError = 1'bx;
					stop = 1'b1;//Fatal trap
				end
				default://Bad opcode
				begin//Unlike ecall/ebreaks, we are shutting down hard without care for cpu state
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
					
					controlError = 1'b1;//Bad opcode
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
			opImm = 1'bx;
			//ImmediateFormer
			immediateFormerMode = ImmediateFormerMode_t'('x);
			//BranchALU
			branchALUMode = BranchALUMode_t'('x);
			
			controlError = 1'b0;
			stop = 1'b0;
			
			//Instruction specific settings
			unique case (opcode)
				7'b0000011://load instructions
				begin//This happens first
					//MemoryController
					memoryMode = LOAD;//Begin a memory load that will complete at the next posedge
				end
				7'b0100011://store instructions
				begin//This happens first (only needed for sb and sh)
					//MemoryController
					memoryMode = STORE_PRELOAD;//Fetch the old value from the address in memory to modify + write back in the second cycle
				end
				default://Bad opcode for a 2 cycle instruction
				begin//We are shutting down hard without care for cpu state
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
					
					controlError = 1'b1;
					stop = 1'bx;
				end
			endcase
		end
	endcase
end

/* Bad BranchALU Funct3 Selective Detection */
//Can only listen to branchALUBadBRANCHFunct3 when opcode is BRANCH and state is FETCH_EXECUTE
assign branchALUBadFunct3 = branchALUBadBRANCHFunct3 && (opcode == 7'b1100011) && currentState == FETCH_EXECUTE;

endmodule 
