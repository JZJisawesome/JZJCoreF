module RDInputChooser
(
	//Module output selection (from control logic)
	//Only 1 should be enabled at a time, could be bundled in a struct down the road
	input memoryOutputEnable,
	input aluOutputEnable,
	input immediateFormerOutputEnable,
	input branchALUOutputEnable,

	//Inputs from modules
	input [31:0] memoryOutput,
	input [31:0] aluOutput,
	input [31:0] immediateFormerOutput,
	input [31:0] branchALUOutput,
	
	//Output to register file in (rd)
	output logic [31:0] rd
);
//Switched versions of module data are 32'h00000000 if their corresponding enable line is disabled
logic [31:0] memoryOutputSwitched;
logic [31:0] aluOutputSwitched;
logic [31:0] immediateFormerOutputSwitched;
logic [31:0] branchALUOutputSwitched;

//Or all inputs together
//Proably should be swapped with a priority decoder if that is faster, but at least this is better than a wor
assign rd = memoryOutputSwitched | aluOutputSwitched | immediateFormerOutputSwitched | branchALUOutputSwitched;

/* Switching Logic */
//Switched versions of module data are 32'h00000000 if their corresponding enable line is disabled
always_comb
begin
	memoryOutputSwitched = memoryOutput & {{32{memoryOutputEnable}}};
	aluOutputSwitched = aluOutput & {{32{aluOutputEnable}}};
	immediateFormerOutputSwitched = immediateFormerOutput & {{32{immediateFormerOutputEnable}}};
	branchALUOutputSwitched = branchALUOutput & {{32{branchALUOutputEnable}}};
end

endmodule