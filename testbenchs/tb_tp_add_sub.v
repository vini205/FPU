`timescale 1ns / 1ps

module tb_tp_add_sub;

    // =========================================================================
    // DECLARAÇÃO DE SINAIS
    // =========================================================================
    reg clk;
    reg reset;
    reg start;
    reg is_sub;
    reg [31:0] a;
    reg [31:0] b;

    wire [31:0] result;
    wire f_div_zero;
    wire f_overflow;
    wire f_underflow;
    wire f_inexact;
    wire f_inv_op;
    wire over;

    // =========================================================================
    // INSTANCIAÇÃO DO DEVICE UNDER TEST (DUT)
    // =========================================================================
    tp_add_sub dut (
        .clk(clk),
        .reset(reset),
        .start(start),         
        .is_sub(is_sub),       
        .a(a),
        .b(b),
        .result(result),
        .f_div_zero(f_div_zero),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .f_inexact(f_inexact),
        .f_inv_op(f_inv_op),
        .over(over)
    );

    // =========================================================================
    // GERAÇÃO DE CLOCK E DUMP PARA FORMAS DE ONDA
    // =========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Período de 10ns (100 MHz)
    end

    initial begin
        $dumpfile("wave_tp_add_sub.vcd");
        $dumpvars(0, tb_tp_add_sub);
    end

    // =========================================================================
    // TASK DE AUTOMAÇÃO E VERIFICAÇÃO (SELF-CHECKING)
    // =========================================================================
    task run_test;
        input [8*30:1] test_name; 
        input [31:0] val_a;
        input [31:0] val_b;
        input op_sub;
        input [31:0] expected_result;
        input expected_inv_op;
        
        reg result_match;
        reg flags_match;
        begin
            $display("------------------------------------------------------");
            $display("-> Teste: %s", test_name);
            
            // Atribuição de Operandos
            a = val_a;
            b = val_b;
            is_sub = op_sub;
            
            // Engatilha a FSM rigorosamente fora da borda de subida
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0; 

            // Aguarda assincronamente a conclusão da operação pela UC
            wait(over == 1'b1);
            @(posedge clk);
            
            // Lógica de Autoverificação
            // Se o esperado for 32'hFFFFFFFF, o resultado numérico é um "Don't Care" (ignorado).
            result_match = (expected_result === 32'hFFFFFFFF) ? 1'b1 : (result === expected_result);
            flags_match  = (f_inv_op === expected_inv_op);
            
            // Relatório Analítico
            $display("Operacao: %h %s %h", val_a, op_sub ? "-" : "+", val_b);
            $display("Obtido  : %h | Flags: INV=%b OVF=%b UNF=%b INX=%b", 
                      result, f_inv_op, f_overflow, f_underflow, f_inexact);
            
            // Veredito Computacional
            if (result_match && flags_match) begin
                $display("Status  : [APROVADO]");
            end else begin
                $display("Status  : [ERRADO]");
                if (!result_match) 
                    $display("          -> Inconsistencia no Resultado. Esperado: %h", expected_result);
                if (!flags_match)  
                    $display("          -> Inconsistencia na Flag INV_OP. Esperado: %b", expected_inv_op);
            end
            $display("------------------------------------------------------\n");
            
            // Margem temporal para a transição natural da FSM para IDLE
            #20;
        end
    endtask

    // =========================================================================
    // VETORES DE TESTE PRINCIPAIS (COM GABARITOS)
    // =========================================================================
    initial begin
        // Estado Inicial do Sistema
        reset = 1;
        start = 0;
        is_sub = 0;
        a = 32'd0;
        b = 32'd0;

        // Sequência de Reset Estrito
        #20;
        reset = 0;
        #20;

        $display("\n=== INICIO DA BATERIA DE TESTES AUTOMATIZADA IEEE 754 ===\n");

        // 1. Operações Nominais (Precisão Estrita)
        // 1.5 + 2.5 = 4.0
        run_test("Adicao Nominal (1.5 + 2.5)", 32'h3fc00000, 32'h40200000, 1'b0, 32'h40800000, 1'b0);
        
        // 5.0 - 2.0 = 3.0
        run_test("Subtracao Nominal (5.0 - 2.0)", 32'h40a00000, 32'h40000000, 1'b1, 32'h40400000, 1'b0);
        
        // 5.0 - 5.0 = 0.0 (Teste de Aniquilação Total)
        run_test("Aniquilacao na Subtracao", 32'h40a00000, 32'h40a00000, 1'b1, 32'h00000000, 1'b0);

        // 2. Comportamento com Subnormais (Underflow Gradual)
        // O bit menos significativo do subnormal (2^-149) somado a si mesmo = 2^-148.
        run_test("Soma de Subnormais", 32'h00000001, 32'h00000001, 1'b0, 32'h00000002, 1'b0);

        // 3. Exceções e Indeterminações Arquiteturais
        // Indeterminação: (+Inf) - (+Inf) -> Resultado indefinido (Ignorado), mas a flag f_inv_op DEVE ser 1.
        run_test("Conflito Infinito (Inf - Inf)", 32'h7f800000, 32'h7f800000, 1'b1, 32'hFFFFFFFF, 1'b1);

        // Signaling NaN: Bit 22 = 0. Deve abortar a operação e levantar f_inv_op.
        run_test("Injecao de sNaN", 32'h7f800001, 32'h40000000, 1'b0, 32'hFFFFFFFF, 1'b1);

        // Quiet NaN: Bit 22 = 1. Deve apenas se propagar. f_inv_op DEVE ser 0.
        run_test("Injecao de qNaN", 32'h7fc00000, 32'h40000000, 1'b0, 32'hFFFFFFFF, 1'b0);

        // 4. Testes de Cancelamento Catastrófico
        // A subtração de números muito próximos causa deslocamentos severos à esquerda no normalizador.
        // A = 1.000000119 (3f800001) | B = 1.0 (3f800000) -> Diff = 2^-23 (34000000)
        run_test("Cancelamento na Subtracao", 32'h3f800001, 32'h3f800000, 1'b1, 32'h34000000, 1'b0);

        // 3.0 + 4.0 = 7.0
        run_test("Adicao (+A + +B)", 32'h40400000, 32'h40800000, 1'b0, 32'h40e00000, 1'b0);

        // 10.0 + (-4.0) = 6.0
        run_test("Adicao (+A + -B)", 32'h41200000, 32'hc0800000, 1'b0, 32'h40c00000, 1'b0);

        // -5.0 + 2.0 = -3.0
        run_test("Adicao (-A + +B)", 32'hc0a00000, 32'h40000000, 1'b0, 32'hc0400000, 1'b0);

        // -2.0 + (-3.0) = -5.0
        run_test("Adicao (-A + -B)", 32'hc0000000, 32'hc0400000, 1'b0, 32'hc0a00000, 1'b0);

        // 2.0 + (-6.0) = -4.0
        run_test("Adicao (+A + -B inv)", 32'h40000000, 32'hc0c00000, 1'b0, 32'hc0800000, 1'b0);

        // 10.0 - 3.0 = 7.0
        run_test("Subtracao (+A - +B)", 32'h41200000, 32'h40400000, 1'b1, 32'h40e00000, 1'b0);

        // 4.0 - (-2.0) = 6.0
        run_test("Subtracao (+A - -B)", 32'h40800000, 32'hc0000000, 1'b1, 32'h40c00000, 1'b0);

        // -1.0 - 4.0 = -5.0
        run_test("Subtracao (-A - +B)", 32'hbf800000, 32'h40800000, 1'b1, 32'hc0a00000, 1'b0);

        // -6.0 - (-1.0) = -5.0
        run_test("Subtracao (-A - -B)", 32'hc0c00000, 32'hbf800000, 1'b1, 32'hc0a00000, 1'b0);

        // -3.0 - (-5.0) = 2.0
        run_test("Subtracao (-A - -B inv)", 32'hc0400000, 32'hc0a00000, 1'b1, 32'h40000000, 1'b0);

        $display("=== SIMULACAO CONCLUIDA ===\n");
        $finish;
    end

endmodule