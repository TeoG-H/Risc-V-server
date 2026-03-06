`timescale 1ns / 1ps

module Writeback_Cycle(clk, rst, ResultSrcW, PCPlus4W, ALU_ResultW, ReadDataW, ResultW);

    input clk, rst, ResultSrcW;
    input [31:0] PCPlus4W, ALU_ResultW, ReadDataW;
    output [31:0] ResultW;

    Mux result_mux (.A(ALU_ResultW), .B(ReadDataW), .sel(ResultSrcW), .Mux_out(ResultW));

endmodule
