module _mux8(
    input [7:0] a,
    input [7:0] b,
    input s,
    output [7:0] f
);

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
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