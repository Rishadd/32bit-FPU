`timescale 1ns / 1ps

module Karatsuba16bit (
    input  [15:0] A,
    input  [15:0] B,
    output [31:0] P
);

    wire [15:0] Z0, Z2, Z1;

    Karatsuba8bit m0 (A[7:0],  B[7:0],  Z0);
    Karatsuba8bit m2 (A[15:8], B[15:8], Z2);
    Karatsuba8bit m1 (A[7:0] + A[15:8], B[7:0] + B[15:8], Z1);

    wire signed [31:0] mid = $signed(Z1) - $signed(Z2) - $signed(Z0);

    assign P = (Z2 << 16) + (mid << 8) + Z0;

endmodule
