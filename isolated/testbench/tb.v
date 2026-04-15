`timescale 1ns/1ps

module testbench;

    parameter WIDTH = 8;

    reg [WIDTH-1:0] a, b;
    wire [WIDTH-1:0] exact_sum, approx_sum;

    integer i, j;
    integer error, total, errors, max_error;
    real med;

    top uut (
        .a(a),
        .b(b),
        .exact_sum(exact_sum),
        .approx_sum(approx_sum)
    );

    initial begin
        total = 0;
        errors = 0;
        max_error = 0;
        med = 0;

        // Full sweep (256 × 256)
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #1;

                // Absolute error
                if (exact_sum >= approx_sum)
                    error = exact_sum - approx_sum;
                else
                    error = approx_sum - exact_sum;

                total = total + 1;
                med = med + error;

                if (error != 0)
                    errors = errors + 1;

                if (error > max_error)
                    max_error = error;
            end
        end

        med = med / total;

        $display("\n===== RESULTS =====");
        $display("Total samples   : %d", total);
        $display("Error count     : %d", errors);
        $display("Error rate      : %f %%", (errors*100.0)/total);
        $display("MED             : %f", med);
        $display("Max error       : %d", max_error);

        $finish;
    end

endmodule