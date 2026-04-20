module sum_uc (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [23:0] mant_sum,
    input wire [22:0] mant_final,
    input wire count_over,
    input wire sum;
    output wire load_sum;
    output wire load_shift;
    output wire shift_mant,
    output wire done
);

localparam  IDLE = 3'd0,
            LOAD = 3'd1,
            SHIFT = 3'd2,
            ADD = 3'd3,
            NORMALIZE = 3'd4
            
reg state; 
reg next_state;

always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

always @(posedge clk or next_state) begin
    next_state = state;
    load_shift = 1'b0;
    shift_mant = 1'b0;
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
            load_sum = 1;
            next_state = NORMALIZE;
        end
        NORMALIZE: begin
            
        end
        default: 
    endcase
end



endmodule