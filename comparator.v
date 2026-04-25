module comparator(
    input eq, //1 se eh eq, 0 se eh 
    input clk,
    input reset,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op,
    output over
);
comparator_uc uc_comparator(
    .clk(clk),
    .reset(reset),
    .over(over)
);

comparator_fd fd_comparator(
    .eq(eq),
    .a((reset) ? (32'bz) : (a)),
    .b((reset) ? (32'bz) : (b)),
    .c(c),
    .f_inv_op(f_inv_op) 
);


endmodule