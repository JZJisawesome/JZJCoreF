import JZJCoreFTypes::MemoryMode_t;
import EndiannessFunctions::*;
import BitExtensionFunctions::*;

module MemoryController//2.5 port memory: 1 read port for instruction fetching, 1 read/write port for data loads/stores
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",
	parameter RAM_A_WIDTH = 12
)
(
	input clock, reset,
	
	//Memory Mode and Control
	input MemoryMode_t memoryMode,
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

//backendDataOut to memoryOutput (reading/loading)
always_comb//Assumes memoryMode is LOAD since memoryOutput will be ignored anyways if it RDInputChooser has not selected memory
begin
	unique case (funct3)
		3'b000: memoryOutput = signExtend8To32(getByteAtOffset(backendDataOut, offset));//lb
		3'b001: memoryOutput = signExtend16To32(toBigEndian16(getHalfwordAtOffset(backendDataOut, offset)));//lh
		3'b010: memoryOutput = toBigEndian32(backendDataOut);//lw
		3'b100: memoryOutput = zeroExtend8To32(getByteAtOffset(backendDataOut, offset));//lbu
		3'b101: memoryOutput = zeroExtend16To32(toBigEndian16(getHalfwordAtOffset(backendDataOut, offset)));//lhu
		default: memoryOutput = 'x;//Bad funct3 or not LOAD
	endcase
end

//rs2 + (possibly) backendDataOut to backendDataIn (writing/storing)
always_comb//Assumes memoryMode is STORE since backendDataIn will not be writen unless memoryMode == STORE (see backendWriteEnable)
begin//If funct3 is sb or sh, backendDataOut will have already been updated with the original contents of an address last posedge (STORE_PRELOAD), so we can use that here
	unique case (funct3)
		//3'b000: //todo
		//3'b001: //todo
		3'b010: backendDataIn = toLittleEndian32(rs2);//sw
		default: backendDataIn = 'x;//Bad funct3 or not STORE
	endcase
end

assign backendWriteEnable = memoryMode == STORE;

/* Selection Functions */

function automatic logic [7:0] getByteAtOffset(input [31:0] data, input [1:0] offset);
begin
	unique case (offset)
		2'b00: getByteAtOffset = data[31:24];
		2'b01: getByteAtOffset = data[23:16];
		2'b10: getByteAtOffset = data[15:8];
		2'b11: getByteAtOffset = data[7:0];
	endcase
end
endfunction

function automatic logic [15:0] getHalfwordAtOffset(input [31:0] data, input [1:0] offset);
begin
	unique case (offset)
		2'b00: getHalfwordAtOffset = data[31:16];
		2'b10: getHalfwordAtOffset = data[15:0];
		default: getHalfwordAtOffset = 'x;//Bad offset
	endcase
end
endfunction

/* Modules */
//Internal
MemoryControllerErrorDetector errorDetector(.*);//Should be nested but Quartus Prime does not support nested modules :(

//External
MemoryBackend #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) memoryBackend(.*);//todo move definition of MemoryBackend to inside this module; (maybe, does not have to)

endmodule: MemoryController

/****/

//Should be nested but Quartus Prime does not support nested modules :(
module MemoryControllerErrorDetector
(
	//Inputs
	input MemoryMode_t memoryMode,
	input [2:0] funct3,
	input [1:0] offset,
	
	//Error Flags
	output memoryUnalignedAccess,
	output memoryBadFunct3
);

//Unaligned Access Detection
always_comb
begin
	unique case (memoryMode)
		LOAD, STORE_PRELOAD, STORE:
		begin
			unique case (funct3)
				3'b000, 3'b100: memoryUnalignedAccess = 1'b0;//lb/lbu | sb/Bad funct3
				3'b001, 3'b101: memoryUnalignedAccess = (offset == 2'b01) || (offset == 2'b11);//lh/lhu | sh/Bad funct3
				3'b010: memoryUnalignedAccess = offset != 2'b00;//lw | sw
				default: memoryUnalignedAccess = 1'bx;//Bad funct3
			endcase
		end
		NOP: memoryUnalignedAccess = 1'b0;//Not executing an instruction
		default: memoryUnalignedAccess = 1'bx;//Something is not right; bad enum
	endcase
end

//Bad Funct3 Detection
always_comb
begin
	unique case (memoryMode)
		LOAD: memoryBadFunct3 = (funct3 == 3'b011) || (funct3 == 3'b110)|| (funct3 == 3'b111);//None of these funct3s exist
		STORE_PRELOAD, STORE: memoryBadFunct3 = !((funct3 == 3'b000) || (funct3 == 3'b001)|| (funct3 == 3'b010));//Only these 3 funct3s exist
		NOP: memoryBadFunct3 = 1'b0;//Not executing an instruction
		default: memoryBadFunct3 = 1'bx;//Something is not right; bad enum
	endcase
end

endmodule: MemoryControllerErrorDetector