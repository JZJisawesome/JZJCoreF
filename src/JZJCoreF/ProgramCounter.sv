module ProgramCounter
#(
	parameter INITIAL_PC = 32'h00000000
)
(
	input clock, reset,
	
	//Read Port
	output [31:0] pcOfInstruction,
	
	//Write Port
	input [31:0] programCounterInput,
	input programCounterWriteEnable,
	
	//Error Flag
	output programCounterMisaligned
);
reg [31:0] programCounter = INITIAL_PC;

assign pcOfInstruction = programCounter;
assign programCounterMisaligned = programCounter[1:0] != 2'b00;

/* Writing Logic */
always_ff @(posedge clock, posedge reset)
begin
	if (reset)
		programCounter <= INITIAL_PC;
	else if (clock)
	begin
		if (programCounterWriteEnable)
			programCounter <= programCounterInput;
	end
end

endmodule