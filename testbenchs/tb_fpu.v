module tb_fpu();
    reg clock , reset , start;
    reg [ 31 : 0 ] a , b,expected_res;
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
    reg passed;

    task run_test;
        input [31:0] a_in;
        input [31:0] b_in;
        input [31:0] expected_result;
        input [2:0] op_in;
        begin
            #10
            a = a_in;
            b =  b_in;
            op = op_in;
            reset =1; 
            start=0;#10
            reset = 0;#10
            start=1;#10
            start=0;
            wait(done);
            
            passed = (c == expected_result);
            case (op_in)
                3'b000:
            $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b   | PASSED: %b\t| SOMA",
             a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done, passed);
                3'b001:
                $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b   | PASSED: %b\t| SUB",
             a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done, passed);
                3'b011:
                $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b   | PASSED: %b\t| DIV",
             a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done, passed);
                3'b100:
                $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b   | PASSED: %b\t| EQ",
             a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done, passed);
                3'b101:
                $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b   | PASSED: %b\t| SLT",
             a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done, passed);
                default:
                $display("%h | %h | %h |    %b     |     %b      |     %b      |      %b      |     %b     |   %b  |  %b   | PASSED: %b\t| MULT",
             a, b, c, f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact, busy, done, passed); 
            endcase
            
        end
    endtask

    initial begin

        $display("    a    |     b    |    c     | f_inv_op | f_div_zero | f_overflow | f_underflow | f_inexact | busy | done | PASSED\t| OP");
        
        //SOMA E SUBTRAÇÂO
        run_test(32'h00000000,32'h80000000,32'h00000000,3'b000);
        
        // 12 +26
        run_test(32'b01000001010000000000000000000000,
        32'b11000001110100000000000000000000,
        32'b11000001011000000000000000000000,3'b00);
        
        //12 - -26 =38 ERRO
        run_test(
        32'b01000001010000000000000000000000,
        32'b11000001110100000000000000000000,
        32'b01000010000110000000000000000000,3'b01);

        // -6.0 - (-1.0) = -5.0 
        run_test(32'hc0c00000, 32'hbf800000, 32'hc0a00000, 3'b01);

        run_test(
            32'b01000010111110000000000000000000,
            32'b11000001010000000000000000000000,
            32'b01000010111000000000000000000000, 3'b00);
        
        // -3.0 - (-5.0) = 2.0
        run_test( 32'hc0400000,
                  32'hc0a00000,
                  32'h40000000, 3'b01);
        $display("COMPARADOR");
        // COMPARADOR

        run_test(
            32'h0000_000A,
            32'h0000_000B,
            32'h3F800000, 3'b101
                );

        run_test(
            32'h0000_000A,
            32'h0000_000B,
            32'h00000000, 3'b100
                );

        run_test(
            32'h0000_000A,
            32'h0000_000B,
            32'h00000000, 3'b100
        );     

         run_test(
            32'h0000_000A,
            32'h0000_000B,
            32'h3F800000, 3'b101
        );    
        // a= -13.6 < b -13.1                
        run_test(
            32'hC159999A,
            32'hC151999A,
            32'h00000000, 3'b101
        );
        $display("DIVISAO");

        run_test(
            32'h40A00000, 
            32'h00000000,
            32'h7F800000, 3'b011
        );
        
        // 1.0 / 8.0 = 0.125
        run_test( 32'h3F800000, 32'h41000000, 32'h3E000000,  3'b011);

        // 100.0 / 0.5 = 200.0
        run_test( 32'h42C80000, 32'h3F000000, 32'h43480000,  3'b011);
        // 2^120 / 2^118 = 4.0 (Valores Grandes Nominais)
        run_test(32'h7B800000, 32'h7A800000, 32'h40800000,  3'b011);

        // 2^120 / 2^-10 = +Inf (Overflow Aritmético)
        run_test(32'h7B800000, 32'h3A800000, 32'h7F800000,  3'b011);

        // 2^-120 / 2^10 = 2^-130 (Underflow Gradual / Subnormal)
        run_test(32'h03800000, 32'h44800000, 32'h00080000,  3'b011);

        $finish();
    end

endmodule