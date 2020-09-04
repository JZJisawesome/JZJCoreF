module ALU
(
	//Determine ALU function
	input Funct3_t funct3,
	input Funct7_t funct7,
	input logic opImm,//Instruction type is OP-IMM (so using immediateI instead of rs2)
	
	//Operands
	input logic [31:0] rs1,
	input logic [31:0] rs2,
	input logic [31:0] immediateI,
	
	//Output
	output logic [31:0] aluOutput
);
logic [31:0] secondOperand;

/* Input Multiplexing */

always_comb
begin
	if (opImm)
	begin
		secondOperand = immediateI;
	end
	else
		secondOperand = rs2;
end

/* ALU Functions */
always_comb
begin
	unique case (funct3)
		3'b000://add/sub/addi
		begin
			if (opImm)//There is no subi
				aluOutput = rs1 + secondOperand;//addi
			else
				aluOutput = funct7[5] ? rs1 - secondOperand : rs1 + secondOperand;//add/sub
		end
		3'b001: aluOutput = rs1 << secondOperand[4:0];//sll/slli
		3'b010: aluOutput = ($signed(rs1) < $signed(secondOperand)) ? 32'h00000001 : 32'h00000000;//slt/slti
		3'b011: aluOutput = (rs1 < secondOperand) ? 32'h00000001 : 32'h00000000;//sltu/sltiu
		3'b100: aluOutput = rs1 ^ secondOperand;//xor/xori
		3'b101: aluOutput = funct7[5] ? rs1 >>> secondOperand[4:0] : rs1 >> secondOperand[4:0];//srl/sra/srli/srai
		3'b110: aluOutput = rs1 | secondOperand;//or/ori
		3'b111: aluOutput = rs1 & secondOperand;//and/andi
	endcase
end

endmodule 
