module fsm_mestre(
    input start,    //indica para a maquina que pode comecar
    input [2:0]op,  //operacao a ser feita
    input clk,      //clock do sistema
    input reset,    //reset do sistema
    input stop,     //sinal interno que diz que acabou coma as contas
    output reg [2:0]addr,    //manda o endereco (da operacao) que sera utilizado
    output reg busy,    //diz se ainda esta calculando
    output reg done     //inverso de ibusy
);

//Maquina de Moore com 3 estados
reg [1:0]state;
parameter IDLE = 2'b00;      //Estado em que esta tudo pronto para uma nova operacao 
parameter CALC = 2'b01;      //Estado em que esta calculando (busy)
parameter DONE = 2'b10;

//contador para acabar caso passe de 100 ciclos de clk
wire is_over;
reg load;
down_counter #(7) dut(
    .clk(~clk), //para nao ocorrer checagem de estado ao mesmo tempo que is_over vira 1
    .rst(1'b0),
    .load(load),
    .start(~load),
    .data_in(7'b1100100), //=100 (ciclos para vai para done)
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
                    state = DONE;
            DONE: begin //fica 1 ciclo de clk com done = 1
                if(start) state=CALC;
                else  state =  IDLE;
            end
        endcase
    end
end

always @(state) begin //logica de estado
    case (state)
        IDLE: begin
            busy = 1'b0;
            done = 1'b0;
            load= 1'b1;
        end
        CALC: begin
            addr =  op;
            busy = 1'b1;
            done = 1'b0;
            load = 1'b0;   //comeca a contar
        end
        DONE: begin //fica 1 ciclo de clk aqui
            busy = 1'b0;
            done = 1'b1; 
            load= 1'b1;
        end
        default:
            state = IDLE;
    endcase
end
endmodule