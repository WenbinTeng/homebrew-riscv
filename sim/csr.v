`include "util/_bus32.v"
`include "util/_reg32.v"
`include "util/_mux32.v"

module CSR (
    input           aclk,       // Simulate async write clock signal
    input           clk,        // Clock signal
    input           ei,         // External interrupt, ACTIVE LOW
    input           ti,         // Timer interrupt, ACTIVE LOW
    input   [31:0]  pc,         // Program Counter
    input   [31:0]  gpr_qa,     // Output data of port a
    input   [ 7:0]  csr_op,     // op: ecall, ebreak, mret, csrrw, csrrs, csrrc, is_imm. ACTIVE LOW
    input   [ 4:0]  csr_zimm,   // Immediate number from instruciton
    input   [11:0]  csr_addr,   // Read and write address
    output  [31:0]  csr_rdata,  // CSR registers read data output
    output          int_flag,   // interrupt signal
    output  [31:0]  int_addr    // interrupt address
);

    /* CSR registers' signal */
    wire [31:0] mtvec;
    wire [31:0] mepc;
    wire [31:0] mcause;
    wire [31:0] mie;
    wire [31:0] mip;
    wire [31:0] mstatus;

    /* CSR operation one-hot (active LOW) code */
    wire ecall  = csr_op[6];
    wire ebreak = csr_op[5];
    wire mret   = csr_op[4];
    wire csrrw  = csr_op[3];
    wire csrrs  = csr_op[2];
    wire csrrc  = csr_op[1];
    wire is_imm = csr_op[0];

    /*
        Only if a trap instruction or external interrupt is encountered and
        the corresponding flag (in Mie register) is valid and global interrupt
        is enable (for machine level, in Mstatus), the interrupt occurs.
        Active LOW.
    */
    wire csr_en = csrrw&csrrs&csrrc;
    wire ecall_en = ~(~ecall&mie[3]&mstatus[3]);
    wire ebreak_en = ~(~ebreak&mie[3]&mstatus[3]);
    wire ei_en = ~(mip[11]&mie[11]);
    wire ti_en = ~(mip[7]&mie[7]);

    /* interrupt handling state. Active LOW */
    wire        _int_handle = ecall_en & ebreak_en & ei_en & ti_en;
    wire        _int_flag = _int_handle & mret;
    wire [30:0] _int_flag_dontcare;
    wire [31:0] _int_addr;

    /* IO data wire */
    wire [31:0] wdata;
    wire [31:0] din;
    wire [31:0] dout;

    /* Choose operand */
    _mux32 u_mux32_0 (
        {27'b0, csr_zimm},
        gpr_qa,
        is_imm,
        wdata
    );

    /*
        When an interrupt occurs, take Mtvec as the program entrance.
        When the interrupt returns, take Mepc as the return address.
    */
    _mux32 u_mux32_1 (
        mepc,
        mtvec,
        mret,
        _int_addr
    );

    /* Write/Set/Clear the flag(s) in CSRs */
    _bus32 #(3) u_bus32_0 (
        {csrrw,     csrrs,          csrrc       },
        {wdata,     dout|wdata,     dout&wdata  },
        din
    );

    /* CSR operations, for more infornmations, please refer to Risc-V Manual. */
    _reg32 mtvec_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h305),
        din,
        mtvec
    );
    _reg32 mepc_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h341|~_int_handle),
        ~_int_handle ? {pc[31:2], 2'b0} : {din[31:2], 2'b0},
        mepc
    );
    _reg32 mcause_reg (
        1'b0,
        ~aclk&~_int_handle,
        ~ecall_en ? 32'hb : ~ebreak_en ? 32'h3 : ~ti_en ? 32'h80000007 : ~ei_en ? 32'h8000000b : 32'ha,
        mcause
    );
    _reg32 mie_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h304),
        {20'b0, din[11], 3'b0, din[7], 3'b0, din[3], 3'b0},
        mie
    );
    _reg32 mip_reg (
        1'b0,
        ~aclk,
        {20'b0, ~ei, 3'b0, ~ti, 3'b0, 1'b0, 3'b0},
        mip
    );
    _reg32 mstatus_reg (
        1'b0,
        ~aclk&(~csr_en&csr_addr==12'h300|~_int_flag),
        ~_int_handle ? {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b0, 3'b0} : ~mret ? {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b1, 3'b0} : {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, din[3], 3'b0},
        mstatus
    );

    /* Select output data based on the read address */
    _bus32 #(6) u_bus32_1 (
        {
            ~(~csr_en&csr_addr==12'h305),
            ~(~csr_en&csr_addr==12'h341),
            ~(~csr_en&csr_addr==12'h342),
            ~(~csr_en&csr_addr==12'h304),
            ~(~csr_en&csr_addr==12'h344),
            ~(~csr_en&csr_addr==12'h300)
        },
        {
            mtvec,
            mepc,
            mcause,
            mie,
            mip,
            mstatus
        },
        dout
    );
    assign csr_rdata = dout;

    /* Buffer interrupt signal and address in negative edge to avoid gpr_qa changes */
    _reg32 u_reg32_1 (
        1'b0,
        ~aclk,
        {31'b0, _int_flag},
        {_int_flag_dontcare, int_flag}
    );
    _reg32 u_reg32_2 (
        1'b0,
        ~aclk,
        _int_addr,
        int_addr
    );

endmodule