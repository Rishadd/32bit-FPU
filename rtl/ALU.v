module ALU(
    input clk,
    input rst,
    input i_vld,
    input [31:0] i_a,
    input [31:0] i_b,
    input opcode,
    output reg [31:0] o_res,
    output reg o_res_vld,
    output reg overflow
);

wire [31:0] add_o_res, mul_o_res;
wire add_o_res_vld, mul_o_res_vld;
wire add_overflow, mul_overflow;

adder_32bit adder_inst(
    .clk(clk),
    .rst(rst),
    .i_a(i_a),
    .i_b(i_b),
    .i_vld(i_vld),
    .o_res(add_o_res),
    .o_res_vld(add_o_res_vld),
    .overflow(add_overflow)
);

multiplier_32bit multiplier_inst(
    .clk(clk),
    .rst(rst),
    .i_a(i_a),
    .i_b(i_b),
    .i_vld(i_vld),
    .o_res(mul_o_res),
    .o_res_vld(mul_o_res_vld),
    .overflow(mul_overflow)
);

always @(*) begin
    case (opcode)
        1'b0: begin
            o_res = add_o_res;
            o_res_vld = add_o_res_vld;
            overflow = add_overflow;
        end
        1'b1: begin
            o_res = mul_o_res;
            o_res_vld = mul_o_res_vld;
            overflow = mul_overflow;
        end
        default: begin
            o_res = 32'b0;
            o_res_vld = 1'b0;
            overflow = 1'b0;
        end
    endcase
end

endmodule
