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

    integer i, j, k;
    initial begin
        $dumpfile("bus_controler_tb.vcd");
        $dumpvars(0, bus_controler_tb);

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
        
        $finish;
    end

endmodule