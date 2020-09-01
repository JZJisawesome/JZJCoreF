//This is an old project I'm just using to test the core (Verilog, not system verilog)
module multi7seg
(
	//one segment displayed each posedge
	//to get desired refresh rate, give four times higher clock (400hz should do)
	input clock,
	
	input [3:0] data0,
	input [3:0] data1,
	input [3:0] data2,
	input [3:0] data3,
	
	output [7:0] segment,
	output reg [3:0] ground//current segment//reg
);

reg [1:0] current_seg;
reg [3:0] current_data;
decoder7seg(.data(current_data), .segment(segment));

always @(posedge clock)//switch to next segment every time
begin
	current_seg <= current_seg + 2'b1;
end

always @*
begin
	case (current_seg)
		0:current_data = data0;
		1:current_data = data1;
		2:current_data = data2;
		3:current_data = data3;
	endcase
	
	case (current_seg)
		0:ground = 4'b0111;
		1:ground = 4'b1011;
		2:ground = 4'b1101;
		3:ground = 4'b1110;
	endcase
end

endmodule

module decoder7seg
(
	input [3:0] data,
	output reg [7:0] segment
);

//   DP GFADCBE
//8'bX  XXXXXXX

always @(data)
begin
	case(data)//for first cyclone iv board
        //hex characters
		0:segment = 8'hc0;
		1:segment = 8'hf9;
		2:segment = 8'ha4;
		3:segment = 8'hb0;
		4:segment = 8'h99;
		5:segment = 8'h92;
		6:segment = 8'h82;
		7:segment = 8'hf8;
		8:segment = 8'h80;
		9:segment = 8'h90;
		10:segment = 8'h88;
		11:segment = 8'h83;
		12:segment = 8'hc6;
		13:segment = 8'ha1;
		14:segment = 8'h86;
		15:segment = 8'h8e;
		default:segment = 0;
	endcase
end

endmodule