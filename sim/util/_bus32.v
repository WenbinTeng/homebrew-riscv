// `include "./include/_74x245.v"

module _bus32 #(
    parameter N = 8
)(
    input [N-1:0] g,
    input [32*N-1:0] a,
    output [31:0] y
);

    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                _74x245 u_74x245 (
                    g[i],
                    a[i*32+j*8+7:i*32+j*8],
                    y[j*8+7:j*8]
                );
            end
        end
    endgenerate

endmodule