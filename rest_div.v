module add_sub #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire         sub,        // 0: soma (A+B), 1: subtração (A-B)
    output wire [N-1:0] result,
    output wire         cout,       // carry out
    output wire         overflow,   // overflow em complemento de 2
    output wire         negative    // result[N-1]: resultado negativo
);
    wire [N-1:0] b_op;
    wire         cin;
    wire [N:0]   sum_ext;

    assign b_op    = sub ? ~b : b;
    assign cin     = sub;
    assign sum_ext = {1'b0, a} + {1'b0, b_op} + cin;

    assign result   = sum_ext[N-1:0];
    assign cout     = sum_ext[N];
    assign overflow = (a[N-1] == b_op[N-1]) && (result[N-1] != a[N-1]);
    assign negative = result[N-1];
endmodule


// -------------------------------------------------------------
// 2. Registrador de N bits
// -------------------------------------------------------------
module register #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         load,
    input  wire [N-1:0] data_in,
    output reg  [N-1:0] data_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= {N{1'b0}};
        else if (load)
            data_out <= data_in;
    end
endmodule


// -------------------------------------------------------------
// 3. Registrador de deslocamento para a esquerda
// -------------------------------------------------------------
module shift_left #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         load,
    input  wire         shift,      // desloca para a esquerda
    input  wire [N-1:0] data_in,
    output reg  [N-1:0] data_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= {N{1'b0}};
        else if (load)
            data_out <= data_in;
        else if (shift)
            data_out <= {data_out[N-2:0], 1'b0};
    end
endmodule


// -------------------------------------------------------------
// 4. Fluxo de dados (df)
// -------------------------------------------------------------
//
// Organização interna:
//   - M : registrador do divisor (N bits)
//   - {A, Q} : registrador duplo de 2N bits tratado como unidade
//              A = N MSBs (resto parcial)
//              Q = N LSBs (quociente em formação)
//
// Operação passo a passo (coordenado pela UC):
//   1. load_m=1  → M  ← divisor
//      load_aq=1 → A  ← 0 , Q ← dividend
//   2. shift_aq=1 → {A,Q} deslocado 1 bit à esquerda
//   3. Calcula A_sub = A - M  (add_sub com sub=1)
//   4. update_a=1 →
//         se A_sub >= 0 (negative=0): A ← A_sub, Q[0] ← 1  (bit quociente = 1)
//         se A_sub <  0 (negative=1): A não muda,  Q[0] ← 0  (restaura; bit quociente = 0)
//
// -------------------------------------------------------------
module df #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         load_m,     // M <- divisor
    input  wire [N-1:0] divisor,
    input  wire         load_aq,    // A <- 0, Q <- dividend
    input  wire [N-1:0] dividend,
    // Controles da UC
    input  wire         shift_aq,   // desloca {A,Q} 1 bit à esquerda
    input  wire         update_a,   // escreve resultado da ULA em A, seta Q[0]
    // Saídas
    output wire [N-1:0] M,
    output wire [N-1:0] A,
    output wire [N-1:0] Q,
    output wire         negative    // (A-M) < 0 → UC observa
);

    // ---- registradores internos ----
    reg [N-1:0] reg_M;
    reg [N-1:0] reg_A;
    reg [N-1:0] reg_Q;

    // ---- ULA: A - M ----
    wire [N-1:0] alu_result;
    wire         alu_neg;

    add_sub #(.N(N)) alu (
        .a        (reg_A),
        .b        (reg_M),
        .sub      (1'b1),
        .result   (alu_result),
        .cout     (),
        .overflow (),
        .negative (alu_neg)
    );

    assign negative = alu_neg;
    assign M = reg_M;
    assign A = reg_A;
    assign Q = reg_Q;

    // ---- lógica sequencial ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_M <= {N{1'b0}};
            reg_A <= {N{1'b0}};
            reg_Q <= {N{1'b0}};
        end else begin
            // Carrega M
            if (load_m)
                reg_M <= divisor;

            // Carrega A=0 e Q=dividend
            if (load_aq) begin
                reg_A <= {N{1'b0}};
                reg_Q <= dividend;
            end

            // Desloca {A,Q} 1 bit à esquerda como unidade
            if (shift_aq) begin
                reg_A <= {reg_A[N-2:0], reg_Q[N-1]};
                reg_Q <= {reg_Q[N-2:0], 1'b0};
            end

            // Atualiza A com resultado da ULA e define bit LSB de Q
            if (update_a) begin
                if (!alu_neg) begin
                    // A - M >= 0: aceita subtração, quociente bit = 1
                    reg_A    <= alu_result;
                    reg_Q[0] <= 1'b1;
                end else begin
                    // A - M < 0: restaura A (não muda), quociente bit = 0
                    reg_Q[0] <= 1'b0;
                end
            end
        end
    end
endmodule


// -------------------------------------------------------------
// 5. Unidade de Controle (uc)
//
// FSM com os seguintes estados:
//   IDLE    → aguarda start
//   LOAD    → carrega M, A, Q (1 ciclo)
//   SHIFT   → desloca {A,Q} à esquerda (1 ciclo)
//   SUB     → UC observa negative; dispara update_a (1 ciclo)
//   CHECK   → decrementa contador; se count=0 vai para DONE
//   DONE    → sinaliza done=1
//
// Repete SHIFT→SUB→CHECK por N iterações.
// -------------------------------------------------------------
module uc #(
    parameter N = 24
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  load_m,
    output reg  load_aq,
    output reg  shift_aq,
    output reg  update_a,
    output wire done
);
    // Estados
    localparam IDLE  = 3'd0,
               LOAD  = 3'd1,
               SHIFT = 3'd2,
               SUB   = 3'd3,
               CHECK = 3'd4,
               DONE  = 3'd5;

    reg [2:0]               state, next_state;
    reg [$clog2(N+1)-1:0]   count;

    assign done = (state == DONE);

    // Registro de estado
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
        end else begin
            state <= next_state;
            if (state == LOAD)
                count <= N;
            else if (state == CHECK && count != 0)
                count <= count - 1;
        end
    end

    // Lógica de próximo estado
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (start)        next_state = LOAD;
            LOAD:                    next_state = SHIFT;
            SHIFT:                   next_state = SUB;
            SUB:                     next_state = CHECK;
            CHECK: if (count == 1)   next_state = DONE;
                   else              next_state = SHIFT;
            DONE:  if (!start)       next_state = IDLE;
            default:                 next_state = IDLE;
        endcase
    end

    // Saídas (Moore)
    always @(*) begin
        load_m   = 1'b0;
        load_aq  = 1'b0;
        shift_aq = 1'b0;
        update_a = 1'b0;
        case (state)
            LOAD:  begin load_m = 1'b1; load_aq = 1'b1; end
            SHIFT: shift_aq = 1'b1;
            SUB:   update_a = 1'b1;
            default: ;
        endcase
    end
endmodule


// -------------------------------------------------------------
// 6. Restoring Division – módulo top
// -------------------------------------------------------------
module restoring_div #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [N-1:0] dividend,
    input  wire [N-1:0] divisor,
    output wire [N-1:0] quotient,
    output wire [N-1:0] remainder,
    output wire         done
);
    wire load_m, load_aq, shift_aq, update_a;
    wire negative;

    uc #(.N(N)) control (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .load_m   (load_m),
        .load_aq  (load_aq),
        .shift_aq (shift_aq),
        .update_a (update_a),
        .done     (done)
    );

    df #(.N(N)) datapath (
        .clk      (clk),
        .rst      (rst),
        .load_m   (load_m),
        .divisor  (divisor),
        .load_aq  (load_aq),
        .dividend (dividend),
        .shift_aq (shift_aq),
        .update_a (update_a),
        .M        (),
        .A        (remainder),
        .Q        (quotient),
        .negative (negative)
    );
endmodule

