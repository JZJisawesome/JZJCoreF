//`timescale 1ns/1ps
module JZJCoreF_tb;

reg clock = 1'b0;

JZJCoreF #(.INITIAL_MEM_CONTENTS("../src/memFiles/adding2.mem")) coreTest (.clock(clock), .reset(1'b0));

always
begin
    #10;
    clock = ~clock;
end

initial
begin
    $dumpfile("/tmp/JZJCoreF.vcd");
    $dumpvars(0,JZJCoreF_tb);
    #10000 $finish;
end

endmodule
