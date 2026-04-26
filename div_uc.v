module div_uc (
    input clk,
    input rst,
    input start,
    input div_done,
    input msb_is_zero,
    input div_zero,

    output reg start_div,
    output reg busy,
    output reg load_norm_shift,
    output reg shift_left_norm,
    output reg done
);
    
    localparam IDLE = 3'd0,
                DIVISION = 3'd1,
                FINAL = 3'd2;
    reg [2:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        next_state = state;
        start_div = 1'b0;
        busy = 1'b1; 
        load_norm_shift = 1'b0;
        shift_left_norm = 1'b0;
        done = 1'b0;
        case (state)
            IDLE: begin
                if (start) begin
                    if(div_zero) begin
                        next_state = FINAL;
                    end else begin
                        start_div = 1'b1;
                        next_state = DIVISION;
                    end
                end
            end
            DIVISION: begin
                if(div_done) begin
                    load_norm_shift = 1'b1;
                    next_state = FINAL;
                end

            end
            FINAL: begin
                    if (msb_is_zero) begin
                        shift_left_norm = 1'b1;
                    end
                    done = 1'b1;
                    busy = 1'b0;
                    next_state = IDLE;
                    if(!start)begin
                        next_state = IDLE;
                    end else begin
                        next_state = FINAL;
                    end
                end
            default: next_state = IDLE;
        endcase
    end

endmodule