// `include "./include/_74x138.v"

module _dec32(
    input [4:0] s,
    output [31:0] f
);

    wire [7:0] cs;

    _74x138 u_74x138_0 (
        {1'b0, s[4:3]},
        1'b1,
        1'b0,
        1'b0,
        cs
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _74x138 u_74x138 (
                s[2:0],
                1'b1,
                cs[i],
                cs[i],
                f[i*8+7:i*8]
            );
        end
    endgenerate

endmodule