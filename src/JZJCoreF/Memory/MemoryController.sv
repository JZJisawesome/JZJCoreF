import JZJCoreFTypes::*;

module MemoryController
#(
	parameter INITIAL_MEM_CONTENTS,
	parameter int RAM_A_WIDTH
)
(
	input logic clock, reset,
	
	//Memory Mode and Control
	input MemoryMode_t memoryMode,//LOAD, STORE_PREFETCH, and NOP do not alter any internal states, but only NOP will never set error flags 
	input Funct3_t funct3,
	
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
	output ErrorFlag_t memoryUnalignedAccess,
	
	//Memory Mapped Ports
	//mmioInputs [7:0] and mmioOutputs [7:0] are at byte-wise memory addresses [FFFFFFE0:FFFFFFFC] (each are 4 bytes (1 word) wide)
	input logic [31:0] mmioInputs [8],
	output logic [31:0] mmioOutputs [8]
);
/* Primitives */
WriteEnable_t backendWriteEnable;

//Instruction Fetching
logic [29:0] backendInstructionAddress;

//Data Addressing
logic [31:0] addressToAccess;
logic [29:0] backendAddress;
logic [1:0] offset;

//Memory Mapped IO Data Connections
WriteEnable_t mmioWriteEnable;
logic [31:0] mmioDataOut;//Big endian

//RAM Data Connections
WriteEnable_t ramWriteEnable;
logic [31:0] ramDataOut;//Big endian

/* Instruction Fetching Logic */

assign backendInstructionAddress = instructionAddressToAccess[31:2];//If the instruction offset is bad, the ProgramCounter will set its error flag so we don't worry about that here

/* Data Addressing And Write Enable Logic */

//Determine byte-wise address from the instruction
always_comb
begin
	case (memoryMode)
		LOAD: addressToAccess = rs1 + immediateI;
		STORE_PRELOAD, STORE: addressToAccess = rs1 + immediateS;//STORE_PRELOAD loads data currently at the address of the read-modify-write sequence
		default: addressToAccess = 'x;//NOP or Invalid enum
	endcase
end

//Split up addressToAccess into backendAddress and byte offset
assign backendAddress = addressToAccess[31:2];//High 30 bits
assign offset = addressToAccess[1:0];//Low 2 bits

//Write enable logic
assign backendWriteEnable = WriteEnable_t'(memoryMode == STORE);//We only ever write to memory for a store operation
assign mmioWriteEnable = WriteEnable_t'(backendWriteEnable & backendAddress[29]);//Upper half of memory is dedicated to MMIO
assign ramWriteEnable = WriteEnable_t'(backendWriteEnable & ~backendAddress[29]);//Lower half of memory is dedicated to RAM

/* Output Multiplexer */

always_comb
begin
	if (backendAddress[29])//Upper half of memory is dedicated to MMIO
		memoryOutput = mmioDataOut;
	else//Lower half of memory is dedicated to RAM
		memoryOutput = ramDataOut;
end

/* Unaligned Access Detection */

//TODO speed up
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

/* Modules */

MemoryMappedIO memoryMappedIO(.*);//Upper half of memory is dedicated to MMIO

RAMWrapper #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) ramWrapper(.*);//Lower half of memory is dedicated to RAM

endmodule: MemoryController