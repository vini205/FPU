module multi_uc(
    input clk,
    input reset,
    input exeption,
    output load_shift,
    output e_norm, //enable normalizacao
    output over
);

reg [2:0]state;
parameter IDLE = 3'b000;
parameter EXP_CHECK = 3'b001; //checar os numeros especiais
parameter SHIFT=3'b010; 
parameter NORM = 3'b011; //normalização
parameter OVER = 3'b100; 

//contador para acabar caso passe de 100 ciclos de clk
wire down_over;
reg load_down;
down_counter #(6) dut(
    .clk(~clk), //para nao ocorrer checagem de estado ao mesmo tempo que is_over vira 1
    .rst(1'b0),
    .load(load_down),
    .start(~load_down),
    .data_in(6'b100000), //=32
    .is_over(down_over)
);

always @(posedge clk or reset) begin
    if(reset) state = IDLE;
    else begin
        case (state)
            IDLE:
                state=EXP_CHECK;
            EXP_CHECK: begin
                if(exeption) state=OVER;
                else state=SHIFT;
            end
            SHIFT: 
                if(down_over) state=NORM;
            NORM:
                state=OVER;
            OVER:
                state=IDLE;
        endcase
    end
end

always @(state) begin
    case (state)
        IDLE: begin
            load_down =1'b1;
            load_shift =1'b1;
            over=1'b0;
            e_norm = 1'b0;
        end
        EXP_CHECK: begin
            load_down =1'b1;
            load_shift =1'b1;
            over=1'b0;
            e_norm=1'b0;
        end
        SHIFT: begin
            load_down =1'b0;
            load_shift =1'b0;
            over=1'b0;
            e_norm=1'b0;
        end
        NORM: begin
            load_down =1'b1;
            load_shift =1'b1;
            over=1'b0;
            e_norm=1'b1;
        end
        OVER: begin
            load_down =1'b1;
            load_shift =1'b1;
            over=1'b1;
            e_norm=1'b0;
        end
        default: 
            state=IDLE;
    endcase
end

endmodule