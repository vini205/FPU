module fsm_mestre(
    input start,    //indica para a maquina que pode comecar
    input [2:0]op,  //operacao a ser feita
    input clk,      //clock do sistema
    input reset,    //reset do sistema
    input stop,     //sinal interno que diz que acabou coma as contas
    output reg [2:0]addr,    //manda o endereco (da operacao) que sera utilizado
    output busy,    //diz se ainda esta calculando
    output done     //inverso de ibusy
);

reg  calculating;     //registrador para diser se esta ocupado ou nao. 1 ocupado, 0 nao
assign busy = calculating;
assign done = ~calculating;

//Maquina de Moore com 4 estados
reg state;
parameter IDLE = 1'b0;      //Estado em que esta tudo pronto para uma nova operacao 
parameter CALC = 1'b1;      //Estado em que esta calculando (busy)

//contador para acabar caso passe de 100 ciclos de clk
wire is_over;
reg load;
down_counter #(7) dut(
    .clk(~clk), //para nao ocorrer checagem de estado ao mesmo tempo que is_over vira 1
    .rst(1'b0),
    .load(load),
    .start(~load),
    .data_in(7'b1100100), //=100 (ciclos para voltar para IDLE)
    .is_over(is_over)
);

always @(posedge clk or posedge reset) begin //logica de proximo estado com reset
    if (reset) begin
        state = IDLE;
    end else begin
        case (state)
            IDLE:
                if (start)
                    state = CALC;
            CALC:
                if(stop || is_over) 
                    state = IDLE;
            default:
                state = IDLE;
        endcase
    end
end

always @(state) begin //logica de estado
    case (state)
        IDLE: begin
            calculating = 1'b0;
            load= 1'b1;
        end
        CALC: begin
            addr =  op;
            calculating = 1'b1;
            load = 1'b0;   //comeca a contar
        end
        default:
            state = IDLE;
    endcase
end
endmodule