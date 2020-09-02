package JZJCoreFTypes;
	/* Enums */
	typedef enum {MEMORY, ALU, IMMEDIATE_FORMER, BRANCH_ALU} RDSource_t;//Todo use this for RDInputChooser in the future
	typedef enum {LUI, AUIPC} ImmediateFormerMode_t;
	typedef enum {JAL, JALR, BRANCH, INCREMENT} BranchALUMode_t;
	typedef enum {LOAD, STORE_PRELOAD, STORE} MemoryMode_t;
	
	/* Structs */
	
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