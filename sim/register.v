`include "./include/_74x244.v"
`include "./include/_74x574.v"
`include "./include/_cy7c1021.v"
`include "./util/_reg32.v"

module register(
    input           aclk,   // simulate async write
    input           clk,
    input           we,
    input   [ 4:0]  ra,
    input   [ 4:0]  rb,
    input   [ 4:0]  rd,
    input   [31:0]  di,
    output  [31:0]  qa,
    output  [31:0]  qb
);

    wire [4:0] _ra;
    wire [2:0] _ra_dontcare;
    wire [4:0] _rb;
    wire [2:0] _rb_dontcare;

    _74x244 u_74x244_a0 (
        {~clk, ~clk},
        {3'b0, ra},
        {_ra_dontcare, _ra}
    );
    _74x244 u_74x244_a1 (
        {clk, clk},
        {3'b0, rd},
        {_ra_dontcare, _ra}
    );
    _74x244 u_74x244_b0 (
        {~clk, ~clk},
        {3'b0, rb},
        {_rb_dontcare, _rb}
    );
    _74x244 u_74x244_b1 (
        {clk, clk},
        {3'b0, rd},
        {_rb_dontcare, _rb}
    );

    wire       buffer_we;
    wire [6:0] buffer_we_dontcare;

    _74x574 u_74x574 (
        1'b0,
        ~clk,
        {7'b0, we},
        {buffer_we_dontcare, buffer_we}
    );
    
    wire [31:0] buffer_di;

    _reg32 u_reg32 (
        1'b0,
        ~clk,
        di,
        buffer_di
    );

    wire [31:0] apin = ~clk ? buffer_di : 'bz;
    wire [31:0] bpin = ~clk ? buffer_di : 'bz;

    assign qa = _ra == 5'b0 ? 32'b0 : apin;
    assign qb = _rb == 5'b0 ? 32'b0 : bpin;

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021_a (
                aclk,
                1'b0,
                ~clk,
                buffer_we|clk,
                1'b0,
                1'b0,
                {11'b0, _ra[4:0]},
                apin[i*16+15:i*16]
            );
            _cy7c1021 u_cy7c1021_b (
                aclk,
                1'b0,
                ~clk,
                buffer_we|clk,
                1'b0,
                1'b0,
                {11'b0, _rb[4:0]},
                bpin[i*16+15:i*16]
            );
        end
    endgenerate

endmodule