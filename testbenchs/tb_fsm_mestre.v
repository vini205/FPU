module fsm_mestre_tb();
    reg start;   //indica para a maquina que pode comecar
    reg [2:0]op;  //operacao a ser feita
    reg clk;      //clock do sistema
    reg stop;     //sinal interno que diz que acabou coma as contas
    wire [2:0]addr;    //manda o endereco (da operacao) que sera utilizado
    wire busy;    //diz se ainda esta calculando
    wire done;     //inverso de ibusy
    reg reset;

    fsm_mestre dut(
        .start(start),    //indica para a maquina que pode comecar
        .op(op),  //operacao a ser feita
        .clk(clk),      //clock do sistema
        .reset(reset),
        .stop(stop),     //sinal interno que diz que acabou coma as contas
        .addr(addr),    //manda o endereco (da operacao) que sera utilizado
        .busy(busy),    //diz se ainda esta calculando
        .done(done)     //inverso de ibusy
    );

    always #5 clk = ~clk;

    //expected
    reg [2:0]eaddr;
    reg ebusy;
    reg edone;

    initial begin
        $dumpfile("fsm_mestre_tb.vcd");
        $dumpvars(0, fsm_mestre_tb);

        reset =1;
        #10

        $monitor("Tempo=%0t | start=%b op=%b stop=%b addr=%b busy=%b done=%b", $time, start, op, stop, addr, busy, done);
        clk=0;
        reset=0;
        ebusy=1'b0;
        edone =1'b0;
        #20
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end
        start=0;
        #20
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end
        op=3'b101;
        #20
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end
        start=1;
        ebusy=1;
        eaddr=3'b101;
        #10
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end
        stop=0;
        #10
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end
        stop = 1;
        ebusy=0;
        edone =1'b1;
        #10
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end
        stop = 0;
        op = 3'b000;
        eaddr = 3'b000;
        ebusy = 1;
        edone =0;
        #10

        ebusy=0;
        start=0;
        edone =1;
        #1000
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end

        //testando reset
        reset=1;
        start=1;
        edone = 0;
        #20
        if(eaddr === addr && edone==done && ebusy==busy) begin
            $display("PASS");
        end else begin
            $display("FAIL: eaddr=%b, ebusy=%b, edone=%b", eaddr, ebusy, edone);
        end

        #20
        $finish;
    end

endmodule