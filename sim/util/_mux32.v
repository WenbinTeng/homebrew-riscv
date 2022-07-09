// `include "../include/_74x157.v"

module _mux32(
    input [31:0] a,
    input [31:0] b,
    input s,
    output [31:0] f
);

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            _74x157 u_74x157 (
                s,
                1'b0,
                a[i*4+3:i*4],
                b[i*4+3:i*4],
                f[i*4+3:i*4]
            );
        end
    endgenerate

endmodule