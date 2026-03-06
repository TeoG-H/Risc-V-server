`timescale 1ns / 1ps


module Fetch_Cycle(clk, rst, PCSrc, PC_EX, StallF, StallD, FlushD, InstrD, PCD, PCPlus4D);
    input clk, rst, PCSrc;
    input StallF, StallD, FlushD;
    input [31:0] PC_EX;
    output [31:0] InstrD, PCD, PCPlus4D;

    wire [31:0] PCNext_F;   // PC selectat de mux, intra in registrul PC
    wire [31:0] PCF;        // PC curent in stadiul Fetch
    wire [31:0] InstrF;     // Instructiunea citita din memorie
    wire [31:0] PCPlus4F;   // PC+4 in stadiul Fetch

    reg [31:0] InstrD_r, PCD_r, PCPlus4D_r;

    Mux PC_MUX (.sel(PCSrc), .A(PCPlus4F), .B(PC_EX), .Mux_out(PCNext_F));
    PC Program_Counter (.clk(clk), .reset(rst), .en(~StallF), .PC_in(PCNext_F), .PC_out(PCF));
    Instruction_Mem IM (.read_address(PCF), .instruction(InstrF));
    adder_PC_4 PC_adder (.adder_4_in(PCF), .adder_4_out(PCPlus4F));

    always @(posedge clk or posedge rst) begin
        if(rst || FlushD) begin
            InstrD_r   <= 32'b0;
            PCD_r      <= 32'b0;
            PCPlus4D_r <= 32'b0;
        end
        else if(~StallD) begin
            InstrD_r   <= InstrF;
            PCD_r      <= PCF;
            PCPlus4D_r <= PCPlus4F;
        end
    end

    assign InstrD  = (rst) ? 32'b0 : InstrD_r;
    assign PCD     = (rst) ? 32'b0 : PCD_r;
    assign PCPlus4D = (rst) ? 32'b0 : PCPlus4D_r;
endmodule
