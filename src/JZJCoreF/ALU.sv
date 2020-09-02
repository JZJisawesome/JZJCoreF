module ALU
(
	input aluOutputEnable,//If 0, force ALU output to '0 so that something else can write to registers

	//Determine ALU function
	input [2:0] funct3,
	input [6:0] funct7,
	input opImm,//Instruction type is OP-IMM (so using immediateI instead of rs2)
	
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
		y = immediateI;
	end
	else
		y = rs2;
end

/* ALU Functions */
always_comb
begin
	case (funct3)
		3'b000://add/sub/addi
		begin
			if (opImm)//There is no subi
				result = x + y;//addi
			else
				result = funct7[5] ? x - y : x + y;//add/sub
		end
		3'b001: result = x << y[4:0];//sll/slli
		3'b010: result = ($signed(x) < $signed(y)) ? 32'h00000001 : 32'h00000000;//slt/slti
		3'b011: result = (x < y) ? 32'h00000001 : 32'h00000000;//sltu/sltiu
		3'b100: result = x ^ y;//xor/xori
		3'b101: result = funct7[5] ? x >>> y[4:0] : x >> y[4:0];//srl/sra/srli/srai
		3'b110: result = x | y;//or/ori
		3'b111: result = x & y;//and/andi
	endcase
end

endmodule 
