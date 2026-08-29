module DSP48A1 #(
    // Attributes (Configuration Bits)
    parameter A0REG = 0,
    parameter A1REG = 1,
    parameter B0REG = 0,
    parameter B1REG = 1,
    parameter CREG = 1,
    parameter DREG = 1,
    parameter MREG = 1,
    parameter PREG = 1,
    parameter CARRYINREG = 1,
    parameter OPMODEREG = 1,
    parameter CARRYINSEL = "CARRYIN",
    parameter CARRYOUTREG = 1,
    parameter B_INPUT = "DIRECT"
)(
    // Clock and Control Pins
    input  wire        CLK,
    input  wire        CEA, CEB, CEC, CECY, CED, CEM, CEO, CEP,
    input  wire        RSTA, RSTB, RSTC, RSTCY, RSTD, RSTM, RSTO, RSTP,
    
    // Data Inputs
    input  wire [17:0] A, B, D, BCIN,
    input  wire [47:0] C, PCIN,
    input  wire [7:0]  OPMODE,
    input  wire        CIN,
    
    
    // Data Outputs
    output wire [17:0] BCOUT,
    output wire [47:0] P, PCOUT,
    output wire [35:0] MFOUT,
    output wire        CCOUT, CFOUT
    
);

    // 1. Internal Wires
   
    wire [7:0]  opmode_reg_out, opmode_mux_out;
    wire [17:0] b_actual_in; // Selects between B and BCIN
    
    // Stage 1 --Input_Registers and MUX_Outputs
    wire [17:0] d_reg_out, d_mux_out;
    wire [17:0] b0_reg_out, b0_mux_out;
    wire [17:0] a0_reg_out, a0_mux_out;
    wire [47:0] c_reg_out, c_mux_out;
    
    // Stage 2 --Pre-Adder & Second Stage Registers Outputs
    wire [17:0] pre_adder_out;
    wire [17:0] b_pre_adder_mux; // Mux controlled by opmode[4]
    wire [17:0] b1_reg_out, b1_mux_out;
    wire [17:0] a1_reg_out, a1_mux_out;
    
    // Stage 3 --Multiplier Output
    wire [35:0] m_out_comb;
    wire [35:0] m_reg_out, m_mux_out;
    
    // Stage 4 --Carry, X & Z Muxes
    wire        carry_out_int;
    wire [47:0] x_mux_out, z_mux_out;
    
    // Stage 5 --Post-Adder & P Register
    wire [47:0] p_out_comb;
    wire [47:0] p_reg_out, p_mux_out;
    wire post_adder_cout;
    wire cyo_reg_out;
    wire cout_mux_out;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // 2. OPMODE Logic
 
    register #(8) opmode_reg (.clk(CLK), .rst(RSTO), .ce(CEO), .d(OPMODE), .q(opmode_reg_out));
    mux_2to1 #(8) opmode_mux (.in0(OPMODE), .in1(opmode_reg_out), .sel(OPMODEREG), .out(opmode_mux_out));

/////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 3. Input Ports Logic (D, B, A, C)

    // D Port
    register #(18) d_reg (.clk(CLK), .rst(RSTD), .ce(CED), .d(D), .q(d_reg_out));
    mux_2to1 #(18) d_mux (.in0(D), .in1(d_reg_out), .sel(DREG), .out(d_mux_out));

    // B Port (Handles B_INPUT attribute)
    assign b_actual_in = (B_INPUT == "CASCADE") ? BCIN : B; // Selects between B and BCIN based on B_INPUT attribute
    register #(18) b0_reg (.clk(CLK), .rst(RSTB), .ce(CEB), .d(b_actual_in), .q(b0_reg_out));
    mux_2to1 #(18) b0_mux (.in0(b_actual_in), .in1(b0_reg_out), .sel(B0REG), .out(b0_mux_out));

    // A Port
    register #(18) a0_reg (.clk(CLK), .rst(RSTA), .ce(CEA), .d(A), .q(a0_reg_out));
    mux_2to1 #(18) a0_mux (.in0(A), .in1(a0_reg_out), .sel(A0REG), .out(a0_mux_out));

    // C Port
    register #(48) c_reg (.clk(CLK), .rst(RSTC), .ce(CEC), .d(C), .q(c_reg_out));
    mux_2to1 #(48) c_mux (.in0(C), .in1(c_reg_out), .sel(CREG), .out(c_mux_out));

////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 4. Pre-Adder and Stage 1 Registers (A1, B1)
    pre_adder_subtracter pre_adder_inst (
        .D(d_mux_out), .B(b0_mux_out), 
        .opmode_6(opmode_mux_out[6]), .pre_adder_out(pre_adder_out)
    );

    // Mux controlled by opmode[4] 
    assign b_pre_adder_mux = opmode_mux_out[4] ? pre_adder_out : b0_mux_out;

    // B1 Register
    register #(18) b1_reg (.clk(CLK), .rst(RSTB), .ce(CEB), .d(b_pre_adder_mux), .q(b1_reg_out));
    mux_2to1 #(18) b1_mux (.in0(b_pre_adder_mux), .in1(b1_reg_out), .sel(B1REG), .out(b1_mux_out));
    assign BCOUT = b1_mux_out; // Cascade output for B

    // A1 Register
    register #(18) a1_reg (.clk(CLK), .rst(RSTA), .ce(CEA), .d(a0_mux_out), .q(a1_reg_out));
    mux_2to1 #(18) a1_mux (.in0(a0_mux_out), .in1(a1_reg_out), .sel(A1REG), .out(a1_mux_out));

////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 5. Multiplier
    multiplier mult_inst (
        .A_mult(a1_mux_out), .B_mult(b1_mux_out), .M_out(m_out_comb)
    );

    register #(36) m_reg (.clk(CLK), .rst(RSTM), .ce(CEM), .d(m_out_comb), .q(m_reg_out));
    mux_2to1 #(36) m_mux (.in0(m_out_comb), .in1(m_reg_out), .sel(MREG), .out(m_mux_out));
    assign MFOUT = m_mux_out; // Route multiplier output to FPGA logic

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 6. Carry, X, and Z Multiplexers
    carry_input #(
        .CARRYINSEL(CARRYINSEL), .CARRYINREG(CARRYINREG)
    ) carry_inst (
        .clk(CLK), .RSTCY(RSTCY), .CECY(CECY), .CIN(CIN),
        .opmode_5(opmode_mux_out[5]), .carry_out(carry_out_int)
    );

    x_mux x_mux_inst (
        .M_out(m_mux_out), .P_in(p_mux_out), .D_in(d_mux_out), 
        .A_in(a1_mux_out), .B_in(b1_mux_out), 
        .opmode_1_0(opmode_mux_out[1:0]), .X_out(x_mux_out)
    ); 

    z_mux z_mux_inst (
        .PCIN(PCIN), .P_in(p_mux_out), .C_in(c_mux_out),
        .opmode_3_2(opmode_mux_out[3:2]), .Z_out(z_mux_out)
    );
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // 7. Post-Adder/Subtracter and P Output
    post_adder_subtracter post_adder_inst (
        .Z(z_mux_out), .X(x_mux_out), .CIN(carry_out_int),
        .opmode_7(opmode_mux_out[7]), .P_out(p_out_comb),.carry_out(post_adder_cout)
    );

    register #(48) p_reg (.clk(CLK), .rst(RSTP), .ce(CEP), .d(p_out_comb), .q(p_reg_out));
    mux_2to1 #(48) p_mux (.in0(p_out_comb), .in1(p_reg_out), .sel(PREG), .out(p_mux_out));

    assign P = p_mux_out;
    assign PCOUT = p_mux_out; // Cascade output for P

//////////////////////////////////////////////////////////////////////////////////////////////////////////////    
    // 8. Carry and Overflow Outputs
    register #(1) cyo_reg (
    .clk(CLK), .rst(RSTCY), .ce(CECY), .d(post_adder_cout), .q(cyo_reg_out)
); 

    mux_2to1 #(1) cyo_mux (
        .in0(post_adder_cout), .in1(cyo_reg_out), .sel(CARRYOUTREG), .out(cout_mux_out)
    );

    assign CCOUT = cout_mux_out; // Carry output
    assign CFOUT = cout_mux_out;  // Overflow output (same as carry for this implementation)

endmodule