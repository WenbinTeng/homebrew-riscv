module _at28c256 (
    input  ce,          // Chip Enable (Active LOW)
    input  oe,          // Output Enable (Active LOW)
    input  [14:0] a,    // Address
    output [ 7:0] io    // Data Input/Output
);

    reg [7:0] mem [15:0];

    assign io = mem[a[3:0]];

    initial begin
        mem[0] = 8'b0;
        mem[1] = 8'b0;
        mem[2] = 8'b0;
        mem[3] = 8'b0;
    end
    
endmodule