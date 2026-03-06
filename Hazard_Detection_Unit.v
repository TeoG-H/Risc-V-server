`timescale 1ns / 1ps


module Hazard_Detection_Unit(ResultSrcE, RD_E, RS1_D, RS2_D, StallF, StallD, FlushE);
    input ResultSrcE;
    input [4:0] RD_E, RS1_D, RS2_D;
    output reg StallF, StallD, FlushE;

always @(*) begin

    StallF = 1'b0;
    StallD = 1'b0;
    FlushE = 1'b0;

    if (ResultSrcE && (RD_E != 5'd0) && ((RD_E == RS1_D) || (RD_E == RS2_D))) begin
        StallF = 1'b1;
        StallD = 1'b1;
        FlushE = 1'b1;
    end

end

endmodule
