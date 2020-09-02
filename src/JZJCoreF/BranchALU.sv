import JZJCoreFTypes::BranchALUMode_t;

module BranchALU
(
	//Control Signals
	input BranchALUMode_t branchALUMode,
	
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
	output [31:0] branchALUOutput
);

endmodule