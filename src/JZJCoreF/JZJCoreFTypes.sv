package JZJCoreFTypes;
	/* Simple Types */
	typedef logic [6:0] Opcode_t;//todo maybe this should be made into a enum; see the comments in the Enums section
	typedef logic [2:0] Funct3_t;
	typedef logic [6:0] Funct7_t;

	/* Enums */
	typedef enum logic {LUI, AUIPC} ImmediateFormerMode_t;
	typedef enum logic [1:0] {JAL, JALR, BRANCH, INCREMENT} BranchALUMode_t;//Note: use anything but BRANCH for a nop
	typedef enum logic [1:0] {LOAD, STORE_PRELOAD, STORE, NOP} MemoryMode_t;
	typedef enum logic {NEXT_PC, CURRENT_PC} InstructionAddressSource_t;
	
	//Todo add opcode type (prefix enum type names with OPCODE_ to avoid conflicts with above enums)
	//I tried to add it before, but curiously it slowed things down significantly
	//todo try again at some point
	
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
	} DecodedAddresses_t;//todo rename with _t
	
	//Used to selecting between RegisterFile inputs
	typedef struct
	{
		logic memoryOutputEnable;
		logic aluOutputEnable;
		logic immediateFormerOutputEnable;
		logic branchALUOutputEnable;
	} RDSourceSelectLines_t;
endpackage