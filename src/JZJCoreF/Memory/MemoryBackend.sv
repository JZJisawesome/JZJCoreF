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
	output logic [31:0] instructionLittleEndian,
	
	//Memory Mapped Ports
	//mmioInputs [7:0] and mmioOutputs [7:0] are at word-wise memory addresses [3FFFFFF8:3FFFFFFF]
	input logic [31:0] mmioInputs [8],
	output reg [31:0] mmioOutputs [8]
);
logic [31:0] mmioDataOut;
logic [31:0] ramDataOut;
logic mmioWriteEnable;
logic ramWriteEnable;

/* backendDataOut Multiplexing and ramWriteEnable/mmioWriteEnable Control */
always_comb
begin
	if (backendAddress[29])//Upper half of the address space is for memory mapped io
	begin
		backendDataOut = mmioDataOut;
		mmioWriteEnable = backendWriteEnable;
		ramWriteEnable = 1'b0;
	end
	else//Lower half of the address space is for ram
	begin
		backendDataOut = ramDataOut;
		mmioWriteEnable = 1'b0;
		ramWriteEnable = backendWriteEnable;
	end
end

/* Backend Backend Modules */

MemoryMappedIO memoryMappedIO(.*);

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
