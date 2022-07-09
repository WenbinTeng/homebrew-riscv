// `include "../include/_74x377.v"

module _reg32 (
    input e,
    input clk,
    input [31:0] d,
    output [31:0] q
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _74x377 u_74x377 (
                e,
                clk,
                d[i*8+7:i*8],
                q[i*8+7:i*8]
            );
        end
    endgenerate
    
endmodule