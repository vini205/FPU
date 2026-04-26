module div_uc (
    input clk,
    input rst,
    input start,
    input div_done,
    input msb_is_zero,

    output reg start_div,
    output reg busy,
    output reg load_norm_shift,
    output reg shift_left_norm,
    output reg done
);
    
    localparam IDLE = 3'd0,
                DIVISION = 3'd1,
                NORMALIZE = 3'd2,
                ROUND = 3'd3;

    reg [2:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start) begin
                    if(div_zero) begin
                        //aborta
                    end else begin
                        start_div = 1'b1;
                        next_state = DIVISION;
                    end
                end
            end
            DIVISION: begin
                if(div_done) begin
                    load_norm_shift = 1'b1;
                    next_state = NORMALIZE;
                end

            end
            NORMALIZE: begin
                if (msb_is_zero) begin
                    shift_left_norm = 1'b1;
                end
                load_round = 1b'1;
                next_state = ROUND;
            end
            ROUND: begin
                done = 1b'1;
                busy = 1'b0;
                if(!start)begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

endmodule