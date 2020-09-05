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
	input WriteEnable_t rdWriteEnable
);
/* Primitives */

reg [31:0] registerFile [32:1];//x1 through x31

//Read Port Multiplexing
assign rs1 = getRegister(registerFile, decodedAddresses.rs1Address);
assign rs2 = getRegister(registerFile, decodedAddresses.rs2Address);
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
		if (rdWriteEnable)
			registerFile[decodedAddresses.rdAddress] <= rd;
	end
end

/* Register File Initialization */
initial
begin
	for (int i = 1; i < 32; ++i)
		registerFile[i] = 32'h00000000;
end

/* Read Multiplexer Function */

function automatic logic [31:0] getRegister(input [31:0] registerFile [32:1], input [4:0] address);
begin
	unique case (address)//If I don't manually specify each register (eg. default: registerFile[address]), it creates 2 tiers of multiplexers and slows things down significantly
		0: getRegister = 32'h00000000;//x0 is always 0
		1: getRegister = registerFile[1];
		2: getRegister = registerFile[2];
		3: getRegister = registerFile[3];
		4: getRegister = registerFile[4];
		5: getRegister = registerFile[5];
		6: getRegister = registerFile[6];
		7: getRegister = registerFile[7];
		8: getRegister = registerFile[8];
		9: getRegister = registerFile[9];
		10: getRegister = registerFile[10];
		11: getRegister = registerFile[11];
		12: getRegister = registerFile[12];
		13: getRegister = registerFile[13];
		14: getRegister = registerFile[14];
		15: getRegister = registerFile[15];
		16: getRegister = registerFile[16];
		17: getRegister = registerFile[17];
		18: getRegister = registerFile[18];
		19: getRegister = registerFile[19];
		20: getRegister = registerFile[20];
		21: getRegister = registerFile[21];
		22: getRegister = registerFile[22];
		23: getRegister = registerFile[23];
		24: getRegister = registerFile[24];
		25: getRegister = registerFile[25];
		26: getRegister = registerFile[26];
		27: getRegister = registerFile[27];
		28: getRegister = registerFile[28];
		29: getRegister = registerFile[29];
		30: getRegister = registerFile[30];
		31: getRegister = registerFile[31];
	endcase
end
endfunction

endmodule