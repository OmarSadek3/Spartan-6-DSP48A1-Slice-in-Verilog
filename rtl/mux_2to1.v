module mux_2to1 #(
    parameter WIDTH = 18 
)(
    input  wire [WIDTH-1:0] in0, // Bypass
    input  wire [WIDTH-1:0] in1, // Register Value
    input  wire             sel, 
    output wire [WIDTH-1:0] out
);

    assign out = sel ? in1 : in0;

endmodule