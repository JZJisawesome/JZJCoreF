typedef struct
{
	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	logic [6:0] opcode
	

} DecodedInstruction;


module InstructionDecoder
(
	input [31:0] instruction,
	output DecodedInstruction decodedInstruction
);

endmodule