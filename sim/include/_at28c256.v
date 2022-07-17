module _at28c256 (
    input  ce,          // Chip Enable (Active LOW)
    input  oe,          // Output Enable (Active LOW)
    input  [14:0] a,    // Address
    output [ 7:0] io    // Data Input/Output
);

    reg [7:0] mem [32767:0];

    assign io = ~oe ? mem[a] : 8'bz;

    initial begin
        $readmemh("addi.coe", mem);
    end
    
endmodule