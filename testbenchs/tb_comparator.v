module  comp_tb;
    reg eq; //1 se eh eq, 0 se eh 
    reg clk;
    reg reset;
    reg [31:0] a, b;
    wire [31:0] c;
    wire f_inv_op;
    wire over;

    comparator dut(
        .eq(eq), //1 se eh eq, 0 se eh 
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .c(c),
        .f_inv_op(f_inv_op),
        .over(over)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    reg [31:0]ce;
    reg ef;

    initial begin
        $dumpfile("comp_tb.vcd");
        $dumpvars(0, comp_tb);

        eq = 0;
        a = 32'h0;
        b = 32'h0;
        ce = 32'h00000000;
        ef =0;
        reset = 1;
        #20
        reset =0;
        #20
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end
        eq = 1;
        ce = 32'h3F800000;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end
        a = 32'h80000000;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        a = 32'h40A0_0000;
        b = 32'h40A0_0000;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        a=32'h7F800001;
        b=32'hxx0x_xxxx;
        ef=1;
        ce = 32'h00000000;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        b=32'h7F800001;
        a=32'hxx0x_xxxx;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        b= 32'h7FC0_0000;
        a= 32'h7FC0_0000;
        ef=0;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        $display("eq=0");
        eq=0;
        a=32'h8000_0000;
        b=32'h0000_0000;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        a=32'h7FC0_0000;
        b=32'h0000_0005;
        ef = 1;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        a=32'hFF80_0000;
        b=32'hC000_0000;
        ef=0;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        a = 32'h0000_000A;
        b = 32'h0000_000B;
        ce = 32'h3F800000;
        #30
        if(over == 1'b1) begin
            if(c == ce && f_inv_op==ef) begin
                $display("PASS: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end else begin
                $display("FAIL: a=%h, b=%h,  c=%h, ce=%h, f_inv_op=%b, ef=%b", a, b, c, ce, f_inv_op, ef);
            end
        end

        a=32'hFFFF_FFFF;
        a=32'hFFFF_FFFE;

        $finish();
    end

endmodule