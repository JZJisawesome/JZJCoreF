# JZJCoreF

A fast RV32IZifencei soft core implementation with a 2-stage pipeline, written in SystemVerilog!

This is my sixth major single-cycle/2-stage RISC-V core revision that is a major rewrite from previous versions. Much of JZJCoreA through JZJCoreE shared code and were kind of just a way to avoid using version control properly. Not anymore.

Along with the transition from Verilog to SystemVerilog, I also decided that I should also redo things from scratch in order to get more practice with learning CPU architecture, and to just get a "fresh start" in general. Because I was learning and trying out new features present in SystemVerilog that were absent in Verilog, I figured that this core's Fmax would be lower by a measurable amount (probably around 1 - 3 mhz less performant). Instead, this design achieves nearly 40 mhz on the "Slow Model" of my fpga _without_ any optimized synthesizer options whatsoever (an over 10mhz _improvement_)!

I'm not sure if it was the switch of the HDL or some other changes that were made in this design that contributed to this bump. I think primarily the change of disallowing writes to x0 instead of always returning reads of 32'h00000000 from the register is the source of the improvement, but I have no idea. Again, I expected things to be _worse_.

I plan to make this a longer term core revision. Instead of manually forking cores each time I want to make a big change, I'm going to try to use git tags and branches. I've used them before, it's just that they can be a bit annoying sometimes (so I've avoided them up to this point). This way I can practice using version control properly as well as learn computer engineering at the same time (also it's a much more sustainable way to develop things)!

Although this design is a complete rewrite (I never copied any core code from older cores), I still took ideas from older cores. I didn't look at the code to remember these ideas, but just tried to "do what I did last time" and reference other materials I made (lots of timing diagrams on scrap paper). Because of this, the CPI of the instructions is identical to JZJCoreC through JZJCoreE. The main advantages with this core are the > 10mhz Fmax improvement and the much more organized/maintainable code.

## CPI For All Instructions

Note: The first instruction executed by JZJCoreF takes an additional cycle because it needs to be fetched from memory. After this "initial fetch," later instructions are fetched concurently with the one being executed, allowing for a lower CPI overall.

Some instructions take two cycles, so the fetch for the following instruction is performed on the second cycle. Load instructions need two cycles so that data at a memory address can be read (1), then latched into a register (2). Store halfword and store byte instructions need two cycles because of the nature of the memory backend in JZJCoreF; it is organized as 32 bit data, so partial writes require a read(1)-modify-write(2) sequence.

Store word instructions take only 1 cycle because they don't care about existing data at an address; they will overwrite it all anyways. Every other instruction just uses combinatorial logic between the register file/the pc's outputs and inputs, and so only take 1 cycle to latch changes (All Hail Contamination Delay!).

| Instruction | Cycle Count |
|:------------|:-----------------------|
|Base Spec(I)|
| lui | 1 |
| auipc | 1 |
| jal | 1 |
| jalr | 1 |
| beq | 1 |
| bne | 1 |
| blt | 1 |
| bge | 1 |
| bltu | 1 |
| bgeu | 1 |
| lb | 2 |
| lh | 2 |
| lw | 2 |
| lbu | 2 |
| lhu | 2 |
| sb | 2 |
| sh | 2 |
| sw | 1 |
| addi | 1 |
| slti | 1 |
| sltiu | 1 |
| xori | 1 |
| ori | 1 |
| andi | 1 |
| slli | 1 |
| srli | 1 |
| srai | 1 |
| add | 1 |
| sub | 1 |
| sll | 1 |
| slt | 1 |
| sltu | 1 |
| xor | 1 |
| srl | 1 |
| sra | 1 |
| or | 1 |
| and | 1 |
| fence | 1 |
| ecall | 1 |
| ebreak | 1 |
|Zifencei|
| fence.i | 1 |

## JZJCore EEI

### Initial Register Values

All general purpose registers are initialized with 32'h00000000 at power up and reset. The program counter is initialized with the SystemVerilog parameter RESET_VECTOR, which is 32'h00000000 by default if unspecified during JZJCoreF module instantiation.

### Hart Information and ISA Class

JZJCoreF contains only a single, unprivileged RV32IZifencei hart.

### Traps

JZJCoreF contains no interrupt controller or interrupt/exception vector. All exceptions from defined instructions cause fatal traps, but invalid instruction encodings (opcode, funct3, or funct7) cause undefined behaviour; not necessarily a fatal trap. Nevertheless they should obviously be avoided. The ECALL and EBREAK instructions provide a clean way of stopping execution by terminating the hart (a requested trap).

### Memory Map

Note: Addresses in the table below are inclusive and a read/write to an unmapped address will cause undefined behaviour. Execution is only supported within the RAM Start and RAM End addresses, undefined behaviour will occur if an instruction is fetched from outside that region, and a misaligned control transfer instruction will cause a fatal trap.

Since JZJCoreE, memory mapped IO registers function differently. There are no more direction registers, only port registers. Writes to a memory mapped io address write to mmioOutputs[X], and reads read from mmioInputs[X]. A register must be dedicated to an external tristate logic controller if desired, and if feedback is desired then pins in mmioInputs should be connected directly to the respective mmioOutputs pins. Connections to the ports from or to other clock domains require synchronizers or asynchronous FIFOs. This new scheme allows for greater flexibility with external devices and modules, while still allowing for high speed communication between modules in the same clock domain.

Memory Mapped IO registers must be read/written 1 word at a time, otherwise read-modify-write behaviour and endianness could break things. However, if you are careful and inspect MemoryMappedIO.sv/MemoryController.sv, you can read/write halfwords and bytes (but you might need feedback between the inputs and outputs). RAM addresses may be accessed with any load/store instruction.

All memory accesses must be aligned (to 4 bytes boundaries for word accesses, and to 2 byte boundaries for halfword accesses), or else will cause a fatal trap.

At power-on, the RAM addresses are loaded with the contents of the file INITIAL_MEM_CONTENTS, and all memory mapped IO output registers contain the value 32'h00000000. At reset, the memory mapped IO output registers return to 32'h00000000, but RAM is NOT RELOADED.

| Byte-wise Address (whole word) | Backend Word-wise Address | Function |
|:------------------------------|:---------------------------|:---------|
|0x00000000 to 0x00000003|0x00000000|RAM Start|
|0x0000FFFC to 0x0000FFFF|0x00003FFF|RAM End (Default for 12 bit RAM_A_WIDTH)|
|0xFFFFFFE0 to 0xFFFFFFE3|0x3FFFFFF8|Memory Mapped IO Registers Start|
|0xFFFFFFFC to 0xFFFFFFFF|0x3FFFFFFF|Memory Mapped IO Registers End|
