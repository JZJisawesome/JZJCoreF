import JZJCoreFTypes::ImmediateFormerMode_t;

module ImmediateFormer
(
	input ImmediateFormerMode_t immediateFormerMode,

	//Operands
	input [31:0] immediateU,
	input [31:0] pcOfInstruction,
	
	//Output
	output [31:0] immediateFormerOutput
);
/* Multiplexing Logic */

always_comb
begin
	if (immediateFormerMode == LUI)
		immediateFormerOutput = immediateU;
	else//auipc
		immediateFormerOutput = immediateU + pcOfInstruction;
end

endmodule