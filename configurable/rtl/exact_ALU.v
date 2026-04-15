`timescale 1ns/1ps

module exact_alu #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0]       op,
    output reg [WIDTH-1:0] result,
    output reg carry_out,
    output reg zero
);
    localparam ADD  = 3'b000;
    localparam SUB  = 3'b001;
    localparam ANDP = 3'b010;
    localparam ORP  = 3'b011;
    localparam XORP = 3'b100;
    localparam SLL  = 3'b101;
    localparam SRL  = 3'b110;
    localparam MUL  = 3'b111;
    
    reg [WIDTH:0] temp_result;
    reg [2*WIDTH-1:0] mul_result;
    
    always @(*) begin
        carry_out = 1'b0;
        temp_result = {(WIDTH+1){1'b0}};
        mul_result = {(2*WIDTH){1'b0}};
        
        case (op)
            ADD: begin
                temp_result = a + b;
                result = temp_result[WIDTH-1:0];
                carry_out = temp_result[WIDTH];
            end
            
            SUB: begin
                {carry_out, result} = {1'b0, a} - {1'b0, b};
            end
            
            ANDP: begin
                result = a & b;
            end
            
            ORP: begin
                result = a | b;
            end
            
            XORP: begin
                result = a ^ b;
            end
            
            SLL: begin
                result = a << b[($clog2(WIDTH))-1:0];
            end
            
            SRL: begin
                result = a >> b[($clog2(WIDTH))-1:0];
            end
            
            MUL: begin
                mul_result = a * b;
                result = mul_result[WIDTH-1:0];
                carry_out = |mul_result[2*WIDTH-1:WIDTH];
            end
            
            default: begin
                result = {WIDTH{1'b0}};
            end
        endcase
        
        zero = (result == {WIDTH{1'b0}});
    end
endmodule
