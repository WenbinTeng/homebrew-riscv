module _74x283(
    input [3:0] a,  // Operand A Inputs
    input [3:0] b,  // Operand B Inputs
    input c0,       // Carry Input
    output [3:0] s, // Sum Outputs
    output c4       // Carry Output
);

    assign {c4, s} = a + b + c0;

endmodule