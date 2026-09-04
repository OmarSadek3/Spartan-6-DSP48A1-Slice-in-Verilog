module CLA_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Cout,
    //  carry lookahead signals
    output wire       P_group, 
    output wire       G_group  
);

    wire [3:0] P; // Propagate
    wire [3:0] G; // Generate
    wire [4:0] C; // Internal Carries (C[0] to C[4])

    // 1. Calculate propagate and generate signals
    assign P = A ^ B;
    assign G = A & B;

    // 2. Calculate internal carries
    assign C[0] = Cin;
    
    assign C[1] = G[0] | (P[0] & C[0]);
    
    assign C[2] = G[1] | (P[1] & G[0]) | 
                  (P[1] & P[0] & C[0]);
                  
    assign C[3] = G[2] | (P[2] & G[1]) | 
                  (P[2] & P[1] & G[0]) | 
                  (P[2] & P[1] & P[0] & C[0]);
                  
    assign C[4] = G[3] | (P[3] & G[2]) | 
                  (P[3] & P[2] & G[1]) | 
                  (P[3] & P[2] & P[1] & G[0]) | 
                  (P[3] & P[2] & P[1] & P[0] & C[0]);

    // 3.final sum and carry out
    assign Sum  = P ^ C[3:0];
    assign Cout = C[4];

    // p_group and g_group are used for hierarchical carry lookahead in larger adders
    // 
    assign P_group = P[3] & P[2] & P[1] & P[0];
    
    assign G_group = G[3] | (P[3] & G[2]) | 
                     (P[3] & P[2] & G[1]) | 
                     (P[3] & P[2] & P[1] & G[0]) ;

endmodule