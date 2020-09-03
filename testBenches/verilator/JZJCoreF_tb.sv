`timescale 1ns/1ps
module JZJCoreF_tb
(
    input logic clock//toggled by verilator
);

//Toggling the clock internally workes with Iverilog, but not with verilator
//reg clock = 1'b0;

JZJCoreF #(.INITIAL_MEM_CONTENTS("../../src/memFiles/adding2.mem")) coreTest (.clock(clock), .reset(1'b0));

//Toggling the clock internally workes with Iverilog, but not with verilator
/*
always
begin
    #10;
    clock = ~clock;
end
*/

//Dump waveforms
initial
begin
    $dumpfile("/tmp/JZJCoreF.vcd");
    $dumpvars(0,JZJCoreF_tb);
end

endmodule
