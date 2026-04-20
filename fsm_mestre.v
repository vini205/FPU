module fsm_mestre(
    input start,    //indica para a maquina que pode comecar
    input [2:0]op,  //operacao a ser feita
    input clk,      //clock do sistema
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

always @(posedge clk) begin //logica de proximo estado
    case (state)
        IDLE:
            if (start)
                state = CALC;
        CALC:
            if(stop) 
                state = IDLE;
        default:
            state = IDLE;
    endcase
end

always @(state) begin //logica de estado
    case (state)
        IDLE: begin
            calculating = 1'b0;
        end
        CALC: begin
            addr =  op;
            calculating = 1'b1;
        end
        default:
            state = IDLE;
    endcase
end
endmodule