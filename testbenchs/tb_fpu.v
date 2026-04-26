module tb_fpu;
    reg clock , reset , start;
    reg [ 31 : 0 ] a , b;
    reg [ 2 : 0 ] op; // ADD , SUB , MUL , DIV , EQ , SLT
    wire [ 31 : 0 ] c;
    wire busy , done;
    wire f_inv_op , f_div_zero , f_overflow , f_underflow , f_inexact;

    fpu dut(
        .clock(clock) , .reset(reset) , .start(start) ,
        .a(a) , .b(b) ,
        .op(op) , // ADD , SUB , MUL , DIV , EQ , SLT
        .c(c) ,
        .busy(busy) , .done(done) ,
        .f_inv_op(f_inv_op) , .f_div_zero(f_div_zero) ,
        .f_overflow(f_overflow) , .f_underflow(f_underflow) , .f_inexact(f_inexact)
    );

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    initial begin
        $display("    a    |     b    |    c     | f_inv_op | f_div_zero | f_overflow | f_underflow | f_inexact | busy | done");
        reset = 1;
        #10
        reset = 0;
        a =  32'h00000000;
        b =  32'h80000000;
        op = 3'b000; //soma
        #10
        start=0;
        #10
        start=1;
        #10
        start=0;
        wait(done);
        $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b", a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done);
        #10
        $finish();
    end

endmodule