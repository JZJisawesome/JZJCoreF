//Note: This is not part of the core, just a file for me to use to test the core on my devboard
//To actually use the core, just add JZJCoreF.sv and its dependencies to your project (everything in the JZJCoreF folder)
//This and multi7seg are the only modules borrowed from older cores (other then ideas that I had from then)
module TopTestFile//heavily borrowed from JZJCoreE
(
	input logic clock,//50mhz
	input logic notReset,

	//Testing things I have setup
	input logic [3:0] notButton,
	output logic [3:0] notLed,
	output logic [7:0] logicAnalyzerOut,
	//7 segment display
	output logic [7:0] segment,
	output logic [3:0] digit
);
//Inversion for inverted devboard stuff
wire reset = ~notReset;
wire [3:0] button = ~notButton;
logic [3:0] led;
assign notLed = ~led;

//Clock stuff division stuff
reg [18:0] clockPrescaler = '0;
always_ff @(posedge clock)
begin
	clockPrescaler <= clockPrescaler + '1;
end

wire clock25MHz = clockPrescaler[0];//25mhz (50mhz / (2^1))
wire clock90Hz = clockPrescaler[18];//about 90 hz (50mhz / (2^19)) (for debugging)

//Wires
wire [31:0] register31Output;

assign logicAnalyzerOut[7] = clock90Hz;
assign logicAnalyzerOut[6:0] = register31Output;

//Port stuffs
logic [31:0] mmioInputs [8];
logic [31:0] mmioOutputs [8];
assign mmioInputs[4][3:0] = button[3:0];//Todo this really should be synchronized before passing to the core
assign led[3:0] = mmioOutputs[4][7:4];
assign mmioInputs[4][7:4] = mmioOutputs[4][7:4];//Feedback from leds

logic [15:0] displayOutput;

//Choose source for display output
assign displayOutput = mmioOutputs[5][15:0];
//assign displayOutput = register31Output;

//The core
localparam FILE = "../jzjcoresoftware/precompiled/c/corefdemo.hex";

//Full speed
//JZJCoreF #(.INITIAL_MEM_CONTENTS(FILE)) coreTest(.*);

//Half speed
//JZJCoreF #(.INITIAL_MEM_CONTENTS(FILE)) coreTest(.*, .clock(clock25MHz));

//Slow
JZJCoreF #(.INITIAL_MEM_CONTENTS(FILE)) coreTest(.*, .clock(clock90Hz));

//7 segment display output (in Verilog)
multi7seg (.clock(clockPrescaler[17]), .data0(displayOutput[15:12]), .data1(displayOutput[11:8]), .data2(displayOutput[7:4]), .data3(displayOutput[3:0]), .segment(segment), .ground(digit));

endmodule