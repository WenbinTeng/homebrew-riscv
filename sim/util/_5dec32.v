module _5dec32(
    input [4:0] a,
    output [31:0] d
);

    _74x154 u_74x154_0 (
        a[3:0],
        {1'b0, a[4]},
        d[15:0]
    );

    _74x154 u_74x154_1 (
        a[3:0],
        {1'b0, ~a[4]},
        d[31:16]
    );

endmodule