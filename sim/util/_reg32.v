// `include "./include/_74x574.v"

module _reg32 (
    input oe,
    input clk,
    input [31:0] d,
    output [31:0] q
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _74x574 u_74x574 (
                oe,
                clk,
                d[i*8+7:i*8],
                q[i*8+7:i*8]
            );
        end
    endgenerate
    
endmodule