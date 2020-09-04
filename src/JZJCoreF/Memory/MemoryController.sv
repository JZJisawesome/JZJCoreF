import JZJCoreFTypes::*;

import EndiannessFunctions::toBigEndian32;
import EndiannessFunctions::toLittleEndian32;
import EndiannessFunctions::toBigEndian16;
import EndiannessFunctions::toLittleEndian16;

import BitExtensionFunctions::signExtend16To32;
import BitExtensionFunctions::signExtend8To32;
import BitExtensionFunctions::zeroExtend16To32;
import BitExtensionFunctions::zeroExtend8To32;

module MemoryController
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",
	parameter RAM_A_WIDTH = 12
)
(
	input logic clock, reset,
	
	//Memory Mode and Control
	input MemoryMode_t memoryMode,//LOAD, STORE_PREFETCH, and NOP do not alter any internal states, but only NOP will never set error flags 
	input logic [2:0] funct3,
	
	//Addressing
	input logic [31:0] rs1,
	input logic [31:0] immediateI,
	input logic [31:0] immediateS,
	
	//Memory Loads
	output logic [31:0] memoryOutput,//Will only update if memoryMode is LOAD
	
	//Memory Stores
	input logic [31:0] rs2,//Will only write if memoryMode is STORE; for half words and bytes the memoryMode must be STORE_PRELOAD for 1 cycle first, then STORE to actually write
	
	//Instruction Fetching
	input logic [31:0] instructionAddressToAccess,
	output logic [31:0] instruction,
	
	//Error Flag
	output logic memoryUnalignedAccess,
	
	//Memory Mapped Ports
	//mmioInputs [7:0] and mmioOutputs [7:0] are at byte-wise memory addresses [FFFFFFE0:FFFFFFFC] (each are 4 bytes (1 word) wide)
	input logic [31:0] mmioInputs [8],
	output reg [31:0] mmioOutputs [8]
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
logic [31:0] instructionLittleEndian;

assign backendWriteEnable = memoryMode == STORE;
assign instruction = toBigEndian32(instructionLittleEndian);

/* Addressing Logic */

assign backendInstructionAddress = instructionAddressToAccess[31:2];//If the instruction offset is bad, the ProgramCounter will set its error flag so we don't worry about that here

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

/* Modules */
//Internal
//Should be nested but Quartus Prime does not support nested modules :(
MemoryControllerLOADProcessor memoryControllerLOADProcessor(.*);
MemoryControllerSTOREProcessor memoryControllerSTOREProcessor(.*);
MemoryControllerUnalignmentDetector unalignmentDetector(.*);

//External
MemoryBackend #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) memoryBackend(.*);

endmodule: MemoryController

/* Internal Modules */

//Should be nested but Quartus Prime does not support nested modules :(
module MemoryControllerLOADProcessor
(
	//Inputs and raw memory data
	input logic [2:0] funct3,
	input logic [1:0] offset,
	input logic [31:0] backendDataOut,
	
	//Output (what to write to rd)
	output logic [31:0] memoryOutput
);
/* backendDataOut to memoryOutput (reading/loading) */
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

endmodule: MemoryControllerLOADProcessor

//Should be nested but Quartus Prime does not support nested modules :(
module MemoryControllerSTOREProcessor
(
	//Inputs, new data, and old raw memory data at the address to write to
	input logic [2:0] funct3,
	input logic [1:0] offset,
	input logic [31:0] rs2,
	input logic [31:0] backendDataOut,//old data
	
	//Output (what to write to the memory address)
	output logic [31:0] backendDataIn
);
/* rs2 + (possibly) backendDataOut to backendDataIn (writing/storing) */
always_comb//Assumes memoryMode is STORE since backendDataIn will not be writen unless memoryMode == STORE (see backendWriteEnable)
begin//If funct3 is sb or sh, backendDataOut will have already been updated with the original contents of an address last posedge (STORE_PRELOAD), so we can use that here
	unique case (funct3)
		3'b000: backendDataIn = replaceByteAtOffset(backendDataOut, rs2[7:0], offset);//sb
		3'b001: backendDataIn = replaceHalfwordAtOffset(backendDataOut, toLittleEndian16(rs2[15:0]), offset);//sh
		3'b010: backendDataIn = toLittleEndian32(rs2);//sw
		default: backendDataIn = 'x;//Bad funct3 or not STORE
	endcase
end

/* Replacement Functions */

function automatic logic [31:0] replaceByteAtOffset(input [31:0] data, input [7:0] newData, input [1:0] offset);
begin
	unique case (offset)
		2'b00: replaceByteAtOffset = {newData[7:0], data[23:0]};
		2'b01: replaceByteAtOffset = {data[31:24], newData[7:0], data[15:0]};
		2'b10: replaceByteAtOffset = {data[31:16], newData[7:0], data[7:0]};
		2'b11: replaceByteAtOffset = {data[31:8], newData[7:0]};
	endcase
end
endfunction

function automatic logic [31:0] replaceHalfwordAtOffset(input [31:0] data, input [15:0] newData, input [1:0] offset);
begin
	unique case (offset)
		2'b00: replaceHalfwordAtOffset = {newData[15:0], data[15:0]};
		2'b10: replaceHalfwordAtOffset = {data[31:16], newData[15:0]};
		default: replaceHalfwordAtOffset = 'x;//Bad offset
	endcase
end
endfunction

endmodule: MemoryControllerSTOREProcessor

//Should be nested but Quartus Prime does not support nested modules :(
module MemoryControllerUnalignmentDetector
(
	//Inputs
	input MemoryMode_t memoryMode,
	input logic [2:0] funct3,
	input logic [1:0] offset,
	
	//Error Flag
	output logic memoryUnalignedAccess
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

endmodule: MemoryControllerUnalignmentDetector