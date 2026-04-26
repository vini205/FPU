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


module df #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         load_m,     
    input  wire [N-1:0] divisor,
    input  wire         load_aq,    
    input  wire [N-1:0] dividend,
    input  wire         shift_aq,   
    input  wire         update_a,   
    
    output wire [N-1:0] M,
    output wire [N-1:0] A,
    output wire [N-1:0] Q,
    output wire         negative    
);

    reg [N:0] reg_M;
    reg [N:0] reg_A;
    reg [N-1:0] reg_Q; 

    wire [N:0] alu_result;
    wire       alu_neg;

    add_sub #(.N(N+1)) alu (
        .a        (reg_A),
        .b        (reg_M),
        .sub      (1'b1),
        .result   (alu_result),
        .cout     (),
        .overflow (),
        .negative (alu_neg) 
    );

    assign negative = alu_neg;
    

    assign M = reg_M[N-1:0];
    assign A = reg_A[N-1:0]; 
    assign Q = reg_Q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_M <= {(N+1){1'b0}};
            reg_A <= {(N+1){1'b0}};
            reg_Q <= {N{1'b0}};
        end else begin
            
            if (load_m)
                reg_M <= {1'b0, divisor};

            if (load_aq) begin
                reg_A <= {2'b00, dividend[N-1:1]};
                reg_Q <= {dividend[0], {(N-1){1'b0}}};
            end

            if (shift_aq) begin
                reg_A <= {reg_A[N-1:0], reg_Q[N-1]};
                reg_Q <= {reg_Q[N-2:0], 1'b0};
            end

            if (update_a) begin
                if (!alu_neg) begin
                    reg_A    <= alu_result;
                    reg_Q[0] <= 1'b1;
                end else begin
                    reg_Q[0] <= 1'b0;
                end
            end
            
        end
    end
endmodule

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

