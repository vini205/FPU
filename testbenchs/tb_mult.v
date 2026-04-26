`timescale 1ns / 1ps

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
        .f_inv_op(invalid), 
        .f_overflow(overflow), 
        .f_underflow(underflow), 
        .f_inexact(inexact),
        .over(done)
    );

    // ========================================================================
    // TASK DE TESTE AUTOMATIZADO
    // ========================================================================
    task run_test;
        input [639:0] test_name;
        input [31:0] in_a;
        input [31:0] in_b;
        input [31:0] exp_res;
        input exp_inv;
        input exp_ovf;
        input exp_unf;
        input exp_inex;
        reg pass_res, pass_flags;
        begin
            a = in_a;
            b = in_b;
            
            // Ciclo de Reset Assíncrono
            #1; reset = 1;
            #10; reset = 0;

            // Timeout de segurança
            begin : wait_timeout_block
                fork
                    begin
                        wait(done == 1'b1);
                        disable wait_timeout_block;
                    end
                    begin
                        #10000;
                        $display("[ERRO FATAL] Timeout no teste: %0s", test_name);
                        disable wait_timeout_block;
                    end
                join
            end

            // Avaliação lógica utilizando '===' para detetar X e Z
            pass_res = (result === exp_res);
            pass_flags = (invalid === exp_inv) && (overflow === exp_ovf) && 
                         (underflow === exp_unf) && (inexact === exp_inex);

            if (pass_res && pass_flags) begin
                $display("[PASSOU] %0s", test_name);
            end else begin
                $display("---------------------------------------------------");
                $display("[FALHA] %0s", test_name);
                if (!pass_res)
                    $display("   > Resultado Incorreto: Obtido %h | Esperado %h", result, exp_res);
                if (!pass_flags) begin
                    $display("   > Flags Incorretas (Inv, Ov, Un, Inex):");
                    $display("       Obtidas:  %b %b %b %b", invalid, overflow, underflow, inexact);
                    $display("       Esperadas: %b %b %b %b", exp_inv, exp_ovf, exp_unf, exp_inex);
                end
                $display("---------------------------------------------------");
            end
        end
    endtask

    // ========================================================================
    // VETORES DE TESTE
    // ========================================================================
    initial begin
        $dumpfile("mult_tb.vcd");
        $dumpvars(0, mult_tb);

        $display("===================================================");
        $display("   INICIANDO BATERIA DE TESTES: MULTIPLICACAO      ");
        $display("===================================================");
        
        // 1. Operação Inválida (0.0 * +Inf = qNaN)
        // O qNaN clássico tem o expoente FF e o MSB da fração a 1 (7FC00000)
        run_test("0.0 * +Infinito", 32'h0000_0000, 32'h7F80_0000, 32'h7FC0_0000, 1'b1, 1'b0, 1'b0, 1'b0);
        
        // 2. Overflow (Max_Float * 2.0 = +Infinito)
        // Transbordamento obriga o Overflow e Inexact a estarem a 1
        run_test("Max Float * 2.0 (Overflow)", 32'h7F7F_FFFF, 32'h4000_0000, 32'h7F80_0000, 1'b0, 1'b1, 1'b0, 1'b1);
        
        // 3. Infinito * Constante
        run_test("+Infinito * 5.0", 32'h7F80_0000, 32'h40A0_0000, 32'h7F80_0000, 1'b0, 1'b0, 1'b0, 1'b0);
        
        // 4. Underflow Gradual exato (2^-126 * 0.5 = 2^-127)
        // O valor 0.5 reduz o expoente em 1, gerando o subnormal 0040_0000. 
        // Segundo IEEE 754, se não houver perda de bits, o 'underflow' pode não subir (assumimos 0 aqui).
        run_test("Underflow Gradual Exato", 32'h0080_0000, 32'h3F00_0000, 32'h0040_0000, 1'b0, 1'b0, 1'b0, 1'b0);
        
        // 5. Resultado Inexato
        // Ocorre perda do LSB. A flag 'inexact' deve subir.
        run_test("Resultado Inexato (Arredondamento)", 32'h4000_0001, 32'h3F80_0001, 32'h4000_0001, 1'b0, 1'b0, 1'b0, 1'b1);
        
        // 6. Infinito Negativo * -1.0 = +Infinito
        run_test("-Infinito * -1.0", 32'hFF80_0000, 32'hBF80_0000, 32'h7F80_0000, 1'b0, 1'b0, 1'b0, 1'b0);

        

        $display("===================================================");
        $display("               TESTES FINALIZADOS                  ");
        $display("===================================================");
        $finish;
    end
endmodule