// `include "./util/_add32.v"
// `include "./util/_reg32.v"
// `include "./util/_mux32.v"
// `include "./include/_cy7c1021.v"

module IF (
    input           clk,
    input           rst,
    input   [31:0]  rst_addr,
    input           brh,
    input   [31:0]  brh_addr,
    input           debug_imem_oe,
    input           debug_imem_we,
    input   [31:0]  debug_imem_addr,
    input   [31:0]  debug_imem_data,
    output  [31:0]  pc,
    output  [31:0]  inst
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

    wire imem_oe = rst ? debug_imem_oe : 1'b0;
    wire imem_we = rst ? debug_imem_we : 1'b1;
    wire [31:0] imem_addr = rst ? debug_imem_addr : currPc[17:2];
    wire [31:0] imem_data = rst ? debug_imem_data : 32'bz;

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021 (
                clk,
                1'b0,
                imem_oe,
                imem_we,
                1'b0,
                1'b0,
                currPc[17:2],
                imem_data[i*16+15:i*16]
            );
        end
    endgenerate

    assign pc = currPc;
    assign inst = imem_data;
    
endmodule