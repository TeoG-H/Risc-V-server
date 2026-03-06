`timescale 1ns / 1ps

module PC( input clk, input reset, input en, input [31:0] PC_in, output reg [31:0] PC_out );

   always @(posedge clk or posedge reset)
   begin
        if(reset)
            PC_out <= 32'b0;
        else if(en)
            PC_out <= PC_in;
   end
endmodule


module adder_PC_4(input [31:0] adder_4_in, output [31:0] adder_4_out);

    assign adder_4_out = 4 +adder_4_in;

endmodule


module PC_Adder (a,b,c);

    input [31:0]a,b;
    output [31:0]c;

    assign c = a + b;
    
endmodule


module Instruction_Mem(input  [31:0] read_address, output [31:0] instruction);

    reg [7:0] mem [0:1023];    
    reg [31:0] temp_mem [0:255]; // mem de 64 ko
    integer i;

    initial begin
        $readmemh("program.mem", temp_mem);

        for (i = 0; i < 64; i = i + 1) begin
            mem[i*4 + 3] = temp_mem[i][31:24];
            mem[i*4 + 2] = temp_mem[i][23:16];
            mem[i*4 + 1] = temp_mem[i][15:8];
            mem[i*4 + 0] = temp_mem[i][7:0];
        end
    end

    assign instruction = {mem[read_address+3],mem[read_address+2],mem[read_address+1],mem[read_address]};
endmodule


module Reg_File(clk, reset, RegWrite, Rs1, Rs2, Rd, write_data, read_data1, read_data2);

    input clk, reset, RegWrite;
    input [4:0] Rs1, Rs2, Rd;
    input [31:0] write_data;
    output [31:0] read_data1, read_data2;
    
    reg [31:0] Registers[31:0];
    integer k;
    
    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            for (k=0; k<32; k=k+1) begin
                Registers[k] <= 32'b0;
            end
        end
        else if (RegWrite  && (Rd != 5'd0)) begin  // registrul 0 trebuie sa fie mereu 0
            Registers[Rd] <= write_data;
        end
    end
    
assign read_data1 = (RegWrite && (Rd != 5'd0) && (Rd == Rs1)) ? write_data : Registers[Rs1];
assign read_data2 = (RegWrite && (Rd != 5'd0) && (Rd == Rs2)) ? write_data : Registers[Rs2];

endmodule




module Sign_Extend (In,ImmSrc,Imm_Ext);
    input [31:0] In;
    input [1:0] ImmSrc;
    output [31:0] Imm_Ext;

    assign Imm_Ext =  (ImmSrc == 2'b00) ? {{20{In[31]}},In[31:20]} : 
                     (ImmSrc == 2'b01) ? {{20{In[31]}},In[31:25],In[11:7]} :
                     (ImmSrc == 2'b10) ?{{20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0} : 32'h00000000; 

endmodule

module Main_Decoder(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp);
    input [6:0]Op;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc,ALUOp;

    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011 | Op == 7'b0010011 ) ? 1'b1 :
                                                              1'b0 ;
    assign ImmSrc = (Op == 7'b0100011) ? 2'b01 : 
                    (Op == 7'b1100011) ? 2'b10 :    
                                         2'b00 ;
    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011 | Op == 7'b0010011) ? 1'b1 :
                                                            1'b0 ;
    assign MemWrite = (Op == 7'b0100011) ? 1'b1 :
                                           1'b0 ;
    assign ResultSrc = (Op == 7'b0000011) ? 1'b1 :
                                            1'b0 ;
    assign Branch = (Op == 7'b1100011) ? 1'b1 :
                                         1'b0 ;
    assign ALUOp = (Op == 7'b0110011) ? 2'b10 :
                   (Op == 7'b1100011) ? 2'b01 :
                                        2'b00 ;

endmodule

module ALU_Decoder(ALUOp,funct3,funct7,op,ALUControl);

    input [1:0]ALUOp;
    input [2:0]funct3;
    input [6:0]funct7,op;
    output [2:0]ALUControl;
    assign ALUControl =
    (ALUOp == 2'b00) ? 3'b000 :                     // add (lw, sw, addi)
    (ALUOp == 2'b01) ? 3'b001 :                     // sub (beq)
    (ALUOp == 2'b10 && funct3 == 3'b000 && funct7[5]) ? 3'b001 : // sub
    (ALUOp == 2'b10 && funct3 == 3'b000) ? 3'b000 : // add
    (ALUOp == 2'b10 && funct3 == 3'b111) ? 3'b010 : // and
    (ALUOp == 2'b10 && funct3 == 3'b110) ? 3'b011 : // or
    (ALUOp == 2'b10 && funct3 == 3'b010) ? 3'b101 : // slt
    3'b000;
endmodule



module Control_Unit_Top(Op,funct3,funct7, RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUControl);

    input [6:0]Op,funct7;
    input [2:0]funct3;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc;
    output [2:0]ALUControl;

    wire [1:0]ALUOp;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp)
    );

    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );


endmodule



module ALU(A,B,Result,ALUControl,OverFlow,Carry,Zero,Negative);

    input [31:0]A,B;
    input [2:0]ALUControl;
    output Carry,OverFlow,Zero,Negative;
    output [31:0]Result;

    wire Cout;
    wire [31:0]Sum;

    assign Sum = (ALUControl[0] == 1'b0) ? A + B :
                                          (A + ((~B)+1)) ;
    assign {Cout,Result} = (ALUControl == 3'b000) ? Sum :
                           (ALUControl == 3'b001) ? Sum :
                           (ALUControl == 3'b010) ? A & B :
                           (ALUControl == 3'b011) ? A | B :
                           (ALUControl == 3'b101) ? {{32{1'b0}},(Sum[31])} :
                           {33{1'b0}};
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]));
    assign Carry = ((~ALUControl[1]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];

endmodule



module Data_Memory(clk, reset, MemWrite, read_address, Write_data, MemData_out);

    input clk, reset, MemWrite;
    input [31:0] read_address, Write_data;
    output [31:0] MemData_out;
    
    reg [7:0] mem [0:1023];    
    integer k;

    localparam DATA_OFFSET = 32'd256;

    wire [31:0] addr = read_address;

    always @(posedge clk or posedge reset)
    begin
        if (reset)
            for (k=0; k<1024; k=k+1)
                mem[k] <= 8'b0;
        else if (MemWrite)
        begin
            mem[addr + 3] <= Write_data[31:24];
            mem[addr + 2] <= Write_data[23:16];
            mem[addr + 1] <= Write_data[15:8];
            mem[addr + 0] <= Write_data[7:0];
        end
    end

    assign MemData_out = (reset) ? 32'd0 :
                        {mem[addr+3],
                         mem[addr+2],
                         mem[addr+1],
                         mem[addr]};
endmodule

module Mux(sel, A, B, Mux_out);

    input sel;
    input [31:0] A, B;
    output [31:0] Mux_out;
    
    assign Mux_out = (sel == 1'b0) ? A : B;

endmodule

module Mux_3_by_1 (a,b,c,s,d);
    input [31:0] a,b,c;
    input [1:0] s;
    output [31:0] d;

    assign d = (s == 2'b00) ? a : (s == 2'b01) ? b : (s == 2'b10) ? c : 32'h00000000;
    
endmodule






