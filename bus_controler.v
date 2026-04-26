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
    //escravo 3: addr 100(EQ) e 101(SLT)
    //addr 110-111(esse endereco eh invalido e nunca deveria ser acionado)


    wire e_s0;
    assign e_s0 = (~reset)&(~addr[1])&(~addr[2])&busy;
    wire e_s1;
    assign e_s1 = (~reset)&(~addr[0])&(addr[1])&(~addr[2])&busy;
    wire e_s2;
    assign e_s2 = (~reset)&(addr[0])&(addr[1])&(~addr[2])&busy;
    wire e_s3;
    assign e_s3 = (~reset)&(~addr[1])&(addr[2])&busy;
    
    

    wire [31:0] c0;
    wire f_inv_op0, f_div_zero0, f_overflow0 , f_underflow0 , f_inexact0;
    wire over0; //=done
    //instanciar o escravo 0 (Por  favor usar reset como ~es_0, alem dos outputs acima)
    tp_add_sub sum_sub(
        .clk(clk),
        .reset(~e_s0),
        .start(e_s0),
        .is_sub(addr[2]),
        .a(a),
        .b(b),
        .result(c),
        .f_div_zero(f_div_zero0),
        .f_overflow(f_overflow0),
        .f_underflow(f_underflow0),
        .f_inexact(f_inexact0),
        .f_inv_op(f_inv_op0),
        .over(over)
    );
    //
    assign f_div_zero0 = 1'b0;
    
    
    wire [31:0] c1;
    wire f_inv_op1, f_div_zero1, f_overflow1 , f_underflow1 , f_inexact1;
    wire over1; //=done
    //instanciar o escravo 1 (Por  favor usar reset como ~es_1, alem dos outputs acima)
    
    //
    assign f_div_zero1 = 1'b0;
    
    wire [31:0] c2;
    wire f_inv_op2, f_div_zero2, f_overflow2 , f_underflow2 , f_inexact2;
    wire over2; //=done
    //instanciar o escravo 2 (Por  favor usar reset como ~es_2, alem dos outputs acima)

    //
   
   
    wire [31:0] c3;
    wire f_inv_op3, f_div_zero3, f_overflow3 , f_underflow3 , f_inexact3;
    wire over3; //=done
    //instancia do escravo 3
        comparator comp(
            .eq(~addr[0]), //1 se eh EQ, 0 se eh SLT
            .clk(clk),
            .reset(~e_s3),
            .a(a),
            .b(b),
            .c(c3),
            .f_inv_op(f_inv_op3),
            .over(over3)
        );
    assign f_div_zero3= 1'b0;
    assign f_overflow3 = 1'b0;
    assign f_underflow = 1'b0;
    assign f_inexact = 1'b0;
    //
    
   assign c = (e_s0) ? c0 : (e_s1) ? c1 : (e_s2) ? c2 : (e_s3) ? c3 : 32'bz;
   assign f_inv_op = (e_s0) ? f_inv_op0 : (e_s1) ? f_inv_op1 : (e_s2) ? f_inv_op2 : (e_s3) ? f_inv_op3 : 1'bz;
   assign f_div_zero = (e_s0) ? f_div_zero0 : (e_s1) ? f_div_zero1 : (e_s2) ? f_div_zero2 : (e_s3) ? f_div_zero3 : 1'bz;
   assign f_overflow = (e_s0) ? f_overflow0 : (e_s1) ? f_overflow1 : (e_s2) ? f_overflow2 : (e_s3) ? f_overflow3 : 1'bz;
   assign f_underflow = (e_s0) ? f_underflow0 : (e_s1) ? f_underflow1 : (e_s2) ? f_underflow2 : (e_s3) ? f_underflow3 : 1'bz;
   assign f_inexact = (e_s0) ? f_inexact0 : (e_s1) ? f_inexact1 : (e_s2) ? f_inexact2 : (e_s3) ? f_inexact3 : 1'bz;
   assign over = (e_s0) ? over0 : (e_s1) ? over1 : (e_s2) ? over2 : (e_s3) ? over3 : 1'bz;
   
endmodule