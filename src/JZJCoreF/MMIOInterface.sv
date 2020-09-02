interface MMIOInterface();
	/* IO Lines */

	//CPU memory mapped ports
	//Note that reads and writes from/to the addresses are in little endian format
	//then converted back to be output / vise-versa for inputs
	//This makes it so for reads rd[0] = portXMemoryAddress[24] = portXInput[0]
	//and for writes............rs2[0] = portXMemoryAddress[24] = portXOutput[0]
	//My recomendation is therefore that ports are accessed whole words at a time
	//but if you keep the little endian -> big endian format in mind you can write half words or bytes
	//Reads from the address read from the input, writes write to the output
	//Inputs: (byte-wise)		address (starting byte)
	logic [31:0] portAInput;//	FFFFFFE0
	logic [31:0] portBInput;//	FFFFFFE4
	logic [31:0] portCInput;//	FFFFFFE8
	logic [31:0] portDInput;// FFFFFFEC
	logic [31:0] portEInput;//	FFFFFFF0
	logic [31:0] portFInput;//	FFFFFFF4
	logic [31:0] portGInput;//	FFFFFFF8
	logic [31:0] portHInput;//	FFFFFFFC
	//Outputs: (byte-wise)		address (starting byte)
	logic [31:0] portAOutput;//FFFFFFE0
	logic [31:0] portBOutput;//FFFFFFE4
	logic [31:0] portCOutput;//FFFFFFE8
	logic [31:0] portDOutput;//FFFFFFEC
	logic [31:0] portEOutput;//FFFFFFF0
	logic [31:0] portFOutput;//FFFFFFF4
	logic [31:0] portGOutput;//FFFFFFF8
	logic [31:0] portHOutput;//FFFFFFFC
	//For tristate ports, an additional port's outputs can be designated as a direction register in an external module, which can be used by an external module to allow/disalow writing
	//If feedback is desired, then inputs should be connected to their respective output register externally
	//MAKE SURE INPUTS ARE SYNCHRONIZED IF THEY ARE FROM ANOTHER CLOCK DOMAIN; no synchronization occurs in JZJCoreF
	
	/* Modports */
	modport backend
	(
		input portAInput, portBInput, portCInput, portDInput, portEInput, portFInput, portGInput, portHInput,
		output portAOutput, portBOutput, portCOutput, portDOutput, portEOutput, portFOutput, portGOutput, portHOutput
	);
	
	modport external
	(
		output portAInput, portBInput, portCInput, portDInput, portEInput, portFInput, portGInput, portHInput,
		input portAOutput, portBOutput, portCOutput, portDOutput, portEOutput, portFOutput, portGOutput, portHOutput
	);

endinterface