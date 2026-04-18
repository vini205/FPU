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