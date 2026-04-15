`timescale 1ns/1ps
module top_module #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] op,
    input mode,                
    input [1:0] amode,         
    input [1:0] mmode,         
    input [7:0] k,             
    output reg [WIDTH-1:0] result,
    output reg carry_out,
    output reg zero,
    output [WIDTH-1:0] exact_result,
    output [WIDTH-1:0] approx_result,
    output exact_carry,
    output approx_carry
);
    exact_alu #( .WIDTH(WIDTH) ) u_exact ( .a(a), .b(b), .op(op), .result(exact_result), .carry_out(exact_carry), .zero() );
    approximate_alu #( .WIDTH(WIDTH) ) u_approx (
        .a(a), .b(b), .op(op),
        .amode(amode), .mmode(mmode), .k(k),
        .result(approx_result), .carry_out(approx_carry), .zero()
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= {WIDTH{1'b0}};
            carry_out <= 1'b0;
            zero <= 1'b0;
        end else begin
            if (mode == 1'b0) begin
                result <= exact_result;
                carry_out <= exact_carry;
                zero <= (exact_result == {WIDTH{1'b0}});
            end else begin
                result <= approx_result;
                carry_out <= approx_carry;
                zero <= (approx_result == {WIDTH{1'b0}});
            end
        end
    end
endmodule
