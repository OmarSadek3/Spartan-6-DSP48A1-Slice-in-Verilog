module pre_adder_subtracter (
    input  wire signed [17:0] D,
    input  wire signed [17:0] B,
    input  wire               opmode_6, // 0 for Add (D+B), 1 for Subtract (D-B)
    output wire signed [17:0] pre_adder_out
);

    
    // XOR for subtraction (1's complement if opmode_6 == 1)
    
    wire [17:0] B_xor;
    assign B_xor = B ^ {18{opmode_6}};
    
    // Group signals for 5 blocks (Blocks 0-3 are 4-bit, Block 4 is 2-bit)
    wire [4:0] P_g; 
    wire [4:0] G_g; 
    wire [5:0] C_b; 

    // Initial carry-in is the opmode_6 signal (adds 1 for 2's complement subtraction)
    assign C_b[0] = opmode_6;

    
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

    // We calculate C_b[5] just in case you ever need the carry_out, 
    // but for the 18-bit pre-adder, we don't use it.
    assign C_b[5] = G_g[4] | (P_g[4] & G_g[3]) | 
                    (P_g[4] & P_g[3] & G_g[2]) | 
                    (P_g[4] & P_g[3] & P_g[2] & G_g[1]) | 
                    (P_g[4] & P_g[3] & P_g[2] & P_g[1] & G_g[0]) | 
                    (P_g[4] & P_g[3] & P_g[2] & P_g[1] & P_g[0] & C_b[0]);


    // Instantiate the four 4-bit CLA blocks (Bits 0 to 15)
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : PRE_ADDER_4BIT_BLOCKS
            CLA_4bit block4 (
                .A(D[i*4 +: 4]),            // The D input goes here
                .B(B_xor[i*4 +: 4]),
                .Cin(C_b[i]),
                .Sum(pre_adder_out[i*4 +: 4]), // Directly to the output
                .Cout(),                  // Handled by LCU
                .P_group(P_g[i]),
                .G_group(G_g[i])
            );
        end
    endgenerate

  
    // Instantiate the final 2-bit CLA block (Bits 16 and 17)
    CLA_2bit block2 (
        .A(D[17:16]),
        .B(B_xor[17:16]),
        .Cin(C_b[4]),
        .Sum(pre_adder_out[17:16]),
        .Cout(),                  // Handled by LCU (C_b[5])
        .P_group(P_g[4]),
        .G_group(G_g[4])
    );

endmodule
////////////////////////////////////////////////////////////////////////////////////
module CLA_2bit (
    input  wire [1:0] A,
    input  wire [1:0] B,
    input  wire       Cin,
    output wire [1:0] Sum,
    output wire       Cout,
    // carry lookahead signals
    output wire       P_group, 
    output wire       G_group  
);

    wire [1:0] P; // Propagate
    wire [1:0] G; // Generate
    wire [2:0] C; // Carries 

    // 1. Calculate propagate and generate signals
    assign P = A ^ B;
    assign G = A & B;

    // 2. Calculate carries
    assign C[0] = Cin;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);

    // 3. Final sum and carry out
    assign Sum  = P ^ C[1:0];
    assign Cout = C[2];

    // 4. Group signals for the higher-level LCU
    assign P_group = P[1] & P[0];
    assign G_group = G[1] | (P[1] & G[0]);

endmodule
