`include "./util/_add32.v"
`include "./util/_reg32.v"
`include "./util/_mux32fromN.v"
`include "./include/_cy7c1021.v"

module IF (
    input           clk,
    input           rst,
    input   [31:0]  rst_addr,
    input           brh,
    input   [31:0]  brh_addr,
    input           ram_oe,
    input           ram_we,
    inout   [31:0]  ram_data
);

    wire [31:0] currPc;
    wire [31:0] nextPC;
    wire [31:0] plusPC;

    _add32 u_add32 (
        currPc,
        32'h4,
        plusPC
    );

    _bus32 #(3) u_bus32 (
        {rst,       brh,        !rst|!brh},
        {rst_addr,  brh_addr,   plusPC},
        nextPC
    );

    _reg32 u_reg32 (
        1'b1,
        clk,
        nextPC,
        currPc
    );

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021 (
                clk,
                1'b0,
                ram_oe,
                ram_we,
                1'b0,
                1'b0,
                currPc[17:2],
                ram_data[i*16+15:i*16]
            );
        end
    endgenerate
    
endmodule