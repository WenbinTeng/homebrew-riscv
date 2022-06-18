module _74x244 (
    input [1:0] g,  // Output Enable (Active LOW)
    input [7:0] a,  // Data Inputs
    output [7:0] y  // Data Outputs
);

    assign y = {g[1] ? 4'bzzzz : a[7:4], g[0] ? 4'bzzzz : a[3:0]};

endmodule