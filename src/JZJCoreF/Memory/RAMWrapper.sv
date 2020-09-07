import JZJCoreFTypes::*;

import EndiannessFunctions::toBigEndian32;
import EndiannessFunctions::toLittleEndian32;
import EndiannessFunctions::toBigEndian16;
import EndiannessFunctions::toLittleEndian16;

import BitExtensionFunctions::signExtend16To32;
import BitExtensionFunctions::signExtend8To32;
import BitExtensionFunctions::zeroExtend16To32;
import BitExtensionFunctions::zeroExtend8To32;

module RAMWrapper
#(
	parameter INITIAL_MEM_CONTENTS,
	parameter int RAM_A_WIDTH
)
(
	input logic clock, reset,

	//Processing mode
	input logic [2:0] funct3,

	//Data Addressing
	input logic [29:0] backendAddress,
	input logic [1:0] offset,
	
	//Data IO
	input WriteEnable_t ramWriteEnable,
	input logic [31:0] rs2,
	output logic [31:0] ramDataOut,//Big endian
	
	//Instruction Fetching
	input logic [29:0] backendInstructionAddress,
	output logic [31:0] instruction
);
//Note: For a store that is not a whole word, the backendAddress must be set to the location of the store for a posedge
//in order to modify the existing data and write back to the address on a second posedge

/* Primitives */
logic [31:0] instructionLittleEndian;

logic [31:0] ramDataOutLittleEndian;
logic [31:0] ramDataIn;

//Instruction endianness conversion
assign instruction = toBigEndian32(instructionLittleEndian);//Convert fetched instruction to big endian

/* Read Logic */

//ramDataOutLittleEndian to ramDataOut
always_comb//Assumes memoryMode is LOAD
begin
	unique case (funct3)
		3'b000: ramDataOut = signExtend8To32(getByteAtOffset(ramDataOutLittleEndian, offset));//lb
		3'b001: ramDataOut = signExtend16To32(toBigEndian16(getHalfwordAtOffset(ramDataOutLittleEndian, offset)));//lh
		3'b010: ramDataOut = toBigEndian32(ramDataOutLittleEndian);//lw
		3'b100: ramDataOut = zeroExtend8To32(getByteAtOffset(ramDataOutLittleEndian, offset));//lbu
		3'b101: ramDataOut = zeroExtend16To32(toBigEndian16(getHalfwordAtOffset(ramDataOutLittleEndian, offset)));//lhu
		default: ramDataOut = 'x;//Bad funct3 or memoryMode != LOAD
	endcase
end

/* Write Logic */

//rs2 + possibly ramDataOutLittleEndian to ramDataIn
always_comb//Assumes memoryMode is STORE (but does not actually write unless ramWriteEnable is 1'b1)
begin//ramDataOutLittleEndian should have already been updated with the original contents of the address last posedge (STORE_PRELOAD), so we use that here
	unique case (funct3)
		3'b000: ramDataIn = replaceByteAtOffset(ramDataOutLittleEndian, rs2[7:0], offset);//sb
		3'b001: ramDataIn = replaceHalfwordAtOffset(ramDataOutLittleEndian, toLittleEndian16(rs2[15:0]), offset);//sh
		3'b010: ramDataIn = toLittleEndian32(rs2);//sw
		default: ramDataIn = 'x;//Bad funct3 or memoryMode != STORE
	endcase
end

/* Helper Functions */

//Selection Functions
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

//Replacement Functions
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

/* The actual RAM */
InferredRAM #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) inferredRam
				 (.*, .writeAddress(backendAddress), .dataIn(ramDataIn), .writeEnable(logic'(ramWriteEnable)), .readAddressA(backendAddress), .dataOutA(ramDataOutLittleEndian),
				 .readAddressB(backendInstructionAddress), .dataOutB(instructionLittleEndian));

endmodule: RAMWrapper