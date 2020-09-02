typedef struct//DecodedInstruction
{
	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	
	//Instruction Encoding
	logic [6:0] opcode;
	logic [2:0] funct3;
	logic [6:0] funct7;
} DecodedInstruction;

typedef struct//DecodedAddressing
{
	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	
	//Addressing
	logic [4:0] rs1Address;
	logic [4:0] rs2Address;
	logic [4:0] rdAddress;
} DecodedAddressing;

//Todo this might make sense to seperate out into indivdual immediate types instead of using a struct (memory nor alu use all the immediate types)
typedef struct//DecodedImmediates
{
	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	
	//Immediates (preprocessed)
	logic [31:0] immediateI;
	logic [31:0] immediateS;
	logic [31:0] immediateB;
	logic [31:0] immediateU;
	logic [31:0] immediateJ;
} DecodedImmediates;

module InstructionDecoder
(
	input [31:0] instruction,
	output DecodedInstruction decodedInstruction,
	output DecodedAddressing decodedAddressing,
	output DecodedImmediates decodedImmediates
);
//Instruction Encoding
assign decodedInstruction.opcode = instruction[6:0];
assign decodedInstruction.funct3 = instruction[14:12];
assign decodedInstruction.funct7 = instruction[31:25];

//Addressing
assign decodedAddressing.rs1Address = instruction[19:15];
assign decodedAddressing.rs2Address = instruction[24:20];
assign decodedAddressing.rdAddress = instruction[11:7];

//Immediates (preprocessed)


/* Bit Extension Functions */

endmodule