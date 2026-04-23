// Módulo pra um contador 
module down_counter #(parameter N = 8) (
    input wire clk,
    input wire rst,
    input wire load,
    input wire start, 
    input wire [N-1:0] data_in, //o núemro de clks
    output reg [N-1:0] count,
    output wire is_over // acabou
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {N{1'b0}};
        end else if (load) begin
            count <= data_in;
        end else if (start && count > 0) begin
            count <= count - 1'b1;
        end
    end

    assign is_over = (count == {N{1'b0}});

endmodule