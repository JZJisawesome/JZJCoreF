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
typedef enum {INITIAL_WAIT, INITIAL_FETCH, FETCH_EXECUTE, EXECUTE, HALT} State_t;
State_t currentState, nextState;

/* State Machine Logic */

//State Change
always_ff @(negedge clock, posedge reset)
begin
	if (reset)
		currentState <= INITIAL_WAIT;
	else
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
		//todo
		/*FETCH_EXECUTE:
		begin
		
		end
		EXECUTE:
		begin
		
		end*/
	endcase
end

endmodule 
