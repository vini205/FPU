module bus_controler(
    input busy,
    input clk,
    input reset,
    input [2:0]addr,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op , f_div_zero , f_overflow , f_underflow , f_inexact,
    output over
);
    //enables dos escravos
    //escravo 0: addr 000(ADD) ou 001(SUB),
    //escravo 1: addr 010(MULT)
    //escravo 2: addr 011(DIV)
    //escravo 3: addr 100(EQ)
    //escravo 4: addr 101(SLT)
    //addr 110-111(esse endereco eh invalido e nunca deveria ser acionado)


    wire e_s0;
    assign e_s0 = (~reset)&(~addr[1])&(~addr[2])&busy;
    wire e_s1;
    assign e_s1 = (~reset)&(~addr[0])&(addr[1])&(~addr[2])&busy;
    wire e_s2;
    assign e_s2 = (~reset)&(addr[0])&(addr[1])&(~addr[2])&busy;
    wire e_s3;
    assign e_s3 = (~reset)&(~addr[0])&(~addr[1])&(addr[2])&busy;
    wire e_s4;
    assign e_s4 = (~reset)&(addr[0])&(~addr[1])&(addr[2])&busy;
    
    

    wire [31:0] c0;
    wire f_inv_op0, f_div_zero0, f_overflow0 , f_underflow0 , f_inexact0;
    wire over0;
    //instanciar o escravo 0
    
    //
    assign f_div_zero0 = 1'b0;
    
    
    wire [31:0] c1;
    wire f_inv_op1, f_div_zero1, f_overflow1 , f_underflow1 , f_inexact1;
    wire over1;
    //instanciar o escravo 1
    
    //
    assign f_div_zero1 = 1'b0;
    
    wire [31:0] c2;
    wire f_inv_op2, f_div_zero2, f_overflow2 , f_underflow2 , f_inexact2;
    wire over2;
    //instanciar o escravo 2
    assign f_div_zero2 = 1'b1;
    //
   
   
    wire [31:0] c3;
    wire f_inv_op3, f_div_zero3, f_overflow3 , f_underflow3 , f_inexact3;
    wire over3;
    //instanciar o escravo 3
    
    //
    assign f_div_zero3= 1'b0;


    wire [31:0] c4;
    wire f_inv_op4, f_div_zero4, f_overflow4 , f_underflow4 , f_inexact4;
    wire over4;
    //instanciar o escravo 4
    
    //
    assign f_div_zero4= 1'b0;
    
   assign c = (e_s0) ? c0 : (e_s1) ? c1 : (e_s2) ? c2 : (e_s3) ? c3 : (e_s4) ? c4 : 32'bz;
   assign f_inv_op = (e_s0) ? f_inv_op0 : (e_s1) ? f_inv_op1 : (e_s2) ? f_inv_op2 : (e_s3) ? f_inv_op3 : (e_s4) ? f_inv_op4 : 1'bz;
   assign f_div_zero = (e_s0) ? f_div_zero0 : (e_s1) ? f_div_zero1 : (e_s2) ? f_div_zero2 : (e_s3) ? f_div_zero3 : (e_s4) ? f_div_zero4 : 1'bz;
   assign f_overflow = (e_s0) ? f_overflow0 : (e_s1) ? f_overflow1 : (e_s2) ? f_overflow2 : (e_s3) ? f_overflow3 : (e_s4) ? f_overflow4 : 1'bz;
   assign f_underflow = (e_s0) ? f_underflow0 : (e_s1) ? f_underflow1 : (e_s2) ? f_underflow2 : (e_s3) ? f_underflow3 : (e_s4) ? f_underflow4 : 1'bz;
   assign f_inexact = (e_s0) ? f_inexact0 : (e_s1) ? f_inexact1 : (e_s2) ? f_inexact2 : (e_s3) ? f_inexact3 : (e_s4) ? f_inexact4 : 1'bz;
   assign over = (e_s0) ? over0 : (e_s1) ? over1 : (e_s2) ? over2 : (e_s3) ? over3 : (e_s4) ? over4 : 1'bz;
   
endmodule