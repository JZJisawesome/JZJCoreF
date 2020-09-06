module InferredRAM
#(
	parameter INITIAL_MEM_CONTENTS,
	parameter RAM_A_WIDTH
)
(
	input clock,
	
	//Write Port
	input [A_MAX:0] writeAddress,
	input [31:0] dataIn,
	input writeEnable,
	
	//Read Port A
	input [A_MAX:0] readAddressA,
	output reg [31:0] dataOutA,
	
	//Read Port B
	input [A_MAX:0] readAddressB,
	output reg [31:0] dataOutB
);
//Primitives
localparam A_MAX = RAM_A_WIDTH - 1;
localparam NUMBER_OF_ADDRESSES = 2 ** RAM_A_WIDTH;

reg [31:0] inferredRam [NUMBER_OF_ADDRESSES];

//Port Reading and Writing Logic
always_ff @(posedge clock)
begin
	//Write Port
	if (writeEnable)
		inferredRam[writeAddress] <= dataIn;
	
	//Read Ports
	dataOutA <= inferredRam[readAddressA];
	dataOutB <= inferredRam[readAddressB];
end

//Memory Initialization
initial
begin
	$readmemh(INITIAL_MEM_CONTENTS, inferredRam);
end

endmodule 
