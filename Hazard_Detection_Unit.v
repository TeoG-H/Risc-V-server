
module Hazard_Unit_Detection(
    input rst,
    input RegWriteM, RegWriteW,
    input [4:0] RD_M, RD_W, RD_E, Rs1_E, Rs2_E, RS1_D, RS2_D,
    input ResultSrcE,
    output reg [1:0] ForwardAE, ForwardBE,
    output reg StallF, StallD, FlushE
);

always @(*) begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    StallF = 1'b0;
    StallD = 1'b0;
    FlushE = 1'b0;

    if (!rst) begin
    //deci cand reg meu sursa 1 sau 2 este = cu reg dest din mem atunci iau valoarea lui direct din etapa DM si o folosesc in E
     // primul if e cand se afla in mem si al doilea cand se afla in wb  
     //din mem il ia cand instructiunea e la un ciclu distanta (adica exact una dupa alta) si din wb cand e la 2 
        if (RegWriteM && (RD_M != 0) && (RD_M == Rs1_E))
            ForwardAE = 2'b10;
        else if (RegWriteW && (RD_W != 0) && (RD_W == Rs1_E))
            ForwardAE = 2'b01;
            
        if (RegWriteM && (RD_M != 0) && (RD_M == Rs2_E))
            ForwardBE = 2'b10;
        else if (RegWriteW && (RD_W != 0) && (RD_W == Rs2_E))
            ForwardBE = 2'b01;
    end

// apare la lw cand rezultatul e gata abia in ciclul DM si atunci il pun pe pauza cu Stall
// si la beq cand trebuie sa se faca saltul si sa se stearga datele cu Flush 
    if (ResultSrcE && (RD_E != 5'd0) && ((RD_E == RS1_D) || (RD_E == RS2_D))) begin
        StallF = 1'b1;
        StallD = 1'b1;
        //deci eu inghet F si D si sterg din E ca sa nu ramana acelasi lw
        FlushE = 1'b1;
    end
end

endmodule