module InferredRAM
#(
	parameter INITIAL_MEM_CONTENTS,
	parameter int RAM_A_WIDTH
)
(
	input logic clock,
	
	//Write Port
	input logic [A_MAX:0] writeAddress,
	input logic [31:0] dataIn,
	input logic writeEnable,
	
	//Read Port A
	input logic [A_MAX:0] readAddressA,
	output reg [31:0] dataOutA,
	
	//Read Port B
	input logic [A_MAX:0] readAddressB,
	output reg [31:0] dataOutB
);
//Primitives
localparam int A_MAX = RAM_A_WIDTH - 1;
localparam int NUMBER_OF_ADDRESSES = 2 ** RAM_A_WIDTH;

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
	//Old way, using the buggy formatVerilog program to make 8 bit verilog hex files into 32 bit
	//$readmemh(INITIAL_MEM_CONTENTS, inferredRam);
	
	//New way, based on code from https://stackoverflow.com/questions/32070651/reading-of-hex-file-in-testbench-verilog
	reg [7:0] inferredRam8 [NUMBER_OF_ADDRESSES * 4];//Should by synthesized away
	$readmemh(INITIAL_MEM_CONTENTS, inferredRam8);//Formatted as 8 bit wide data
	
	//Copy 8 bit data to 32 bit RAM (done during elaboration)
	for (reg [31:0] i = 0; i < NUMBER_OF_ADDRESSES; ++i)//Cannot use int because otherwise quartus complains
	begin
		//For some reason Quartus burns all my ram and uses up an entire core when I calculate the byteIndex
		//sepereatly. Verilator simulates this without a problem, but in order to be able to synthesize this I have to calculate i * 4
		//in the inferredRam8 index directly :(
		//int byteIndex = i * 4;
		
		//Quartus does not systhesize this properly either
		//I guess I will have to follow the stackoverflow answer more closely (using or)
		//inferredRam[i][31:24] = inferredRam8[(i * 4) + 0];
		//inferredRam[i][23:16] = inferredRam8[(i * 4) + 1];
		//inferredRam[i][15:8] = inferredRam8[(i * 4) + 2];
		//inferredRam[i][7:0] = inferredRam8[(i * 4) + 3];
		
		//THIS STILL DOSEN'T WORK WITH QUARTUS (little endian unlike the stackoverflow post)
		inferredRam[i] =	{24'h000000, inferredRam8[(i * 4) + 3]} |
								{16'h0000, inferredRam8[(i * 4) + 2], 8'h00} |
								{8'h00, inferredRam8[(i * 4) + 1], 16'h0000} |
								{inferredRam8[(i * 4) + 0], 24'h000000};
	end
end

endmodule 
