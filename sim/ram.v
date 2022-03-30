module ram(
    input clk,
    input load,
    input store,
    input [2:0] op,
    input [31:0] addr,
    inout [31:0] data
);

    wire [15:0] op_enable;

    _4dec16 u_4dec16_0 (
        {1'b0, op},
        op_enable
    );

    wire [3:0] ce;
    wire [3:0] oe;
    wire [3:0] we;
    wire [31:0] tdata;

    wire [31:0] load_data;
    wire [31:0] store_data;

    wire [7:0] byte_data;
    wire [15:0] half_data;
    wire [31:0] word_data = tdata;

    _mux16 u_mux16 (
        word_data[15:0],
        word_data[31:16],
        addr[1],
        half_data
    );

    _mux8 u_mux8 (
        half_data[7:0],
        half_data[15:8],
        addr[0],
        byte_data
    );

    _mux32fromN #(3) u_mux32fromN_0 (
        {
            op_enable[0],
            op_enable[1],
            op_enable[2]
        },
        {
            {data[7:0], data[7:0], data[7:0], data[7:0]},   // SB
            {data[15:0], data[15:0]},                       // SH
            data                                            // SW
        },
        store_data
    );

    _mux32fromN #(5) u_mux32fromN_1 (
        {
            op_enable[0],
            op_enable[4],
            op_enable[1],
            op_enable[5],
            op_enable[2]
        },
        {
            {{24{byte_data[7]}}, byte_data},    // LB
            {24'b0, byte_data},                 // LBU
            {{16{half_data[15]}}, half_data},   // LH
            {16'b0, half_data},                 // LHU
            word_data                           // LW
        },
        load_data
    );

    assign data = load ? 'hz : load_data;
    assign tdata = store ? 'hz : store_data;
    
    wire [11:0] dontcare;
    wire [3:0] byte_enable;
    wire [3:0] half_enable;
    wire [3:0] word_enable = 4'b0000;

    _4dec16 u_4dec16_1 (
        {2'b0, addr[1:0]},
        {dontcare, byte_enable}
    );

    _mux4 u_mux4_0 (
        4'b1100,
        4'b0011,
        addr[1],
        half_enable
    );

    _mux4fromN #(3) u_mux4fromN (
        {
            op_enable[0] & op_enable[4],
            op_enable[1] & op_enable[5],
            op_enable[2]
        },
        {
            byte_enable,
            half_enable,
            word_enable
        },
        ce
    );

    _mux4 u_mux4_1 (
        ce,
        4'b1111,
        load,
        oe
    );

    _mux4 u_mux4_2 (
        ce,
        4'b1111,
        store,
        we
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _hm62256b u_hm62256b (
                clk,
                addr[16:2],
                ce[i],
                oe[i],
                we[i],
                tdata[i*8+7:i*8]
            );
        end
    endgenerate

endmodule