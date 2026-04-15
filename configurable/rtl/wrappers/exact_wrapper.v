`timescale 1ns/1ps

module exact_top #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] op,
    output reg [WIDTH-1:0] result
);

    // -------------------------
    // Input Registers
    // -------------------------
    reg [WIDTH-1:0] a_r, b_r;
    reg [2:0] op_r;

    always @(posedge clk) begin
        a_r  <= a;
        b_r  <= b;
        op_r <= op;
    end

    // -------------------------
    // ALU Core
    // -------------------------
    wire [WIDTH-1:0] alu_out;
    wire carry_out, zero;

    exact_alu #(.WIDTH(WIDTH)) u_exact (
        .a(a_r),
        .b(b_r),
        .op(op_r),
        .result(alu_out),
        .carry_out(carry_out),
        .zero(zero)
    );

    // -------------------------
    // Output Register
    // -------------------------
    always @(posedge clk) begin
        result <= alu_out;
    end

endmodule
