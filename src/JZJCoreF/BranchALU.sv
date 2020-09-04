import JZJCoreFTypes::*;

module BranchALU
(
	//Control Signals
	input BranchALUMode_t branchALUMode,
	input logic [2:0] funct3,
	
	//Immediate Inputs
	input logic [31:0] immediateJ,
	input logic [31:0] immediateI,
	input logic [31:0] immediateB,
	
	//Register Inputs
	input logic [31:0] rs1,
	input logic [31:0] rs2,
	input logic [31:0] pcOfInstruction,
	
	//Outputs
	output logic [31:0] programCounterInput,
	output logic [31:0] branchALUOutput,
	
	//Error Flag
	output logic branchALUBadBRANCHFunct3
);
logic [31:0] nextSeqentialPC;
logic [31:0] nextJALPC;
logic [31:0] nextJALRPC;
logic [31:0] nextBranchPC;

logic branchTaken;
logic [31:0] nextJALRPCIntermediateValue;

/* Output Multiplexing */

//The only time the BranchALU writes to rd is for jal or jalr where nextSeqentialPC is written
//For any other mode, the output is ignored by RDInputChooser so branchALUOutput can just be set to this permanetly
assign branchALUOutput = nextSeqentialPC;

always_comb
begin
	unique case (branchALUMode)
		JAL: programCounterInput = nextJALPC;
		JALR: programCounterInput = nextJALRPC;
		BRANCH: programCounterInput = branchTaken ? nextBranchPC : nextSeqentialPC;
		INCREMENT: programCounterInput = nextSeqentialPC;
		default: programCounterInput = 32'hxxxxxxxx;//branchALUMode is invalid
	endcase
end

/* PC Generation Logic */

assign nextJALRPCIntermediateValue = rs1 + immediateI;

assign nextSeqentialPC = pcOfInstruction + 4;
assign nextJALPC = pcOfInstruction + immediateJ;
assign nextJALRPC = {nextJALRPCIntermediateValue[31:1], 1'b0};//Low bit must be set to 0 after calculation
assign nextBranchPC = pcOfInstruction + immediateB;

/* Branch Comparison */
always_comb
begin
	unique case (funct3)
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
begin//Assumes branchALUMode is BRANCH
	if ((funct3 == 3'b010) || (funct3 == 3'b011))
		branchALUBadBRANCHFunct3 = 1'b1;
	else//Valid funct3
		branchALUBadBRANCHFunct3 = 1'b0;
end

endmodule