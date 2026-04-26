module restoring_div #(
    parameter N = 26
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [N-1:0] dividend,
    input  wire [N-1:0] divisor,
    
    output wire [N-1:0] quotient,
    output wire [N-1:0] remainder,
    output wire done
);

    localparam IDLE  = 2'd0,
               SHIFT = 2'd1,
               SUB   = 2'd2,
               DONE  = 2'd3;

    reg [1:0] state;
    reg [$clog2(N+1)-1:0] count;

    reg [N:0] reg_A; // evita overflow na sub
    reg [N:0] reg_M;
    reg [N-1:0] reg_Q;

  
    wire [N:0] alu_result;
    
    // Instanciação do subtrator com N+1 bits de largura
    full_subtractor_nbit #(.N(N+1)) alu_sub (
        .a(reg_A),
        .b(reg_M),
        .bin(1'b0),
        .diff(alu_result),
        .bout() //ignora
    );

    wire alu_neg = alu_result[N]; 

    assign quotient  = reg_Q;
    assign remainder = reg_A[N-1:0];
    assign done = (state == DONE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            reg_A <= 0;
            reg_M <= 0;
            reg_Q <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        reg_A <= {2'b00, dividend[N-1:1]};
                        reg_Q <= {dividend[0], {(N-1){1'b0}}};
                        reg_M <= {1'b0, divisor};
                        
                        count <= N; 
                        state <= SHIFT;
                    end
                end
                
                SHIFT: begin
                    reg_A <= {reg_A[N-1:0], reg_Q[N-1]};
                    reg_Q <= {reg_Q[N-2:0], 1'b0};
                    state <= SUB;
                end
                
                SUB: begin
                    if (!alu_neg) begin
                        reg_A    <= alu_result;
                        reg_Q[0] <= 1'b1;
                    end
                    
                    if (count == 1) begin
                        state <= DONE;
                    end else begin
                        count <= count - 1; 
                        state <= SHIFT;
                    end
                end
                
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule