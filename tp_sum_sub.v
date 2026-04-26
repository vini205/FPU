module tp_add_sub (
    input wire clk,
    input wire reset,
    input wire start,         
    input wire is_sub,        // 0 para adição, 1 para subtração
    input wire [31:0] a,
    input wire [31:0] b,
    
    output wire [31:0] result,
    output wire f_div_zero,
    output wire f_overflow,
    output wire f_underflow,
    output wire f_inexact,
    output wire f_inv_op,
    output wire over          
);

    wire load_shift;
    wire shift_mant;
    wire shift_right_norm;
    wire shift_left_norm;
    wire load_norm_shift;
    wire load_sum;            // Sinal gerado pela UC, atualmente sem sumidouro no FD

    wire count_over;
    wire is_normalized;
    wire exp_is_zero;
    wire cout_sum;

    sum_uc control_unit (
        .clk(clk),
        .rst(reset),
        .start(start),
        
        // Sinais de realimentação (Feedback) do FD
        .count_over(count_over),
        .is_normalized(is_normalized),
        .exp_is_zero(exp_is_zero),
        .cout_sum(cout_sum),
        
        // Sinais de Controle 
        .shift_right_norm(shift_right_norm),
        .shift_left_norm(shift_left_norm),
        .load_sum(load_sum),
        .load_shift(load_shift),
        .shift_mant(shift_mant),
        .load_norm_shift(load_norm_shift),
        .done(over)           
    );

    sum_fd datapath (
        .a(a),
        .b(b),
        .clk(clk),
        .rst(reset),
        
        // Sinais de Controle provenientes da UC
        .load_shift(load_shift),
        .shift_mant(shift_mant),
        .is_sub(is_sub),
        .shift_right_norm(shift_right_norm),
        .shift_left_norm(shift_left_norm),
        .load_norm_shift(load_norm_shift),
        
        // Saídas de Estado e Flags Operacionais
        .exp_is_zero(exp_is_zero),
        .cout_sum(cout_sum),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .sum(result),
        .count_over(count_over),
        .is_normalized(is_normalized),
        .f_inexact(f_inexact),
        .f_inv_op(f_inv_op)
    );

    assign f_div_zero = 1'b0;

endmodule