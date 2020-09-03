module ProgramCounter
#(
	parameter RESET_VECTOR = 32'h00000000
)
(
	input logic clock, reset,
	
	//Read Port
	output logic [31:0] pcOfInstruction,
	
	//Write Port
	input logic  [31:0] programCounterInput,//Latched on the positive edge when programCounterWriteEnable is asserted
	input logic programCounterWriteEnable,
	
	//Error Flag
	output logic programCounterMisaligned
);
reg [31:0] programCounter = RESET_VECTOR;

assign pcOfInstruction = programCounter;
assign programCounterMisaligned = programCounter[1:0] != 2'b00;

/* Writing Logic */
always_ff @(posedge clock, posedge reset)
begin
	if (reset)
		programCounter <= RESET_VECTOR;
	else if (clock)
	begin
		if (programCounterWriteEnable)
			programCounter <= programCounterInput;
	end
end

endmodule