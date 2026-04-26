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

assign f_inv_op = sNaNa | sNaNb;

wire exeptiona, exeptionb;
assign exeptiona = zeroa | sNaNa | qNaNa | pos_infa | neg_infa;
assign exeptionb = zerob | sNaNb | qNaNb | pos_infb | neg_infb;
assign exeption = exeptiona | exeptionb;

wire zero = (zeroa &  ~exeptionb) | (zerob & ~exeptiona);

wire infa, infb; 
assign infa = pos_infa | neg_infa;
assign infb = pos_infb | neg_infb;
wire inf, pos_inf, neg_inf;
assign inf = (infa & ~exeptionb) | (infb & ~exeptiona) | (infa & infb);
assign pos_inf = inf &  ~(a[31]^b[31]);
assign neg_inf = inf & (a[31] ^b[31]);

wire [31:0]c_qNaN;
assign c_qNaN = (zero & inf) ? (32'h7FC00000) : (sNaNa) ? ({a[31:23], 1'b1, a[21:0]}) : (sNaNb) ? ({b[31:23], 1'b1,b[21:0]}) : (qNaNa) ? a : (qNaNb) ? (b) : 32'bz;




wire [31:0]c_exeption;
parameter zeropadrao = 32'h00000000;
parameter pos_infpadrao = 32'h7f800000;
parameter neg_infpadrao = 32'hff800000;
assign c_exeption = (zero) ? (zeropadrao) : (pos_inf) ? (pos_infpadrao) : (neg_inf) ? (neg_infpadrao) : (c_qNaN);
//------------------------------------------------------------------//

wire [45:0]c_shift;
shifter #(46) shift_a(
    .clk(~clk),
    .rst(1'b0),
    .load(load_shift),
    .shift_left(1'b1),
    .shift_right(1'b0),
    .serial_in(1'b0),
    .data_in({23'b0, a[22:0]}),
    .data_out(c_shift)
);

wire [22:0]b_shift;
shifter #(23) shift_b(
    .clk(~clk),
    .rst(1'b0),
    .load(load_shift),
    .shift_left(1'b0),
    .shift_right(1'b1),
    .serial_in(1'b0),
    .data_in(b[22:0]),
    .data_out(b_shift)
);

wire [45:0]s_sum;
full_adder_Nbits #(46) adder_m(
    .a(s_reg), 
    .b((c_shift & b_shift[0])), 
    .cin(1'b0),
    .sum(s_sum)    
);

reg [45:0]s_reg;
always @(posedge clk or load_shift) begin
    if(load_shift) s_reg = s_sum;
    else s_reg = 46'b0;
end

wire m_normalized;
assign m_normalized = (s_reg[45]) ? (s_reg[45:23]) : (s_reg[44:22]);

wire [7:0]e_sum;
wire cout_e;
full_adder_Nbits #(8) adder_e(
    .a(a[30:23]), 
    .b(b[30:23]), 
    .cin(s_reg[45]),
    .sum(e_sum),
    .cout(cout_e)
);
wire e_sub;
full_subtractor_nbit #(8) sub(
.a(e_sum), // minuendo
input [N-1:0] b, // subtraendo
input bin, // borrow in
output [N-1:0] diff, // diferenca
output bout // borrow out
);


assign c = (exeption) ? (c_exeption) : s_reg;

endmodule