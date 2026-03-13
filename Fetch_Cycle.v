module Fetch_Cycle(clk, rst, PCSrc, PCTargetE, StallF, StallD, FlushD, InstrD, PCD, PCPlus4D);

    input clk, rst, PCSrc, StallF, StallD, FlushD;
    input [31:0] PCTargetE;
    output [31:0] InstrD, PCPlus4D, PCD;

    wire [31:0] PCNext_F;   
    wire [31:0] PCF;       
    wire [31:0] InstrF;     
    wire [31:0] PCPlus4F;   

    reg [31:0] InstrD_r, PCD_r, PCPlus4D_r; // cate fire intra in reg atatea reg trebuie sa am 

    Mux PC_Sel (.sel(PCSrc), .A(PCPlus4F), .B(PCTargetE), 
                .Mux_out(PCNext_F));
    
    PC Program_Counter (.clk(clk), .reset(rst), .en(~StallF), .PC_in(PCNext_F), 
                        .PC_out(PCF));
    
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

    assign InstrD  = InstrD_r;
    assign PCPlus4D = PCPlus4D_r;
    assign PCD =  PCD_r;
endmodule
