`timescale 1ns/1ps

module approximate_alu #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0]       op,
    input  [1:0]       amode,    // 0=exact,1=trunc,2=lsb_mask,3=spec_block
    input  [1:0]       mmode,    // 0=exact,1=trunc,2=pp_trunc
    input  [7:0]       k,        // runtime parameter (truncation amount / block size / drop amount)
    output reg [WIDTH-1:0] result,
    output reg carry_out,
    output reg zero
);

    localparam ADD = 3'b000;
    localparam SUB = 3'b001;
    localparam ANDP= 3'b010;
    localparam ORP = 3'b011;
    localparam XORP= 3'b100;
    localparam SLL = 3'b101;
    localparam SRL = 3'b110;
    localparam MUL = 3'b111;

    wire [WIDTH-1:0] sum_exact;
    wire [WIDTH-1:0] sum_trunc;
    wire [WIDTH-1:0] sum_lsb_mask;
    wire [WIDTH-1:0] sum_spec;
    wire cout_exact, cout_trunc, cout_lsb_mask, cout_spec;

    wire [2*WIDTH-1:0] prod_exact;
    wire [2*WIDTH-1:0] prod_trunc;
    wire [2*WIDTH-1:0] prod_pp_trunc;

    exact_adder #( .WIDTH(WIDTH) ) u_exact_add ( .a(a), .b(b), .cin(1'b0), .sum(sum_exact), .cout(cout_exact) );
    trunc_adder #( .WIDTH(WIDTH) ) u_trunc_add ( .a(a), .b(b), .k(k), .sum(sum_trunc), .cout(cout_trunc) );
    lsb_mask_adder #( .WIDTH(WIDTH) ) u_lsb_mask_add ( .a(a), .b(b), .m(k), .sum(sum_lsb_mask), .cout(cout_lsb_mask) );
    spec_block_adder #( .WIDTH(WIDTH) ) u_spec_add ( .a(a), .b(b), .block(k), .sum(sum_spec), .cout(cout_spec) );

    exact_mult #( .A(WIDTH), .B(WIDTH) ) u_exact_mul ( .a(a), .b(b), .prod(prod_exact) );
    trunc_mult #( .A(WIDTH), .B(WIDTH) ) u_trunc_mul ( .a(a), .b(b), .trunc(k), .prod(prod_trunc) );
    pp_trunc_mult #( .A(WIDTH), .B(WIDTH) ) u_pp_trunc_mul ( .a(a), .b(b), .drop_low(k), .prod(prod_pp_trunc) );

    integer i;
    always @(*) begin
        result = {WIDTH{1'b0}};
        carry_out = 1'b0;
        zero = 1'b0;

        case (op)
            ADD: begin
                case (amode)
                    2'd0: begin result = sum_exact; carry_out = cout_exact; end
                    2'd1: begin result = sum_trunc; carry_out = cout_trunc; end
                    2'd2: begin result = sum_lsb_mask; carry_out = cout_lsb_mask; end
                    2'd3: begin result = sum_spec; carry_out = cout_spec; end
                    default: begin result = sum_exact; carry_out = cout_exact; end
                endcase
            end

            SUB: begin
                {carry_out, result} = {1'b0, a} - {1'b0, b};
            end

            ANDP: begin result = a & b; end
            ORP:  begin result = a | b; end
            XORP: begin result = a ^ b; end

            SLL: begin
                result = a << b[($clog2(WIDTH))-1:0];
            end

            SRL: begin
                result = a >> b[($clog2(WIDTH))-1:0];
            end

            MUL: begin
                case (mmode)
                    2'd0: begin result = prod_exact[WIDTH-1:0]; carry_out = |prod_exact[2*WIDTH-1:WIDTH]; end
                    2'd1: begin result = prod_trunc[WIDTH-1:0]; carry_out = |prod_trunc[2*WIDTH-1:WIDTH]; end
                    2'd2: begin result = prod_pp_trunc[WIDTH-1:0]; carry_out = |prod_pp_trunc[2*WIDTH-1:WIDTH]; end
                    default: begin result = prod_exact[WIDTH-1:0]; carry_out = |prod_exact[2*WIDTH-1:WIDTH]; end
                endcase
            end

            default: begin result = {WIDTH{1'b0}}; end
        endcase

        zero = (result == {WIDTH{1'b0}});
    end

endmodule

module exact_adder #(parameter WIDTH = 8)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
    assign {cout, sum} = a + b + cin;
endmodule

module trunc_adder #(parameter WIDTH = 8)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [7:0]       k,
    output [WIDTH-1:0] sum,
    output             cout
);
    wire [WIDTH-1:0] mask;
    wire [WIDTH-1:0] a_m, b_m;
    wire [WIDTH:0]   tmp;
    assign mask = (k >= WIDTH) ? {WIDTH{1'b0}} : ( { {WIDTH{1'b1}} } << k );
    assign a_m = a & mask;
    assign b_m = b & mask;
    assign tmp = a_m + b_m;
    assign sum = tmp[WIDTH-1:0];
    assign cout = tmp[WIDTH];
endmodule

module lsb_mask_adder #(parameter WIDTH = 8)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [7:0]       m,
    output [WIDTH-1:0] sum,
    output             cout
);
    reg  [WIDTH-1:0] r_lo;
    wire [WIDTH-1:0] a_hi, b_hi;
    wire [WIDTH:0]   high_sum;
    integer idx;
    always @(*) begin
        r_lo = {WIDTH{1'b0}};
        for (idx = 0; idx < WIDTH; idx = idx + 1) begin
            if (idx < m)
                r_lo[idx] = a[idx] | b[idx];
            else
                r_lo[idx] = 1'b0;
        end
    end
    assign a_hi = (m >= WIDTH) ? {WIDTH{1'b0}} : (a >> m);
    assign b_hi = (m >= WIDTH) ? {WIDTH{1'b0}} : (b >> m);
    assign high_sum = a_hi + b_hi;
    wire [WIDTH-1:0] r_high;
    assign r_high = (high_sum << m) & {WIDTH{1'b1}};
    assign sum = r_high | r_lo;
    assign cout = (|high_sum[WIDTH:WIDTH]) ? 1'b1 : 1'b0;
endmodule

module spec_block_adder #(parameter WIDTH = 8)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [7:0]       block,   
    output [WIDTH-1:0] sum,
    output             cout
);
    reg [WIDTH-1:0] rsum;
    reg rcout;
    integer idx;
    integer start_idx;    
    integer cur_w;
    reg [WIDTH-1:0] mask_block;
    reg [WIDTH-1:0] tmp_place;
    reg [WIDTH:0] block_sum;

    always @(*) begin
        rsum = {WIDTH{1'b0}};
        rcout = 1'b0;

        if (block == 0 || block >= WIDTH) begin
            { rcout, rsum } = a + b;
        end else begin
            for (idx = 0; idx < WIDTH; idx = idx + 1) begin
                if ((idx % block) == 0) begin
                    start_idx = idx;
                    if ((start_idx + block - 1) < (WIDTH - 1))
                        cur_w = block;
                    else
                        cur_w = WIDTH - start_idx;

                    if (cur_w >= WIDTH)
                        mask_block = {WIDTH{1'b1}};
                    else
                        mask_block = ({WIDTH{1'b1}} >> (WIDTH - cur_w));

                    block_sum = ( ((a >> start_idx) & mask_block) + ((b >> start_idx) & mask_block) );
                    tmp_place = ( (block_sum & mask_block) << start_idx );
                    rsum = rsum | tmp_place;

                    if (block_sum > mask_block)
                        rcout = 1'b1;
                end
            end
        end
    end

    assign sum = rsum;
    assign cout = rcout;
endmodule

module exact_mult #(parameter A = 8, parameter B = 8)(
    input  [A-1:0] a,
    input  [B-1:0] b,
    output [A+B-1:0] prod
);
    assign prod = a * b;
endmodule

module trunc_mult #(parameter A = 8, parameter B = 8)(
    input  [A-1:0] a,
    input  [B-1:0] b,
    input  [7:0]   trunc,
    output [A+B-1:0] prod
);
    localparam MAXT = (A < B) ? A : B;
    wire [7:0] t;
    assign t = (trunc >= MAXT) ? MAXT : trunc;
    wire [A-1:0] a_shr;
    wire [B-1:0] b_shr;
    assign a_shr = a >> t;
    assign b_shr = b >> t;
    assign prod = (a_shr * b_shr) << (2*t);
endmodule

module pp_trunc_mult #(parameter A = 8, parameter B = 8)(
    input  [A-1:0] a,
    input  [B-1:0] b,
    input  [7:0]   drop_low,
    output [A+B-1:0] prod
);
    wire [A+B-1:0] exact;
    wire [A+B-1:0] mask;
    assign exact = a * b;
    assign mask = (drop_low >= (A+B)) ? {A+B{1'b0}} : ({ {A+B{1'b1}} } << drop_low);
    assign prod = exact & mask;
endmodule
