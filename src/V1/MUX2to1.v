`timescale 1ns / 1ps

module MUX2to1_32bit(
    input [31:0] i_a,
    input [31:0] i_b,
    input sel,
    output [31:0] out );
    
    assign out = sel ? i_b :i_a;
    
endmodule
