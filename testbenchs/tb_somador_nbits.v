module tb_full_adder_nbits ();
    reg [7:0]A;
    reg [7:0]B;
    reg cin;
    wire [7:0] sum;
    wire cout;
    reg [7:0]sum_exp;
    reg cout_esp;
    wire check = (sum == sum_exp ) && (cout == cout_esp);

    full_adder_Nbits #(8) dut (
        .a(A),
        .b(B),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin
        $display("INICIO DOS TESTES:");
        $monitor("Tempo=%0t | A=%b B=%b Cin=%b | SUM=%b cout=%b | Esp: D=%b Cout=%b | Aprovado: %b", 
                $time, A, B, cin, sum, cout, sum_exp, cout_esp,
                check);
        sum_exp = 0; cout_esp = 0;
        A = 0; B = 0; cin = 0; #10;
        
        sum_exp = 8'b01011011; cout_esp = 0;
        A = 8'b00011000; B = 8'b01000011; cin = 0; #10;
        
        sum_exp = 8'b11111111; cout_esp = 0;
        A = 8'b11111110; B = 8'b00000001; cin = 0; #10;
        
        sum_exp = 8'b00010000; cout_esp = 0;
        A = 8'b00001111; B = 0; cin = 1; #10;

                
        sum_exp = 8'b00000001; cout_esp = 1;
        A = 8'b11111111; B = 8'b00000001; cin = 1; #10;
        
        sum_exp = 8'd255; cout_esp = 1;
        A = 8'd255; B = 8'd255; cin = 8'd1; #10;
        

    end

endmodule