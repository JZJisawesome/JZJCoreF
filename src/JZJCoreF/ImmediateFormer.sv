import JZJCoreFTypes::ImmediateFormerMode_t;

module ImmediateFormer
(
	input ImmediateFormerMode_t immediateFormerMode,

	//Operands
	input [31:0] immediateU,
	input [31:0] pcOfInstruction,
	
	//Output
	output logic [31:0] immediateFormerOutput
);
/* Multiplexing Logic */
always_comb
begin//todo replace with case
	if (immediateFormerMode == LUI)
		immediateFormerOutput = immediateU;
	else if (immediateFormerMode == AUIPC)
		immediateFormerOutput = immediateU + pcOfInstruction;
	else
		immediateFormerOutput = 'x;//immediateFormerMode is invalid
end

endmodule