# JZJCoreF

A fast RV32IZifencei soft core implementation with a 2 stage pipeline(ish), written in SystemVerilog!

This is my sixth major single-cycle/2-stage RISC-V core revision that is a major rewrite from previous versions. Much of JZJCoreA through JZJCoreE shared code and were kind of just a way to avoid using version control properly. Not anymore.

Along with the transition from Verilog to SystemVerilog, I also decided that I should also redo things from scratch in order to get more practice with learning CPU architecture, and to just get a "fresh start" in general. Because I was learning and trying out new features present in SystemVerilog that were absent in Verilog, I figured that this core's Fmax would be lower by a measurable amount (probably around 1 - 3 mhz less performant). Instead, this design achieves nearly 40 mhz on the "Slow Model" of my fpga _without_ any optimized synthesizer options whatsoever (an over 10mhz _improvement_)!

I'm not sure if it was the switch of the HDL or some other changes that were made in this design that contributed to this bump. I think primarily the change of disallowing writes to x0 instead of always returning reads of 32'h00000000 from the register is the source of the improvement, but I have no idea. Again, I expected things to be _worse_. *Future John here: apparently it was something else or a combination of other things

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
| ecall | 0.5* |
| ebreak | 0.5* |
|Zifencei|
| fence.i | 1 |

*Halts cpu at the following negative clock edge after the previous instruction. This is intended behaviour, see the JZJCore EEI for more information (it is a legal type of requested trap).

## Theories Of Operation

### Execution Cycle

JZJCoreF is a RV32IZifencei implementation that executes instructions using its 2 "stageish" pipeline. Most instruction are completed in effectively a single cycle by fetching a future instruction from memory concurrently with the execution of another.

The ControlLogic module contains a state machine, which, after power on or reset, is initialized with the INITIAL_FETCH state. This state simply configures the MemoryController and InstructionAddressMux to fetch the first instruction to execute (located at the RESET_VECTOR parameter address). This instruction is fetched on the first posedge after reset/power on, and latched in MemoryController's instruction out port. Before the following negative edge of the clock, the instruction is decoded and sent to the ControlLogic module. If the instruction can be completed in a single cycle, the state becomes FETCH_EXECUTE at the negedge; but if it takes two cycles the state becomes EXECUTE.

If the instruction only takes one cycle, the FETCH_EXECUTE state then decodes the instruction starting from the negedge and sets control signals appropriately. The result of the instruction is then latched into either the registers or memory at the next posedge. ControlLogic simultaneously sets the next pc address to be calculated and also latches this value into the pc at the next posedge. Concurently, the InstructionAddressMux is set to bypass the pc and use the calculated future value to fetch the next instruction. All of this happens on a single posedge. After this posedge, if the instruction that was executed caused the PC to be misaligned or attempted an unaligned memory access, the core would enter the HALT state. If not, the newly fetched instruction causes the state to become either FETCH_EXECUTE or EXECUTE and the cycle repeats again.

Some instructions take two cycles. In this instance, the EXECUTE state sets control signals for the first cycle of the instruction, but does _not_ latch a new pc ahead of time or the next instruction. This is why JZJCoreF has a 2 "stageish" pipeline; a proper 2 stage pipeline would be able to fetch a new instruction already. Temporary registers are updated on the next posedge, and assuming there are no pc or memory alignment issues, the state then becomes FETCH_EXECUTE. Here, the second set of control signals for the instruction are set, latched into the appropriate places on the posedge, and this time, like normal, the next instruction is fetched ahead of time (on the posedge as well). Now, just like a regular transition from a FETCH_EXECUTE state, the next state is decided based on the decoded instruction.

This cycle will repeat forever, or until either a misalignment exception or ECALL/EBREAK instruction is encountered. In that case, the core core will enter the HALT state; once there, the core will just busywait until the next reset.

### Instruction Fence (Zifencei: fence.i Instruction)

Both regular fence and fence.i instructions are decoded as a nop in JZJCoreF. However, due to the inherent nature of the design, both of these instructions function as intended. If a memory address is modified right before it is executed, the JZJCoreF instruction fetch (which occurs at the same time as the modification) will fetch the old instruction instead of the new one. This is legal RISC-V behaviour. However, if an address is modified, a fence.i instruction is executed, then that modified address is executed, the instruction that is executed will be the new one because the fence.i nop effectively seperated the memory write and new instruction fetch by a posedge. So technically, fence.i does its job as required by RISC-V!

### Memory Architecture

JZJCoreF uses a simple approach to multi-byte instruction accesses. The inferred SystemVerilog SRAM module that is used by the core has a 32 bit physical data width instead of an 8 bit width. While this slows down byte-wise accesses, which must read, then modify and write data to memory addresses, it speeds up read accesses and whole word writes significantly. Instead of spending 4 cycles reading each byte for an instruction fetch, the entire instruction can be fetched in a single cycle. JZJCoreF is able to provide these net benefits invisibly to RISC-V software it is executing.

## JZJCore EEI

### Initial Register Values

All general purpose registers (x0 through x31) are initialized with 32'h00000000 at power up and reset. The program counter is initialized with the SystemVerilog parameter RESET_VECTOR, which is 32'h00000000 by default if unspecified during JZJCoreF module instantiation.

### Hart Information and ISA Class

JZJCoreF contains only a single, unprivileged RV32IZifencei hart. However, it can also be configured as an unprivileged RV32EZifencei hart by setting the JZJCoreF SystemVerilog parameter to 16 instead of 32.

### Traps

JZJCoreF contains no interrupt controller or interrupt/exception vector. All exceptions from defined instructions cause fatal traps, but invalid instruction encodings (opcode, funct3, or funct7) cause unspecified behaviour; not necessarily a fatal trap. Nevertheless they should obviously be avoided. The ECALL and EBREAK instructions provide a clean way of stopping execution by terminating the hart (a requested trap).

### Memory Access Restrictions and Memory Map

Addresses in the table below are inclusive and a read/write to an unmapped address will cause unspecified behaviour. Execution is only supported within the RAM Start and RAM End addresses, so unspecified behaviour will occur if an instruction is fetched from outside that region. A misaligned control transfer instruction will cause a fatal trap (only if taken in the case of branches).

Since JZJCoreE, memory mapped IO registers function differently. There are no more direction registers, only port registers. Writes to a memory mapped io address write to mmioOutputs[X], and reads read from mmioInputs[X]. A register must be dedicated to an external tristate logic controller if desired, and if feedback is desired then pins in mmioInputs should be connected directly to the respective mmioOutputs pins. Connections to the ports from or to other clock domains require synchronizers or asynchronous FIFOs. This new scheme allows for greater flexibility with external devices and modules, while still allowing for high speed communication between modules in the same clock domain.

Memory Mapped IO registers must be read/written 1 word at a time; halfword or byte accesses may cause unspecified core behaviour. RAM addresses may be accessed with any load/store instruction.

All memory accesses must be aligned (to 4 bytes boundaries for word accesses, and to 2 byte boundaries for halfword accesses), or else will cause a fatal trap.

At power-on, the RAM addresses are loaded with the contents of the file INITIAL_MEM_CONTENTS, and all memory mapped IO output registers contain the value 32'h00000000. At reset, the memory mapped IO output registers return to 32'h00000000, but RAM is NOT RELOADED.

| Byte-wise Address (whole word) | Backend Word-wise Address | Function |
|:------------------------------|:---------------------------|:---------|
|0x00000000 to 0x00000003|0x00000000|RAM Start|
|0x0000FFFC to 0x0000FFFF|0x00003FFF|RAM End (Default for 12 bit RAM_A_WIDTH)|
|0xFFFFFFE0 to 0xFFFFFFE3|0x3FFFFFF8|Memory Mapped IO Registers Start|
|0xFFFFFFFC to 0xFFFFFFFF|0x3FFFFFFF|Memory Mapped IO Registers End|

## Todo List

- Seperate MMIO and InferredRAM within MemoryController  (perhaps multiplex MMIO inside RDInputChooser instead of in MemoryBackend)
- Write Theories Of Operation in this readme
- Test using a regular multiplexer inside RDInputChooser
- Look into bypassing currentState with nextState or something to allow internal comb logic to update starting from the posedge instead of from the negedge (switch state on posedge and negedge, with INTERMEDIATE states or something that bypass things). * Future John here: After some analysis, the only things that update after the negedge are those driven from ControlLogic directly; rs1/rs2 and immediates are decoded immediatly after the posedge when the instruction is fetched however, so updating ControlLogic to output its signals sooner would be less useful as most of those signals are not on the critical path (but might still help with setting multiplexers inside of MemoryController faster (where the main system bottleneck is), so I'm not throwing this idea out yet)
- MORE PERFORMANCE!!!
