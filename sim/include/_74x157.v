module _74x157 (
    input s,        // Common Select Input
    input e,        // Enable (Active LOW) Input
    input [3:0] a,  // Data Inputs from Source 0
    input [3:0] b,  // Data Inputs from Source 1
    output [3:0] f  // Multiplexer Outputs
);

    assign f = e ? 'h0 : s ? b : a;

endmodule