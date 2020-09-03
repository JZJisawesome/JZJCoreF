import JZJCoreFTypes::*;

module JZJCoreF
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",//File containing initial ram contents (32 bit words); execution starts from address 0x00000000
	parameter RAM_A_WIDTH = 12//number of addresses for code/ram (not memory mapped io); 2^RAM_A_WIDTH words = 2^RAM_A_WIDTH * 4 bytes
)
(
	input clock, reset,
	
	//CPU memory mapped ports
	//Note that reads and writes are written to the addresses in little endian format
	//then converted back to be output / vise-versa for inputs
	//This makes it so for reads rd[0] = portXMemoryAddress[24] = portXInput[0]
	//and for writes............rs2[0] = portXMemoryAddress[24] = portXOutput[0]
	//My recomendation is therefore that ports are accessed whole words at a time
	//but if you keep the little endian -> big endian format in mind you can write half words or bytes
	//Reads from the address read from the input, writes write to the output
	//Inputs: (byte-wise read)				address (starting byte)
	input [31:0] portAInput,//				FFFFFFE0
	input [31:0] portBInput,//				FFFFFFE4
	input [31:0] portCInput,//   			FFFFFFE8
	input [31:0] portDInput,//   			FFFFFFEC
	input [31:0] portEInput,//   			FFFFFFF0
	input [31:0] portFInput,//   			FFFFFFF4
	input [31:0] portGInput,//   			FFFFFFF8
	input [31:0] portHInput,//   			FFFFFFFC
	//Outputs: (byte-wise write)			address (starting byte)
	output logic [31:0] portAOutput,//	FFFFFFE0
	output logic [31:0] portBOutput,//	FFFFFFE4
	output logic [31:0] portCOutput,//	FFFFFFE8
	output logic [31:0] portDOutput,//	FFFFFFEC
	output logic [31:0] portEOutput,//	FFFFFFF0
	output logic [31:0] portFOutput,//	FFFFFFF4
	output logic [31:0] portGOutput,//	FFFFFFF8
	output logic [31:0] portHOutput,//	FFFFFFFC
	//For tristate ports, an additional port's outputs can be designated as a direction register, which can be used by and external module to allow/disalow writing
	//If feedback is desired, then inputs should be connected to their respective output register
	//MAKE SURE INPUTS ARE SYNCHRONIZED IF THEY ARE FROM ANOTHER CLOCK DOMAIN
	
	//Output for legacy asembly test programs that output to register 31; for new software use memory mapped io instead
	output logic [31:0] register31Output
);
/* Connections */

//RegisterFile
DecodedAddresses decodedAddresses;
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
logic memoryOutputEnable;
logic aluOutputEnable;
logic immediateFormerOutputEnable;
logic branchALUOutputEnable;

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

ProgramCounter programCounter(.*);

InstructionAddressMux instructionAddressMux(.*);

ALU alu(.*);

ImmediateFormer immediateFormer(.*);

BranchALU branchALU(.*);

ControlLogic controlLogic(.*);

endmodule