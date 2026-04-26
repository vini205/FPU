module tp_div (
    input wire clk, rst, start,
    input wire [31:0] a, b,
    output wire [31:0] result,
    output wire busy, done,
    output wire f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact
);

    wire start_core, div_core_done, msb_is_zero, load_norm, shift_l,  d_zero;

    div_uc uc_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .div_done(div_core_done),
        .msb_is_zero(msb_is_zero),
        .div_zero(d_zero),
        .start_div(start_core),
        .busy(busy),
        .load_norm_shift(load_norm),
        .shift_left_norm(shift_l),
        .done(done)
    );

    div_fd fd_inst (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .start_div(start_core),
        .load_norm_shift(load_norm),
        .shift_left_norm(shift_l),
        .result(result),
        .div_done(div_core_done),
        .div_zero(d_zero),
        .msb_is_zero(msb_is_zero),
        .f_inv_op(f_inv_op),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .f_inexact(f_inexact)
    );
    assign f_div_zero = d_zero;

endmodule