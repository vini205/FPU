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

