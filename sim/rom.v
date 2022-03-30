module rom (
    input   [31:0]  addr,
    output  [31:0]  inst
);

    wire [31:0] tdata;

    assign inst = tdata;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _at28c256 u_at28c256 (
                1'b0,
                addr[16:2],
                1'b0,
                1'b0,
                1'b1,
                tdata[i*8+7:i*8]
            );
        end
    endgenerate
    
endmodule