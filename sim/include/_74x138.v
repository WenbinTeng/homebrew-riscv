module _74x138 (
    input [2:0] s,  // Select Signal
    input g1,       // Output Enable 1 (Active HIGH)
    input g2a,      // Output Enable 2a (Active LOW)
    input g2b,      // Output Enable 2b (Active LOW)
    output [7:0] f  // Decode Output
);
    
    reg [7:0] out;

    always @(*) begin
        case (s)
            3'b000: out = 8'b11111110;
            3'b001: out = 8'b11111101;
            3'b010: out = 8'b11111011;
            3'b011: out = 8'b11110111;
            3'b100: out = 8'b11101111;
            3'b101: out = 8'b11011111;
            3'b110: out = 8'b10111111;
            3'b111: out = 8'b01111111;
        endcase
    end

    assign f = g1 & !g2a & !g2b ? out : 8'hff;

endmodule