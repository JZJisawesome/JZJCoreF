import JZJCoreFTypes::MemoryMode_t;
import EndiannessFunctions::*;

module MemoryController//2.5 port memory: 1 read port for instruction fetching, 1 read/write port for data loads/stores
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",
	parameter RAM_A_WIDTH = 12
)
(
	input clock, reset,
	
	//Memory Mode and Control
	input MemoryMode_t memoryMode,//Note: Use LOAD as nop (or STORE_PRELOAD alternatively)
	input [2:0] funct3,
	
	//Addressing
	input [31:0] rs1,
	input [31:0] immediateI,
	input [31:0] immediateS,
	
	//Memory Loads
	output [31:0] memoryOutput,//Will only update if memoryMode is LOAD
	
	//Memory Stores
	input [31:0] rs2,//Will only write if memoryMode is STORE; for half words and bytes the memoryMode must be STORE_PRELOAD for 1 cycle first, then STORE to actually write
	
	//Instruction Fetching
	input [31:0] pcOfInstruction,
	output [31:0] instruction,
	
	//Error Flags
	output memoryUnalignedAccess,
	output memoryBadFunct3,
	
	//CPU memory mapped ports
	//Note that reads and writes are written to the addresses in little endian format
	//then converted back to be output / vise-versa for inputs
	//This makes it so for reads rd[0] = portXMemoryAddress[24] = portXInput[0]
	//and for writes............rs2[0] = portXMemoryAddress[24] = portXOutput[0]
	//My recomendation is therefore that ports are accessed whole words at a time
	//but if you keep the little endian -> big endian format in mind you can write half words or bytes
	//Reads from the address read from the input, writes write to the output
	//Inputs: (byte-wise read)		address (starting byte)
	input [31:0] portAInput,//		FFFFFFE0
	input [31:0] portBInput,//		FFFFFFE4
	input [31:0] portCInput,//  	FFFFFFE8
	input [31:0] portDInput,//  	FFFFFFEC
	input [31:0] portEInput,//   	FFFFFFF0
	input [31:0] portFInput,//   	FFFFFFF4
	input [31:0] portGInput,//   	FFFFFFF8
	input [31:0] portHInput,//   	FFFFFFFC
	//Outputs: (byte-wise write)	address (starting byte)
	output [31:0] portAOutput,//	FFFFFFE0
	output [31:0] portBOutput,//	FFFFFFE4
	output [31:0] portCOutput,//	FFFFFFE8
	output [31:0] portDOutput,//	FFFFFFEC
	output [31:0] portEOutput,//	FFFFFFF0
	output [31:0] portFOutput,//	FFFFFFF4
	output [31:0] portGOutput,//	FFFFFFF8
	output [31:0] portHOutput//	FFFFFFFC
	//For tristate ports, an additional port's outputs can be designated as a direction register, which can be used by and external module to allow/disalow writing
	//If feedback is desired, then inputs should be connected to their respective output register
	//MAKE SURE INPUTS ARE SYNCHRONIZED IF THEY ARE FROM ANOTHER CLOCK DOMAIN
);
/* Primitives */
//Addressing
logic [1:0] offset;
logic [31:0] addressToAccess;

//Backend Connections
logic [29:0] backendAddress;
logic [31:0] backendDataOut;
logic [31:0] backendDataIn;
logic backendWriteEnable;
logic [29:0] backendInstructionAddress;

/* Addressing Logic */

assign backendInstructionAddress = pcOfInstruction[31:2];//If the instruction offset is bad, the ProgramCounter will set its error flag

always_comb
begin
	case (memoryMode)
		LOAD: addressToAccess = rs1 + immediateI;
		STORE_PRELOAD, STORE: addressToAccess = rs1 + immediateS;//STORE_PRELOAD loads data currently at the address of the read-modify-write sequence
		default: addressToAccess = 'x;//Invalid enum
	endcase
end

assign backendAddress = addressToAccess[31:2];
assign offset = addressToAccess[1:0];

/* Data Processing */

/* Error Detection *///todo might move this to its own module//actually better idea; make this an internally defined + instantized module

/* Sign Extension Functions */

function automatic logic [31:0] extend16To32(input [15:0] data);
begin
	extend16To32 = {{16{data[15]}}, data[15:0]};
end
endfunction

//todo more needed

/* Modules */
//Internal

//External

MemoryBackend #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) memoryBackend(.*);//todo move definition of MemoryBackend to inside this module; (maybe)

endmodule