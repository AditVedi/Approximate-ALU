module approx_adder_k2 #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);

    // Approximate lower 2 bits using OR
    assign sum[1:0] = a[1:0] | b[1:0];

    // Exact addition for upper bits (no carry from lower bits)
    assign sum[WIDTH-1:2] = a[WIDTH-1:2] + b[WIDTH-1:2];

endmodule