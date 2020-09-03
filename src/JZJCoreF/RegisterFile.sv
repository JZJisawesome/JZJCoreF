import JZJCoreFTypes::DecodedAddresses_t;

module RegisterFile
(
	input logic clock, reset,
	
	//Register addressing from the decoded instruction
	input DecodedAddresses_t decodedAddresses,
	
	//Read Ports
	output logic [31:0] rs1, rs2,
	output logic [31:0] register31Output,
	
	//Write Port
	input logic [31:0] rd,
	input logic rdWriteEnable
);
reg [31:0] registerFile [32];//x0 through x31

//Read Port Multiplexing
assign rs1 = registerFile[decodedAddresses.rs1Address];
assign rs2 = registerFile[decodedAddresses.rs2Address];
assign register31Output = registerFile[31];

/* Write Interface Logic */
always_ff @(posedge clock, posedge reset)
begin
	if (reset)
	begin
		for (int i = 1; i < 32; ++i)//x0 does not need to be reset because it is never modified
			registerFile[i] <= 32'h00000000;
	end
	else if (clock)
	begin
		if (rdWriteEnable && (decodedAddresses.rdAddress != 5'b00000))//x0 must always be 32'h00000000
			registerFile[decodedAddresses.rdAddress] <= rd;
	end
end

/* Register File Initialization */
initial
begin
	for (int i = 0; i < 32; ++i)
		registerFile[i] = 32'h00000000;
end

endmodule