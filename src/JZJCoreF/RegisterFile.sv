module RegisterFile
(
	input logic clock, reset,
	
	//Read Ports
	input logic [4:0] rs1Address, rs2Address
	output logic [31:0] rs1, rs2,
	output logic [31:0] register31Output,
	
	//Write Interface
	input logic [4:0] rdAddress,
	input logic [31:0] rd,
	input logic writeEnable
);
/* Registers */
reg [31:0] registerFile [32];

/* Read Port Multiplexing */
assign rs1 = registerFile[rs1Address];
assign rs2 = registerFile[rs2Address];
assign register31Output = registerFile[31];

/* Write Interface Logic */
always_ff @(posedge clock, posedge reset)
begin
	if (reset)
		clearRegisterFile();
	else if (clock)
	begin
		if (writeEnable && (rdAddress != 5'b00000))//x0 must always be 32'h00000000
			registerFile <= rd;
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

endmodule