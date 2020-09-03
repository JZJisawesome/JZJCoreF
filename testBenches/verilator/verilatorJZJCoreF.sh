#Settings
SIM_RUN_TIME="0.01"

FILES_TO_INCLUDE="-I ../../src/JZJCoreF/JZJCoreFTypes.sv -I ../../src/JZJCoreF/Memory/BitExtensionFunctions.sv -I ../../src/JZJCoreF/Memory/EndiannessFunctions.sv -I ../../src/JZJCoreF/Memory/InferredRAM.sv -I ../../src/JZJCoreF/Memory/MemoryBackend.sv -I ../../src/JZJCoreF/Memory/MemoryController.sv -I ../../src/JZJCoreF/ALU.sv -I ../../src/JZJCoreF/BranchALU.sv -I ../../src/JZJCoreF/ControlLogic.sv -I ../../src/JZJCoreF/ImmediateFormer.sv -I ../../src/JZJCoreF/InstructionAddressMux.sv -I ../../src/JZJCoreF/InstructionDecoder.sv -I ../../src/JZJCoreF/ProgramCounter.sv -I ../../src/JZJCoreF/RDInputChooser.sv -I ../../src/JZJCoreF/RegisterFile.sv -I ../../src/JZJCoreF/JZJCoreF.sv"

#Verilate the testbench and JZJCoreF SystemVerilog files//todo split into multiple commands
verilator $FILES_TO_INCLUDE -Wall -Wno-fatal -sv -cc JZJCoreF_tb.sv --exe --trace --top-module JZJCoreF_tb --build main.cpp
#Run the simulation (creates /tmp/JZJCoreF.vcd)
timeout $SIM_RUN_TIME ./obj_dir/VJZJCoreF_tb
#Open in waveform viewer
gtkwave /tmp/JZJCoreF.vcd
#Delete files
rm -rf ./obj_dir
rm /tmp/JZJCoreF.vcd
