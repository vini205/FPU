module div_fd (
    input clok,
    input rst,
    input start_div,
    input load_norm_shift,
    input shift_left_norm,

    output div_done,
    output div_zero,
    output msb_is_zero
);

    wire is_snan_A;
    
    wire is_inf_A;
    wire is_ninf_A;
    
    wire inf_conflict = is_inf_A & is_inf_B & is_diff;
    assign f_inv_op = inf_conflict | is_snan_A | is_snan_B;
    exeptions_number_detector exep_a(
    .a(a),
    .sNaN(is_snan_A),
    .pos_inf(is_inf_A),
    .neg_inf(is_ninf_A),
    .zero()
    );
    wire is_snan_B, is_inf_B, is_ninf_B,B_zero;


    exeptions_number_detector exep_a(
    .a(b),
    .sNaN(is_snan_B),
    .pos_inf(is_inf_B),
    .neg_inf(is_ninf_B),
    .zero(B_zero)
    );
    div_zero = B_zero;

    
endmodule