module top #(
    parameter WIDTH = 8
)(
    input clk,
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output reg [WIDTH-1:0] exact_sum,
    output reg [WIDTH-1:0] approx_sum
);
    wire [WIDTH-1:0] approx_sum_w;
    // Exact disabled
    wire [WIDTH-1:0] exact_sum_w = 0;
    // Approx adder enabled
    approx_adder_k2 #(.WIDTH(WIDTH)) u_approx (
        .a(a),
        .b(b),
        .sum(approx_sum_w)
    );
    // Register outputs
    always @(posedge clk) begin
        exact_sum  <= exact_sum_w;
        approx_sum <= approx_sum_w;
    end
endmodule