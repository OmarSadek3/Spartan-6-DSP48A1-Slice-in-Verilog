module post_adder_subtracter (
    input  wire signed [47:0] Z,
    input  wire signed [47:0] X,
    input  wire               CIN,
    input  wire               opmode_7, 
    output wire signed [47:0] P_out,
    output wire               carry_out
);

    // The outputs of the X multiplexer and CIN are always added together.
    // This result is then added to or subtracted from the output of the Z multiplexer.
    // OPMODE[7] = 1 specifies subtraction.
    
    wire signed [47:0] x_plus_cin;
    assign x_plus_cin = {X[47], X} + CIN;

    wire signed [48:0] full_result;
    assign full_result = opmode_7 ? ({Z[47], Z} - x_plus_cin) : ({Z[47], Z} + x_plus_cin);
    
    assign P_out = full_result[47:0]; // The lower 48 bits are the output
    assign carry_out = full_result[48]; // The 49th bit is the carry

endmodule