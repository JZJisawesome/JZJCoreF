import JZJCoreFTypes::*;

module InstructionAddressMux
(
	//Choose instruction address source (NEXT_PC or CURRENT_PC)
	input InstructionAddressSource_t instructionAddressSource,

	//Inputs
	input logic [31:0] programCounterInput,//Output of BranchALU before being latched by the ProgramCounter (NEXT_PC)
	input logic [31:0] pcOfInstruction,//The current contents of the ProgramCounter (CURRENT_PC)

	//Output (address for MemoryController port)
	output logic [31:0] instructionAddressToAccess
);
//Multiplexing
always_comb
begin
	unique case (instructionAddressSource)
		NEXT_PC: 	instructionAddressToAccess = programCounterInput;
		CURRENT_PC:	instructionAddressToAccess = pcOfInstruction;
		default: 	instructionAddressToAccess = 'x;//instructionAddressSource is invalid
	endcase
end

endmodule