module mult(
    input clk,
    input reset,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op , f_overflow , f_underflow , f_inexact,
    output over
);
wire exeption, load_shift, e_norm;

mult_fd fd(
    .clk(clk),
    .load_shift(load_shift),
    .e_norm(e_norm),
    .a(a), .b(b),
    .c(c),
    .exeption(exeption),
    .f_inv_op(f_inv_op) , .f_overflow(f_overflow) , .f_underflow(f_underflow) , .f_inexact(f_inexact)
);

mult_uc uc( 
    .clk(clk),
    .reset(reset),
    .exeption(exeption),
    .load_shift(load_shift),
    .e_norm(e_norm), //enable normalizacao
    .over(over)
);
endmodule