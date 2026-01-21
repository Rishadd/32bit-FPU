`timescale 1ns / 1ps

module Karatsuba32bit (
    input  [31:0] A,
    input  [31:0] B,
    output [63:0] P
);

    wire [15:0] A_L = A[15:0];
    wire [15:0] A_H = A[31:16];
    wire [15:0] B_L = B[15:0];
    wire [15:0] B_H = B[31:16];

    wire [31:0] Z0, Z2, Z1;

    Karatsuba16bit m0 (.A(A_L), .B(B_L), .P(Z0));
    Karatsuba16bit m2 (.A(A_H), .B(B_H), .P(Z2));
    Karatsuba16bit m1 (.A(A_L + A_H), .B(B_L + B_H), .P(Z1));

    wire signed [63:0] mid = 
        $signed({32'b0, Z1}) - 
        $signed({32'b0, Z2}) - 
        $signed({32'b0, Z0});

    assign P = ({Z2, 32'b0}) + (mid << 16) + Z0;

endmodule