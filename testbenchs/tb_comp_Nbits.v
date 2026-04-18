
module tb_agtb_n;
    reg [8-1:0] A, B;
    reg AGTBI;
    reg AEQBI;
    reg esperado_AEQBO;
    reg esperado_AGTBO;
    reg esperado_ALTBO;
    wire AGTBO;
    wire AEQBO;
    wire ALTBO;
    
    // Instanciar o somador
    comp_Nbits comp (
        .A(A),
        .B(B),
        .AGTB(AGTBO),
        .AEQB(AEQBO),
        .ALTB(ALTBO)
    );
    
    initial begin
        
        

        // 1) A == B
        A = 8'b00000000;
        B = 8'b00000000;
        esperado_AGTBO = 0;
        esperado_AEQBO = 1;
        esperado_ALTBO = 0 ;
        #1000;

        $display("1) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");
        A = 8'b11111111;
        B = 8'b11111111;
        esperado_AGTBO = 0;
        esperado_AEQBO = 1;
        esperado_ALTBO = 0;
        #1000;

        $display("2) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("2) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");
        // A> B
        A = 8'b10110000;
        B = 8'b01000000;
        esperado_AGTBO = 1;
        esperado_AEQBO = 0;
        esperado_ALTBO = 0;
        #1000;

        $display("3) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("3) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");
        
        // 2) A > B
        A = 8'b10000010;
        B = 8'b01000010;
        
        esperado_AGTBO = 1;
        esperado_AEQBO = 0;
        esperado_ALTBO = 0;
        #1000;

        $display("4) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("4) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");

         // 1) A < B
        A = 8'b00111100;
        B = 8'b01001100;
        
        esperado_AGTBO = 0;
        esperado_AEQBO = 0;
        esperado_ALTBO = 1;
        #1000;

        $display("5) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("5) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");

          // 1) A < B
        A = 8'b0111100;
        B = 8'b0111110;
        
        esperado_AGTBO = 0;
        esperado_AEQBO = 0;
        esperado_ALTBO = 1;
        #1000;

        $display("5) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("5) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");

          // 1) A > B
        A = 8'b01111100;
        B = 8'b01001100;
        
        esperado_AGTBO = 1;
        esperado_AEQBO = 0;
        esperado_ALTBO = 0;
        #1000;

        $display("5) A=%b | B=%b | %s", A, B, (esperado_AGTBO == AGTBO ) ? "OK" : "ERRO");
        $display("5) A=%b | B=%b | %s", A, B, (esperado_AEQBO == AEQBO ) ? "OK" : "ERRO");
        $display("1) A=%b | B=%b | %s", A, B, (esperado_ALTBO == ALTBO ) ? "OK" : "ERRO");


        $finish;
    end
    

endmodule