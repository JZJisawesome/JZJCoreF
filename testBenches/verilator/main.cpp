//Put together with scraps of example, forum, and tutorial code found throughout the internet
//MIT licensed like everything else

//Library includes
#include <cstdint>
#include "verilated.h"

//SystemVerilog Testbench
#include "VJZJCoreF_tb.h"

//Needed to generate a $dumpfile
uint64_t simulationTime = 0;//Used to keep track of simulation time for vcd dumping
double sc_time_stamp()//Used by Verilator for vcd dumping
{       
    return (double)(simulationTime);
}

int main(int argc, char** argv)
{
    //Setup things
    Verilated::commandArgs(argc, argv);//Interpret command line arguments for Verilator
    VJZJCoreF_tb* testbench = new VJZJCoreF_tb;//Instantiate the JZJCoreF_tb module for simulation
    
    Verilated::traceEverOn(true);//Needed to support $dumpfile
    
    //Simulation Loop
    
    testbench->eval();//Update simulation
    ++simulationTime;//Used to keep track of simulation time for vcd dumping
    while (!Verilated::gotFinish())//Run simulation until $finish() is called in systemVerilog
    {
        testbench->clock = 1;//Set clock high
        testbench->eval();//Update simulation
        ++simulationTime;//Used to keep track of simulation time for vcd dumping
        
        testbench->clock = 0;//Set clock high
        testbench->eval();//Update simulation
        ++simulationTime;//Used to keep track of simulation time for vcd dumping
    }
    
    //Exit simulation
    delete testbench;//Free testbench memory
    return 0;//End program
}
