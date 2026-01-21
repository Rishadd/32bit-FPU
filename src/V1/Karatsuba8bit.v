`timescale 1ns / 1ps

module Karatsuba8bit (
    input  [7:0] A,
    input  [7:0] B,
    output [15:0] P
);

    wire [7:0] Z0, Z2, Z1;

    Karatsuba4bit m0 (A[3:0], B[3:0], Z0);
    Karatsuba4bit m2 (A[7:4], B[7:4], Z2);
    Karatsuba4bit m1 (A[3:0] + A[7:4], B[3:0] + B[7:4], Z1);

    wire signed [15:0] mid = $signed(Z1) - $signed(Z2) - $signed(Z0);

    assign P = (Z2 << 8) + (mid << 4) + Z0;

endmodule
