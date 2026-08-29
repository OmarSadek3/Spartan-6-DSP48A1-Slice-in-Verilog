module multiplier (
    input  wire signed [17:0] A_mult,
    input  wire signed [17:0] B_mult,
    output wire signed [35:0] M_out
);

    // 18x18-bit (two's-complement multiplier) producing a 36-bit output
    assign M_out = A_mult * B_mult;

endmodule