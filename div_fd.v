module div_fd (
    input clk,
    input rst,
    input [31:0]a,b,
    input start_div,
    input load_norm_shift,
    input shift_left_norm,

    output [31:0] result,
    output div_done,
    output div_zero,
    output msb_is_zero,
    output wire f_inv_op,
    output wire f_overflow,   
    output wire f_underflow,  
    output wire f_inexact
);

    wire is_snan_A;
    wire A_zero;
    wire is_inf_A;
    wire is_ninf_A;
    
    wire inf_conflict = is_inf_A & is_inf_B;
    exeptions_number_detector exep_a(
    .a(a),
    .sNaN(is_snan_A),
    .qNaN(is_qnan_A),
    .pos_inf(is_inf_A),
    .neg_inf(is_ninf_A),
    .zero(A_zero)
    );
    wire is_snan_B, is_inf_B, is_ninf_B,B_zero,is_qnan_A,is_qnan_B;


    exeptions_number_detector exep_b(
    .a(b),
    .sNaN(is_snan_B),
    .qNaN(is_qnan_B),
    .pos_inf(is_inf_B),
    .neg_inf(is_ninf_B),
    .zero(B_zero)
    );
    assign div_zero = B_zero & ~A_zero;//Apenas se A != 0


    wire [7:0] exp_A = a[30:23];
    wire [7:0] exp_B = b[30:23];

    //Para subnormais
    wire [7:0] eff_exp_A = (~|exp_A) ? 8'd1 : exp_A;
    wire [7:0] eff_exp_B = (~|exp_B) ? 8'd1 : exp_B;

    wire [23:0] mant_A = {|exp_A, a[22:0]};
    wire [23:0] mant_B = {|exp_B,b[22:0]};
    wire [25:0] quotient;
    wire [25:0] remainder;
    restoring_div #(.N(26)) divisor_mant (
        .clk(clk),
        .rst(rst),
        .start(start_div),
        .dividend({mant_A,2'b00}),//guard bits
        .divisor({mant_B, 2'b00}),
        .quotient(quotient),
        .remainder(remainder),
        .done(div_done)
    );
    assign msb_is_zero = ~quotient[25];
    wire sign_out = a[31] ^ b[31];

    wire [9:0] exp_A_ext = {2'b00, eff_exp_A};// estendo para ver o overflow/underflow 
    wire [9:0] exp_B_ext = {2'b00, eff_exp_B};
    wire [9:0] bias = 10'd127;
    wire [9:0] exp_calc;
    wire [9:0] exp_sub_tot;
    
    // SUBTRAÇÂO DOS EXP
    full_subtractor_nbit #(.N(10)) sub_exp (
        .a(exp_A_ext),
        .b(exp_B_ext),
        .bin(1'b0),
        .diff(exp_calc),
        .bout()
    );

    full_adder_Nbits #(.N(10)) adicionador_bias (
        .a(exp_calc),
        .b(bias),
        .cin(1'b0), //Soma Bias
        .sum(exp_sub_tot),
        .cout()
    );

    //NORMALIZE
    wire [25:0] mant_normalized = shift_left_norm ? {quotient[24:0], 1'b0} : quotient;

    
    wire [23:0] mantissaNorm = mant_normalized[25:2];

    wire [2:0] guards = {mant_normalized[1], mant_normalized[0], |remainder};

    wire [9:0] exp_normalized;
    full_subtractor_nbit #(.N(10)) exp_norm (
        .a(exp_sub_tot),
        .b( {9'b0, shift_left_norm} ),
        .bin( 1'b0),
        .diff(exp_normalized),
        .bout()
    );

    // ROUND
    wire round_up = guards[2] & (guards[1] | guards[0] | mantissaNorm[0]);

    wire [22:0] mantissaRouded;
    wire round_cout;
    full_adder_Nbits #(.N(23)) somador_round (
        .a(mantissaNorm[22:0]),
        .b(23'b0),
        .cin(round_up),
        .sum(mantissaRouded),
        .cout(round_cout)
    );

    wire [22:0] mantissa_final = round_cout ? 23'd0 : mantissaRouded;    
    wire [9:0] exp_pos_round;
    

    // ajustar o EXP caso o arredondamento transborde
    full_adder_Nbits #(.N(10)) ajustador_exp_round (
        .a(exp_normalized),
        .b(10'd0),
        .cin(round_cout), 
        .sum(exp_pos_round),
        .cout()
    );


    // FLAGS
    wire [31:0] qnan = {1'b0, 8'hFF, 23'h400000};
    wire [31:0] infinity = {sign_out, 8'hFF, 23'd0};

    // Invalid
    wire zero_por_zero = A_zero & B_zero;
    wire inf_por_inf = is_inf_A & is_inf_B;
    assign f_inv_op = is_snan_A | is_snan_B | zero_por_zero | inf_por_inf|is_qnan_A | is_qnan_B;

    //Underflow


    wire is_neg_exp = exp_pos_round[9];
    wire is_zero_exp = (~|exp_pos_round[8:0]);
    wire underflow_exp = is_neg_exp | is_zero_exp;
    wire [9:0] denorm_shift;

    full_subtractor_nbit #(.N(10)) calc_shift_norm (
        .a(10'd1),
        .b(exp_pos_round),
        .bin(1'b0),
        .bout(),
        .diff(denorm_shift )
    );
    wire [23:0] full_mant_denorm = {1'b1, mantissa_final};

     wire denorm00, denorm01;
    comp_Nbits #(.N(10)) comp_denorm_shift(
        .A(denorm_shift),
        .B(10'd24),
        .AGTB(denorm00),
        .AEQB(denorm01)
    );

    // Desloca , se for for >= 24 a fracao zera
    wire [23:0] denorm_mantissa = ( denorm00 | denorm01 ) ? 24'd0 :
                                  (full_mant_denorm >> denorm_shift);


    //OVerlfow
    wire exp_over00, exp_over01;
    comp_Nbits #(.N(10)) comp_overflow_exp(
        .A(exp_pos_round),
        .B(10'b0011111111),
        .AGTB(exp_over00),
        .AEQB(exp_over01)
    );
    wire f_overflow_exp  = (~is_neg_exp) & ( exp_over00 | exp_over01);
    wire [7:0] final_exp  = underflow_exp ? 8'h00 : exp_pos_round[7:0];
    wire [22:0] final_frac = underflow_exp ? denorm_mantissa[22:0] : mantissa_final;
    // INVALID

    wire force_nan_out = f_inv_op | is_qnan_A | is_qnan_B;
    assign result = force_nan_out    ? qnan :
                    (div_zero)  ? infinity  : 
                    (f_overflow_exp) ? infinity  :
                                         {sign_out, final_exp, final_frac};
    // se overflow => infinito, se underflow => zero

    assign f_overflow = f_overflow_exp;
    assign f_underflow = underflow_exp & (|guards);

    assign f_inexact = |guards | f_overflow | f_underflow;

endmodule