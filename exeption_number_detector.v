module exeptions_number_detector(
    input [31:0] a,
    output sNaN, //signaling NaN
    output qNaN, //quiet
    output pos_inf, //infinito positivo
    output neg_inf, //"" negativo
    output zero //==0
);
    wire [7:0] exp_A;
    wire [22:0] mant_A;
    assign exp_A = a[30:23];
    assign mant_A = a[22:0];

    wire NaN_a;
    wire m_zero_a;
    wire max_a;
    comp_Nbits #(8) exp_max_a( 
        .A(exp_A), 
        .B(8'b11111111), 
        .AEQB(max_a)
    );
    comp_Nbits #(23) mant_zero_a( 
        .A(mant_A), 
        .B(23'b0), 
        .AEQB(m_zero_a)
    );

    assign NaN_a = max_a & (~m_zero_a);

    assign sNaN = NaN_a & (~a[22]);
    assign qNaN = NaN_a & (a[22]);
    
    wire inf;
    assign inf = max_a & (m_zero_a);
    assign pos_inf = inf & (~a[31]);
    assign neg_inf = inf & (a[31]);

    wire exp_zero;
    comp_Nbits #(8) exp_min_a( 
        .A(exp_A), 
        .B(8'b00000000), 
        .AEQB(exp_zero)
    );

    assign zero = exp_zero & m_zero_a;


endmodule