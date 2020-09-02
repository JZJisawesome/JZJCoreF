module MemoryBackend
#(
	parameter INITIAL_MEM_CONTENTS = "initialRam.mem",
	parameter RAM_A_WIDTH = 12
)
(
	input clock, reset,
	
	//Read/Write Address
	input [29:0] backendAddress,
	
	//Read Port
	output [31:0] backendDataOut,
	
	//Write Port
	input [31:0] backendDataIn,
	input backendWriteEnable,
	
	//Instruction Fetch (only from RAM)
	input [29:0] backendInstructionAddress,
	output [31:0] instruction
);

endmodule 
