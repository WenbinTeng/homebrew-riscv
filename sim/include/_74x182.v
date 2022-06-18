module _74x182 (
    input [3:0] gni, // Carry Generate Input (Active LOW)
    input [3:0] pni, // Carry Propagate Input (Active LOW)
    input cn,       // Carry Input
    output cnx,     // Carry Output X
    output cny,     // Carry Output Y
    output cnz,     // Carry Output Z
    output gno,     // Carry Generate Output (Active LOW)
    output pno      // Carry Propagate Output (Active LOW)
);

    wire [3:0] g = ~gni;
    wire [3:0] p = ~pni;

    assign cnx = g[0] | p[0] & cn;
    assign cny = g[1] | g[0] & p[1] | p[1] & p[0] & cn;
    assign cnz = g[2] | g[1] & p[2] | g[0] & p[2] & p[1] | p[2] & p[1] & p[0] & cn;
    assign gno = ~(g[3] | g[2] & p[3] | g[1] & p[3] & p[2] | g[0] & p[3] & p[2] & p[1]);
    assign pno = ~(p[3] & p[2] & p[1] & p[0]);

endmodule