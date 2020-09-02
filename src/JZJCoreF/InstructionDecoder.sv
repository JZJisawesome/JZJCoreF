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

module InstructionDecoder
(
	input [31:0] instruction,
	output DecodedInstruction decodedInstruction,//To control logic
	output DecodedAddressing decodedAddressing,//To register file
	
	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	//Immediates (preprocessed)
	output [31:0] immediateI,
	output [31:0] immediateS,
	output [31:0] immediateB,
	output [31:0] immediateU,
	output [31:0] immediateJ
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
assign immediateI = extend12To32(instruction[31:20]);
assign immediateS = extend12To32({instruction[31:25], instruction[11:7]});
assign immediateB = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
assign immediateU = {instruction[31:12], 12'h000};
assign immediateJ = {{19{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

function automatic logic [31:0] extend12To32(input [11:0] data);
begin
	extend12To32 = {{20{data[11]}}, data[11:0]};
end
endfunction

endmodule