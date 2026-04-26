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

    wire [23:0] mant_A = {(exp_A != 8'h00), a[22:0]};

    wire sign_B = b[31];
    wire [7:0] exp_B = b[30:23];
    wire [23:0] mant_B = {(exp_B != 8'h00), b[22:0]};

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

    wire is_diff = (sign_A ^ sign_B) ^ is_sub;// Para saber se é uma soma ou subtração
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
    assign f_overflow = (exp_cout_round == 1) ;
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