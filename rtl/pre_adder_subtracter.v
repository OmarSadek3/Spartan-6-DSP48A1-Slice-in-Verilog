module pre_adder_subtracter (
    input  wire signed [17:0] D,
    input  wire signed [17:0] B,
    input  wire               opmode_6, 
    output wire signed [17:0] pre_adder_out
);

    // OPMODE[6] = 1 specifies subtraction (D - B)
    // OPMODE[6] = 0 specifies addition (D + B)
    assign pre_adder_out = opmode_6 ? (D - B) : (D + B);

endmodule