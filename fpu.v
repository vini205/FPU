module fpu (
    input clock , reset , start ,
    input [ 31 : 0 ] a , b ,
    input [ 2 : 0 ] op , // ADD , SUB , MUL , DIV , EQ , SLT
    output [ 31 : 0 ] c ,
    output busy , done ,
    output f_inv_op , f_div_zero , f_overflow , f_underflow , f_inexact
);
    wire over;
    wire [2:0]addr;
    wire [31:0]c_i; //interno, pode mudar enquanto done =1
    reg  [31:0]c_reg; //registra o resultado quando over =1

    bus_controler bus(
        .busy(busy),
        .clk(clock),
        .reset(reset),
        .addr(addr),
        .a(a),
        .b(b),
        .c(c_i),
        .f_inv_op(f_inv_op),
        .f_div_zero(f_div_zero),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .f_inexact(f_inexact),
        .over(over)
    );

    fsm_mestre fsm(
        .start(start),    //indica para a maquina que pode comecar
        .op(op),  //operacao a ser feita
        .clk(clock),      //clock do sistema
        .reset(reset),    //reset do sistema
        .stop(over),     //sinal interno que diz que acabou coma as contas
        .addr(addr),    //manda o endereco (da operacao) que sera utilizado
        .busy(busy),    //diz se ainda esta calculando
        .done(done)     //inverso de ibusy
    );

    always @(posedge over) begin
        if(over) c_reg = c_i;
    end
    assign c = c_reg;


endmodule