`timescale 1ns/1ps
module shift_tb();
localparam WIDTH = 8;
    reg clk;
    reg rst;
    reg load;
    reg shift_left;
    reg shift_right;
    reg [WIDTH-1:0]datain; 
    reg serial_in = 1;
    wire [WIDTH-1:0]dataout;

shifter #(WIDTH) dut(
    .clk(clk),
    .rst(rst),
    .load(load),
    .shift_left(shift_left),
    .shift_right(shift_right),
    .serial_in(serial_in),
    .data_in(datain),
    .data_out(dataout)
);

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


 // Estímulos
initial begin
    $display("clk\t rst  load  shift_l shift_r    |datain \t dataout");
    $monitor(" %b\t%b\t%b\t%b\t%b      | %b \t    %b",
                 clk, rst, load, shift_left, shift_right, datain, dataout);
    rst = 1;
    load = 0;
    shift_left = 0;
    shift_right = 0;
    datain = 8'b00000000;
    #20;
    rst = 0;   // libera reset
    #10;
    // carrega dados
    datain = 8'b10101010;
    load = 1;
    #10;
    load = 0;
    #10;
    rst = 1;
    load = 0;
    datain = 8'b00000000;
    #20;
    rst = 0;   // libera reset
    #10;
    datain = 8'b10101010;
    load = 1;
    #10;
    load = 0;
    #10;
    shift_left = 1;
    #50;

    shift_left = 0;
    shift_right = 1;

    #80;
    $finish;
end



endmodule



