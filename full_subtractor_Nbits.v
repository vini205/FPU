
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