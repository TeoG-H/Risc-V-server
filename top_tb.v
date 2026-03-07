`timescale 1ns/1ps

module top_tb;
    
    reg clk;
    reg rst;
    integer i;
    
    Procesor_top cpu(.clk(clk), .rst(rst));
    
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
    
    rst = 1;
    #20; 
    rst = 0;
    #500;
        
        for(i=0;i<32;i=i+1)
           $display("x%0d = %0d", i, $signed(cpu.Decode.rf.Registers[i]));
            
    $finish(0);
    
    end
endmodule
