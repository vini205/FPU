module bus_controler_tb;
    reg busy;
    reg clk;
    reg reset;
    reg [2:0]addr;
    reg [31:0] a, b;
    wire [31:0] c;
    wire f_inv_op , f_div_zero , f_overflow , f_underflow , f_inexact;
    wire over;
    
    bus_controler dut(
        .busy(busy),
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .a(a),
        .b(b),
        .c(c),
        .f_inv_op(f_inv_op) , .f_div_zero(f_div_zero) , .f_overflow(f_overflow) , .f_underflow(f_underflow) , .f_inexact(f_inexact),
        .over(over)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    integer i, j, k;
    reg [31:0]  ce;
    reg efinv;
    initial begin
        $dumpfile("bus_controler_tb.vcd");
        $dumpvars(0, bus_controler_tb);

        $display("testando reset e busy");
        $display("addr | reset | busy |f_div_zero");
        for(k=0; k<2; k++)begin
            reset=k;
            for(j=0; j<2; j++) begin
                busy=j;
                for(i=0; i<8; i++) begin
                    #1;
                    $display("%b  |   %b   |   %b  |    %b", addr, reset, busy, f_div_zero);
                    addr=i;
                    
                end
            end
        end

        busy=1;
        reset = 0;
        addr = 3'b100;
        $display("testando igualdade (addr=100)");
        $display("    a     |    b     |    c     | f_inv_op");
        a = 32'h0000_0000;
        b = 32'h0000_0000;
        ce = 32'h3F800000;
        efinv = 0;
        wait (over == 1'b1);
        if(c==ce && efinv == f_inv_op) $display(" %h | %h | %h |    %b       PASS", a, b, c, f_inv_op);
        else $display(" %h | %h | %h |    %b       FAIL", a, b, c, f_inv_op);
        
        a=32'h7F800001;
        b=32'hxx0x_xxxx;
        ce = 32'h0000_0000;
        efinv = 1;
        #10
        wait (over == 1'b1);
        if(c==ce && efinv == f_inv_op) $display(" %h | %h | %h |    %b       PASS", a, b, c, f_inv_op);
        else $display(" %h | %h | %h |    %b       FAIL", a, b, c, f_inv_op);

        busy=1;
        reset = 0;
        addr = 3'b101;
        $display("testando menor que (addr=101)");
        $display("    a     |    b     |    c     | f_inv_op");
        a = 32'h8000_0000;
        b = 32'h0000_0000;
        ce = 32'h00000000;
        efinv = 0;
        #10
        wait (over == 1'b1);
        if(c==ce && efinv == f_inv_op) $display(" %h | %h | %h |    %b       PASS", a, b, c, f_inv_op);
        else $display(" %h | %h | %h |    %b       FAIL", a, b, c, f_inv_op);
        
        a=32'h7F800001;
        b=32'hxxxx_xxxx;
        ce = 32'h0000_0000;
        efinv = 1;
        #10
        wait (over == 1'b1);
        if(c==ce && efinv == f_inv_op) $display(" %h | %h | %h |    %b       PASS", a, b, c, f_inv_op);
        else $display(" %h | %h | %h |    %b       FAIL", a, b, c, f_inv_op);


        #10
        $finish;
    end

endmodule