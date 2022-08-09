module _74x574 (
    input oe,       // Output Enable (Active LOW)
    input clk,      // Clock Signal
    input [7:0] d,  // Input Data
    output [7:0] q  // Output Data
);

    reg [7:0] r;

    always @(posedge clk) begin
        r <= d;
    end

    assign q = oe ? 8'bz : r;
    
endmodule