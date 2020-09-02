import JZJCoreFTypes::BranchALUMode_t;

module BranchALU
(
	//Control Signals
	input BranchALUMode_t branchALUMode,
	input [2:0] funct3,
	
	//Immediate Inputs
	input [31:0] immediateJ,
	input [31:0] immediateI,
	input [31:0] immediateB,
	
	//Register Inputs
	input [31:0] rs1,
	input [31:0] rs2,
	input [31:0] pcOfInstruction,
	
	//Outputs
	output [31:0] programCounterInput,
	output [31:0] branchALUOutput,
	
	//Error Flag
	output branchALUBadFunct3
);
logic [31:0] nextSeqentialPC;
logic [31:0] nextJALPC;
logic [31:0] nextJALRPC;
logic [31:0] nextBranchPC;

logic branchTaken;

/* Output Multiplexing */

//The only time the BranchALU writes to rd is for jal or jalr where nextSeqentialPC is written; for any other mode the output is ignored by RDInputChooser
assign branchALUOutput = nextSeqentialPC;

always_comb
begin
	case (branchALUMode)
		JAL: programCounterInput = nextJALPC;
		JALR: programCounterInput = nextJALRPC;
		BRANCH: programCounterInput = branchTaken ? nextBranchPC : nextSeqentialPC;
		INCREMENT: programCounterInput = nextSeqentialPC;
		default: programCounterInput = 32'hxxxxxxxx;//Invalid enum
	endcase
end

/* PC Generation Logic */

assign nextSeqentialPC = pcOfInstruction + 4;
assign nextJALPC = pcOfInstruction + immediateJ;
assign nextJALRPC = rs1 + immediateI;
assign nextBranchPC = pcOfInstruction + immediateB;

/* Branch Comparison */
always_comb
begin
	case (funct3)
		3'b000: branchTaken = rs1 == rs2;//beq
		3'b001: branchTaken = rs1 != rs2;//bne
		3'b100: branchTaken = $signed(rs1) < $signed(rs2);//blt
		3'b101: branchTaken = $signed(rs1) >= $signed(rs2);//bge
		3'b110: branchTaken = rs1 < rs2;//bltu
		3'b111: branchTaken = rs1 >= rs2;//bgeu
		default: branchTaken = 1'bx;//Invalid funct3
	endcase
end

/* Bad Funct3 Detection */
always_comb
begin
	if ((branchALUMode == BRANCH) && ((funct3 == 3'b010) || (funct3 == 3'b011)))
		branchALUBadFunct3 = 1'b1;
	else//Valid funct3
		branchALUBadFunct3 = 1'b0;
end

endmodule