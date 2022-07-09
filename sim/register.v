// `include "./include/_74x244.v"
// `include "./include/_74x574.v"
// `include "./include/_cy7c1021.v"

module register(
    input           clk,
    input           rst,
    input           we,
    input   [ 4:0]  ra,
    input   [ 4:0]  rb,
    input   [ 4:0]  rd,
    input   [31:0]  di,
    output  [31:0]  qa,
    output  [31:0]  qb
);

    wire [2:0] dontcare;
    wire [4:0] _ra;
    wire [4:0] _rb;

    _74x244 u_74x244_a0 (
        {~clk, ~clk},
        {3'b0, ra},
        {dontcare, _ra}
    );
    _74x244 u_74x244_a1 (
        {clk, clk},
        {3'b0, rd},
        {dontcare, _ra}
    );
    _74x244 u_74x244_b0 (
        {~clk, ~clk},
        {3'b0, rb},
        {dontcare, _rb}
    );
    _74x244 u_74x244_b1 (
        {clk, clk},
        {3'b0, rd},
        {dontcare, _rb}
    );

    wire [ 7:0] buffer_we;
    wire [31:0] buffer_di;

    _74x574 u_74x574 (
        1'b0,
        ~clk,
        {7'b0, we},
        buffer_we
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _74x574 u_74x574 (
                1'b0,
                ~clk,
                di[i*8+7:i*8],
                buffer_di[i*8+7:i*8]
            );
        end
    endgenerate

    wire [31:0] apin =  ~clk ? buffer_di : 'bz;
    wire [31:0] bpin =  ~clk ? buffer_di : 'bz;

    assign qa = apin;
    assign qb = bpin;

    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021_a (
                clk,
                1'b0,
                1'b0,
                buffer_we[0],
                1'b0,
                1'b0,
                {11'b0, _ra[4:0]},
                apin[i*16+15:i*16]
            );
            _cy7c1021 u_cy7c1021_b (
                clk,
                1'b0,
                1'b0,
                buffer_we[0],
                1'b0,
                1'b0,
                {11'b0, _rb[4:0]},
                bpin[i*16+15:i*16]
            );
        end
    endgenerate

endmodule