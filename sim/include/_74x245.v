module _74x245 (
    input oe,  // Output Enable (Active LOW)
    input [7:0] a,  // Data Inputs
    output [7:0] y  // Data Outputs
);

    assign y = oe ? 8'bz : a;

endmodule