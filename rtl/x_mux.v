module x_mux (
    input  wire signed [35:0] M_out,      // Multiplier Output
    input  wire signed [47:0] P_in,       // Feedback from P register
    input  wire signed [17:0] D_in,       // D input (needs careful concatenation)
    input  wire signed [17:0] A_in,       // A input
    input  wire signed [17:0] B_in,       // B input
    input  wire        [1:0]  opmode_1_0, // OPMODE[1:0]
    output reg  signed [47:0] X_out
);

/*      0 – Specifies to place all zeros (disable the post-adder/subtracter)
        1 – Use the multiplier product
        2 – Use the P output signal (accumulator)
        3 – Use the concatenated D, B, A input signals        
*/

    always @(*) begin

        case (opmode_1_0)                                                   
            2'b00: X_out = 48'sd0; // Zero 
            
            
            // Sign-extend the 36-bit multiplier output to 48 bits
            2'b01: X_out = { {12{M_out[35]}}, M_out }; 
            
            2'b10: X_out = P_in; // P Accumulator feedback
            
            // Concatenate D[11:0], A[17:0], B[17:0] to form 48 bits

            2'b11: X_out = { D_in[11:0], A_in, B_in }; 
            
            default: X_out = 48'sd0;
        endcase
    end

endmodule