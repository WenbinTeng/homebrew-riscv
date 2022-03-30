module _hm62256b (
    input clk,
    input [14:0] a, // Address
    input ce,       // Chip Enable (Active LOW)
    input oe,       // Output Enable (Active LOW)
    input we,       // Write Enable (Active LOW)
    inout [7:0] io  // Data Input/Output
);

    reg [7:0] mem [32765:0];

    initial begin
        
    end

    always @(posedge clk) begin
        if (!we) begin
            mem[a] <= io;
        end
    end

    assign io = !ce & !oe & we ? mem[a] : 8'bzzzzzzzz;
    
endmodule