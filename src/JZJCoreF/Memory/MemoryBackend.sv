module MemoryBackend
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",
	parameter RAM_A_WIDTH = 12
)
(
	input logic clock, reset,
	
	//Read/Write Address
	input logic [29:0] backendAddress,
	
	//Read Port
	output logic [31:0] backendDataOut,
	
	//Write Port
	input logic [31:0] backendDataIn,
	input logic backendWriteEnable,
	
	//Instruction Fetch (only from RAM)
	input logic [29:0] backendInstructionAddress,
	output logic [31:0] instructionLittleEndian
	
	//todo put mmio inputs and outputs here
);

//TODO in the future, addressing logic for switching between mmio and ram

InferredRAM #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) inferredRamTemp(.*, .writeAddress(backendAddress), .dataIn(backendDataIn),
																																		.writeEnable(backendWriteEnable), .readAddressA(backendAddress),
																																		.dataOutA(backendDataOut), .readAddressB(backendInstructionAddress),
																																		.dataOutB(instructionLittleEndian));

endmodule 
