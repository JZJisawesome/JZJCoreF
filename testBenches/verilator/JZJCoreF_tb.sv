//`timescale 1ns/1ps//if this was here, verilator would require all other modules have it and I don't know what values make sense/it's a pain to put that in each file
module JZJCoreF_tb
(
    input logic clock//toggled by verilator
);

//Toggling the clock internally workes with Iverilog, but not with verilator
//reg clock = 1'b0;

JZJCoreF #(.INITIAL_MEM_CONTENTS("../../src/memFiles/sllisrliblttest.mem")) coreTest (.clock(clock), .reset(1'b0));

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
