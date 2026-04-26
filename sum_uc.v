module sum_uc (
    input wire clk,
    input wire rst,
    input wire start,
    input wire count_over,
    input wire is_normalized,
    input wire exp_is_zero,
    input wire cout_sum,

    output reg shift_right_norm,
    output reg shift_left_norm,
    output reg load_sum,
    output reg load_shift,
    output reg shift_mant,
    output reg load_norm_shift,
    output reg done
);

localparam  IDLE = 3'd0,
            LOAD = 3'd1,
            SHIFT = 3'd2,
            ADD = 3'd3,
            LOAD_NORMALIZED = 4'd4,
            NORMALIZE = 3'd5,
            ROUND = 3'd6;
            
reg [2:0] state; 
reg [2:0] next_state;

always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

always @(*) begin
    next_state = state;
    load_shift = 1'b0;
    shift_mant = 1'b0;
    shift_left_norm = 1'b0;
    shift_right_norm  = 1'b0;
    load_sum = 1'b0;
    load_norm_shift = 1'b0;
    done = 1'b0;
    case (state)
        IDLE: begin
            if (start) next_state = LOAD;
        end
        LOAD: begin
            next_state = SHIFT;
            load_shift = 1'b1;

        end
        SHIFT: begin
            if(count_over) begin
                next_state = ADD;
            end else begin
                shift_mant = 1'b1;
            end
        end
        ADD: begin// Apenas demora 1 ciclo de clk
            load_sum = 1'b1;
            next_state = LOAD_NORMALIZED;
        end
        LOAD_NORMALIZED:begin
            //carrega o dado no registrador, 1 clk
            load_norm_shift = 1'b1;
            next_state = NORMALIZE;
        end
        NORMALIZE: begin
            load_norm_shift =1'b0;
            if (cout_sum) begin
                shift_right_norm = 1'b1;
                next_state = ROUND;
            end else if (!(is_normalized ||exp_is_zero)) begin
                shift_left_norm = 1'b1;
            end else begin
                next_state = ROUND;
            end
        end
        ROUND:begin
            done = 1'b1;
            if (!start) begin
                next_state = IDLE;
            end
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end



endmodule