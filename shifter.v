/*
    Este módulo implementa um registrador de deslocamento para esquerda
    e para a direita. Contém uma entrada serial.
*/

module shifter #( parameter N = 8 )(
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire shift_left,
    input  wire shift_right,
    input wire serial_in,
    input  wire [N-1:0] data_in,
    output reg [N-1:0] data_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= {N{1'b0}};
    end else if (load) begin
        data_out <= data_in;
    end else if (shift_left) begin
        data_out <= {data_out[N-2:0], 1'b0}; 
    end else if (shift_right) begin
        data_out <= {serial_in,data_out[N-1:1]}; 
    end
end
endmodule