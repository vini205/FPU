module tb_subtractor ();
    reg [7:0]A;
    reg [7:0]B;
    reg bin;
    wire [7:0] diff;
    wire bout;
    reg [7:0]diff_esp;
    reg bout_esp;
    wire check = (diff == diff_esp ) && (bout == bout_esp);

    full_subtractor_nbit #(8) dut (
        .a(A),
        .b(B),
        .bin(bin),
        .diff(diff),
        .bout(bout)
    );

    initial begin
        $display("INICIO DOS TESTES:");
        $monitor("Tempo=%0t | A=%b B=%b Bin=%b | Diff=%b Bout=%b | Esp: D=%b B=%b | Aprovado: %b", 
                $time, A, B, bin, diff, bout, diff_esp, bout_esp,
                check);
        diff_esp = 0; bout_esp = 0;
        A = 0; B = 0; bin = 0; #10;
        
        diff_esp = 8'b11111111; bout_esp = 1;
        A = 0; B = 0; bin = 1; #10;
        
        diff_esp = 8'b11111111; bout_esp = 1;
        A = 8'b00000000; B = 8'b00000001; bin = 0; #10;
        
        diff_esp = 8'b00001000; bout_esp = 0;
        A = 8'b00101100; B = 8'b00100011; bin = 1; #10;

                
        diff_esp = 8'b00001001; bout_esp = 0;
        A = 8'b00101100; B = 8'b00100011; bin = 0; #10;
        
        diff_esp = 8'd255; bout_esp = 1;
        A = 8'd254; B = 8'd255; bin = 0; #10;
        

    end

endmodule