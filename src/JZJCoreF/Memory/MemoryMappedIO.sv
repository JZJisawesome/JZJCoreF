import JZJCoreFTypes::*;

module MemoryMappedIO
#(
	parameter int RAM_A_WIDTH
)
(
	input logic clock, reset,
	
	//MemoryBackend Interface
	input logic [PHYS_MAX:0] backendAddress,
	output logic [31:0] mmioDataOut,
	input logic [31:0] rs2,//Data to write from instruction
	input WriteEnable_t mmioWriteEnable,
	
	//Memory Mapped Ports
	//mmioInputs [7:0] and mmioOutputs [7:0] are at word-wise memory addresses [3FFFFFF8:3FFFFFFF]
	input logic [31:0] mmioInputs [8],
	output reg [31:0] mmioOutputs [8]
);
//Physical Addressing Parameters
//Physical addressing width "hugs" around the ram address width
localparam PHYSICAL_WIDTH = RAM_A_WIDTH + 1;//1 bit extra for mmio/ram switching + the size of ram
localparam PHYS_MAX = PHYSICAL_WIDTH - 1;

//Port Addressing
logic [2:0] portNumber;
assign portNumber = backendAddress[2:0];//We only care about the low 3 bits

//Read Logic
assign mmioDataOut = mmioInputs[portNumber];

//Write Logic
always_ff @(posedge clock, posedge reset)
begin
	if (reset)
	begin
		for (int i = 0; i < 8; ++i)
			mmioOutputs[i] <= 32'h00000000;
	end
	else if (clock)
	begin
		if (mmioWriteEnable)
			mmioOutputs[portNumber] <= rs2;//Latch new data to output
	end
end

//Output Register Initialization
initial
begin
	for (int i = 0; i < 8; ++i)
		mmioOutputs[i] = 32'h00000000;
end

endmodule