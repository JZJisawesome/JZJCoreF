module ALU
(
	input aluOutputEnable,//If 0, force ALU output to '0 so that something else can write to registers

	//Determine ALU function
	input [2:0] funct3,
	input [6:0] funct7,
	input [6:0] opImm,//Instruction type is OP-IMM (so using immediateI instead of rs2)
	
	//Operands
	input [31:0] rs1,
	input [31:0] rs2,
	input [31:0] immediateI,
	
	//Output
	output [31:0] aluOutput
);
logic [31:0] x;
logic [31:0] y;
logic [31:0] result;

assign aluOutput = aluOutputEnable ? result : 32'h00000000;

/* Input Multiplexing */
assign x = rs1;

always_comb
begin
	if (opImm)
	begin
		if (funct3 == 101)
			y = immediateI[4:0];//Only looking at low 5 bits
		else
			y = immediateI;//Looking at the whole immediate value
	end
	else
		y = rs2;
end

/* ALU Functions */
always_comb
begin
	case (funct3)
		3'b000://addi/add/sub
		begin
			if (opImm)//There is no subi
				result = x + y;//addi
			else
				result = funct7[5] ? x - y : x + y;//add/sub
		end
	endcase
end

endmodule 
