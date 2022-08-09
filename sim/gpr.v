// `include "./include/_74x245.v"
// `include "./include/_74x377.v"
// `include "./include/_cy7c1021.v"
// `include "./util/_reg32.v"

module gpr(
    input           aclk,   // simulate async write
    input           clk,
    input           gpr_we,
    input   [ 4:0]  gpr_ra,
    input   [ 4:0]  gpr_rb,
    input   [ 4:0]  gpr_rd,
    input   [31:0]  gpr_di,
    input   [31:0]  csr_rdata,
    output  [31:0]  qa,
    output  [31:0]  qb
);

    wire [4:0] _ra;
    wire [2:0] _ra_dontcare;
    wire [4:0] _rb;
    wire [2:0] _rb_dontcare;
    wire [31:0] di;

    _bus32 #(2) u_bus32_0 (
        {1'b0,      1'b0     },
        {gpr_di,    csr_rdata},
        di
    );

    _74x245 u_74x245_a0 (
        ~clk,
        {3'b0, gpr_ra},
        {_ra_dontcare, _ra}
    );
    _74x245 u_74x245_a1 (
        clk,
        {3'b0, gpr_rd},
        {_ra_dontcare, _ra}
    );
    _74x245 u_74x245_b0 (
        ~clk,
        {3'b0, gpr_rb},
        {_rb_dontcare, _rb}
    );
    _74x245 u_74x245_b1 (
        clk,
        {3'b0, gpr_rd},
        {_rb_dontcare, _rb}
    );

    wire        buffer_we;
    wire [30:0] buffer_we_dontcare;

    _reg32 u_reg32_0 (
        clk,
        ~clk,
        {31'b0, gpr_we},
        {buffer_we_dontcare, buffer_we}
    );
    
    wire [31:0] buffer_di;

    _reg32 u_reg32_1 (
        clk,
        ~clk,
        di,
        buffer_di
    );

    wire [31:0] apin = buffer_di;
    wire [31:0] bpin = buffer_di;

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