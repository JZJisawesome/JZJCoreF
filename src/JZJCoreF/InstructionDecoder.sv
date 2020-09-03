import JZJCoreFTypes::DecodedAddresses;

module InstructionDecoder
(
	input [31:0] instruction,

	//Note: Modules must be smart enough to decode the opcode and 
	//know which of these members is valid at a given instant
	output DecodedAddresses decodedAddresses,//To register file
	
	//Instruction Encoding
	output logic [6:0] opcode,//For JZJCoreF, opcode is strictly only to be used by the control logic
	output logic [2:0] funct3,
	output logic [6:0] funct7,
	
	//Immediates (preprocessed)
	output [31:0] immediateI,
	output [31:0] immediateS,
	output [31:0] immediateB,
	output [31:0] immediateU,
	output [31:0] immediateJ
);
//Addressing
assign decodedAddresses.rs1Address = instruction[19:15];
assign decodedAddresses.rs2Address = instruction[24:20];
assign decodedAddresses.rdAddress = instruction[11:7];

//Instruction Encoding
assign opcode = instruction[6:0];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

//Immediates (preprocessed)
assign immediateI = extend12To32(instruction[31:20]);
assign immediateS = extend12To32({instruction[31:25], instruction[11:7]});
assign immediateB = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
assign immediateU = {instruction[31:12], 12'h000};
assign immediateJ = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

function automatic logic [31:0] extend12To32(input [11:0] data);
begin
	extend12To32 = {{20{data[11]}}, data[11:0]};
end
endfunction

endmodule