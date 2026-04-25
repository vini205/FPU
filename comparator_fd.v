module comparator_fd(
    input eq,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op
);
    wire sign_A, sign_B;
    wire [7:0] exp_A, exp_B;
    wire [22:0] mant_A, mant_B;

    assign sign_A = a[31];
    assign exp_A = a[30:23];
    assign mant_A = a[22:0];

    assign exp_B = b[30:23];
    assign sign_B = b[31];
    assign mant_B = b[22:0];

    wire NaN_a, NaN_b;
    wire m_zero_a, m_zero_b;
    wire max_a, max_b;
    comp_Nbits #(8) exp_max_a( 
        .A(exp_A), 
        .B(8'b11111111), 
        .AEQB(max_a)
    );
    comp_Nbits #(8) exp_max_b( 
        .A(exp_B), 
        .B(8'b11111111), 
        .AEQB(max_b)
    );
    comp_Nbits #(23) mant_zero_a( 
        .A(mant_A), 
        .B(23'b0), 
        .AEQB(m_zero_a)
    );
    comp_Nbits #(23) mant_zero_b( 
        .A(mant_B), 
        .B(23'b0), 
        .AEQB(m_zero_b)
    );
    assign NaN_a = max_a & (~m_zero_a);
    assign NaN_b = max_b & (~m_zero_b);

    wire SNaN_a, SNaN_b;
    assign SNaN_a = NaN_a & (~a[22]);
    assign SNaN_b = NaN_b & (~b[22]);
    assign f_inv_op = (NaN_a | NaN_b)&(~eq) | (SNaN_a |SNaN_b); 

    wire exp_zero_a;
    wire exp_zero_b;
    wire zero_a, zero_b;
    comp_Nbits #(8) exp_0_a( 
        .A(exp_A), 
        .B(8'b0), 
        .AEQB(exp_0_a)
    );
    comp_Nbits #(8) exp_0_b( 
        .A(exp_B), 
        .B(8'b0), 
        .AEQB(exp_0_b)
    );
    assign zero_a = exp_0_a & m_zero_a;
    assign zero_b = exp_0_b & m_zero_b;



    wire AEQB0; //sem cobrir as execessoes
    wire ALTB0;
    comp_Nbits #(32) comp( 
        .A({~sign_A, a[30:0]}), 
        .B({~sign_B, b[30:0]}), 
        .AEQB(AEQB0),
        .ALTB(ALTB0)
    );


    wire AEQB;
    assign AEQB = ((zero_b & zero_a) | AEQB0)&(~NaN_a)&(~NaN_b);
    wire ALTB;
    assign ALTB = (~(zero_b & zero_a))&(ALTB0)&(~NaN_a)&(~NaN_b);

    assign c = (eq) ? ((AEQB) ?  (32'h3F800000) : (32'h00000000)) : ((ALTB) ?  (32'h3F800000) : (32'h00000000));

endmodule