module tb_small_alu ();
    reg [7:0] A;
    reg [7:0] B;
    reg [7:0] diff_esp;

    wire [7:0] Diff;
    wire AGTB;
    wire ALTB;
    wire AEQB;
    reg agtn_esp, aeqb_esp, altb_esp;

    wire check = (AGTB == agtn_esp)&& (ALTB == altb_esp) && (AEQB == aeqb_esp);

    small_alu dut(
        .A(A),
        .B(B),
        .diff(Diff),
        .A_gt_B(AGTB),
        .A_eq_B(AEQB),
        .A_lt_B(ALTB)
    );
     
    initial begin
        $display("INICIO DOS TESTES: |A - B| = | DIFF | \n");
        
         $monitor("Tempo=%0t | %b - %b = Diff:%b |\t A>B(%b)  A=B(%b)  A<B(%b) Aprovado: %b", 
                 $time, A, B, Diff, AGTB, AEQB, ALTB, check);
        
        
        A = 0; B = 0; diff_esp = 0;
        agtn_esp = 0;
        altb_esp = 0;
        aeqb_esp = 1;

        #10;
        
        A = 8'd3; B = 8'd0; diff_esp = 8'd3;
        agtn_esp = 1;
        altb_esp = 0;
        aeqb_esp = 0;

        #10;

        A = 8'd200; B = 8'd236; diff_esp = 8'd36  ;
        agtn_esp = 0;
        altb_esp = 1;
        aeqb_esp = 0;

        #10;
    end


endmodule