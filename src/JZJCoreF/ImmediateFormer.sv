import JZJCoreFTypes::*;

module ImmediateFormer
(
	//Type of immediate to form (LUI or AUIPC)
	input ImmediateFormerMode_t immediateFormerMode,

	//Operands
	input logic [31:0] immediateU,
	input logic [31:0] pcOfInstruction,//Only for AUIPC
	
	//Output
	output logic [31:0] immediateFormerOutput
);
/* Multiplexing Logic */
always_comb
begin
	unique case (immediateFormerMode)
		LUI: immediateFormerOutput = immediateU;
		AUIPC: immediateFormerOutput = immediateU + pcOfInstruction;
		default: immediateFormerOutput = 'x;//immediateFormerMode is invalid
	endcase
end

endmodule