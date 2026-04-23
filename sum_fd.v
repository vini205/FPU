module sum_fd (
    input wire [31:0] a,
    input wire[31:0] b,
    input wire clk,
    input wire rst;
    input wire load_shift;
    input wire shift;

    output wire sum;
    output wire cout_sum;
    output wire overflow;
    output wire underflow;
    output wire [31:0] sum;
    output wire count_over;
    
);
    assign wire sign_A = a[31];
    assign wire exp_A = a[30:23];
    assign wire [23:0] mant_A = {1'b1,a[22:0]};

    assign wire exp_B = b[30:23];
    assign wire sign_B = b[31];
    assign wire [23:0] mant_B = {1'b1,b[22:0]};

    assign wire [7:0] diff_exp;
    assign wire choose_exp;
    assign wire [7:0] larger_exp ;
    assign wire [7:0] smaller_exp;
    assign wire [23:0] larger_mant;
    assign wire [23:0] smaller_mant;

    // Verificando os expoentes
    small_alu comparador_exp (
        .A(exp_A),
        .B(exp_B),
        .diff(diff_exp),
        .A_gt_B(choose_exp),
    );
    //Vendo qual é o maior
    larger_exp = choose_exp ? exp_A: exp_B;
    larger_mant = choose_exp ? mant_A: mant_B;
    assign sign_final = choose_exp ? sign_A: sign_B;
    // O sinal do resultado final é o sinal do maior valor

    smaller_exp = choose_exp ? exp_B:exp_A;
    smaller_mant = choose_exp ? mant_B: mant_A;

    // fazendo shift

    down_counter contador(
        .clk(clk),
        .rst(rst),
        .load(load_shift),
        .start(shifter),
        .data_in(diff_exp),// A diferença entre as mantissas é o quanto devo mover
        .count(),
        .is_over(count_over)
    );

    wire [23:0] shifted_mant ;
    shifter # (24) rightShift(
        .clk(clk),
        .rst(rst),
        .load(load_shift),
        .shift_right(shift),
        .serial_in(1'b0),
        .data_in(smaller_mant),
        .data_out(shifted_mant)
    );
    
    wire is_sub = sign_A ^sign_B;// Para fazer a subtração
    shifted_mant = is_sub ? ~shifted_mant:shifted_mant;
    //Caso for negativo
    wire [23:0] somaMant;
    //Pode haver um carry out

    full_adder_Nbits #(24) somaddorMant(
        .a(larger_mant),
        .b(shifted_mant),
        .cin(is_sub),//Caso for subtração colocar em comp. de 2
        .sum(somaMant),
        .cout(cout_sum)
    );

    
    assign mantissaFinal = cout ? somaMant[23:1] :somaMant[22:0];
    
endmodule