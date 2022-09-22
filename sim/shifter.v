// `include "./util/_mux32.v"

module shifter (
    input   [31:0]  operand_a,  // Number to be shifted
    input   [31:0]  operand_b,  // Count of shift
    input   [ 2:0]  alu_op,     // op: sll, srl, sra, active LOW
    output  [31:0]  h
);

    /* Original and reversed operand */
    wire [31:0] operand_pos;
    wire [31:0] operand_rev;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign operand_pos[i] = operand_a[i];
            assign operand_rev[i] = operand_a[31-i];
        end
    endgenerate
    
    /* Define 5 shift layers */
    wire [31:0] shift_layer [5:0];
    wire [31:0] shift_right [4:0];

    /* Select input based on operation code */
    _mux32 u_mux32_0 (
        operand_rev,
        operand_pos,
        alu_op[2],
        shift_layer[0]
    );

    /* Right shift, fill 1 if signed, reverse after shift if is left shift. */
    assign shift_right[0] = {{16{~alu_op[0] & shift_layer[0][31]}}, shift_layer[0][31:16]};
    assign shift_right[1] = {{ 8{~alu_op[0] & shift_layer[1][31]}}, shift_layer[1][31: 8]};
    assign shift_right[2] = {{ 4{~alu_op[0] & shift_layer[2][31]}}, shift_layer[2][31: 4]};
    assign shift_right[3] = {{ 2{~alu_op[0] & shift_layer[3][31]}}, shift_layer[3][31: 2]};
    assign shift_right[4] = {{ 1{~alu_op[0] & shift_layer[4][31]}}, shift_layer[4][31: 1]};

    /* Select output for each shift layer based on the bits of counter */
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

    /* Original and reversed output */
    wire [31:0] h_pos;
    wire [31:0] h_rev;
    generate
        for (i = 0; i < 32; i = i + 1) begin
            assign h_pos[i] = shift_layer[5][i];
            assign h_rev[i] = shift_layer[5][31-i];
        end
    endgenerate

    /* Select output based on left/right shift */
    _mux32 u_mux32_1 (
        h_rev,
        h_pos,
        alu_op[2],
        h
    );
    
endmodule