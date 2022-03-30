module pc(
    input clk,
    input rst_take,
    input [31:0] rst_addr,
    input refill_take,
    input [31:0] refill_addr,
    input branch_take,
    input [31:0] branch_addr,
    output [31:0] addr
);

    reg [31:0] pcr;
    wire [31:0] pcp4;

    _adder (pcr, 32'h4, pcp4);

    always @(posedge clk) begin
        if (rst_take)
            pcr <= rst_addr;
        else if (branch_take)
            pcr <= branch_addr;
        else if (refill_addr)
            pcr <= refill_addr;
        else
            pcr <= pcp4;
    end

endmodule