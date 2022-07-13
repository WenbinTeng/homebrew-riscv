module _cy7c1021 (
    input clk,      // Clock Signal
    input ce,       // Chip Enable (Active LOW)
    input oe,       // Output Enable (Active LOW)
    input we,       // Write Enable (Active LOW)
    input bhe,      // Byte High Enable (Active LOW)
    input ble,      // Byte Low Enable (Active LOW)
    input [15:0] a, // Address
    inout [15:0] io // Data Input/Output
);
    reg [7:0] mem_bh [65535:0];
    reg [7:0] mem_bl [65535:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            mem_bh[i] = 'h0;
            mem_bl[i] = 'h0;
        end
    end

    always @(posedge clk) begin
        if (!ce & !we) begin
            if (!bhe)
                mem_bh[a] <= io[15:8];
            if (!ble)
                mem_bl[a] <= io[ 7:0];
        end
    end

    assign io = !ce & !oe & we ? {!bhe ? mem_bh[a] : 8'bz, !ble ? mem_bl[a] : 8'bz} : 16'bz;

endmodule