module _4dec16(
    input [3:0] a,
    output [15:0] d
);

    _74x154 u_74x154 (
        a[3:0],
        2'b0,
        d
    );

endmodule