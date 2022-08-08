`include "./util/_bus32.v"
`include "./util/_reg32.v"

module csr (
    input   aclk,
    input   clk,
    input   [31:0] pc,
    input   ei,                 // external interrupt, ACTIVE LOW
    input   ti,                 // timer interrupt, ACTIVE LOW
    input   [ 6:0] csr_op,      // op: ecall, ebreak, mret, csrrw, csrrs, csrrc, is_imm. ACTIVE LOW
    input   [11:0] csr_addr,    
    input   [31:0] wdata,
    output  [31:0] rdata,
    output         int_flag,
    output  [31:0] int_addr
);

    wire [31:0] mtvec;
    wire [31:0] mepc;
    wire [31:0] mcause;
    wire [31:0] mie;
    wire [31:0] mip;
    wire [31:0] mtval;
    wire [31:0] mscratch;
    wire [31:0] mstatus;

    wire ecall  = csr_op[6];
    wire ebreak = csr_op[5];
    wire mret   = csr_op[4];
    wire csrrw  = csr_op[3];
    wire csrrs  = csr_op[2];
    wire csrrc  = csr_op[1];
    wire is_imm = csr_op[0];
    wire si = ecall&ebreak;
    wire we = csrrw&csrrs&csrrc;
    wire        _int_handle = ((ei|~mie[11]) & (ti|~mie[7]) & (si|~mie[3])) | ~mstatus[3];
    wire        _int_flag = _int_handle & mret;
    wire [30:0] _int_flag_dontcare;
    wire [31:0] _int_addr = ~mret ? mepc : mtvec;

    wire [31:0] din;
    wire [31:0] dout;

    _bus32 #(3) u_bus32_0 (
        {csrrw,     csrrs,          csrrc       },
        {wdata,     dout|wdata,     dout&wdata  },
        din
    );

    _reg32 mtvec_reg (
        ~(csr_addr==12'h305&~we),
        ~aclk,
        din,
        mtvec
    );
    _reg32 mepc_reg (
        ~(csr_addr==12'h341&~we)&_int_handle,
        ~aclk,
        ~_int_handle ? {pc[31:2], 2'b0} : {din[31:2], 2'b0},
        mepc
    );
    _reg32 mcause_reg (
        _int_handle,
        ~aclk,
        ~ecall&mie[3] ? 32'hb : ~ebreak&mie[3] ? 32'h3 : ~ti&mie[7] ? 32'h80000007 : ~ei&mie[11] ? 32'h8000000b : 32'ha,
        mcause
    );
    _reg32 mie_reg (
        ~(csr_addr==12'h304&~we),
        ~aclk,
        {20'b0, din[11], 3'b0, din[7], 3'b0, din[3], 3'b0},
        mie
    );
    _reg32 mip_reg (
        1'b0,
        ~aclk,
        {20'b0, ~ei, 3'b0, ~ti, 3'b0, 1'b0, 3'b0},
        mip
    );
    _reg32 mtval_reg (
        ~(csr_addr==12'h343&~we),
        ~aclk,
        din,
        mtval
    );
    _reg32 mscratch_reg (
        ~(csr_addr==12'h340&~we),
        ~aclk,
        din,
        mscratch
    );
    _reg32 mstatus_reg (
        ~(csr_addr==12'h300&~we)&_int_flag,
        ~aclk,
        ~_int_handle ? {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b0, 3'b0} : ~mret ? {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, 1'b1, 3'b0} : {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, din[3], 3'b0},
        mstatus
    );

    _bus32 #(8) u_bus32_1 (
        {
            ~(csr_addr==12'h305),
            ~(csr_addr==12'h341),
            ~(csr_addr==12'h342),
            ~(csr_addr==12'h304),
            ~(csr_addr==12'h344),
            ~(csr_addr==12'h343),
            ~(csr_addr==12'h340),
            ~(csr_addr==12'h300)
        },
        {
            mtvec,
            mepc,
            mcause,
            mie,
            mip,
            mtval,
            mscratch,
            mstatus
        },
        dout
    );

    assign rdata = dout;

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