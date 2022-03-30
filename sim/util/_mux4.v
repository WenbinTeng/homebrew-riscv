module _mux4 (
    input [3:0] a,
    input [3:0] b,
    input s,
    output [3:0] f
);

    _74x157 u_74x157 (
        s,
        1'b0,
        a,
        b,
        f
    );

endmodule