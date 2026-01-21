module Multiplier3bit (
    input  [2:0] A,
    input  [2:0] B,
    output [5:0] P
);
    wire [3:0] lo;  
    Multiplier2bit m0 (A[1:0], B[1:0], lo);

    wire a2b0 = A[2] & B[0];
    wire a2b1 = A[2] & B[1];
    wire a2b2 = A[2] & B[2];

    wire a0b2 = A[0] & B[2];
    wire a1b2 = A[1] & B[2];

    // Proper 3×3 addition tree:
    assign P[0] = lo[0];

    assign P[1] = lo[1] ^ a2b0;
    wire c1 = lo[1] & a2b0;

    wire s2 = lo[2] ^ a2b1 ^ a0b2;
    wire c2 = (lo[2] & a2b1) | (lo[2] & a0b2) | (a2b1 & a0b2);

    assign P[2] = s2 ^ c1;
    wire c3 = (s2 & c1) | c2;

    wire s3 = lo[3] ^ a2b2 ^ a1b2;
    wire c4 = (lo[3] & a2b2) | (lo[3] & a1b2) | (a2b2 & a1b2);

    assign P[3] = s3 ^ c3;
    wire c5 = (s3 & c3) | c4;

    assign P[4] = c5;
    assign P[5] = 0;

endmodule
