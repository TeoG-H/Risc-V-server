module Decode_Cycle(clk, rst, InstrD, PCD, PCPlus4D, RegWriteW, RDW, ResultW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE,
                    BranchE,  ALUControlE, RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, RS1_E, RS2_E, FlushE);

    input clk, rst, RegWriteW,FlushE;
    input [4:0] RDW;
    input [31:0] InstrD, PCD, PCPlus4D, ResultW;

    output RegWriteE,ALUSrcE,MemWriteE,ResultSrcE,BranchE;
    output [2:0] ALUControlE;
    output [31:0] RD1_E, RD2_E, Imm_Ext_E,PCE, PCPlus4E;
    output [4:0] RS1_E, RS2_E, RD_E;

    wire RegWriteD,ALUSrcD,MemWriteD,ResultSrcD,BranchD;
    wire [1:0] ImmSrcD;
    wire [2:0] ALUControlD;
    wire [31:0] RD1_D, RD2_D, Imm_Ext_D;

    reg RegWriteD_r,ALUSrcD_r,MemWriteD_r,ResultSrcD_r,BranchD_r;
    reg [2:0] ALUControlD_r;
    reg [31:0] RD1_D_r, RD2_D_r, Imm_Ext_D_r,PCD_r, PCPlus4D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r;


    Control_Unit_Top control (.Op(InstrD[6:0]), .funct3(InstrD[14:12]), .funct7(InstrD[31:25]),
                              .RegWrite(RegWriteD), .ImmSrc(ImmSrcD), .ALUSrc(ALUSrcD),  .MemWrite(MemWriteD), .ResultSrc(ResultSrcD), .Branch(BranchD), .ALUControl(ALUControlD));
                              
                              
    Reg_File rf (.clk(clk), .reset(rst), .RegWrite(RegWriteW), .write_data(ResultW), .Rs1(InstrD[19:15]), .Rs2(InstrD[24:20]), .Rd(RDW), 
                 .read_data1(RD1_D), .read_data2(RD2_D));
                 
                 
    Imm extension (.In(InstrD[31:0]), .Imm_Ext(Imm_Ext_D), .ImmSrc(ImmSrcD));
    
    always @(posedge clk or posedge rst) begin
        if(rst || FlushE) begin
            RegWriteD_r <= 1'b0;
            ResultSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            BranchD_r <= 1'b0;
            ALUControlD_r <= 3'b0;
            ALUSrcD_r <= 1'b0;
            
            RD1_D_r <= 32'b0;
            RD2_D_r <= 32'b0;
            
            RD_D_r <= 5'b0;
            RS1_D_r <= 5'b0;
            RS2_D_r <= 5'b0;
            
            PCD_r <= 32'b0;
            Imm_Ext_D_r <= 32'b0;
            PCPlus4D_r <= 32'b0;
        end
        else  begin
            RegWriteD_r <= RegWriteD;
            ResultSrcD_r <= ResultSrcD;
            MemWriteD_r <= MemWriteD;
            BranchD_r <= BranchD;
            ALUControlD_r <= ALUControlD;
            ALUSrcD_r <= ALUSrcD;
            
            
            RD1_D_r <= RD1_D; 
            RD2_D_r <= RD2_D; 
            
            
            RD_D_r <= InstrD[11:7];
            RS1_D_r <= InstrD[19:15];
            RS2_D_r <= InstrD[24:20];
            
            PCD_r <= PCD; 
            Imm_Ext_D_r <= Imm_Ext_D;
            PCPlus4D_r <= PCPlus4D;
        end
    end
    
//RDE e valoarea registrului
        assign RegWriteE = RegWriteD_r;
        assign ResultSrcE = ResultSrcD_r;
        assign MemWriteE = MemWriteD_r;
        assign BranchE = BranchD_r;
        assign ALUControlE = ALUControlD_r;
        assign ALUSrcE = ALUSrcD_r;
        
        assign RD1_E = RD1_D_r;
        assign RD2_E = RD2_D_r;
        
        assign RD_E = RD_D_r;
        assign RS1_E = RS1_D_r;
        assign RS2_E = RS2_D_r;
        
        assign PCE = PCD_r;
        assign Imm_Ext_E = Imm_Ext_D_r;
        assign PCPlus4E = PCPlus4D_r;
        
endmodule