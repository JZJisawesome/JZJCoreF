package JZJCoreFTypes;
	typedef enum {LUI, AUIPC} immediateFormerMode_t;
	
	//Used for passing addressing data from InstructionDecoder to RegisterFile
	typedef struct
	{
		//Note: Modules must be smart enough to decode the opcode and 
		//know which of these members is valid at a given instant
		
		//Addressing
		logic [4:0] rs1Address;
		logic [4:0] rs2Address;
		logic [4:0] rdAddress;
	} DecodedAddresses;
endpackage