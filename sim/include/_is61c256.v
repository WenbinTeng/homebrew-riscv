module _is61c256 (
    input clk,      // Clock Signal
    input ce,       // Chip Enable (Active LOW)
    input oe,       // Output Enable (Active LOW)
    input we,       // Write Enable (Active LOW)
    input [14:0] a, // Address
    inout [ 7:0] io // Data Input/Output
);
    reg [7:0] mem [32765:0];

    always @(posedge clk) begin
        if (~ce & ~we) begin
            mem[a] <= io;
        end
    end

    assign io = ~ce & ~oe & we ? mem[a] : 8'bz;

endmodule