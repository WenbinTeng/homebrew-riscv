// `include "./include/_74x245.v"
// `include "./include/_cy7c1021.v"
// `include "./util/_bus32.v"
// `include "./util/_reg32.v"

module GPR (
    input           aclk,       // Simulate async write clock signal
    input           clk,        // Clock signal
    input           gpr_we,     // Write enable
    input   [ 4:0]  gpr_ra,     // Read address of port a
    input   [ 4:0]  gpr_rb,     // Read address of port b
    input   [ 4:0]  gpr_rd,     // Write address
    input   [31:0]  gpr_di,     // Input data of ALU/MEM
    input   [31:0]  csr_rdata,  // Input data of CSR
    output  [31:0]  gpr_qa,     // Output data of port a
    output  [31:0]  gpr_qb      // Output data of port b
);

    wire [4:0] _ra;
    wire [2:0] _ra_dontcare;
    wire [4:0] _rb;
    wire [2:0] _rb_dontcare;
    wire [31:0] di;

    /* Combine two inputs through bus */
    _bus32 #(2) u_bus32_0 (
        {1'b0,      1'b0     },
        {gpr_di,    csr_rdata},
        di
    );

    /* Activate gpr_ra and gpr_rb at high voltage of clock signal, and gpr_rd otherwise. */
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

    /* Buffer write enable signal at negative edge, and use it at low voltage. */
    wire        buffer_we;
    wire [30:0] buffer_we_dontcare;
    _reg32 u_reg32_0 (
        clk,
        ~clk,
        {31'b0, gpr_we},
        {buffer_we_dontcare, buffer_we}
    );
    
    /* Buffer write data at negative edge, and use it at low voltage. */
    wire [31:0] buffer_di;
    _reg32 u_reg32_1 (
        clk,
        ~clk,
        di,
        buffer_di
    );

    /* Tri-state wire statement for RAM */
    wire [31:0] apin = buffer_di;
    wire [31:0] bpin = buffer_di;

    /* 
        Instantiate 2 RAMs instead of using a stack of registers. Usually, single
        RAM chip have only one read port, we use two RAM to offer two read port,
        which have to maintain the same content with each other. So, the write 
        enable signal and data are valid for each RAM chip.
    */
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

    /* Get output, assign 0 while read address is 0. */
    assign gpr_qa = _ra == 5'b0 ? 32'b0 : apin;
    assign gpr_qb = _rb == 5'b0 ? 32'b0 : bpin;

endmodule