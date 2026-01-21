`timescale 1ns/1ps

module tb_karatsuba_32;

    reg  [31:0] A;
    reg  [31:0] B;
    wire [63:0] P;

    // DUT
    karatsuba_32_gate dut (
        .A(A),
        .B(B),
        .P(P)
    );

    integer i;
    reg [63:0] golden;

    initial begin
        $display("==============================================");
        $display("     Testing 32x32 Karatsuba Multiplier");
        $display("==============================================");

        // Corner case 1
        A = 0; B = 0; #10;
        golden = A * B;
        if (P !== golden) $display("FAIL: 0*0 expected %h got %h", golden, P);

        // Corner case 2
        A = 32'hFFFFFFFF; B = 32'hFFFFFFFF; #10;
        golden = A * B;
        if (P !== golden) $display("FAIL: FFFF*FFFF expected %h got %h", golden, P);

        // Random tests
        $display("Running 1000 random tests...");
        for (i = 0; i < 1000; i = i + 1) begin
            A = $random;
            B = $random;
            #1;
            golden = A * B;
            if (P !== golden) begin
                $display("FAIL at test %0d:", i);
                $display(" A = %h", A);
                $display(" B = %h", B);
                $display(" Expected = %h", golden);
                $display(" Got      = %h", P);
                $finish;
            end
        end

        $display("==============================================");
        $display("   ALL TESTS PASSED for 32-bit Karatsuba!");
        $display("==============================================");
        $finish;
    end
endmodule
