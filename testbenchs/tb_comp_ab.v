module tb_comp_ab ();

reg  [8:0] a ;
reg  [8:0] b;
reg agtb;
reg altb;
reg aeqb;

reg agtbe_esp;
reg altbe_esp;
reg aeqbe_esp;

wire aproved = !(agtb ^ agtbe_esp) || !(altb ^ altbe_esp) || !( aeqb ^aeqbe_esp );

comp_ab dut(
    .A(a),
    .B(b),
    .A_gt_B(atgb),
    .A_lt_B(altb),
    .A_eq_B(aeqb)
);
initial begin
$display("A \t B \t A_eq_B \t A_lt_b \t A_gt_B \t APROVED:");
$monitor("%b \t %b \t %b \t    %b   \t %b \t %b",
                 a,b,aeqb, altb,agtb,aproved);

#10
a = 8'b0001010;
b = 8'b0001011;
aeqbe_esp = 0;
agtbe_esp = 0;
altbe_esp = 1;

#10

a = 8'b0001111;
b = 8'b0001111;
aeqbe_esp = 0;
agtbe_esp = 1;
altbe_esp = 0;

#10

a = 8'b0101111;
b = 8'b0001111;
aeqbe_esp = 1;
agtbe_esp = 0;
altbe_esp = 0;

end


endmodule