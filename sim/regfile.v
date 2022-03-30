module regfile(
    input clk,
    input [4:0] ra,
    input [4:0] rb,
    input we,
    input [4:0] rd,
    input [31:0] di,
    inout [31:0] qa,
    inout [31:0] qb
);

    wire [31:0] sel_a;
    wire [31:0] sel_b;
    wire [31:0] sel_d;

    _5dec32 u_5dec32_0 (ra, sel_a);
    _5dec32 u_5dec32_1 (rb, sel_b);
    _5dec32 u_5dec32_2 (rd, sel_d);

    genvar i, j;
    generate
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                _74x574 u_74x574 (
                    sel_a[i],
                    clk & we & ~sel_d[i],
                    di[j*8+7:j*8],
                    qa[j*8+7:j*8]
                );
            end
            for (j = 0; j < 4; j = j + 1) begin
                _74x574 u_74x574 (
                    sel_b[i],
                    clk & we & ~sel_d[i],
                    di[j*8+7:j*8],
                    qb[j*8+7:j*8]
                );
            end
        end
    endgenerate

endmodule