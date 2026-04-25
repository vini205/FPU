module exeptions_number_detector_tb;
    reg [31:0] a;
    wire sNaN; //signaling NaN
    wire qNaN; //quiet
    wire pos_inf; //infinito positivo
    wire neg_inf; //"" negativo
    wire zero; //==0

    exeptions_number_detector dut(
        .a(a),
        .sNaN(sNaN),
        .qNaN(qNaN),
        .pos_inf(pos_inf),
        .neg_inf(neg_inf),
        .zero(zero)
    );

    initial begin
        $monitor("a=%h , sNaN=%b, qNaN=%b, pos_inf=%b, neg_inf=%b, zero=%b", a, sNaN, qNaN, pos_inf, neg_inf, zero);
        a = 32'h8000_0000; //0
        #10
        a = 32'h0000_0000; //0
        #10
        a=32'h7F800001; //SNaN
        #10
        a=32'h7F800000; //pos_inf
        #10
        a=32'hFF800000; //neg_inf
        #10
        a=32'hFFC00000; //qNaN
        #10
        a=32'h3f800000; //=1
        #10
        $finish();
    end

endmodule