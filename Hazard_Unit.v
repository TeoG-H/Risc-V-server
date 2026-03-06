`timescale 1ns / 1ps

module Hazard_Unit(rst, RegWriteM, RegWriteW, RD_M, RD_W, Rs1_E, Rs2_E, ForwardAE, ForwardBE);
    input rst;
    input RegWriteM, RegWriteW;
    input [4:0] RD_M, RD_W, Rs1_E, Rs2_E;
    output reg [1:0] ForwardAE, ForwardBE;

always @(*) begin

    ForwardAE = 2'b00;
    ForwardBE = 2'b00;

    if (!rst) begin
        // practic daca reg dst din memorie e acelasi cu Rs 1 sau 2  sau reg d din W e acel cu ... il iau direct din etapa de E, nu mai astept WB
        // A  
        if (RegWriteM && (RD_M != 0) && (RD_M == Rs1_E))
            ForwardAE = 2'b10;
        else if (RegWriteW && (RD_W != 0) && (RD_W == Rs1_E))
            ForwardAE = 2'b01;

        //  B
        if (RegWriteM && (RD_M != 0) && (RD_M == Rs2_E))
            ForwardBE = 2'b10;
        else if (RegWriteW && (RD_W != 0) && (RD_W == Rs2_E))
            ForwardBE = 2'b01;

    end
end

endmodule