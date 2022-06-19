`include "./include/_74x157.v"
`include "./include/_74x182.v"
`include "./include/_74x381.v"
`include "./include/_cy7c1021.v"
`include "./util/_mux32.v"

module backend (
    input           clk,
    input   [3:0]   alu_op,
    input   [5:0]   mem_op,
    input   [31:0]  operand_a,
    input   [31:0]  operand_b,
    input   [31:0]  reg_do,
    output  [31:0]  reg_di,
    output          carry
);

    wire [7:0] pn;
    wire [7:0] gn;
    wire [1:0] pa;
    wire [1:0] ga;
    wire [8:0] c = 'b0;
    wire [31:0] f;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            _74x381 u_74x381 (
                operand_a[i*4+3:i*4],
                operand_b[i*4+3:i*4],
                alu_op[2:0],
                c[i],
                gn[i],
                pn[i],
                f[i*4+3:i*4]
            );
        end
    endgenerate

    _74x182 u_74x182_0 (
        gn[3:0],
        pn[3:0],
        c[0],
        c[1],
        c[2],
        c[3],
        ga[0],
        pa[0]
    );
    _74x182 u_74x182_1 (
        gn[7:4],
        pn[7:4],
        c[4],
        c[5],
        c[6],
        c[7],
        ga[1],
        pa[1]
    );
    _74x182 u_74x182_2 (
        {2'b0, ga},
        {2'b0, pa},
        c[0],
        c[4],
        c[8],
        x,
        x,
        x
    );

    assign carry = c[8];

    wire [31:0] operand_pos;
    wire [31:0] operand_rev;

    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign operand_pos[i] = operand_a[i];
            assign operand_rev[i] = operand_a[31-i];
        end
    endgenerate
    
    wire [31:0] shift_layer [5:0];
    wire [31:0] shift_right [4:0];

    _mux32 u_mux32_0 (
        operand_pos,
        operand_rev,
        alu_op[0],
        shift_layer[0]
    );

    assign shift_right[0] = {{16{alu_op[2] & shift_layer[0][31]}}, shift_layer[0][31:16]};
    assign shift_right[1] = {{ 8{alu_op[2] & shift_layer[1][31]}}, shift_layer[1][31: 8]};
    assign shift_right[2] = {{ 4{alu_op[2] & shift_layer[2][31]}}, shift_layer[2][31: 4]};
    assign shift_right[3] = {{ 2{alu_op[2] & shift_layer[3][31]}}, shift_layer[3][31: 2]};
    assign shift_right[4] = {{ 1{alu_op[2] & shift_layer[4][31]}}, shift_layer[4][31: 1]};

    generate
        for (i = 0; i < 5; i = i + 1) begin
            _mux32 u_mux32 (
                shift_layer[i],
                shift_right[i],
                operand_b[4-i],
                shift_layer[i+1]
            );
        end
    endgenerate

    wire [31:0] h;
    wire [31:0] h_pos;
    wire [31:0] h_rev;

    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign h_pos[i] = shift_layer[5][i];
            assign h_rev[i] = shift_layer[5][31-i];
        end
    endgenerate

    _mux32 u_mux32_1 (
        h_pos,
        h_rev,
        alu_op[0],
        h
    );

    wire [31:0] alu_data;

    _mux32 u_mux32_2 (
        f,
        h,
        alu_op[3],
        alu_data
    );

    wire oe = mem_op[5];
    wire we = mem_op[4];
    wire [31:0] pin = we ? reg_di : 32'bz;

    generate
        for (i = 0; i < 2; i = i + 1) begin
            _cy7c1021 u_cy7c1021 (
                clk,
                1'b0,
                oe,
                we,
                mem_op[i*2],
                mem_op[i*2+1],
                alu_data[15:0],
                pin[16*i+15:16*i]
            );
        end
    endgenerate
    
    assign reg_do = oe ? pin : alu_data;
    
endmodule