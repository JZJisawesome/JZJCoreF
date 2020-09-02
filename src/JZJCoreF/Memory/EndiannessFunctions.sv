package EndiannessFunctions;
	/* Wrapper Functions */

	function automatic logic [31:0] toBigEndian32(input [31:0] littleEndianData);
	begin
		toBigEndian32 = swapEndianness32(littleEndianData);
	end
	endfunction
	
	function automatic logic [31:0] toLittleEndian32(input [31:0] bigEndianData);
	begin
		toLittleEndian32 = swapEndianness32(bigEndianData);
	end
	endfunction
	
	function automatic logic [15:0] toBigEndian16(input [15:0] littleEndianData);
	begin
		toBigEndian16 = swapEndianness16(littleEndianData);
	end
	endfunction
	
	function automatic logic [15:0] toLittleEndian16(input [15:0] bigEndianData);
	begin
		toLittleEndian16 = swapEndianness16(bigEndianData);
	end
	endfunction

	/* Heavy Lifting Functions */
	
	function automatic logic [31:0] swapEndianness32(input [31:0] data);
	begin
		swapEndianness32 = {data[7:0], data[15:8], data[23:16], data[31:24]};
	end
	endfunction
	
	function automatic logic [15:0] swapEndianness16(input [15:0] data);
	begin
		swapEndianness16 = {data[7:0], data[15:8]};
	end
	endfunction
endpackage