module comparator_uc(
    input clk,
    input reset,
    output reg over
);

    reg [1:0]state;
    parameter IDLE = 2'b00;      //Estado em que esta tudo pronto para uma nova operacao 
    parameter CALC = 2'b01;
    parameter DONE = 2'b10;

    always @(posedge clk or posedge reset) begin //logica de proximo estado com reset
        if (reset) begin
            state = IDLE;
        end else begin
            case (state)
                IDLE:
                    state = CALC;
                CALC: //supondo que termina em um ciclo de clk. Depende da complexidade do comparador e da frequencia do clk
                    state = DONE;
                DONE:
                    state = IDLE;
            endcase
        end
    end

    always @(state) begin
        case (state)
                IDLE: begin
                    over = 1'b0;
                end
                CALC: begin
                    over = 1'b0;
                end
                DONE: begin
                    over = 1'b1;
                end
        endcase
    end
endmodule