import JZJCoreFTypes::*;

module ControlLogic
(
	input clock, reset,
	
	/* Instruction Parameters In */
	input [6:0] opcode,
	input [2:0] funct3,
	
	/* Control Lines */
	//RegisterFile
	output reg rdWriteEnable,
	//MemoryController
	output MemoryMode_t memoryMode,
	//RDInputChooser
	output reg memoryOutputEnable,
	output reg aluOutputEnable,
	output reg immediateFormerOutputEnable,
	output reg branchALUOutputEnable,
	//ProgramCounter
	output reg programCounterWriteEnable,
	//InstructionAddressMux
	output InstructionAddressSource_t instructionAddressSource,
	//ALU
	output reg opImm,
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

//State Machine
typedef enum {INITIAL_WAIT, INITIAL_FETCH, FETCH_EXECUTE, EXECUTE, HALT} State_t;
State_t currentState, nextState;

/* State Machine Logic */

/* Control Line Logic */

/* Halt Logic */

assign halt = branchALUBadFunct3 | programCounterMisaligned | memoryUnalignedAccess | memoryBadFunct3 | stop | controlError;

endmodule 
