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

//---------------//

module bus_controler(
    input busy,
    input clk,
    input reset,
    input [2:0]addr,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op , f_div_zero , f_overflow , f_underflow , f_inexact,
    output over
);
    //enables dos escravos
    //escravo 0: addr 000(ADD) ou 001(SUB),
    //escravo 1: addr 010(MULT)
    //escravo 2: addr 011(DIV)
    //escravo 3: addr 100(EQ) e 101(SLT)
    //addr 110-111(esse endereco eh invalido e nunca deveria ser acionado)


    wire e_s0;
    assign e_s0 = (~reset)&(~addr[1])&(~addr[2])&busy;
    wire e_s1;
    assign e_s1 = (~reset)&(~addr[0])&(addr[1])&(~addr[2])&busy;
    wire e_s2;
    assign e_s2 = (~reset)&(addr[0])&(addr[1])&(~addr[2])&busy;
    wire e_s3;
    assign e_s3 = (~reset)&(~addr[1])&(addr[2])&busy;
    
    

    wire [31:0] c0;
    wire f_inv_op0, f_div_zero0, f_overflow0 , f_underflow0 , f_inexact0;
    wire over0; //=done
    //instanciar o escravo 0 (ADD_SUB) (Por  favor usar reset como ~es_0, alem dos outputs acima)
    tp_add_sub sum_sub(
        .clk(clk),
        .reset(~e_s0),
        .start(e_s0),
        .is_sub(addr[0]),// Soma ou sub
        .a(a),
        .b(b),
        .result(c0),
        .f_div_zero(f_div_zero0),
        .f_overflow(f_overflow0),
        .f_underflow(f_underflow0),
        .f_inexact(f_inexact0),
        .f_inv_op(f_inv_op0),
        .over(over0)
    );
    //
    assign f_div_zero0 = 1'b0;
    
    
    wire [31:0] c1;
    wire f_inv_op1, f_div_zero1, f_overflow1 , f_underflow1 , f_inexact1;
    wire over1; //=done
    //instanciar o escravo 1 (MULT) (Por  favor usar reset como ~es_1, alem dos outputs acima)
        mult tp_mult (
            .clk(clk),
            .reset(~e_s1),
            .a(a),
            .b(b),
            .c(c1),
            .f_inv_op(f_inv_op1),
            .f_overflow(f_overflow1),
            .f_underflow(f_underflow1),
            .f_inexact(f_inexact1),
            .over(over1)
        );
    //
    assign f_div_zero1 = 1'b0;

    wire [31:0] c2;
    wire f_inv_op2, f_div_zero2, f_overflow2 , f_underflow2 , f_inexact2;
    wire over2; //=done
    //instanciar o escravo 2 (DIV) (Por  favor usar reset como ~es_2, alem dos outputs acima)

    tp_div topLevel_div (
        .clk(clk),
        .rst(~e_s2),
        .start(e_s2),
        .a(a),
        .b(b),
        .result(c2),
        .f_inv_op(f_inv_op2),
        .f_div_zero(f_div_zero2),
        .f_overflow(f_overflow2),
        .f_underflow(f_underflow2),
        .f_inexact(f_inexact2),
        .done(over2)
    );


    //
   
   
    wire [31:0] c3;
    wire f_inv_op3, f_div_zero3, f_overflow3 , f_underflow3 , f_inexact3;
    wire over3; //=done
    //instancia do escravo 3 (COMP)
        comparator comp(
            .eq(~addr[0]), //1 se eh EQ, 0 se eh SLT
            .clk(clk),
            .reset(~e_s3),
            .a(a),
            .b(b),
            .c(c3),
            .f_inv_op(f_inv_op3),
            .over(over3)
        );
    assign f_div_zero3= 1'b0;
    assign f_overflow3 = 1'b0;
    assign f_underflow3 = 1'b0;
    assign f_inexact3 = 1'b0;
    //
    
   assign c = (e_s0) ? c0 : (e_s1) ? c1 : (e_s2) ? c2 : (e_s3) ? c3 : 32'bz;
   assign f_inv_op = (e_s0) ? f_inv_op0 : (e_s1) ? f_inv_op1 : (e_s2) ? f_inv_op2 : (e_s3) ? f_inv_op3 : 1'bz;
   assign f_div_zero = (e_s0) ? f_div_zero0 : (e_s1) ? f_div_zero1 : (e_s2) ? f_div_zero2 : (e_s3) ? f_div_zero3 : 1'bz;
   assign f_overflow = (e_s0) ? f_overflow0 : (e_s1) ? f_overflow1 : (e_s2) ? f_overflow2 : (e_s3) ? f_overflow3 : 1'bz;
   assign f_underflow = (e_s0) ? f_underflow0 : (e_s1) ? f_underflow1 : (e_s2) ? f_underflow2 : (e_s3) ? f_underflow3 : 1'bz;
   assign f_inexact = (e_s0) ? f_inexact0 : (e_s1) ? f_inexact1 : (e_s2) ? f_inexact2 : (e_s3) ? f_inexact3 : 1'bz;
   assign over = (e_s0) ? over0 : (e_s1) ? over1 : (e_s2) ? over2 : (e_s3) ? over3 : 1'bz;
   
endmodule

//---------//

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

//--------//

/* Comparador de N bits, nesse arquivo há um comparador de 1 bit
 e um comparador de n Bits
*/
module comp_Nbits #(parameter N = 8) (
    input wire [N-1:0] A, 
    input wire [N-1:0] B, 
    output wire AGTB, // A Greater Than B
    output wire AEQB, // A Equal to B
    output wire ALTB // A Lower than B
);

    genvar i;

    wire [N-1:0] g_int, e_int;

    generate
        for (i = N-1; i >= 0; i = i - 1) begin
            // No estado inicial, supõe que são iguais
            comp_1bit comp (
                (i == N-1) ? 1'b0 : g_int[i+1],
                (i == N-1) ? 1'b1 : e_int[i+1],
                A[i],
                B[i],
                g_int[i],
                e_int[i]
            );
        end
    endgenerate

    assign AGTB = g_int[0];
    assign AEQB = e_int[0];
    assign ALTB = ~AGTB && ~AEQB;


endmodule

module comp_1bit (
    input wire AGTBI,  
    input wire AEQBI,  
    input wire A, 
    input wire B, 
    output wire AGTBO, 
    output wire AEQBO  
);
    assign AEQBO = ~(A ^ B) & AEQBI;
    assign AGTBO = ((A & ~B) & AEQBI) | AGTBI;


endmodule

//-----------------//

module tp_add_sub (
    input wire clk,
    input wire reset,
    input wire start,         
    input wire is_sub,        // 0 para adição, 1 para subtração
    input wire [31:0] a,
    input wire [31:0] b,
    
    output wire [31:0] result,
    output wire f_div_zero,
    output wire f_overflow,
    output wire f_underflow,
    output wire f_inexact,
    output wire f_inv_op,
    output wire over          
);

    wire load_shift;
    wire shift_mant;
    wire shift_right_norm;
    wire shift_left_norm;
    wire load_norm_shift;
    wire load_sum;            // Sinal gerado pela UC, atualmente sem sumidouro no FD

    wire count_over;
    wire is_normalized;
    wire exp_is_zero;
    wire cout_sum;

    sum_uc control_unit (
        .clk(clk),
        .rst(reset),
        .start(start),
        
        // Sinais de realimentação (Feedback) do FD
        .count_over(count_over),
        .is_normalized(is_normalized),
        .exp_is_zero(exp_is_zero),
        .cout_sum(cout_sum),
        
        // Sinais de Controle 
        .shift_right_norm(shift_right_norm),
        .shift_left_norm(shift_left_norm),
        .load_sum(load_sum),
        .load_shift(load_shift),
        .shift_mant(shift_mant),
        .load_norm_shift(load_norm_shift),
        .done(over)           
    );

    sum_fd datapath (
        .a(a),
        .b(b),
        .clk(clk),
        .rst(reset),
        
        // Sinais de Controle provenientes da UC
        .load_shift(load_shift),
        .shift_mant(shift_mant),
        .is_sub(is_sub),
        .shift_right_norm(shift_right_norm),
        .shift_left_norm(shift_left_norm),
        .load_norm_shift(load_norm_shift),
        
        // Saídas de Estado e Flags Operacionais
        .exp_is_zero(exp_is_zero),
        .cout_sum(cout_sum),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .sum(result),
        .count_over(count_over),
        .is_normalized(is_normalized),
        .f_inexact(f_inexact),
        .f_inv_op(f_inv_op)
    );

    assign f_div_zero = 1'b0;

endmodule

module sum_fd (
    input wire [31:0] a,
    input wire[31:0] b,
    input wire clk,
    input wire rst,
    input wire load_shift,
    input wire shift_mant,
    input wire is_sub,
    input wire shift_right_norm,
    input wire shift_left_norm,
    input wire load_norm_shift,

    output wire exp_is_zero,//caso denormalizado
    output wire cout_sum,
    output wire f_overflow,
    output wire f_underflow,
    output wire [31:0] sum,
    output wire count_over,
    output wire is_normalized,
    output wire f_inexact,
    output wire f_inv_op
    
);

    wire sign_A = a[31];
    wire [7:0] exp_A = a[30:23];
    
    // Se exp for 0, o bit implícito é 0 (subnormal). Caso contrário, é 1 (normal).
    wire [23:0] mant_A = {(|exp_A), a[22:0]};

    wire sign_B = b[31];
    wire [7:0] exp_B = b[30:23];
    wire [23:0] mant_B = {(|exp_B), b[22:0]};

    wire [7:0] diff_exp;
    wire choose_exp;
    wire [7:0] larger_exp ;
    wire [7:0] smaller_exp;
    wire [23:0] larger_mant;
    wire [23:0] smaller_mant;

    //Para arredondamento
    wire [2:0] guards;
    //Caso for subnormal
    wire [7:0] eff_exp_A = (~|exp_A ) ? 8'd1 : exp_A;
    wire [7:0] eff_exp_B = (~|exp_B) ? 8'd1 : exp_B;

    wire [31:0] mag_A = {eff_exp_A, mant_A};
    wire [31:0] mag_B = {eff_exp_B, mant_B};
    
    wire exp_eq;
    // Verificando os expoentes
    small_alu #(.N(8)) comparador_exp (
        .A(eff_exp_A),
        .B(eff_exp_B),
        .diff(diff_exp),
        .A_gt_B(choose_exp),
        .A_eq_B(exp_eq)
    );


    wire mag_mant;
    //verificando as mantissas
    small_alu #(.N(24)) comparador_mant (
        .A(mant_A),
        .B(mant_B),
        .diff(),
        .A_gt_B(mag_mant)
    );

    //Vendo qual é o maior
    assign larger_exp = exp_eq ?(mag_mant? exp_A: exp_B) :
                                (choose_exp ? exp_A: exp_B) ;

    assign larger_mant = exp_eq ? (mag_mant ? mant_A:mant_B ):
                                (choose_exp ? mant_A: mant_B);

    // sinal de B altera pela subtracao
    wire eff_sign_B = is_sub ? ~sign_B : sign_B;
    
    // O sinal do resultado final é o sinal do maior valor
    wire sign_final = exp_eq ? (mag_mant ?  sign_A : eff_sign_B) :
                               (choose_exp ? sign_A : eff_sign_B);
    
                                

    assign smaller_exp = exp_eq ? (mag_mant ? exp_B :exp_A) :
                                choose_exp ? exp_B:exp_A;
    assign smaller_mant = exp_eq ? (mag_mant ?  mant_B :mant_A ):
                                choose_exp ? mant_B: mant_A;


    // fazendo shift
    down_counter contador(
        .clk(clk),
        .rst(rst),
        .load(load_shift),
        .start(shift_mant),
        .data_in(diff_exp),// A diferença entre as mantissas é o quanto devo mover
        .count(),
        .is_over(count_over)
    );

    wire [23:0] shifted_mant ;
    shifter # (24) rightShift(
        .clk(clk),
        .rst(rst),
        .load(load_shift),
        .shift_right(shift_mant),
        .shift_left(1'b0),
        .serial_in(1'b0),
        .data_in(smaller_mant),
        .data_out(shifted_mant),
        .guards(guards)
    ); 

    wire is_diff = sign_A ^ eff_sign_B;// Para saber se é uma soma ou subtração
    wire [23:0] op_mant = is_diff ? (~shifted_mant) :shifted_mant;
    //Faz subtração com o complemento de 2 do menor
    wire [23:0] somaMant;
    wire rawCout;
    full_adder_Nbits #(24) somadorMantissa(
        .a(larger_mant),
        .b(op_mant),
        .cin(is_diff),//Caso for subtração colocar em comp. de 2
        .sum(somaMant),
         .cout(rawCout)
    );
    assign cout_sum = rawCout & (!is_diff);

    wire [23:0] normalized;
    shifter # (24) shift_norm(
        .clk(clk),
        .rst(rst),
        .load(load_norm_shift),
        .shift_right(shift_right_norm),
        .shift_left(shift_left_norm),
        .serial_in(cout_sum),
        .data_in(somaMant),
        .data_out(normalized)
    ); 
    assign is_normalized = normalized[23];//Se o 1 bit for 1
    wire [22:0] mantissaNorm = normalized[22:0];



    // Fazer nova soma para expoente para normalização

    wire overflow_exp;
    reg [7:0] exp_to_norm;
    wire [7:0] next_exp;

    wire [7:0] norm_exp = shift_left_norm? 8'b11111111: {7'b0000000, shift_right_norm};
    // se for left, subtrai 1, senão soma 1
    full_adder_Nbits #(.N(8)) atualizador_de_expoente (
        .a(exp_to_norm),     // O valor atual 
        .b(norm_exp),  
        .cin(1'b0),  
        .sum(next_exp),
        .cout()//ignorado
    );

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            exp_to_norm <= 8'b0;
        end else if (load_norm_shift) begin
            exp_to_norm <= larger_exp;//inicia
        end else if (shift_left_norm || shift_right_norm) begin
            exp_to_norm <= next_exp;// guarda a saida
        end
    end
    assign exp_is_zero = ~|exp_to_norm; //caso denormal


    // Arredondamento

    //MANTISSA
    wire l_bit = mantissaNorm[0];
    wire round_up =  guards[2] & (guards[1] | guards[0] | l_bit);// maior que 0.5
    wire [22:0] mantissaRouded;
    wire round_cout;
    full_adder_Nbits #(.N(23)) somador_round (
        .a(mantissaNorm),
        .b(23'b0),
        .cin(round_up),
        .sum(mantissaRouded),
        .cout(round_cout)
    );
    


    wire [22:0] mantissa_final = round_cout ? 23'd0 : mantissaRouded;    
    wire [7:0] exp_pos_round;
    wire exp_cout_round;

    // ajustar o EXP caso o arredondamento transborde
    full_adder_Nbits #(.N(8)) ajustador_exp_round (
        .a(exp_to_norm),
        .b(8'd0),
        .cin(round_cout), 
        .sum(exp_pos_round),
        .cout(exp_cout_round)
    );
    // Forçar o sinal  positivo
    wire is_zero_result = (~|exp_pos_round) & (~|mantissa_final);
    wire true_sign_final = is_zero_result ? 1'b0 : sign_final;

    wire [31:0] final_value = {true_sign_final, exp_pos_round, mantissa_final};

    // FLAGS
    assign f_overflow = (exp_pos_round >= 8'hFF);
    wire [31:0] infinity = {sign_final, 8'hFF, 23'd0};
    assign sum = f_overflow ? infinity : final_value;

    wire is_inexact =guards[2] || guards[1] || guards[0];
    assign f_underflow = is_inexact && (~|exp_pos_round); 
    assign f_inexact = is_inexact || f_overflow || f_underflow;

    //Verificação de operações invalidas
    //(sNaN)
    wire is_snan_A = (&exp_A) & (|a[22:0]) & (~a[22]);
    wire is_snan_B = (&exp_B) & (|b[22:0]) & (~b[22]);
    
    wire is_inf_A  = (&exp_A) & (~|a[22:0]);
    wire is_inf_B  = (&exp_B) & (~|b[22:0]);
    
    wire inf_conflict = is_inf_A & is_inf_B & is_diff;
    assign f_inv_op = inf_conflict | is_snan_A | is_snan_B;

 
    


endmodule

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
            ROUND = 3'd6,
            WAIT = 3'd7;
            
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
                next_state = WAIT;
            end else if (!(is_normalized ||exp_is_zero)) begin
                shift_left_norm = 1'b1;
            end else begin
                next_state = ROUND;
            end
        end
        WAIT: begin
            next_state = ROUND;//Para dar tempo de carregar a resposta (dps do shift)
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

//-------//

module mult(
    input clk,
    input reset,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op , f_overflow , f_underflow , f_inexact,
    output over
);
wire exeption, load_shift, e_norm;

mult_fd fd(
    .clk(clk),
    .load_shift(load_shift),
    .e_norm(e_norm),
    .a(a), .b(b),
    .c(c),
    .exeption(exeption),
    .f_inv_op(f_inv_op) , .f_overflow(f_overflow) , .f_underflow(f_underflow) , .f_inexact(f_inexact)
);

mult_uc uc( 
    .clk(clk),
    .reset(reset),
    .exeption(exeption),
    .load_shift(load_shift),
    .e_norm(e_norm), //enable normalizacao
    .over(over)
);
endmodule

module mult_fd(
    input clk,
    input load_shift,
    input e_norm,
    input [31:0] a, b,
    output [31:0] c,
    output exeption,
    output f_inv_op , f_div_zero , f_overflow , f_underflow , f_inexact
);

wire sNaNa, sNaNb, qNaNa, qNaNb, pos_infa, pos_infb, neg_infa, neg_infb, zeroa, zerob;

exeptions_number_detector a_ex(
    .a(a),
    .sNaN(sNaNa), //signaling NaN
    .qNaN(qNaNa), //quiet
    .pos_inf(pos_infa), //infinito positivo
    .neg_inf(neg_infa), //"" negativo
    .zero(zeroa)//==0
);

exeptions_number_detector b_ex(
    .a(b),
    .sNaN(sNaNb), //signaling NaN
    .qNaN(qNaNb), //quiet
    .pos_inf(pos_infb), //infinito positivo
    .neg_inf(neg_infb), //"" negativo
    .zero(zerob)//==0
);

assign f_inv_op = sNaNa | sNaNb | ((zeroa | zerob) & (infa | infb));


//Extremos
wire exeptiona, exeptionb;
assign exeptiona = zeroa | sNaNa | qNaNa | pos_infa | neg_infa;
assign exeptionb = zerob | sNaNb | qNaNb | pos_infb | neg_infb;
assign exeption = exeptiona | exeptionb;

wire zero = (zeroa &  ~exeptionb) | (zerob & ~exeptiona) | (zeroa & zerob);

wire infa, infb; 
assign infa = pos_infa | neg_infa;
assign infb = pos_infb | neg_infb;
wire inf, pos_inf, neg_inf;
assign inf = (infa & ~exeptionb) | (infb & ~exeptiona) | (infa & infb);//resultado é infinito
assign pos_inf = inf &  ~(a[31]^b[31]);
assign neg_inf = inf & (a[31] ^b[31]);

wire [31:0]c_qNaN;
assign c_qNaN = ((zeroa | zerob) & (infa | infb)) ? (32'h7FC00000) : (sNaNa) ? ({a[31:23], 1'b1, a[21:0]}) : (sNaNb) ? ({b[31:23], 1'b1,b[21:0]}) : (qNaNa) ? a : (qNaNb) ? (b) : 32'bz;




wire [31:0]c_exeption;
parameter zeropadrao = 31'h00000000;
parameter pos_infpadrao = 32'h7f800000;
parameter neg_infpadrao = 32'hff800000;
assign c_exeption = (zero) ? ({a[31]^b[31], zeropadrao}) : (pos_inf) ? (pos_infpadrao) : (neg_inf) ? (neg_infpadrao) : (c_qNaN);


wire [47:0]c_shift;
shifter #(48) shift_a(
    .clk(~clk),
    .rst(1'b0),
    .load(load_shift),
    .shift_left(1'b1),
    .shift_right(1'b0),
    .serial_in(1'b0),
    .data_in({24'b0, 1'b1, a[22:0]}),
    .data_out(c_shift)
);

wire [23:0]b_shift;
shifter #(24) shift_b(
    .clk(~clk),
    .rst(1'b0),
    .load(load_shift),
    .shift_left(1'b0),
    .shift_right(1'b1),
    .serial_in(1'b0),
    .data_in({1'b1, b[22:0]}),
    .data_out(b_shift)
);

wire [47:0]s_sum;
full_adder_Nbits #(48) adder_m(
    .a(s_reg), 
    .b((c_shift & {48{b_shift[0]}})), 
    .cin(1'b0),
    .sum(s_sum)    
);

reg [47:0]s_reg; //reg para o shifter
always @(posedge clk or load_shift) begin
    if(load_shift & ~e_norm) s_reg = 48'b0;
    else s_reg = s_sum;
end 

reg [47:0]mult_reg; //reg para guardar multiplicacao
always @(e_norm) begin
    if(e_norm) mult_reg = s_reg;    
end


wire [23:0] full_mantissa = (mult_reg[47]) ? mult_reg[47:24] : mult_reg[46:23];
wire [22:0] m_normalized = full_mantissa[22:0];

//correcao para subnormais
wire [7:0] eff_exp_a = (~|a[30:23]) ? 8'd1 : a[30:23];
wire [7:0] eff_exp_b = (~|b[30:23]) ? 8'd1 : b[30:23];

wire [7:0] e_sum; //soma dos expoentes
wire cout_e;
full_adder_Nbits #(8) adder_e(
    .a(eff_exp_a), 
    .b(eff_exp_b), 
    .cin(mult_reg[47]), // Soma 1 se a mantissa transbordou à esquerda
    .sum(e_sum),
    .cout(cout_e)
);

wire [8:0] e_sub; //subtracao por 127
wire bout_e; 
full_subtractor_nbit #(9) sub(
    .a({cout_e, e_sum}), // minuendo
    .b(9'b00111_1111),   // subtraendo (Bias 127)
    .bin(1'b0),
    .diff(e_sub),
    .bout(bout_e)
);

// Se bout_e 1, ou e_sub 0, subnormal
wire is_subnormal = bout_e | (~|e_sub);
wire [9:0] denorm_shift;

// Calculamos: Shift = 1 - (E_calculado)
full_subtractor_nbit #(10) calc_denorm_shift (
    .a(10'd1),
    .b({bout_e, e_sub}), 
    .bin(1'b0),
    .diff(denorm_shift),
    .bout()
);

wire shift_limit0, shift_limit1;
comp_Nbits #(10) limit_comp (
    .A(denorm_shift),
    .B(10'd24),
    .AGTB(shift_limit0),
    .AEQB(shift_limit1)
);

//denormalizando
wire shift_out_of_bounds = shift_limit0 | shift_limit1;
wire [23:0] denorm_mantissa = shift_out_of_bounds ? 24'd0 : (full_mantissa >> denorm_shift);

assign f_overflow = (e_sub[8] | &e_sub[7:0]) & ~exeption & ~bout_e;

// se reg[47] = 1, tem que ter movido um para esquerda
wire mult_inexact = mult_reg[47] ? |mult_reg[23:0] : |mult_reg[22:0];

// checando a denormalização
wire lost_in_denorm = shift_out_of_bounds ? |full_mantissa : ((denorm_mantissa << denorm_shift) != full_mantissa);

// juntando os dois
wire any_lost_bits = mult_inexact | (is_subnormal & lost_in_denorm);


assign f_underflow = is_subnormal & any_lost_bits & ~exeption; 


assign f_inexact = (any_lost_bits | f_overflow | f_underflow) & ~exeption;

wire [7:0] final_exp  = is_subnormal ? 8'h00 : e_sub[7:0];
wire [22:0] final_frac = is_subnormal ? denorm_mantissa[22:0] : m_normalized;
wire sign_out = a[31] ^ b[31];

assign c = (exeption) ? c_exeption : (f_overflow) ? {sign_out, 8'hFF, 23'd0} : {sign_out, final_exp, final_frac};

endmodule

module mult_uc(
    input clk,
    input reset,
    input exeption,
    output reg load_shift,
    output reg e_norm, //enable normalizacao
    output reg over
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
down_counter #(5) dut(
    .clk(~clk), //para nao ocorrer checagem de estado ao mesmo tempo que is_over vira 1
    .rst(1'b0),
    .load(load_down),
    .start(~load_down),
    .data_in(5'b11000), //=23
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

//------//

module tp_div (
    input wire clk, rst, start,
    input wire [31:0] a, b,
    output wire [31:0] result,
    output wire done,
    output wire f_inv_op, f_div_zero, f_overflow, f_underflow, f_inexact
);

    wire start_core, div_core_done, msb_is_zero, load_norm, shift_l,  d_zero;

    div_uc uc_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .div_done(div_core_done),
        .msb_is_zero(msb_is_zero),
        .div_zero(d_zero),
        .start_div(start_core),
        .load_norm_shift(load_norm),
        .shift_left_norm(shift_l),
        .done(done)
    );

    div_fd fd_inst (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .start_div(start_core),
        .load_norm_shift(load_norm),
        .shift_left_norm(shift_l),
        .result(result),
        .div_done(div_core_done),
        .div_zero(d_zero),
        .msb_is_zero(msb_is_zero),
        .f_inv_op(f_inv_op),
        .f_overflow(f_overflow),
        .f_underflow(f_underflow),
        .f_inexact(f_inexact)
    );
    assign f_div_zero = d_zero;

endmodule

module div_fd (
    input clk,
    input rst,
    input [31:0]a,b,
    input start_div,
    input load_norm_shift,
    input shift_left_norm,

    output [31:0] result,
    output div_done,
    output div_zero,
    output msb_is_zero,
    output wire f_inv_op,
    output wire f_overflow,   
    output wire f_underflow,  
    output wire f_inexact
);

    wire is_snan_A;
    wire A_zero;
    wire is_inf_A;
    wire is_ninf_A;
    
    wire inf_conflict = is_inf_A & is_inf_B;
    exeptions_number_detector exep_a(
    .a(a),
    .sNaN(is_snan_A),
    .qNaN(is_qnan_A),
    .pos_inf(is_inf_A),
    .neg_inf(is_ninf_A),
    .zero(A_zero)
    );
    wire is_snan_B, is_inf_B, is_ninf_B,B_zero,is_qnan_A,is_qnan_B;


    exeptions_number_detector exep_b(
    .a(b),
    .sNaN(is_snan_B),
    .qNaN(is_qnan_B),
    .pos_inf(is_inf_B),
    .neg_inf(is_ninf_B),
    .zero(B_zero)
    );
    assign div_zero = B_zero & ~A_zero;//Apenas se A != 0


    /// subnormais
    wire [7:0] exp_A = a[30:23];
    wire [7:0] exp_B = b[30:23];

    // O expoente efetivo de um subnormal 1
    wire [7:0] eff_exp_A = (~|exp_A) ? 8'd1 : exp_A;
    wire [7:0] eff_exp_B = (~|exp_B) ? 8'd1 : exp_B;

    wire [23:0] mant_A = {|exp_A, a[22:0]};
    wire [23:0] mant_B = {|exp_B, b[22:0]};

    // Contar zero a esquerda
    wire [4:0] lz_A =
        mant_A[23] ? 5'd0 : mant_A[22] ? 5'd1 : mant_A[21] ? 5'd2 : mant_A[20] ? 5'd3 :
        mant_A[19] ? 5'd4 : mant_A[18] ? 5'd5 : mant_A[17] ? 5'd6 : mant_A[16] ? 5'd7 :
        mant_A[15]? 5'd8 : mant_A[14] ? 5'd9 : mant_A[13] ? 5'd10: mant_A[12] ? 5'd11:
        mant_A[11] ? 5'd12: mant_A[10] ? 5'd13: mant_A[9]  ? 5'd14: mant_A[8]  ? 5'd15:
        mant_A[7]  ? 5'd16: mant_A[6]   ? 5'd17: mant_A[5]  ? 5'd18: mant_A[4]  ? 5'd19:
        mant_A[3]  ? 5'd20: mant_A[2]  ? 5'd21: mant_A[1]  ? 5'd22: mant_A[0]  ? 5'd23: 5'd24;

    wire [4:0] lz_B =
        mant_B[23] ? 5'd0 : mant_B[22] ? 5'd1 : mant_B[21] ? 5'd2 : mant_B[20] ? 5'd3 :
        mant_B[19] ? 5'd4 : mant_B[18]   ? 5'd5 : mant_B[17] ? 5'd6 : mant_B[16] ? 5'd7 :
        mant_B[15] ? 5'd8 : mant_B[14]   ? 5'd9 : mant_B[13] ? 5'd10: mant_B[12] ? 5'd11:
        mant_B[11] ? 5'd12: mant_B[10] ? 5'd13: mant_B[9]  ? 5'd14: mant_B[8]  ? 5'd15:
        mant_B[7]  ? 5'd16: mant_B[6] ? 5'd17: mant_B[5]  ? 5'd18: mant_B[4]  ? 5'd19:
        mant_B[3]  ? 5'd20: mant_B[2] ? 5'd21: mant_B[1]  ? 5'd22: mant_B[0]  ? 5'd23: 5'd24;

    // Alinha o bit 1
    wire [23:0] norm_mant_A = mant_A << lz_A;
    wire [23:0] norm_mant_B = mant_B << lz_B;

    wire [25:0] quotient;
    wire [25:0] remainder;
    
    restoring_div #(.N(26)) divisor_mant (
        .clk(clk),
        .rst(rst),
        .start(start_div),
        .dividend({norm_mant_A, 2'b00}), 
        .divisor({norm_mant_B, 2'b00}),
        .quotient(quotient),
        .remainder(remainder),
        .done(div_done)
    );

    assign msb_is_zero = ~quotient[25];
    wire sign_out = a[31] ^ b[31];

    wire [9:0] exp_A_ext = {2'b00, eff_exp_A} - lz_A; 
    wire [9:0] exp_B_ext = {2'b00, eff_exp_B} - lz_B;

    wire [9:0] bias = 10'd127;
    wire [9:0] exp_calc;
    wire [9:0] exp_sub_tot;
        
    // SUBTRAÇÂO DOS EXP
    full_subtractor_nbit #(.N(10)) sub_exp (
        .a(exp_A_ext),
        .b(exp_B_ext),
        .bin(1'b0),
        .diff(exp_calc),
        .bout()
    );

    full_adder_Nbits #(.N(10)) adicionador_bias (
        .a(exp_calc),
        .b(bias),
        .cin(1'b0), //Soma Bias
        .sum(exp_sub_tot),
        .cout()
    );

    //NORMALIZE
    wire [25:0] mant_normalized = shift_left_norm ? {quotient[24:0], 1'b0} : quotient;

    
    wire [23:0] mantissaNorm = mant_normalized[25:2];

    wire [2:0] guards = {mant_normalized[1], mant_normalized[0], |remainder};

    wire [9:0] exp_normalized;
    full_subtractor_nbit #(.N(10)) exp_norm (
        .a(exp_sub_tot),
        .b( {9'b0, shift_left_norm} ),
        .bin( 1'b0),
        .diff(exp_normalized),
        .bout()
    );

    // ROUND
    wire round_up = guards[2] & (guards[1] | guards[0] | mantissaNorm[0]);

    wire [22:0] mantissaRouded;
    wire round_cout;
    full_adder_Nbits #(.N(23)) somador_round (
        .a(mantissaNorm[22:0]),
        .b(23'b0),
        .cin(round_up),
        .sum(mantissaRouded),
        .cout(round_cout)
    );

    wire [22:0] mantissa_final = round_cout ? 23'd0 : mantissaRouded;    
    wire [9:0] exp_pos_round;
    

    // ajustar o EXP caso o arredondamento transborde
    full_adder_Nbits #(.N(10)) ajustador_exp_round (
        .a(exp_normalized),
        .b(10'd0),
        .cin(round_cout), 
        .sum(exp_pos_round),
        .cout()
    );


    // FLAGS
    wire [31:0] qnan = {1'b0, 8'hFF, 23'h400000};
    wire [31:0] infinity = {sign_out, 8'hFF, 23'd0};

    // Invalid
    wire zero_por_zero = A_zero & B_zero;
    wire inf_por_inf = (is_inf_A| is_ninf_A) & (is_inf_B| is_ninf_B);
    assign f_inv_op = is_snan_A | is_snan_B | zero_por_zero | inf_por_inf|is_qnan_A | is_qnan_B;

    //Underflow


    wire is_neg_exp = exp_pos_round[9];
    wire is_zero_exp = (~|exp_pos_round[8:0]);
    wire underflow_exp = is_neg_exp | is_zero_exp;
    wire [9:0] denorm_shift;

    full_subtractor_nbit #(.N(10)) calc_shift_norm (
        .a(10'd1),
        .b(exp_pos_round),
        .bin(1'b0),
        .bout(),
        .diff(denorm_shift )
    );
    wire [23:0] full_mant_denorm = {1'b1, mantissa_final};

     wire denorm00, denorm01;
    comp_Nbits #(.N(10)) comp_denorm_shift(
        .A(denorm_shift),
        .B(10'd24),
        .AGTB(denorm00),
        .AEQB(denorm01)
    );

    // Desloca , se for for >= 24 a fracao zera
    wire [23:0] denorm_mantissa = ( denorm00 | denorm01 ) ? 24'd0 :
                                  (full_mant_denorm >> denorm_shift);


    //OVerlfow
    wire exp_over00, exp_over01;
    comp_Nbits #(.N(10)) comp_overflow_exp(
        .A(exp_pos_round),
        .B(10'b0011111111),
        .AGTB(exp_over00),
        .AEQB(exp_over01)
    );
    wire f_overflow_exp  = (~is_neg_exp) & ( exp_over00 | exp_over01);
    wire [7:0] final_exp  = underflow_exp ? 8'h00 : exp_pos_round[7:0];
    wire [22:0] final_frac = underflow_exp ? denorm_mantissa[22:0] : mantissa_final;
    // INVALID

    wire force_nan_out = f_inv_op | is_qnan_A | is_qnan_B;
    assign result = force_nan_out    ? qnan :
                    (div_zero)  ? infinity  : 
                    (f_overflow_exp) ? infinity  :
                                         {sign_out, final_exp, final_frac};
    // se overflow => infinito, se underflow => zero

    assign f_overflow = f_overflow_exp;
    assign f_underflow = underflow_exp & (|guards);

    assign f_inexact = |guards | f_overflow | f_underflow;

endmodule

module div_uc (
    input clk,
    input rst,
    input start,
    input div_done,
    input msb_is_zero,
    input div_zero,

    output reg start_div,
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

module restoring_div #(
    parameter N = 26
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [N-1:0] dividend,
    input  wire [N-1:0] divisor,
    
    output wire [N-1:0] quotient,
    output wire [N-1:0] remainder,
    output wire done
);

    localparam IDLE  = 2'd0,
               SHIFT = 2'd1,
               SUB   = 2'd2,
               DONE  = 2'd3;

    reg [1:0] state;
    reg [$clog2(N+1)-1:0] count;

    reg [N:0] reg_A; // evita overflow na sub
    reg [N:0] reg_M;
    reg [N-1:0] reg_Q;

  
    wire [N:0] alu_result;
    
    // Instanciação do subtrator com N+1 bits de largura
    full_subtractor_nbit #(.N(N+1)) alu_sub (
        .a(reg_A),
        .b(reg_M),
        .bin(1'b0),
        .diff(alu_result),
        .bout() //ignora
    );

    wire alu_neg = alu_result[N]; 

    assign quotient  = reg_Q;
    assign remainder = reg_A[N-1:0];
    assign done = (state == DONE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            reg_A <= 0;
            reg_M <= 0;
            reg_Q <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        reg_A <= {2'b00, dividend[N-1:1]};
                        reg_Q <= {dividend[0], {(N-1){1'b0}}};
                        reg_M <= {1'b0, divisor};
                        
                        count <= N; 
                        state <= SHIFT;
                    end
                end
                
                SHIFT: begin
                    reg_A <= {reg_A[N-1:0], reg_Q[N-1]};
                    reg_Q <= {reg_Q[N-2:0], 1'b0};
                    state <= SUB;
                end
                
                SUB: begin
                    if (!alu_neg) begin
                        reg_A    <= alu_result;
                        reg_Q[0] <= 1'b1;
                    end
                    
                    if (count == 1) begin
                        state <= DONE;
                    end else begin
                        count <= count - 1; 
                        state <= SHIFT;
                    end
                end
                
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

//--------//

module comparator(
    input eq, //1 se eh eq, 0 se eh 
    input clk,
    input reset,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op,
    output over
);
comparator_uc uc_comparator(
    .clk(clk),
    .reset(reset),
    .over(over)
);

comparator_fd fd_comparator(
    .eq(eq),
    .a((reset) ? (32'bz) : (a)),
    .b((reset) ? (32'bz) : (b)),
    .c(c),
    .f_inv_op(f_inv_op) 
);


endmodule

module comparator_fd(
    input eq,
    input [31:0] a, b,
    output [31:0] c,
    output f_inv_op
);
    wire sign_A, sign_B;
    wire [7:0] exp_A, exp_B;
    wire [22:0] mant_A, mant_B;

    assign sign_A = a[31];
    assign exp_A = a[30:23];
    assign mant_A = a[22:0];

    assign exp_B = b[30:23];
    assign sign_B = b[31];
    assign mant_B = b[22:0];

    wire NaN_a, NaN_b;
    wire m_zero_a, m_zero_b;
    wire max_a, max_b;
    comp_Nbits #(8) exp_max_a( 
        .A(exp_A), 
        .B(8'b11111111), 
        .AEQB(max_a)
    );
    comp_Nbits #(8) exp_max_b( 
        .A(exp_B), 
        .B(8'b11111111), 
        .AEQB(max_b)
    );
    comp_Nbits #(23) mant_zero_a( 
        .A(mant_A), 
        .B(23'b0), 
        .AEQB(m_zero_a)
    );
    comp_Nbits #(23) mant_zero_b( 
        .A(mant_B), 
        .B(23'b0), 
        .AEQB(m_zero_b)
    );
    assign NaN_a = max_a & (~m_zero_a);
    assign NaN_b = max_b & (~m_zero_b);

    wire SNaN_a, SNaN_b;
    assign SNaN_a = NaN_a & (~a[22]);
    assign SNaN_b = NaN_b & (~b[22]);
    assign f_inv_op = (NaN_a | NaN_b)&(~eq) | (SNaN_a |SNaN_b); 

    wire exp_zero_a;
    wire exp_zero_b;
    wire zero_a, zero_b;
    comp_Nbits #(8) exp_0_a( 
        .A(exp_A), 
        .B(8'b0), 
        .AEQB(exp_0_a)
    );
    comp_Nbits #(8) exp_0_b( 
        .A(exp_B), 
        .B(8'b0), 
        .AEQB(exp_0_b)
    );
    assign zero_a = exp_0_a & m_zero_a;
    assign zero_b = exp_0_b & m_zero_b;



    wire AEQB0; //sem cobrir as execessoes
    wire ALTB0;
    comp_Nbits #(32) comp( 
        .A({~sign_A, a[30:0]}), 
        .B({~sign_B, b[30:0]}), 
        .AEQB(AEQB0),
        .ALTB(ALTB0)
    );


    wire AEQB;
    assign AEQB = ((zero_b & zero_a) | AEQB0)&(~NaN_a)&(~NaN_b);
    wire ALTB;
    assign ALTB = (~(zero_b & zero_a))&(ALTB0)&(~NaN_a)&(~NaN_b);

    assign c = (eq) ? ((AEQB) ?  (32'h3F800000) : (32'h00000000)) : ((ALTB) ?  (32'h3F800000) : (32'h00000000));

endmodule

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

//--------//
//COMPONENTES UTEIS USADOS 

// Módulo pra um contador 
module down_counter #(parameter N = 8) (
    input wire clk,
    input wire rst,
    input wire load,
    input wire start, 
    input wire [N-1:0] data_in, //o núemro de clks
    output reg [N-1:0] count,
    output wire is_over // acabou
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {N{1'b0}};
        end else if (load) begin
            count <= data_in;
        end else if (start && count > 0) begin
            count <= count - 1'b1;
        end
    end

    assign is_over = (count == {N{1'b0}});

endmodule

module exeptions_number_detector(
    input [31:0] a,
    output sNaN, //signaling NaN
    output qNaN, //quiet
    output pos_inf, //infinito positivo
    output neg_inf, //"" negativo
    output zero //==0
);
    wire [7:0] exp_A;
    wire [22:0] mant_A;
    assign exp_A = a[30:23];
    assign mant_A = a[22:0];

    wire NaN_a;
    wire m_zero_a;
    wire max_a;
    comp_Nbits #(8) exp_max_a( 
        .A(exp_A), 
        .B(8'b11111111), 
        .AEQB(max_a)
    );
    comp_Nbits #(23) mant_zero_a( 
        .A(mant_A), 
        .B(23'b0), 
        .AEQB(m_zero_a)
    );

    assign NaN_a = max_a & (~m_zero_a);

    assign sNaN = NaN_a & (~a[22]);
    assign qNaN = NaN_a & (a[22]);
    
    wire inf;
    assign inf = max_a & (m_zero_a);
    assign pos_inf = inf & (~a[31]);
    assign neg_inf = inf & (a[31]);

    wire exp_zero;
    comp_Nbits #(8) exp_min_a( 
        .A(exp_A), 
        .B(8'b00000000), 
        .AEQB(exp_zero)
    );

    assign zero = exp_zero & m_zero_a;


endmodule

module full_adder_Nbits #( parameter N= 8) (
    input [N-1:0] a, 
    input [N-1:0] b, 
    input cin,
    output [N-1:0] sum, 
    output cout     
);

    wire [N:0] carries;
    assign carries[0] = cin;
    genvar i;
    generate
        for (i = 0; i<N; i = i+1) begin : gen_sum
            full_adder somador(
                .a(a[i]),
                .b(b[i]),
                .cin(carries[i]),
                .sum(sum[i]),
                .cout(carries[i+1])
            );
        end
    endgenerate
    assign cout = carries[N];
endmodule

module full_adder (
    input wire a ,
    input wire b ,
    input wire cin ,
    output wire sum ,
    output wire cout
);

    assign sum = (a ^ b) ^ cin;
    assign cout = (a & cin) | (a & b) | (b & cin);

endmodule


module full_subtractor_nbit #(
parameter N = 8
) (
input [N-1:0] a, // minuendo
input [N-1:0] b, // subtraendo
input bin, // borrow in
output [N-1:0] diff, // diferenca
output bout // borrow out
);

//criando N bins e bouts com o borrow
wire [N:0] borrow_aux;
assign borrow_aux[0] = bin;

genvar i;
generate
    for (i = 0;i<N ;i = i+1 ) begin : gen_subtractor
    full_subtractor_1bit subtractorInstance(
        .a(a[i]),
        .b(b[i]),
        .bin(borrow_aux[i]),
        .diff(diff[i]),
        .bout(borrow_aux[i+1])
    );
    end
    
endgenerate
assign bout = borrow_aux[N];

endmodule



module full_subtractor_1bit (
input a, // minuendo
input b, // subtraendo
input bin, // borrow in
output diff, // diferenca
output bout // borrow out
);

wire xor_ab = a ^b; 
assign diff = ( xor_ab )  ^ bin;
assign bout = (~a & b)  | ((~xor_ab) & bin);

    
endmodule

/*
    Este módulo implementa um registrador de deslocamento para esquerda
    e para a direita. Contém uma entrada serial.
*/

module shifter #( parameter N = 8 )(
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire shift_left,
    input  wire shift_right,
    input wire serial_in,
    input  wire [N-1:0] data_in,
    output reg [N-1:0] data_out,
    output reg [2:0] guards
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= {N{1'b0}};
        guards <= 3'b000;
    end else if (load) begin
        guards <= 3'b000;
        data_out <= data_in;
    end else if (shift_left) begin
        data_out <= {data_out[N-2:0], 1'b0}; 
    end else if (shift_right) begin
        guards[2] <= data_out[0];
        guards[1] <= data_out[2];
        guards[0] <= guards[0] | guards[1];
        data_out <= {serial_in,data_out[N-1:1]}; 
    end
end
endmodule

module small_alu #(parameter N = 8) (
    input  wire [N-1:0] A,
    input  wire [N-1:0] B,
    output wire [N-1:0] diff,
    output wire       A_gt_B,
    output wire       A_eq_B,
    output wire       A_lt_B
);

    wire [N-1:0] max_val;
    wire [N-1:0] min_val;
    wire bout_ignorado;

    comp_Nbits #(.N(N)) dut (
        .A(A),
        .B(B),
        .AGTB(A_gt_B),
        .AEQB(A_eq_B),
        .ALTB(A_lt_B)
    );

    assign max_val = A_lt_B ? B : A;
    assign min_val = A_lt_B ? A : B;

    full_subtractor_nbit #(.N(N)) subtrator_absoluto (
        .a(max_val),
        .b(min_val),
        .bin(1'b0),
        .diff(diff),
        .bout(bout_ignorado)
    );

endmodule
