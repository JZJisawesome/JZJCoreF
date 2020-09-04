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
logic [31:0] mmioDataOut;
logic [31:0] ramDataOut;
logic ramWriteEnable;

/* backendDataOut Multiplexing and ramWriteEnable Control */
always_comb
begin
	if (backendAddress[29])//Upper half of the address space is for memory mapped io
	begin
		backendDataOut = mmioDataOut;
		ramWriteEnable = 1'b0;
	end
	else//Lower half of the address space is for ram
	begin
		backendDataOut = ramDataOut;
		ramWriteEnable = backendWriteEnable;
	end
end

/* Backend Backend Modules */



InferredRAM #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) inferredRam
				 (.*, .writeAddress(backendAddress), .dataIn(backendDataIn), .writeEnable(ramWriteEnable), .readAddressA(backendAddress), .dataOutA(ramDataOut),
				 .readAddressB(backendInstructionAddress), .dataOutB(instructionLittleEndian));


//TODO in the future, addressing logic for switching between mmio and ram

//temporary
/*InferredRAM #(.INITIAL_MEM_CONTENTS(INITIAL_MEM_CONTENTS), .RAM_A_WIDTH(RAM_A_WIDTH)) inferredRamTemp(.*, .writeAddress(backendAddress), .dataIn(backendDataIn),
																																		.writeEnable(backendWriteEnable), .readAddressA(backendAddress),
																																		.dataOutA(backendDataOut), .readAddressB(backendInstructionAddress),
																																		.dataOutB(instructionLittleEndian));
*/
endmodule 
