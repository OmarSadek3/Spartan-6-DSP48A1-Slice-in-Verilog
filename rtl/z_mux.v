module z_mux (
    input  wire signed [47:0] PCIN,       // Cascade input from another DSP slice
    input  wire signed [47:0] P_in,       // Feedback from P register
    input  wire signed [47:0] C_in,       // C port input
    input  wire        [1:0]  opmode_3_2, // OPMODE[3:2]
    output reg  signed [47:0] Z_out
);
 /*
    0 – Specifies to place all zeros 
(disable the post-adder/subtracter and propagate the multiplier product to P)
    
    1 – Use the PCIN
    2 – Use the P port (accumulator)
    3 – Use the C port

*/

    always @(*) begin
        case (opmode_3_2)
            2'b00: Z_out = 48'sd0; // Zero
            2'b01: Z_out = PCIN;   // P Cascade Input
            2'b10: Z_out = P_in;   // P Accumulator feedback
            2'b11: Z_out = C_in;   // C port input
            default: Z_out = 48'sd0;
        endcase
    end

endmodule