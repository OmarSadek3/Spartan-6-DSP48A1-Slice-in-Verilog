module carry_input #(
    parameter CARRYINSEL = "CARRYIN", // "CARRYIN" or "OPMODE5"
    parameter CARRYINREG = 1          // 1 to use CYI register, 0 to bypass
)(
    input  wire clk,
    input  wire RSTCY,       // Reset for CYI
    input  wire CECY,        // Clock Enable for CYI
    input  wire CIN,         // Carry Cascade input
    input  wire opmode_5,    // opmode[5] input
    output wire carry_out    // Goes to Post-Adder/Subtracter
);

    wire carry_mux1_out;
    reg  CYI; // The CYI register matching the schematic name

    // 1st MUX: Selects between CIN and opmode[5] based on CARRYINSEL attribute
    assign carry_mux1_out = (CARRYINSEL == "OPMODE5") ? opmode_5 : CIN;

    // CYI Register Logic
    always @(posedge clk) begin
        if (RSTCY) begin
            CYI <= 1'b0;
        end else if (CECY) begin
            CYI <= carry_mux1_out;
        end
    end

    // 2nd MUX: Selects between the CYI register output and the direct path
    assign carry_out = (CARRYINREG == 1) ? CYI : carry_mux1_out;

endmodule