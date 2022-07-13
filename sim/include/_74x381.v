module _74x381 (
    input [3:0] a,  // A Operand Inputs
    input [3:0] b,  // B Operand Inputs
    input [2:0] s,  // Function Select Inputs
    input cn,       // Carry Input
    output gn,      // Carry Generate Output (Active LOW)
    output pn,      // Carry Propagate Output (Active LOW)
    output [3:0] f  // Function Outputs
);

    reg [4:0] ft;
    reg gt;
    reg pt;

    always @(*) begin
        case (s)
            3'b000: ft = 4'b0000;
            3'b001: ft = b - a - cn;
            3'b010: ft = a - b - cn;
            3'b011: ft = a + b + cn;
            3'b100: ft = a ^ b;
            3'b101: ft = a | b;
            3'b110: ft = a & b;
            3'b111: ft = 4'b1111;
        endcase
    end

    assign f = ft;

    // for simulation
    always @(*) begin
        case (s)
            3'b001, 3'b010: gt = ft >= 5'b10001;
            3'b011: gt = ft >= 5'b10000;
            default: gt = 0;
        endcase
    end
    assign gn = ~gt;

    // for simulation
    always @(*) begin
        case (s)
            3'b001, 3'b010: pt = ft >= 5'b10000;
            3'b011: pt = ft >= 5'b01111;
            default: pt = 0;
        endcase
    end
    assign pn = ~pt;

endmodule