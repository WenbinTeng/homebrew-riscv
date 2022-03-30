module _74x574(
    input oe,       // Output Enable (Active LOW)
    input cp,       // Clock
    input [7:0] d,  // Data Inputs
    inout [7:0] q   // Data Outputs
);

    reg [7:0] r;

    always @(posedge cp) begin
        r <= d;
    end

    assign q = oe ? 8'bzzzzzzzz : r;

endmodule