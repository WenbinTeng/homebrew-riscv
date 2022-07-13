`include "./util/_add32.v"
`include "./util/_mux32.v"
`include "./util/_reg32.v"
`include "./include/_at28c256.v"

module IF (
    input           clk,
    input           rst,
    input   [31:0]  rst_addr,
    input           brh,
    input   [31:0]  brh_addr,
    output  [31:0]  pc,
    output  [31:0]  inst
);

    wire [31:0] temp_pc;
    wire [31:0] curr_pc;
    wire [31:0] next_pc;
    wire [31:0] plus_pc;

    _mux32 u_mux32_0 (
        brh_addr,
        plus_pc,
        brh,
        temp_pc
    );

    _mux32 u_mux32_1 (
        rst_addr,
        temp_pc,
        rst,
        next_pc
    );

    _reg32 u_reg32 (
        1'b0,
        clk,
        next_pc,
        curr_pc
    );

    _add32 u_add32 (
        curr_pc,
        32'h4,
        plus_pc
    );

    wire [31:0] imem_data;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            _at28c256 u_at28c256 (
                1'b0,
                1'b0,
                {curr_pc[14:2], i[1:0]},
                imem_data[i*8+7:i*8]
            );
        end
    endgenerate

    assign pc = curr_pc;
    assign inst = imem_data;
    
endmodule