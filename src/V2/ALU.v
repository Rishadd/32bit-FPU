//========== TOP MODULE ==========

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


//========== ADDER 32 BIT ==========

module adder_32bit(
    input clk,
    input rst,
    input [31:0] i_a,
    input [31:0] i_b,
    input i_vld,
    output reg [31:0] o_res,
    output reg o_res_vld,
    output reg overflow );

wire [7:0] shift;
wire [23:0] al_man_a, al_man_b;
wire sign_a, sign_b, sign_res;
wire [7:0] exp_a, exp_b, exp_res;
wire [23:0] man_a, man_b, man_res;
wire [24:0] res;
wire operation_overflow;

//unpacking the inputs - 32bit single precision
assign sign_a = i_a[31];
assign sign_b = i_b[31];
assign exp_a = i_a[30:23];
assign exp_b = i_b[30:23];
assign man_a = (exp_a == 8'b0) ? {1'b0, i_a[22:0]} : {1'b1, i_a[22:0]}; //adding explicit 1 for normalized and 0 for denormalised numbers
assign man_b = (exp_b == 8'b0) ? {1'b0, i_b[22:0]} : {1'b1, i_b[22:0]};

wire is_nan_a = ((exp_a == 8'b11111111) && (man_a[22:0] != 0)); //only 23 bits of mantissa must be checked excluding the added 1
wire is_nan_b = ((exp_b == 8'b11111111) && (man_b[22:0] != 0));
wire is_inf_a = ((exp_a == 8'b11111111) && (man_a[22:0] == 0));
wire is_inf_b = ((exp_b == 8'b11111111) && (man_b[22:0] == 0));
wire is_zero_a = ((i_a[30:0] == 0)); //sign bit doesnt contribute anything
wire is_zero_b = ((i_b[30:0] == 0));

CompareAndShift32Bit u_CompareAndShift32Bit (
    .exp_a(exp_a),          //input
    .exp_b(exp_b),          //input
    .man_a(man_a),          //input
    .man_b(man_b),          //input
    .al_man_a(al_man_a),    //wire out
    .al_man_b(al_man_b),    //wire out
    .shift(shift)           //wire out
);

Addition32Bit u_Addition32Bit (
    .sign_a(sign_a),        //input
    .sign_b(sign_b),        //input
    .a(al_man_a),           //wire in from submodule
    .b(al_man_b),           //wire in from submodule
    .res(res),              //wire out
    .sign_res(sign_res)     //wire out
);

Normalization32Bit u_Normalization32Bit (
    .res(res),                                  //wire in from submodule
    .exp_base((exp_a > exp_b) ? exp_a : exp_b), //input
    .man_res(man_res),                          //wire out
    .exp_res(exp_res),                          //wire out
    .overflow(operation_overflow)               //wire out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        o_res_vld <= 1'b0;
        o_res <= 32'b0;
        overflow <=0;
    end
    else if (i_vld) begin
        if (is_nan_a || is_nan_b || (is_inf_a && is_inf_b && (sign_a != sign_b))) begin
            o_res <= 32'h7FC00000; // Quiet NaN
            overflow <= 1'b1;
        end 
        else if (is_inf_a || is_inf_b) begin
            o_res <= is_inf_a ? i_a : i_b; // Preserve Infinity
            overflow <= 1'b1;
        end 
        else if (is_zero_a && is_zero_b) begin
            o_res <= 32'b0; // Zero
        end 
        else begin
        o_res <= {sign_res, exp_res, man_res[22:0]};
        o_res_vld <= 1'b1;
        overflow <= operation_overflow;
        end
        o_res_vld <= 1'b1;
    end 
    else begin
        o_res_vld <= 1'b0;
        o_res <= 32'b0;
    end
end

endmodule


//========== MULTIPLIER 32 BIT ==========

module multiplier_32bit (
    input clk,
    input rst,
    input [31:0] i_a,
    input [31:0] i_b,
    input i_vld,
    output reg [31:0] o_res,
    output reg o_res_vld,
    output reg overflow );

// Internal wires
wire sign_a, sign_b, sign_res;
wire [7:0] exp_a, exp_b, final_exp;
wire [22:0] final_mantissa;
wire result_overflow;
wire [23:0] man_a, man_b;

//unpacking the inputs - 32bit single precision
assign sign_a = i_a[31];
assign sign_b = i_b[31];
assign exp_a = i_a[30:23];
assign exp_b = i_b[30:23];
assign man_a = (exp_a == 8'b0) ? {1'b0, i_a[22:0]} : {1'b1, i_a[22:0]}; //adding explicit 1 for normalized and 0 for denormalised numbers
assign man_b = (exp_b == 8'b0) ? {1'b0, i_b[22:0]} : {1'b1, i_b[22:0]};

wire is_nan_a = ((exp_a == 8'b11111111) && (man_a[22:0] != 0)); //only 23 bits of mantissa must be checked excluding the added 1
wire is_nan_b = ((exp_b == 8'b11111111) && (man_b[22:0] != 0));
wire is_inf_a = ((exp_a == 8'b11111111) && (man_a[22:0] == 0));
wire is_inf_b = ((exp_b == 8'b11111111) && (man_b[22:0] == 0));
wire is_zero_a = ((i_a[30:0] == 0)); //sign bit doesnt contribute anything
wire is_zero_b = ((i_b[30:0] == 0));

// Compute result sign (XOR of inout signs)
assign sign_res = sign_a ^ sign_b;

// Core multiplication and normalization
Multiplication32bit u_Multiplication32bit (
    .man_a(man_a),
    .man_b(man_b),
    .exp_a(exp_a),
    .exp_b(exp_b),
    .final_mantissa(final_mantissa),
    .final_exp(final_exp),
    .overflow(result_overflow) );

always @(posedge clk or posedge rst) begin
    if (rst) begin
        o_res_vld <= 1'b0;
        o_res <= 32'b0;
        overflow <=0;
    end
    else if (i_vld) begin
        if (is_nan_a || is_nan_b || ((is_inf_a && is_zero_b) || (is_zero_a && is_inf_b))) begin
            o_res <= 32'h7FC00000; // NaN
            overflow <= 1'b1;
        end else if (is_inf_a || is_inf_b) begin
            o_res <= {sign_res, 8'hFF, 23'b0}; // Infinity
            overflow <= 1'b1;
        end else if (is_zero_a || is_zero_b) begin
            o_res <= {sign_res, 31'b0}; // Zero
            overflow <= 1'b0;
        end else if (result_overflow) begin
            o_res <= {sign_res, 8'hFF, 23'b0}; // Overflow → Inf
            overflow <= 1'b1;
        end else begin
            o_res <= {sign_res, final_exp, final_mantissa};
            overflow <= 1'b0;
        end
        o_res_vld <= 1'b1;
    end 
    else begin
        o_res_vld <= 1'b0;
        o_res <= 32'b0;
    end
end

endmodule


//========== ADDER HELPER MODULES ==========


module CompareAndShift32Bit (
    input [4:0] exp_a,
    input [4:0] exp_b,
    input [10:0] man_a,
    input [10:0] man_b,
    output reg [10:0] al_man_a,
    output reg [10:0] al_man_b,
    output reg [7:0] shift
);
    always @(*) begin
        if (exp_a > exp_b) begin
            shift = exp_a - exp_b;
            al_man_a = man_a;
            al_man_b = man_b >> shift;
        end else begin
            shift = exp_b - exp_a;
            al_man_a = man_a >> shift;
            al_man_b = man_b;
        end
    end
endmodule

module Addition32Bit (
    input sign_a,
    input sign_b,
    input [23:0] a,b,
    output reg [24:0] res,
    output reg sign_res
    );
    
    always @(*) begin
        if (sign_a == sign_b) begin
            sign_res = sign_a;   
            res = a+b;
        end
        else if (a >= b) begin
            res = a - b;
            sign_res = sign_a;
        end
        else begin
            res = b - a;
            sign_res = sign_b;
        end
    end
    
endmodule

module Normalization32Bit (
    input [24:0] res,
    input [7:0] exp_base,
    output reg [23:0] man_res,
    output reg [7:0] exp_res,
    output reg overflow
);
    reg [24:0] normalized_result;
    integer i;
    reg continue_shift;

    always @(*) begin
        normalized_result = res;
        exp_res = exp_base;
        overflow = 0;

        if (normalized_result == 0) begin //explicitly handle 0 case for lower runtime
            man_res = 0;
            exp_res = 0;
            overflow = 0;
        end 
        else begin
            if (normalized_result[24]) begin // If MSB is 1, shift right once and increment exponent
                normalized_result = normalized_result >> 1;
                exp_res = exp_base + 1;
            end 
            else begin // Shift left until bit 23 is 1 or exponent reaches 0, max 25 times
                //continue_shift = 1;
                repeat (24) begin                
                    if(normalized_result[23] == 0) begin
                        normalized_result = normalized_result << 1;
                        exp_res = exp_res - 1;
                    end
		        end		    
            man_res = normalized_result[23:0];
                if(exp_res==8'b11111111) begin
                     overflow=1;
                end
            end
        end
    end
endmodule


//========== MULTIPLIER HELPER MODULES ==========

module Multiplication32bit(
    input [23:0] man_a,
    input [23:0] man_b,
    input [7:0] exp_a,
    input [7:0] exp_b,
    output [22:0] final_mantissa,
    output [7:0] final_exp,
    output overflow
);

wire [47:0] product = man_a * man_b; // Multiply mantissas max (24x24 = 48 bits)

// Normalization
wire norm_shift = product[47]; //checking if number is normal or denormal
wire [22:0] man_norm = norm_shift ? product[46:24] : product[45:23]; //nomalizing the mantissa product
wire guard_bit = norm_shift ? product[23] : product[22]; //guard bit is the one after 10 bits from decimal point
wire sticky_bit = norm_shift ? |product[22:0] : |product[21:0]; //checking if there is a 1 present after guard bit
wire round = guard_bit & sticky_bit; //round = 1 if guard bit is 1 and sticky bit is 1

// Add rounding (could overflow mantissa → handled later)
wire [23:0] rounded = {1'b0, man_norm} + round; //24 bit wire to account for overflow
wire carry = rounded[23]; // For overflow detection after rounding
assign final_mantissa = carry ? rounded[23:1] : rounded[22:0]; //final 23 bits of the mantissa

//Exponent computation
wire [9:0] exp_raw = exp_a + exp_b - 8'd127 + norm_shift + carry; //127 is subtracted because it is added twice
assign final_exp = exp_raw[7:0];

assign overflow = exp_raw > 8'd254;

endmodule


