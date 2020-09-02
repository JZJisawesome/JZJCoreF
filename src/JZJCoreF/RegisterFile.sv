module RegisterFile
(
	input clock, reset,
	
	//Register addressing from decoded instruction
	input DecodedAddressing decodedAddressing,
	
	//Read Ports
	output [31:0] rs1, rs2,
	output [31:0] register31Output,
	
	//Write Interface
	input [31:0] rd,
	input rdWriteEnable
);
reg [31:0] registerFile [32];

//Read Port Multiplexing
assign rs1 = registerFile[decodedAddressing.rs1Address];
assign rs2 = registerFile[decodedAddressing.rs2Address];
assign register31Output = registerFile[31];

/* Write Interface Logic */
always_ff @(posedge clock, posedge reset)
begin
	if (reset)
		clearRegisterFile();
	else if (clock)
	begin
		if (rdWriteEnable && (decodedAddressing.rdAddress != 5'b00000))//x0 must always be 32'h00000000
			registerFile[decodedAddressing.rdAddress] <= rd;
	end
end

/* Register File Initialization */
initial
begin
	clearRegisterFile();
end

//Does not need to be automatic since there is only 1 registerFile
task clearRegisterFile();
begin
	for (int i = 0; i < 32; ++i)
		registerFile[i] <= 32'h00000000;
end
endtask

endmodule