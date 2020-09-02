package BitExtensionFunctions;
	/* Sign Extension */
	
	function automatic logic [31:0] signExtend16To32(input [15:0] data);
	begin
		signExtend16To32 = {{16{data[15]}}, data[15:0]};
	end
	endfunction
	
	function automatic logic [31:0] signExtend8To32(input [7:0] data);
	begin
		signExtend8To32 = {{24{data[7]}}, data[7:0]};
	end
	endfunction
	
	/* Zero Extension */
	
	function automatic logic [31:0] zeroExtend16To32(input [15:0] data);
	begin
		zeroExtend16To32 = {16'h0000, data[15:0]};
	end
	endfunction
	
	function automatic logic [31:0] zeroExtend8To32(input [7:0] data);
	begin
		zeroExtend8To32 = {24'h000000, data[7:0]};
	end
	endfunction
endpackage