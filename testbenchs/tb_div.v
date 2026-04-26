`timescale 1ns / 1ps

module tb_div();

    // Sinais de entrada
    reg clk;
    reg rst;
    reg start;
    reg [31:0] a;
    reg [31:0] b;

    // Sinais de saída
    wire [31:0] result;
    wire busy;
    wire done;
    wire f_inv_op;
    wire f_div_zero;
    wire f_overflow;
    wire f_underflow;
    wire f_inexact;

    // Instanciação do módulo Top-Level da Divisão
    tp_div uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .busy(busy),
        .done(done),
        .f_inv_op(f_inv_op),
        .f_div_zero(f_div_zero),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .f_inexact(f_inexact)
    );

    // Geração do Clock (Período de 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task para automatizar os testes
    task run_test;
        input [639:0] test_name; // Suporta strings de até 80 caracteres
        input [31:0] in_a;
        input [31:0] in_b;
        input [31:0] expected_result;
        input expected_inv_op;
        input expected_div_zero;
        begin
            $display("---------------------------------------------------");
            // O %0s ignora os espaços vazios da string
            $display("Iniciando Teste: %0s", test_name); 
            
            // Injeta os valores
            a = in_a;
            b = in_b;
            
            // Pulso de Start
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // Espera pelo sinal 'done' em VERILOG CLASSICO (Sem SystemVerilog)
            begin : wait_timeout_block
                fork
                    begin
                        wait(done == 1'b1);
                        disable wait_timeout_block; // Sai do bloco se o done chegar
                    end
                    begin
                        #10000; // Timeout de segurança
                        $display("[ERRO FATAL] Timeout! O sinal 'done' nunca foi a 1.");
                        $finish; // Termina a simulação
                    end
                join
            end

            // Aguarda a borda de subida para ler os dados de saída estáveis
            @(posedge clk);

            // Verificação do Resultado
            if (result !== expected_result) begin
                $display("[FALHA] Resultado incorreto. Obtido: %h | Esperado: %h", result, expected_result);
            end else begin
                $display("[PASSOU] Resultado correto: %h", result);
            end

            // Verificação das Flags Críticas
            if (f_inv_op !== expected_inv_op) begin
                $display("[FALHA] Flag f_inv_op incorreta. Obtido: %b | Esperado: %b", f_inv_op, expected_inv_op);
            end
            if (f_div_zero !== expected_div_zero) begin
                $display("[FALHA] Flag f_div_zero incorreta. Obtido: %b | Esperado: %b", f_div_zero, expected_div_zero);
            end
            
            // Pequena pausa entre testes
            #20;
        end
    endtask

    // Sequência de Testes
    initial begin
        // Inicialização
        start = 0;
        a = 0;
        b = 0;
        
        // Reset inicial
        rst = 1;
        #20;
        rst = 0;
        #20;

        $display("===================================================");
        $display("       INICIANDO BATERIA DE TESTES: DIVISAO        ");
        $display("===================================================");

        // 1. Testes Nominais
        // 3.0 / 2.0 = 1.5
        run_test("3.0 / 2.0 = 1.5", 32'h40400000, 32'h40000000, 32'h3FC00000, 1'b0, 1'b0);
        
        // 5.0 / -2.0 = -2.5
        run_test("5.0 / -2.0 = -2.5", 32'h40A00000, 32'hC0000000, 32'hC0200000, 1'b0, 1'b0);
        
        // 1.0 / 4.0 = 0.25
        run_test("1.0 / 4.0 = 0.25", 32'h3F800000, 32'h40800000, 32'h3E800000, 1'b0, 1'b0);

        // 2. Divisão por Zero
        // 5.0 / 0.0 = +Infinito
        run_test("5.0 / 0.0 = +Inf (DivZero)", 32'h40A00000, 32'h00000000, 32'h7F800000, 1'b0, 1'b1);
        
        // -3.0 / 0.0 = -Infinito
        run_test("-3.0 / 0.0 = -Inf (DivZero)", 32'hC0400000, 32'h00000000, 32'hFF800000, 1'b0, 1'b1);

        // 3. Operações Inválidas (NaN)
        // 0.0 / 0.0 = NaN
        run_test("0.0 / 0.0 = NaN (InvOp)", 32'h00000000, 32'h00000000, 32'h7FC00000, 1'b1, 1'b0);
        
        // +Inf / +Inf = NaN
        run_test("+Inf / +Inf = NaN (InvOp)", 32'h7F800000, 32'h7F800000, 32'h7FC00000, 1'b1, 1'b0);
        
        // NaN / 2.0 = NaN
        run_test("NaN / 2.0 = NaN (InvOp)", 32'h7FC00000, 32'h40000000, 32'h7FC00000, 1'b1, 1'b0);

        // 7.0 / 2.0 = 3.5
        run_test("7.0 / 2.0 = 3.5", 32'h40E00000, 32'h40000000, 32'h40600000, 1'b0, 1'b0);

        // -12.0 / 3.0 = -4.0
        run_test("-12.0 / 3.0 = -4.0", 32'hC1400000, 32'h40400000, 32'hC0800000, 1'b0, 1'b0);

        // 0.5 / 0.25 = 2.0
        run_test("0.5 / 0.25 = 2.0", 32'h3F000000, 32'h3E800000, 32'h40000000, 1'b0, 1'b0);

        // 1.0 / 8.0 = 0.125
        run_test("1.0 / 8.0 = 0.125", 32'h3F800000, 32'h41000000, 32'h3E000000, 1'b0, 1'b0);

        // 100.0 / 0.5 = 200.0
        run_test("100.0 / 0.5 = 200.0", 32'h42C80000, 32'h3F000000, 32'h43480000, 1'b0, 1'b0);
        // 2^120 / 2^118 = 4.0 (Valores Grandes Nominais)
        run_test("2^120 / 2^118 = 4.0", 32'h7B800000, 32'h7A800000, 32'h40800000, 1'b0, 1'b0);

        // 2^120 / 2^-10 = +Inf (Overflow Aritmético)
        run_test("2^120 / 2^-10 = +Inf", 32'h7B800000, 32'h3A800000, 32'h7F800000, 1'b0, 1'b0);

        // 2^-120 / 2^10 = 2^-130 (Underflow Gradual / Subnormal)
        run_test("2^-120 / 2^10 = 2^-130", 32'h03800000, 32'h44800000, 32'h00080000, 1'b0, 1'b0);

        // 2^-148 / 2.0 = 2^-149 (Divisão de Subnormal resultando no menor Subnormal possível)
        run_test("2^-148 / 2.0 = 2^-149", 32'h00000002, 32'h40000000, 32'h00000001, 1'b0, 1'b0);

        // 2^-128 / 2^-130 = 4.0 (Subnormal dividido por Subnormal gerando número Normal)
        run_test("2^-128 / 2^-130 = 4.0", 32'h00200000, 32'h00080000, 32'h40800000, 1'b0, 1'b0);
        $display("===================================================");
        $display("               TESTES FINALIZADOS                  ");
        $display("===================================================");
        $finish; 
    end

endmodule