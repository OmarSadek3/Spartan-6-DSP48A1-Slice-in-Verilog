`timescale 1ns / 1ps

module tb_radar_collision_system;

    // Clock and Global Signals
    reg clk;
    reg rst;
    
    // DSP Shared Control (OPMODE for MAC)
    reg [7:0] OPMODE;
    reg signed [17:0] B_dt; // Time step dt is shared
    
    // Projectile A (Interceptor) Signals
    reg signed [17:0] A_vya; // Vertical velocity A
    wire signed [47:0] P_ya; // Height Y of A (from DSP A)
    
    // Projectile B (Target) Signals
    reg signed [17:0] A_vyb; // Vertical velocity B
    wire signed [47:0] P_yb; // Height Y of B (from DSP B)
    
    // Unused DSP inputs tied to zero
    reg signed [17:0] D_in, B_cascade;
    reg signed [47:0] C_in, P_cascade;
    reg cin;

    // Simulation Variables
    integer x_a, x_b;      // Horizontal positions
    integer v_xa, v_xb;    // Horizontal speeds
    integer gravity;
    integer file;
    integer cycle_count;
    integer sync_x_a, sync_x_b;
    
    // Collision Tolerance (Margin of error for intersection)
    parameter TOLERANCE = 15; 
    integer diff_x, diff_y;


    // DSP Instance A (Calculates Y for Projectile A)

    DSP48A1 #(.PREG(1), .MREG(1), .A1REG(1), .B1REG(1)) dsp_A (
        .CLK(clk), .RSTA(rst), .RSTB(rst), .RSTC(rst), .RSTCY(rst), 
        .RSTD(rst), .RSTM(rst), .RSTO(rst), .RSTP(rst),
        .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CECY(1'b1), .CED(1'b1), .CEM(1'b1), .CEO(1'b1), .CEP(1'b1),
        .A(A_vya), .B(B_dt), .C(C_in), .D(D_in), .BCIN(B_cascade), .PCIN(P_cascade), 
        .OPMODE(OPMODE), .CIN(cin), .P(P_ya) // Extracting only P for simplicity
    );


    // DSP Instance B (Calculates Y for Projectile B)

    DSP48A1 #(.PREG(1), .MREG(1), .A1REG(1), .B1REG(1)) dsp_B (
        .CLK(clk), .RSTA(rst), .RSTB(rst), .RSTC(rst), .RSTCY(rst), 
        .RSTD(rst), .RSTM(rst), .RSTO(rst), .RSTP(rst),
        .CEA(1'b1), .CEB(1'b1), .CEC(1'b1), .CECY(1'b1), .CED(1'b1), .CEM(1'b1), .CEO(1'b1), .CEP(1'b1),
        .A(A_vyb), .B(B_dt), .C(C_in), .D(D_in), .BCIN(B_cascade), .PCIN(P_cascade), 
        .OPMODE(OPMODE), .CIN(cin), .P(P_yb) 
    );

    
    always #5 clk = ~clk;

initial begin
        file = $fopen("collision_data.txt", "w");
        
        // Initialize System
        clk = 0; rst = 1;
        D_in = 0; B_cascade = 0; C_in = 0; P_cascade = 0; cin = 0;
        
        // OPMODE: X=Mult, Z=P_reg, Post-Adder=Add (MAC Operation)
        OPMODE = 8'b0000_1001; 
        B_dt = 18'sd1;   // dt = 1
        gravity = 98;    // g = 98 scaled by 10
        
        // Initial Conditions for A
        A_vya = 18'sd2000; 
        x_a = 0;
        v_xa = 2500;       
        
        // Initial Conditions for B
        A_vyb = 18'sd2000; 
        x_b = 80000;       
        v_xb = 1500;       

        cycle_count = 0;

        #15 rst = 0; 
        
        $display("Radar Tracking Started...");
        
      
        begin : sim_loop
            while (1) begin
                if (cycle_count >= 3) begin
                    sync_x_a = x_a - (3 * v_xa);
                    sync_x_b = x_b + (3 * v_xb);
                    
                    // The standard Verilog way to "break" out of a loop
                    if (P_ya < 0 || P_yb < 0) disable sim_loop; 
                    
                    $fwrite(file, "%d %d %d %d\n", sync_x_a, P_ya, sync_x_b, P_yb);
                    
                    // Collision Detection Logic
                    diff_x = (sync_x_a > sync_x_b) ? (sync_x_a - sync_x_b) : (sync_x_b - sync_x_a);
                    diff_y = (P_ya > P_yb) ? (P_ya - P_yb) : (P_yb - P_ya);
                    
                    if (diff_x <= 150 && diff_y <= 150) begin
                        $display(">>> BOOM! INTERSECTION DETECTED <<<");
                        $display("Collision at X: %d, Y: %d", sync_x_a, P_ya);
                        $fwrite(file, "COLLISION %d %d\n", sync_x_a, P_ya);
                        #10 $finish;
                    end
                end
                
                //  update
                x_a = x_a + v_xa;
                x_b = x_b - v_xb;
                A_vya = A_vya - gravity;
                A_vyb = A_vyb - gravity;
                
                cycle_count = cycle_count + 1;
                @(posedge clk);
            end
        end
        
        $display("Target Missed.");
        $fclose(file);
        $finish;
    end
endmodule