module _mux4fromN #(
    parameter N = 8
)(
    input [N-1:0] g,
    input [4*N-1:0] a,
    output [3:0] y
);

    wire [3:0] dontcare;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin
            // reuse
            _74x244 u_74x244 (
                {1'b1, g[i]},
                {4'b0, a[i*4+3:i*4]},
                {dontcare, y}
            );
        end
    endgenerate

endmodule