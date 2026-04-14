`timescale 1ns/1ps

module approx_top #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] op,
    input [1:0] amode,
    input [1:0] mmode,
    input [7:0] k,
    output reg [WIDTH-1:0] result
);

    reg [WIDTH-1:0] a_r, b_r;
    reg [2:0] op_r;
    reg [1:0] amode_r, mmode_r;
    reg [7:0] k_r;

    always @(posedge clk) begin
        a_r     <= a;
        b_r     <= b;
        op_r    <= op;
        amode_r <= amode;
        mmode_r <= mmode;
        k_r     <= k;
    end

    wire [WIDTH-1:0] alu_out;
    wire carry_out, zero;

    approximate_alu #(.WIDTH(WIDTH)) u_approx (
        .a(a_r),
        .b(b_r),
        .op(op_r),
        .amode(amode_r),
        .mmode(mmode_r),
        .k(k_r),
        .result(alu_out),
        .carry_out(carry_out),
        .zero(zero)
    );

    always @(posedge clk) begin
        result <= alu_out;
    end

endmodule