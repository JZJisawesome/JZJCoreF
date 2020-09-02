typedef struct//DecodedInstruction
{
	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	
	//Instruction Encoding
	logic [6:0] opcode;
	logic [2:0] funct3;
	logic [6:0] funct7;
	
	//Addressing
	logic [4:0] rs1Address;
	logic [4:0] rs2Address;
	logic [4:0] rdAddress;
	
	//Immediates (preprocessed)
	logic [31:0] immediateI;
	logic [31:0] immediateS;
	logic [31:0] immediateB;
	logic [31:0] immediateU;
	logic [31:0] immediateJ;

} DecodedInstruction;

module InstructionDecoder
(
	input [31:0] instruction,
	output DecodedInstruction decodedInstruction
);
//Instruction Encoding
assign decodedInstruction.opcode = instruction[6:0];
assign decodedInstruction.funct3 = instruction[14:12];
assign decodedInstruction.funct7 = instruction[31:25];

//Addressing
assign decodedInstruction.rs1Address = instruction[19:15];
assign decodedInstruction.rs2Address = instruction[24:20];
assign decodedInstruction.rdAddress = instruction[11:7];

//Immediates (preprocessed)


/* Bit Extension Functions */

endmodule