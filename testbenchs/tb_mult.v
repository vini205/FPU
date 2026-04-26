module mult_tb;

    reg [31:0] a, b;
    wire [31:0] result;
    reg clk;
    wire invalid, overflow, underflow, inexact;
    wire done;
    reg reset;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

        mult dut(
        .clk(clk),
        .reset(reset),
        .a(a), .b(b),
        .c(result),
        .f_inv_op(invalid), .f_overflow(overflow) , .f_underflow(underflow) , .f_inexact(inexact),
        .over(done)
    );



    initial begin
        $dumpfile("mult_tb.vcd");
        $dumpvars(0, mult_tb);

        $display("Iniciando Testes de Multiplicação IEEE 754...");
        
        
        
        // --- CASO 1: Operação Inválida (0 * Inf) ---
        a = 32'h0000_0000; // 0.0
        b = 32'h7F80_0000; // +Infinito
        #1; reset =1;
        #10
        reset=0;
        wait(done); $display("A: %h | B: %h | Res: %h | Inv: %b | Ov: %b | Un: %b | Inex: %b", 
                  a, b, result, invalid, overflow, underflow, inexact);
       // --- CASO #12: Overflow (Max_Float * 2.0) ---
        a = 32'h7F7F_FFFF; // Maior número normal
        b = 32'h4000_0000; // 2.0
        #1; reset =1;
        #10
        reset=0;
        wait(done); $display("A: %h | B: %h | Res: %h | Inv: %b | Ov: %b | Un: %b | Inex: %b", 
                  a, b, result, invalid, overflow, underflow, inexact);
        

        // --- CASO 3: Infinito * Constante (Sem Flags) ---
        a = 32'h7F80_0000; // +Infinito
        #1; reset =1;
        #10
        reset=0;b = 32'h40A0_0000; // 5.0
        wait(done); $display("A: %h | B: %h | Res: %h | Inv: %b | Ov: %b | Un: %b | Inex: %b", 
                  a, b, result, invalid, overflow, underflow, inexact);
        
        // --- CASO 4: Underflow Gradual (Gera Subnormal) ---
        a = 32'h0080_0000; // Menor Normal (2^-126)
        b = 32'h3F00_0000; // 0.5
        #1; reset =1;   
        #10
        reset=0;
        wait(done); $display("A: %h | B: %h | Res: %h | Inv: %b | Ov: %b | Un: %b | Inex: %b", 
                  a, b, result, invalid, overflow, underflow, inexact); // Resultado deve ter expoente 00h e ser Subnormal
        
        // --- CASO 5: Resultado Inexato (Precisão perdida) ---
        a = 32'h4000_0001; // Próximo a 2.0
        b = 32'h3F80_0001; // Pr'óximo a 1.0
        
        #1; reset =1;
        #10
        reset=0;
        wait(done); $display("A: %h | B: %h | Res: %h | Inv: %b | Ov: %b | Un: %b | Inex: %b", 
                  a, b, result, invalid, overflow, underflow, inexact);


        // --- CASO 5: Resultado Inexato (Precisão perdida) ---
        a = 32'hFF80_0000; // Próximo a 2.0
        b = 32'hBF80_0000; // Pr'óximo a 1.0
        
        #1; reset =1;
        #10
        reset=0;
        wait(done); $display("A: %h | B: %h | Res: %h | Inv: %b | Ov: %b | Un: %b | Inex: %b", 
                  a, b, result, invalid, overflow, underflow, inexact); 
       
        $finish;
    end
endmodule