module _cy7c1021 (
    input clk,      // Clock Signal
    input ce,       // Chip Enable (Active LOW)
    input oe,       // Output Enable (Active LOW)
    input we,       // Write Enable (Active LOW)
    input ble,      // Byte Low Enable (Active LOW)
    input bhe,      // Byte High Enable (Active LOW)
    input [15:0] a, // Address
    inout [15:0] io // Data Input/Output
);
    reg [15:0] mem [65535:0];

    initial begin
        
    end

    always @(posedge clk) begin
        if (!we) begin
            if (!bhe)
                mem[a][15:8] <= io[15:8];
            if (!ble)
                mem[a][ 7:0] <= io[ 7:0];
        end
    end

    assign io = !ce & !oe & we ? {!bhe ? mem[a][15:8] : 8'bzzzzzzzz, !ble ? mem[a][7:0] : 8'bzzzzzzzz} : 16'bzzzzzzzzzzzzzzzz;

endmodule