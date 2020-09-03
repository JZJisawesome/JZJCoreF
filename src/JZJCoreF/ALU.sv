module ALU
(
	//Determine ALU function
	input [2:0] funct3,
	input [6:0] funct7,
	input opImm,//Instruction type is OP-IMM (so using immediateI instead of rs2)
	
	//Operands
	input [31:0] rs1,
	input [31:0] rs2,
	input [31:0] immediateI,
	
	//Output
	output logic [31:0] aluOutput
);
logic [31:0] operand2;

/* Input Multiplexing */

always_comb
begin
	if (opImm)
	begin
		operand2 = immediateI;
	end
	else
		operand2 = rs2;
end

/* ALU Functions */
always_comb
begin
	unique case (funct3)
		3'b000://add/sub/addi
		begin
			if (opImm)//There is no subi
				aluOutput = rs1 + operand2;//addi
			else
				aluOutput = funct7[5] ? rs1 - operand2 : rs1 + operand2;//add/sub
		end
		3'b001: aluOutput = rs1 << operand2[4:0];//sll/slli
		3'b010: aluOutput = ($signed(rs1) < $signed(operand2)) ? 32'h00000001 : 32'h00000000;//slt/slti
		3'b011: aluOutput = (rs1 < operand2) ? 32'h00000001 : 32'h00000000;//sltu/sltiu
		3'b100: aluOutput = rs1 ^ operand2;//xor/xori
		3'b101: aluOutput = funct7[5] ? rs1 >>> operand2[4:0] : rs1 >> operand2[4:0];//srl/sra/srli/srai
		3'b110: aluOutput = rs1 | operand2;//or/ori
		3'b111: aluOutput = rs1 & operand2;//and/andi
	endcase
end

endmodule 
