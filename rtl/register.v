module register #(
    parameter WIDTH = 18 
)(
    input  wire             clk,
    input  wire             rst, // Synchronous Reset
    input  wire             ce,  // Clock Enable
    input  wire [WIDTH-1:0] d,   // Data In
    output reg  [WIDTH-1:0] q    // Data Out
);

    always @(posedge clk) begin
        if (rst) begin
            q <= {WIDTH{1'b0}}; // reset the output to zero on reset
        end else if (ce) begin
            q <= d; // register the new data if the enable is active
        end
        // if there is no reset and the enable is inactive, the q will hold its previous value
    end

endmodule