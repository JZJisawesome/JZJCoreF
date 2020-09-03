package JZJCoreFTypes;
	/* Simple Types */
	typedef logic [6:0] Opcode_t;//todo use in the future//todo maybe this should be made into a enum
	typedef logic [2:0] Funct3_t;//todo use in the future
	typedef logic [6:0] Funct7_t;//todo use in the future

	/* Enums */
	typedef enum {MEMORY, ALU, IMMEDIATE_FORMER, BRANCH_ALU} RDSource_t;//Todo use this for RDInputChooser in the future; might also just create a structure containing the enable wires if it is faster
	typedef enum {LUI, AUIPC} ImmediateFormerMode_t;
	typedef enum {JAL, JALR, BRANCH, INCREMENT} BranchALUMode_t;
	typedef enum {LOAD, STORE_PRELOAD, STORE, NOP} MemoryMode_t;
	typedef enum {NEXT_PC, CURRENT_PC} InstructionAddressSource_t;
	
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