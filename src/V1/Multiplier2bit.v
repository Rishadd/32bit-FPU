`timescale 1ns / 1ps

module Multiplier2bit(
    input  [1:0] A,
    input  [1:0] B,
    output [3:0] P
);

    wire p0 = A[0] & B[0];

    wire p1_0 = A[0] & B[1];
    wire p1_1 = A[1] & B[0];
    wire p1 = p1_0 ^ p1_1;
    wire carry1 = p1_0 & p1_1;

    wire p2_0 = A[1] & B[1];
    wire p2 = p2_0 ^ carry1;
    wire p3 = p2_0 & carry1;

    assign P = {p3, p2, p1, p0};

endmodule
