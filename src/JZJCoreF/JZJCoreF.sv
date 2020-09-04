import JZJCoreFTypes::*;

module JZJCoreF
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",//File containing initial ram contents (32 bit words); execution starts from address 0x00000000
	parameter RAM_A_WIDTH = 12,//number of addresses for code/ram (not memory mapped io); 2^RAM_A_WIDTH words = 2^RAM_A_WIDTH * 4 bytes
	parameter RESET_VECTOR = 32'h00000000//address for execution to begin at (must be within RAM)
)
(
	input logic clock, reset,
	
	//Memory Mapped Ports
	//Must be read/written in a whole word at a time
	//Reads from the address read from mmioInputs, writes write to mmioOutputs
	//mmioInputs [7:0] and mmioOutputs [7:0] are at byte-wise memory addresses [FFFFFFE0:FFFFFFFC] (each are 4 bytes (1 word) wide)
	input logic [31:0] mmioInputs [8],
	output reg [31:0] mmioOutputs [8],
	//For tristate ports, an additional port's outputs can be designated as a direction register externally, which can be used by an external module to allow/disalow writing
	//If feedback is desired, then inputs should be connected to their respective output register
	//MAKE SURE INPUTS AND OUTPUTS ARE SYNCHRONIZED IF THEY ARE FROM/TO ANOTHER CLOCK DOMAIN
	
	//Output for legacy asembly test programs that output to register 31; for new software use memory mapped io instead
	//Good for testing things before memory mapped io was implemented
	output logic [31:0] register31Output
);
/* Connections */

//RegisterFile
DecodedAddresses_t decodedAddresses;
//Reading
logic [31:0] rs1, rs2;
//Writing
logic [31:0] rd;//If a module is not writing to rd, then control should set its output to '0 (yes I know I should be using a priority encoder but this is nicer readability wise; I have to test the performance at some point)
logic rdWriteEnable;

//MemoryController
MemoryMode_t memoryMode;
logic [31:0] memoryOutput;
logic [31:0] instruction;

//InstructionDecoder
logic [2:0] funct3;
logic [6:0] funct7;
logic [31:0] immediateI;
logic [31:0] immediateS;
logic [31:0] immediateB;
logic [31:0] immediateU;
logic [31:0] immediateJ;

//RDInputChooser
RDSourceSelectLines_t rdSourceSelectLines;

//ProgramCounter
logic [31:0] programCounterInput;
logic programCounterWriteEnable;
logic [31:0] pcOfInstruction;

//InstructionAddressMux
InstructionAddressSource_t instructionAddressSource;
logic [31:0] instructionAddressToAccess;

//ALU
logic opImm;
logic [31:0] aluOutput;

//ImmediateFormer
ImmediateFormerMode_t immediateFormerMode;
logic [31:0] immediateFormerOutput;

//BranchALU
BranchALUMode_t branchALUMode;
logic [31:0] branchALUOutput;

//Control Logic
logic [6:0] opcode;
//Error Flags
logic branchALUBadFunct3;
logic programCounterMisaligned;
logic memoryUnalignedAccess;
logic memoryBadFunct3;

/* Modules */

RegisterFile registerFile(.*);

MemoryController #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) memoryController(.*);

InstructionDecoder instructionDecoder(.*);

RDInputChooser rdInputChooser(.*);

ProgramCounter #(.RESET_VECTOR(RESET_VECTOR)) programCounter(.*);

InstructionAddressMux instructionAddressMux(.*);

ALU alu(.*);

ImmediateFormer immediateFormer(.*);

BranchALU branchALU(.*);

ControlLogic controlLogic(.*);

endmodule