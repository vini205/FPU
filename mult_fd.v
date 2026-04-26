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
//------------------------------------------------------------------//

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

// ========================================================================
// CORREÇÃO 1: Largura do Barramento (O Bug do 00000100)
// ========================================================================
// Extração correta dos 24 bits inteiros (incluindo o '1' implícito)
wire [23:0] full_mantissa = (mult_reg[47]) ? mult_reg[47:24] : mult_reg[46:23];
wire [22:0] m_normalized = full_mantissa[22:0];

// ========================================================================
// CORREÇÃO 2: Preparação de Expoentes e Subnormais
// ========================================================================
// Se a entrada for um subnormal puro (expoente 0), a matemática exige usar 1
wire [7:0] eff_exp_a = (~|a[30:23]) ? 8'd1 : a[30:23];
wire [7:0] eff_exp_b = (~|b[30:23]) ? 8'd1 : b[30:23];

wire [7:0] e_sum;
wire cout_e;
full_adder_Nbits #(8) adder_e(
    .a(eff_exp_a), 
    .b(eff_exp_b), 
    .cin(mult_reg[47]), // Soma 1 se a mantissa transbordou à esquerda
    .sum(e_sum),
    .cout(cout_e)
);

wire [8:0] e_sub;
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

// A matemática mágica do Complemento de 2: 
// {bout_e, e_sub} atua como extensão de sinal. Calculamos: Shift = 1 - (E_calculado)
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

// Empurra a fração para a direita criando o underflow gradual perfeito
wire shift_out_of_bounds = shift_limit0 | shift_limit1;
wire [23:0] denorm_mantissa = shift_out_of_bounds ? 24'd0 : (full_mantissa >> denorm_shift);

// ========================================================================
// FLAGS & EMPACOTAMENTO FINAL
// ========================================================================
wire f_overflow_internal = (e_sub[8] | &e_sub[7:0]) & ~exeption & ~bout_e;
assign f_overflow = f_overflow_internal;

assign f_underflow = is_subnormal & ~exeption; 

wire has_remnants = |mult_reg[22:0]; 
assign f_inexact = (has_remnants | f_overflow_internal | f_underflow) & ~exeption;

wire [7:0] final_exp  = is_subnormal ? 8'h00 : e_sub[7:0];
wire [22:0] final_frac = is_subnormal ? denorm_mantissa[22:0] : m_normalized;
wire sign_out = a[31] ^ b[31];

assign c = (exeption)            ? c_exeption : 
           (f_overflow_internal) ? {sign_out, 8'hFF, 23'd0} : 
                                   {sign_out, final_exp, final_frac};

endmodule
/* 
wire [23:0] m_normalized;
assign m_normalized = (mult_reg[47]) ? (mult_reg[46:24]) : (mult_reg[45:23]);

wire [7:0]e_sum;
wire cout_e;
full_adder_Nbits #(8) adder_e(
    .a(a[30:23]), 
    .b(b[30:23]), 
    .cin(mult_reg[47]),
    .sum(e_sum),
    .cout(cout_e)
);
wire [8:0]e_sub;
wire bout_e;
full_subtractor_nbit #(9) sub(
.a({cout_e, e_sum}), // minuendo
.b(9'b00111_1111), // subtraendo
.bin(1'b0), // borrow in
.diff(e_sub), // diferenca
.bout(bout_e) // borrow out
);

assign f_underflow = bout_e & ~exeption;
assign f_overflow = (e_sub[8] | &e_sub[7:0])& ~exeption;
assign f_inexact = (|(mult_reg[22:0]) | (mult_reg[23]&mult_reg[47]) )& ~exeption | f_overflow;

assign c = (exeption) ? (c_exeption) : (f_overflow) ? ({a[31]^b[31], 31'h7f800000}) : (f_underflow) ? ({a[31]^b[31], 8'h00, m_normalized}) : ({a[31]^b[31], e_sub[7:0], m_normalized});

endmodule */