`timescale 1ns / 1ps

module Karatsuba4bit (
    input [3:0] A,
    input [3:0] B,
    output [7:0] P
);

    wire [3:0] Z0;
    wire [3:0] Z2;
    wire [5:0] Z1;

    Multiplier2bit m0 (A[1:0], B[1:0], Z0);
    Multiplier2bit m2 (A[3:2], B[3:2], Z2);

    wire [2:0] Asum = A[1:0] + A[3:2];
    wire [2:0] Bsum = B[1:0] + B[3:2];

    Multiplier3bit m3 (Asum, Bsum, Z1);

    wire signed [7:0] middle = $signed({2'b00, Z1}) - 
                               $signed({4'b0000, Z2}) - 
                               $signed({4'b0000, Z0});

    assign P = (Z2 << 4) + (middle << 2) + Z0;

endmodule
