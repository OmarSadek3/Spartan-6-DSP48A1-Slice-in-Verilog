module post_adder_subtracter (
    input  wire signed [47:0] Z,
    input  wire signed [47:0] X,
    input  wire               CIN,
    input  wire               opmode_7, // 0 for Add, 1 for Subtract
    output wire signed [47:0] P_out,
    output wire               carry_out // Final carry out of the 48-bit adder
);

    // XOR for two's complement subtraction
 
    wire [47:0] X_xor;
    assign X_xor = X ^ {48{opmode_7}};

    // Group propagate and generate signals from the 12 blocks
    wire [11:0] P_g; 
    wire [11:0] G_g; 
    wire [12:0] C_b; // Carry-in for each block (C_b[12] is the final Cout)

    // =========================================================
    // Initial Carry Logic (The Hardware Trick)
    // Add (opmode=0): Initial carry is CIN
    // Sub (opmode=1): Initial carry is ~CIN (because 1 - CIN = ~CIN)
    // =========================================================
    assign C_b[0] = CIN ^ opmode_7;


    // Group 1 (Blocks 0 to 3) 
    assign C_b[1] = G_g[0] | (P_g[0] & C_b[0]);
    
    assign C_b[2] = G_g[1] | (P_g[1] & G_g[0]) | 
                    (P_g[1] & P_g[0] & C_b[0]);
                    
    assign C_b[3] = G_g[2] | (P_g[2] & G_g[1]) | 
                    (P_g[2] & P_g[1] & G_g[0]) | 
                    (P_g[2] & P_g[1] & P_g[0] & C_b[0]);
                    
    assign C_b[4] = G_g[3] | (P_g[3] & G_g[2]) | 
                    (P_g[3] & P_g[2] & G_g[1]) | 
                    (P_g[3] & P_g[2] & P_g[1] & G_g[0]) | 
                    (P_g[3] & P_g[2] & P_g[1] & P_g[0] & C_b[0]);


    // Group 2 (Blocks 4 to 7) 
    assign C_b[5] = G_g[4] | (P_g[4] & C_b[4]);
    
    assign C_b[6] = G_g[5] | (P_g[5] & G_g[4]) | 
                    (P_g[5] & P_g[4] & C_b[4]);
                    
    assign C_b[7] = G_g[6] | (P_g[6] & G_g[5]) | 
                    (P_g[6] & P_g[5] & G_g[4]) | 
                    (P_g[6] & P_g[5] & P_g[4] & C_b[4]);
                    
    assign C_b[8] = G_g[7] | (P_g[7] & G_g[6]) | 
                    (P_g[7] & P_g[6] & G_g[5]) | 
                    (P_g[7] & P_g[6] & P_g[5] & G_g[4]) | 
                    (P_g[7] & P_g[6] & P_g[5] & P_g[4] & C_b[4]);

    
    // Super-Group 3 (Blocks 8 to 11) 
    assign C_b[9]  = G_g[8] | (P_g[8] & C_b[8]);
    
    assign C_b[10] = G_g[9] | (P_g[9] & G_g[8]) | 
                     (P_g[9] & P_g[8] & C_b[8]);
                     
    assign C_b[11] = G_g[10] | (P_g[10] & G_g[9]) | 
                     (P_g[10] & P_g[9] & G_g[8]) | 
                     (P_g[10] & P_g[9] & P_g[8] & C_b[8]);
                     
    assign C_b[12] = G_g[11] | (P_g[11] & G_g[10]) | 
                     (P_g[11] & P_g[10] & G_g[9]) | 
                     (P_g[11] & P_g[10] & P_g[9] & G_g[8]) | 
                     (P_g[11] & P_g[10] & P_g[9] & P_g[8] & C_b[8]);

    // Final Carry Out
    assign carry_out = C_b[12];

    // =========================================================
    // Instantiate the 12 CLA_4bit blocks
    // =========================================================
    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : POST_ADDER_4BIT_BLOCKS
            CLA_4bit block (
                .A(Z[i*4 +: 4]),
                .B(X_xor[i*4 +: 4]),
                .Cin(C_b[i]),
                .Sum(P_out[i*4 +: 4]),
                .Cout(),          // Handled externally by LCU
                .P_group(P_g[i]),
                .G_group(G_g[i])
            );
        end
    endgenerate

endmodule