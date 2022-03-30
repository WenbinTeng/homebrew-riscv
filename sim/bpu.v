module bpu(
    input jal,
    input [31:0] jal_offset,
    input jalr,
    input [31:0] jalr_offset,
    input branch,
    input [31:0] branch_offset,
    input [2:0] op,
    input [31:0] addr,
    input [32:0] data,
    output take,
    output [31:0] dest
);

    wire [7:0] op_enable;

    _4dec16 u_4dec16 (
        {1'b0, op},
        op_enable
    );

    assign take = !branch & (
        !op_enable[0] & data[31:0] == 0 |   // BEQ
        !op_enable[1] & data[31:0] != 0 |   // BNE
        !op_enable[4] & data[31] |          // BLT
        !op_enable[5] & !data[31] |         // BGE
        !op_enable[6] & data[32] |          // BLTU
        !op_enable[7] & !data[32]           // BGEU
    ) | jal | jalr;

    wire [31:0] offset;

    _mux32fromN u_mux32fromN (
        {
            jal,
            jalr,
            branch
        },
        {
            jal_offset,
            jalr_offset,
            branch_offset
        },
        offset
    );

    _adder u_adder (
        addr,
        offset,
        dest
    );

endmodule