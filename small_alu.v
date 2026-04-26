module small_alu #(parameter N = 8) (
    input  wire [N-1:0] A,
    input  wire [N-1:0] B,
    output wire [N-1:0] diff,
    output wire       A_gt_B,
    output wire       A_eq_B,
    output wire       A_lt_B
);

    wire [N-1:0] max_val;
    wire [N-1:0] min_val;
    wire bout_ignorado;

    comp_Nbits #(.N(N)) dut (
        .A(A),
        .B(B),
        .AGTB(A_gt_B),
        .AEQB(A_eq_B),
        .ALTB(A_lt_B)
    );

    assign max_val = A_lt_B ? B : A;
    assign min_val = A_lt_B ? A : B;

    full_subtractor_nbit #(.N(N)) subtrator_absoluto (
        .a(max_val),
        .b(min_val),
        .bin(1'b0),
        .diff(diff),
        .bout(bout_ignorado)
    );

endmodule