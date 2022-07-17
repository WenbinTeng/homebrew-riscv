`include "./include/_74x283.v"

module _add32(
    input [31:0] a,
    input [31:0] b,
    output [31:0] s
);

    wire [8:0] c;

    assign c[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            _74x283 u_74x283 (
                a[i*4+3:i*4],
                b[i*4+3:i*4],
                c[i],
                s[i*4+3:i*4],
                c[i+1]
            );
        end
    endgenerate

endmodule