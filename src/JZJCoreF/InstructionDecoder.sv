import JZJCoreFTypes::*;

module InstructionDecoder
(
	//Instruction to decode
	input logic [31:0] instruction,

	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	output DecodedAddresses_t decodedAddresses,//To register file
	
	//Instruction Encoding
	output Opcode_t opcode,//For JZJCoreF, opcode is strictly only to be used by the control logic
	output Funct3_t funct3,
	output Funct7_t funct7,
	
	//Immediates (preprocessed)
	output logic [31:0] immediateI,
	output logic [31:0] immediateS,
	output logic [31:0] immediateB,
	output logic [31:0] immediateU,
	output logic [31:0] immediateJ
);
//Addressing
assign decodedAddresses.rs1Address = instruction[19:15];
assign decodedAddresses.rs2Address = instruction[24:20];
assign decodedAddresses.rdAddress = instruction[11:7];

//Instruction Encoding
assign opcode = Opcode_t'(instruction[6:0]);
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

//Immediates (preprocessed)
assign immediateI = signExtend12To32(instruction[31:20]);
assign immediateS = signExtend12To32({instruction[31:25], instruction[11:7]});
assign immediateB = signExtend13To32({instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0});
assign immediateU = {instruction[31:12], 12'h000};
assign immediateJ = signExtend21To32({instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0});

//Sign extension functions (for immediate processing)
function automatic logic [31:0] signExtend12To32(input [11:0] data);
begin
	signExtend12To32 = {{20{data[11]}}, data[11:0]};
end
endfunction

function automatic logic [31:0] signExtend13To32(input [12:0] data);
begin
	signExtend13To32 = {{19{data[12]}}, data[12:0]};
end
endfunction

function automatic logic [31:0] signExtend21To32(input [20:0] data);
begin
	signExtend21To32 = {{11{data[20]}}, data[20:0]};
end
endfunction

endmodule