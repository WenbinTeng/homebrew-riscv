module _mux16(
    input [15:0] a,
    input [15:0] b,
    input s,
    output [15:0] f
);

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
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