module Multiplier_18x18 (
    input  wire signed [17:0] A_mult,
    input  wire signed [17:0] B_mult,
    // The final 36-bit output from the multiplier
    output wire signed [35:0] M_out
);
        
    // 1. Partial products from Booth Encoder 
    wire signed [35:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8;

    // 2.outputs from Wallace Tree
    wire signed [35:0] tree_sum;
    wire signed [35:0] tree_carry;

    // 3. Final product from the Adder
    wire signed [35:0] final_product;


    // Stage 1: Radix-4 Booth Encoding
    // Generates 9 partial products instead of 18

    Booth_Radix4_Encoder booth_encoder_inst (
        .A(A_mult),
        .B(B_mult),
        .pp0(pp0), .pp1(pp1), .pp2(pp2), 
        .pp3(pp3), .pp4(pp4), .pp5(pp5), 
        .pp6(pp6), .pp7(pp7), .pp8(pp8)
    );


    // Stage 2: Wallace Tree Compression
    
    Wallace_Tree_9to2 #(36) wallace_tree_inst (
        .pp0(pp0), .pp1(pp1), .pp2(pp2), 
        .pp3(pp3), .pp4(pp4), .pp5(pp5), 
        .pp6(pp6), .pp7(pp7), .pp8(pp8),
        .out_sum(tree_sum),
        .out_carry(tree_carry)
    );


    // Stage 3: Final Addition (Carry-Lookahead Adder)

    CLA_36bit fast_adder_inst (
        .A(tree_sum),
        .B(tree_carry),
        .Cin(1'b0),          // No initial carry-in for this multiplication
        .Sum(final_product),
        .Cout()              
    );


    // Output Assignment 
    assign M_out = final_product;

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////// 
module Booth_Radix4_Encoder (
    input  wire signed [17:0] A,
    input  wire signed [17:0] B,
    output wire signed [35:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8
);

    // Append a phantom zero to the right of B for the first window (W0)
    // The total length becomes 19 bits.
    wire [18:0] B_padded = {B, 1'b0};

    
    // window takes bits [2j+1 : 2j-1]
    
    Booth_Row_Generator #(0) row0 (.A(A), .window(B_padded[2:0]),   .pp(pp0));
    Booth_Row_Generator #(1) row1 (.A(A), .window(B_padded[4:2]),   .pp(pp1));
    Booth_Row_Generator #(2) row2 (.A(A), .window(B_padded[6:4]),   .pp(pp2));
    Booth_Row_Generator #(3) row3 (.A(A), .window(B_padded[8:6]),   .pp(pp3));
    Booth_Row_Generator #(4) row4 (.A(A), .window(B_padded[10:8]),  .pp(pp4));
    Booth_Row_Generator #(5) row5 (.A(A), .window(B_padded[12:10]), .pp(pp5));
    Booth_Row_Generator #(6) row6 (.A(A), .window(B_padded[14:12]), .pp(pp6));
    Booth_Row_Generator #(7) row7 (.A(A), .window(B_padded[16:14]), .pp(pp7));
    
    // The final window handles the most significant bits and the sign bit 
    Booth_Row_Generator #(8) row8 (.A(A), .window(B_padded[18:16]), .pp(pp8));

endmodule          
           

///////////////////////////////////////////////////////////////////////////////////////////////////
module Booth_Row_Generator #(
    parameter ROW_INDEX = 0 // Represents 'j' (from 0 to 8)
)(
    input  wire signed [17:0] A,
    input  wire        [2:0]  window,
    output reg  signed [35:0] pp // 36-bit partial product
);

    // Calculate the base shift amount for this specific row (2 * j)
    localparam SHIFT = 2 * ROW_INDEX;

    // Extend A to 36 bits (signed arithmetic)
    wire signed [35:0] A_ext = A;

    always @(*) begin
        case (window)
            3'b000, 3'b111: pp = 36'd0;                           // 0
            3'b001, 3'b010: pp = A_ext << SHIFT;                  // +1 * A
            3'b011:         pp = A_ext << (SHIFT + 1);            // +2 * A (shifted left by 1)
            3'b100:         pp = -(A_ext << (SHIFT + 1));         // -2 * A
            3'b101, 3'b110: pp = -(A_ext << SHIFT);               // -1 * A
            default:        pp = 36'd0;
        endcase
    end

endmodule


//////////////////////////////////////////////////////////////////////////////////////////////////////           
module Wallace_Tree_9to2 #(
    parameter WIDTH = 36 
)(
    input  wire [WIDTH-1:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8,
    output wire [WIDTH-1:0] out_sum,
    output wire [WIDTH-1:0] out_carry
);
   
    wire [WIDTH-1:0] s1_1, c1_1_un, c1_1;
    wire [WIDTH-1:0] s1_2, c1_2_un, c1_2;
    wire [WIDTH-1:0] s1_3, c1_3_un, c1_3;


    wire [WIDTH-1:0] s2_1, c2_1_un, c2_1;
    wire [WIDTH-1:0] s2_2, c2_2_un, c2_2;
    
             

    wire [WIDTH-1:0] s3_1, c3_1_un, c3_1;

  
    wire [WIDTH-1:0] c4_1_un;

    // Stage 1: (9 inputs -> 6 outputs) 
    CSA #(WIDTH) csa1_1 (.A(pp0), .B(pp1), .C(pp2), .SUM(s1_1), .CARRY(c1_1_un));
    assign c1_1 = {c1_1_un[WIDTH-2:0], 1'b0}; 

    CSA #(WIDTH) csa1_2 (.A(pp3), .B(pp4), .C(pp5), .SUM(s1_2), .CARRY(c1_2_un));
    assign c1_2 = {c1_2_un[WIDTH-2:0], 1'b0};

    CSA #(WIDTH) csa1_3 (.A(pp6), .B(pp7), .C(pp8), .SUM(s1_3), .CARRY(c1_3_un));
    assign c1_3 = {c1_3_un[WIDTH-2:0], 1'b0};

    // Stage 2: (6 inputs -> 4 outputs) 
    CSA #(WIDTH) csa2_1 (.A(s1_1), .B(c1_1), .C(s1_2), .SUM(s2_1), .CARRY(c2_1_un));
    assign c2_1 = {c2_1_un[WIDTH-2:0], 1'b0};

    CSA #(WIDTH) csa2_2 (.A(c1_2), .B(s1_3), .C(c1_3), .SUM(s2_2), .CARRY(c2_2_un));
    assign c2_2 = {c2_2_un[WIDTH-2:0], 1'b0};

    // Stage 3: (4 inputs -> 3 outputs)
    CSA #(WIDTH) csa3_1 (.A(s2_1), .B(c2_1), .C(s2_2), .SUM(s3_1), .CARRY(c3_1_un));
    assign c3_1 = {c3_1_un[WIDTH-2:0], 1'b0};
   

    // Stage 4: (3 inputs -> 2 outputs)
    CSA #(WIDTH) csa4_1 (.A(s3_1), .B(c3_1), .C(c2_2), .SUM(out_sum), .CARRY(c4_1_un));
    assign out_carry = {c4_1_un[WIDTH-2:0], 1'b0};

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////
module CLA_36bit (
    input  wire [35:0] A,
    input  wire [35:0] B,
    input  wire        Cin,
    output wire [35:0] Sum,
    output wire        Cout
);

    wire [8:0] P_g; // Group Propagate signals from the 9 blocks
    wire [8:0] G_g; // Group Generate signals from the 9 blocks
    wire [9:0] C_b; // Carry-in for each block

    // Initial carry
    assign C_b[0] = Cin;

 

    // 1. Super-Group 1 (Blocks 0, 1, 2)
    assign C_b[1] = G_g[0] | (P_g[0] & C_b[0]);
    assign C_b[2] = G_g[1] | (P_g[1] & G_g[0]) | 
                    (P_g[1] & P_g[0] & C_b[0]);
    assign C_b[3] = G_g[2] | (P_g[2] & G_g[1]) | 
                    (P_g[2] & P_g[1] & G_g[0]) | 
                    (P_g[2] & P_g[1] & P_g[0] & C_b[0]);

    // 2. Super-Group 2 (Blocks 3, 4, 5) - depends directly on C_b[3]
    assign C_b[4] = G_g[3] | (P_g[3] & C_b[3]);
    assign C_b[5] = G_g[4] | (P_g[4] & G_g[3]) | 
                    (P_g[4] & P_g[3] & C_b[3]);
    assign C_b[6] = G_g[5] | (P_g[5] & G_g[4]) | 
                    (P_g[5] & P_g[4] & G_g[3]) | 
                    (P_g[5] & P_g[4] & P_g[3] & C_b[3]);

    // 3. Super-Group 3 (Blocks 6, 7, 8) - depends directly on C_b[6]
    assign C_b[7] = G_g[6] | (P_g[6] & C_b[6]);
    assign C_b[8] = G_g[7] | (P_g[7] & G_g[6]) | 
                    (P_g[7] & P_g[6] & C_b[6]);
    assign C_b[9] = G_g[8] | (P_g[8] & G_g[7]) | 
                    (P_g[8] & P_g[7] & G_g[6]) | 
                    (P_g[8] & P_g[7] & P_g[6] & C_b[6]);

    // The final carry out of the entire 36-bit adder
    assign Cout = C_b[9];


    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : CLA_BLOCKS
            // Instantiate the 4-bit module 9 times
            CLA_4bit block (
                .A(A[i*4 +: 4]),         // Part-select: 4 bits at a time
                .B(B[i*4 +: 4]),
                .Cin(C_b[i]),
                .Sum(Sum[i*4 +: 4]),
                .Cout(),                 // Left unconnected intentionally; LCU handles it
                .P_group(P_g[i]),
                .G_group(G_g[i])
            );
        end
    endgenerate

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////
/*              Pi = Ai Xor Bi 
                Gi = Ai And Bi
                Si = Pi Xor Ci
                Ci+1 = Gi | (Pi & Ci)
                C1 = G0 | (P0 & C0)
                C2 = G1 | (P1 & G0) | (P1 & P0 & C0)
                C3 = G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & C0)
                C4 = G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0) | (P3 & P2 & P1 & P0 & C0)
                P_group = P3 & P2 & P1 & P0
                G_group = G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0) 
*/


//////////////////////////////////////////////////////////////////////////////////////////////////
module CSA #(
    parameter WIDTH = 36
)(
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    input  [WIDTH-1:0] C,
    output [WIDTH-1:0] SUM,
    output [WIDTH-1:0] CARRY
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : CSA_BITS
            Full_Adder FA (
                .A(A[i]),
                .B(B[i]),
                .Cin(C[i]),
                .Sum(SUM[i]),
                .Cout(CARRY[i])
            );
        end
    endgenerate

endmodule

module Full_Adder (
    input  wire A,
    input  wire B,
    input  wire Cin,
    output wire Sum,
    output wire Cout
);

    assign Sum  = A ^ B ^ Cin;
    assign Cout = (A & B) | (B & Cin) | (A & Cin);

endmodule