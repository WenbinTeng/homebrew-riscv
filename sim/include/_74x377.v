module _74x377 (
    input g,        // Clock Enable (Active LOW)
    input clk,      // Clock Signal
    input [7:0] d,  // Input Data
    output [7:0] q  // Output Data
);

    reg [7:0] r;

    always @(posedge clk) begin
        if (!g) begin
            r <= d;
        end
    end

    assign q = r;
    
endmodule