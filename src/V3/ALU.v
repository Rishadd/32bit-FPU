// ===========================================================================
// Floating-Point ALU - IEEE 754 Single Precision
// Optimized for ASIC synthesis with skywater130nm PDK
// 3-Stage Pipeline: Decode → Compute → Normalize
// ===========================================================================

// ============================ TOP MODULE ===================================
module ALU (
    input         clk,        // System clock
    input         rst,        // Active-high reset
    input         i_vld,      // Input valid
    input  [31:0] i_a,        // Operand A (IEEE 754 single precision)
    input  [31:0] i_b,        // Operand B (IEEE 754 single precision)
    input         opcode,     // 0: addition, 1: multiplication
    output reg [31:0] o_res,  // Result (IEEE 754 single precision)
    output reg    o_res_vld,  // Result valid
    output reg    overflow    // Overflow flag
);

// ========================== PIPELINE STAGE 1 ==============================
reg         i_vld_stage1;
reg [31:0]  i_a_stage1, i_b_stage1;
reg         opcode_stage1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        i_vld_stage1  <= 1'b0;
        i_a_stage1    <= 32'b0;
        i_b_stage1    <= 32'b0;
        opcode_stage1 <= 1'b0;
    end else begin
        i_vld_stage1  <= i_vld;
        i_a_stage1    <= i_a;
        i_b_stage1    <= i_b;
        opcode_stage1 <= opcode;
    end
end

// ========================== INTERNAL SIGNALS ===============================
wire [31:0] add_res, mul_res;
wire        add_vld, mul_vld;
wire        add_ovf,  mul_ovf;

// ========================== SUBMODULE INSTANCES ============================
adder_32bit adder_inst (
    .clk        (clk),
    .rst        (rst),
    .i_vld      (i_vld_stage1),
    .i_a        (i_a_stage1),
    .i_b        (i_b_stage1),
    .o_res      (add_res),
    .o_res_vld  (add_vld),
    .overflow   (add_ovf)
);

multiplier_32bit multiplier_inst (
    .clk        (clk),
    .rst        (rst),
    .i_vld      (i_vld_stage1),
    .i_a        (i_a_stage1),
    .i_b        (i_b_stage1),
    .o_res      (mul_res),
    .o_res_vld  (mul_vld),
    .overflow   (mul_ovf)
);

// ========================== OUTPUT SELECTION ===============================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        o_res     <= 32'b0;
        o_res_vld <= 1'b0;
        overflow  <= 1'b0;
    end else begin
        case (opcode_stage1)
            1'b0: begin  // Addition
                o_res     <= add_res;
                o_res_vld <= add_vld;
                overflow  <= add_ovf;
            end
            1'b1: begin  // Multiplication
                o_res     <= mul_res;
                o_res_vld <= mul_vld;
                overflow  <= mul_ovf;
            end
            default: begin
                o_res     <= 32'b0;
                o_res_vld <= 1'b0;
                overflow  <= 1'b0;
            end
        endcase
    end
end

endmodule

// ========================== ADDER 32 BIT ===================================
module adder_32bit (
    input         clk,
    input         rst,
    input  [31:0] i_a,
    input  [31:0] i_b,
    input         i_vld,
    output reg [31:0] o_res,
    output reg    o_res_vld,
    output reg    overflow
);

// ========================== FLOATING-POINT DECODING ========================
wire        sign_a, sign_b;
wire [7:0]  exp_a, exp_b;
wire [23:0] man_a, man_b;  // 24-bit: [23] implicit bit, [22:0] fraction

assign sign_a = i_a[31];
assign sign_b = i_b[31];
assign exp_a  = i_a[30:23];
assign exp_b  = i_b[30:23];

// Denormalized numbers have implicit 0, normalized have implicit 1
assign man_a = (exp_a == 8'b0) ? {1'b0, i_a[22:0]} : {1'b1, i_a[22:0]};
assign man_b = (exp_b == 8'b0) ? {1'b0, i_b[22:0]} : {1'b1, i_b[22:0]};

// ========================== SPECIAL CASES DETECTION ========================
wire is_nan_a  = (exp_a == 8'hFF) && (|i_a[22:0]);
wire is_nan_b  = (exp_b == 8'hFF) && (|i_b[22:0]);
wire is_inf_a  = (exp_a == 8'hFF) && (i_a[22:0] == 23'b0);
wire is_inf_b  = (exp_b == 8'hFF) && (i_b[22:0] == 23'b0);
wire is_zero_a = (i_a[30:0] == 31'b0);
wire is_zero_b = (i_b[30:0] == 31'b0);

// ========================== PIPELINE STAGE 1 ==============================
reg         i_vld_r;
reg         sign_a_r, sign_b_r;
reg  [7:0]  exp_a_r, exp_b_r;
reg  [23:0] man_a_r, man_b_r;
reg         is_nan_a_r, is_nan_b_r;
reg         is_inf_a_r, is_inf_b_r;
reg         is_zero_a_r, is_zero_b_r;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        i_vld_r     <= 1'b0;
        sign_a_r    <= 1'b0; sign_b_r    <= 1'b0;
        exp_a_r     <= 8'b0; exp_b_r     <= 8'b0;
        man_a_r     <= 24'b0; man_b_r    <= 24'b0;
        is_nan_a_r  <= 1'b0; is_nan_b_r  <= 1'b0;
        is_inf_a_r  <= 1'b0; is_inf_b_r  <= 1'b0;
        is_zero_a_r <= 1'b0; is_zero_b_r <= 1'b0;
    end else begin
        i_vld_r     <= i_vld;
        sign_a_r    <= sign_a;    sign_b_r    <= sign_b;
        exp_a_r     <= exp_a;     exp_b_r     <= exp_b;
        man_a_r     <= man_a;     man_b_r     <= man_b;
        is_nan_a_r  <= is_nan_a;  is_nan_b_r  <= is_nan_b;
        is_inf_a_r  <= is_inf_a;  is_inf_b_r  <= is_inf_b;
        is_zero_a_r <= is_zero_a; is_zero_b_r <= is_zero_b;
    end
end

// ========================== ALIGNMENT ======================================
wire [7:0]  exp_diff;
wire [7:0]  shift_amt;
wire [23:0] man_a_aligned, man_b_aligned;

// Calculate exponent difference (absolute)
assign exp_diff = (exp_a_r > exp_b_r) ? (exp_a_r - exp_b_r) : (exp_b_r - exp_a_r);
assign shift_amt = (exp_diff > 8'd23) ? 8'd23 : exp_diff;  // Clamp to 23 bits

// Align mantissas (right shift smaller one)
assign man_a_aligned = (exp_a_r > exp_b_r) ? man_a_r : (man_a_r >> shift_amt);
assign man_b_aligned = (exp_a_r > exp_b_r) ? (man_b_r >> shift_amt) : man_b_r;
wire [7:0]  exp_larger = (exp_a_r > exp_b_r) ? exp_a_r : exp_b_r;

// ========================== ADDITION/SUBTRACTION ===========================
wire        op_add_sub;  // 0: same sign (add), 1: different signs (sub)
wire [24:0] sum_raw;     // 25-bit result for overflow detection
wire        sign_sum;

assign op_add_sub = sign_a_r ^ sign_b_r;  // Different signs -> subtraction

// Select operation based on signs
assign sum_raw = (sign_a_r == sign_b_r) ? 
                 {1'b0, man_a_aligned} + {1'b0, man_b_aligned} :  // Same sign: add
                 (man_a_aligned >= man_b_aligned) ? 
                 {1'b0, man_a_aligned - man_b_aligned} :          // A >= B: A-B
                 {1'b0, man_b_aligned - man_a_aligned};           // B > A: B-A

assign sign_sum = (sign_a_r == sign_b_r) ? sign_a_r :           // Same sign
                  (man_a_aligned >= man_b_aligned) ? sign_a_r : // A >= B
                  sign_b_r;                                     // B > A

// ========================== PIPELINE STAGE 2 ==============================
reg         i_vld_r2;
reg [24:0]  sum_raw_r;
reg         sign_sum_r;
reg [7:0]   exp_larger_r;
reg         is_nan_r, is_inf_r, is_zero_r;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        i_vld_r2    <= 1'b0;
        sum_raw_r   <= 25'b0;
        sign_sum_r  <= 1'b0;
        exp_larger_r <= 8'b0;
        is_nan_r    <= 1'b0;
        is_inf_r    <= 1'b0;
        is_zero_r   <= 1'b0;
    end else begin
        i_vld_r2    <= i_vld_r;
        sum_raw_r   <= sum_raw;
        sign_sum_r  <= sign_sum;
        exp_larger_r <= exp_larger;
        // Combine special cases
        is_nan_r    <= is_nan_a_r || is_nan_b_r || 
                      ((is_inf_a_r && is_inf_b_r) && (sign_a_r != sign_b_r));
        is_inf_r    <= (is_inf_a_r || is_inf_b_r) && !is_nan_r;
        is_zero_r   <= is_zero_a_r && is_zero_b_r;
    end
end

// ========================== NORMALIZATION ==================================
reg  [23:0] man_norm;
reg  [7:0]  exp_norm;
reg         overflow_norm;

always @(*) begin
    man_norm    = sum_raw_r[23:0];
    exp_norm    = exp_larger_r;
    overflow_norm = 1'b0;
    
    // Handle zero result
    if (sum_raw_r[24:0] == 25'b0) begin
        man_norm = 24'b0;
        exp_norm = 8'b0;
    end
    // Normalize (shift left until MSB=1 or exponent=0)
    else if (~sum_raw_r[24] && ~sum_raw_r[23]) begin  // Need left shift
        if (sum_raw_r[22]) begin
            man_norm = sum_raw_r[23:0] << 1;
            exp_norm = exp_larger_r - 1;
        end else if (sum_raw_r[21]) begin
            man_norm = sum_raw_r[23:0] << 2;
            exp_norm = exp_larger_r - 2;
        end else if (sum_raw_r[20]) begin
            man_norm = sum_raw_r[23:0] << 3;
            exp_norm = exp_larger_r - 3;
        end else if (sum_raw_r[19]) begin
            man_norm = sum_raw_r[23:0] << 4;
            exp_norm = exp_larger_r - 4;
        end else if (sum_raw_r[18]) begin
            man_norm = sum_raw_r[23:0] << 5;
            exp_norm = exp_larger_r - 5;
        end else if (sum_raw_r[17]) begin
            man_norm = sum_raw_r[23:0] << 6;
            exp_norm = exp_larger_r - 6;
        end else begin
            man_norm = sum_raw_r[23:0] << 7;
            exp_norm = exp_larger_r - 7;
        end
    end
    // Handle overflow (right shift)
    else if (sum_raw_r[24]) begin
        man_norm = sum_raw_r[24:1];
        exp_norm = exp_larger_r + 1;
        overflow_norm = (exp_norm == 8'hFF);  // Check for infinity
    end
    
    // Check for overflow to infinity
    if (exp_norm == 8'hFF) overflow_norm = 1'b1;
end

// ========================== OUTPUT GENERATION ==============================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        o_res     <= 32'b0;
        o_res_vld <= 1'b0;
        overflow  <= 1'b0;
    end else if (i_vld_r2) begin
        // Handle special cases
        if (is_nan_r) begin
            o_res <= 32'h7FC0_0000;  // Quiet NaN
            overflow <= 1'b1;
        end
        else if (is_inf_r) begin
            o_res <= {sign_sum_r, 8'hFF, 23'b0};  // Infinity
            overflow <= 1'b1;
        end
        else if (is_zero_r) begin
            o_res <= {sign_sum_r, 31'b0};  // Signed zero
            overflow <= 1'b0;
        end
        else if (overflow_norm) begin
            o_res <= {sign_sum_r, 8'hFF, 23'b0};  // Infinity
            overflow <= 1'b1;
        end
        else begin
            o_res <= {sign_sum_r, exp_norm, man_norm[22:0]};
            overflow <= 1'b0;
        end
        o_res_vld <= 1'b1;
    end else begin
        o_res_vld <= 1'b0;
        o_res     <= 32'b0;
        overflow  <= 1'b0;
    end
end

endmodule

// ========================== MULTIPLIER 32 BIT ==============================
module multiplier_32bit (
    input         clk,
    input         rst,
    input  [31:0] i_a,
    input  [31:0] i_b,
    input         i_vld,
    output reg [31:0] o_res,
    output reg    o_res_vld,
    output reg    overflow
);

// ========================== FLOATING-POINT DECODING ========================
wire        sign_a, sign_b;
wire [7:0]  exp_a, exp_b;
wire [23:0] man_a, man_b;

assign sign_a = i_a[31];
assign sign_b = i_b[31];
assign exp_a  = i_a[30:23];
assign exp_b  = i_b[30:23];
assign man_a  = (exp_a == 8'b0) ? {1'b0, i_a[22:0]} : {1'b1, i_a[22:0]};
assign man_b  = (exp_b == 8'b0) ? {1'b0, i_b[22:0]} : {1'b1, i_b[22:0]};

// ========================== SPECIAL CASES DETECTION ========================
wire is_nan_a  = (exp_a == 8'hFF) && (|i_a[22:0]);
wire is_nan_b  = (exp_b == 8'hFF) && (|i_b[22:0]);
wire is_inf_a  = (exp_a == 8'hFF) && (i_a[22:0] == 23'b0);
wire is_inf_b  = (exp_b == 8'hFF) && (i_b[22:0] == 23'b0);
wire is_zero_a = (i_a[30:0] == 31'b0);
wire is_zero_b = (i_b[30:0] == 31'b0);

// ========================== PIPELINE STAGE 1 ==============================
reg         i_vld_r;
reg         sign_a_r, sign_b_r;
reg  [7:0]  exp_a_r, exp_b_r;
reg  [23:0] man_a_r, man_b_r;
reg         is_nan_a_r, is_nan_b_r;
reg         is_inf_a_r, is_inf_b_r;
reg         is_zero_a_r, is_zero_b_r;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        i_vld_r     <= 1'b0;
        sign_a_r    <= 1'b0; sign_b_r    <= 1'b0;
        exp_a_r     <= 8'b0; exp_b_r     <= 8'b0;
        man_a_r     <= 24'b0; man_b_r    <= 24'b0;
        is_nan_a_r  <= 1'b0; is_nan_b_r  <= 1'b0;
        is_inf_a_r  <= 1'b0; is_inf_b_r  <= 1'b0;
        is_zero_a_r <= 1'b0; is_zero_b_r <= 1'b0;
    end else begin
        i_vld_r     <= i_vld;
        sign_a_r    <= sign_a;    sign_b_r    <= sign_b;
        exp_a_r     <= exp_a;     exp_b_r     <= exp_b;
        man_a_r     <= man_a;     man_b_r     <= man_b;
        is_nan_a_r  <= is_nan_a;  is_nan_b_r  <= is_nan_b;
        is_inf_a_r  <= is_inf_a;  is_inf_b_r  <= is_inf_b;
        is_zero_a_r <= is_zero_a; is_zero_b_r <= is_zero_b;
    end
end

// ========================== MULTIPLICATION CORE ============================
wire [47:0] product_raw;  // 24x24 = 48-bit product
wire        sign_res;
wire [7:0]  exp_raw;
wire [7:0]  exp_calc;
wire        overflow_calc;
wire [23:0] man_rounded;
wire [22:0] man_final;

assign sign_res = sign_a_r ^ sign_b_r;  // XOR of signs
assign product_raw = man_a_r * man_b_r; // Mantissa multiplication

// Exponent calculation: exp1 + exp2 - bias(127)
assign exp_raw = exp_a_r + exp_b_r - 8'd127;

// Normalization detection
wire product_msb = product_raw[47];  // Check if result >= 2.0
wire [47:0] product_shifted = product_msb ? product_raw >> 1 : product_raw;
assign exp_calc = product_msb ? exp_raw + 1 : exp_raw;

// Rounding: round to nearest even (simplified)
wire guard_bit    = product_shifted[23];
wire sticky_bit   = |product_shifted[22:0];
wire round_up     = guard_bit && (sticky_bit || product_shifted[24]);

// Apply rounding
assign man_rounded = product_shifted[47:24] + round_up;
wire carry_round = man_rounded[23];  // Check if rounding caused overflow

// Final mantissa and exponent
assign man_final = carry_round ? man_rounded[23:1] : man_rounded[22:0];
wire [7:0] exp_final = carry_round ? exp_calc + 1 : exp_calc;

// Overflow detection
assign overflow_calc = (exp_final == 8'hFF) || (exp_raw > 8'd254);

// ========================== PIPELINE STAGE 2 ==============================
reg         i_vld_r2;
reg         sign_res_r;
reg [7:0]   exp_final_r;
reg [22:0]  man_final_r;
reg         overflow_calc_r;
reg         is_nan_r, is_inf_r, is_zero_r;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        i_vld_r2        <= 1'b0;
        sign_res_r      <= 1'b0;
        exp_final_r     <= 8'b0;
        man_final_r     <= 23'b0;
        overflow_calc_r <= 1'b0;
        is_nan_r        <= 1'b0;
        is_inf_r        <= 1'b0;
        is_zero_r       <= 1'b0;
    end else begin
        i_vld_r2        <= i_vld_r;
        sign_res_r      <= sign_res;
        exp_final_r     <= exp_final;
        man_final_r     <= man_final;
        overflow_calc_r <= overflow_calc;
        // Combine special cases
        is_nan_r        <= is_nan_a_r || is_nan_b_r || 
                          ((is_inf_a_r && is_zero_b_r) || (is_zero_a_r && is_inf_b_r));
        is_inf_r        <= (is_inf_a_r || is_inf_b_r) && !is_nan_r;
        is_zero_r       <= is_zero_a_r || is_zero_b_r;
    end
end

// ========================== OUTPUT GENERATION ==============================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        o_res     <= 32'b0;
        o_res_vld <= 1'b0;
        overflow  <= 1'b0;
    end else if (i_vld_r2) begin
        // Handle special cases
        if (is_nan_r) begin
            o_res <= 32'h7FC0_0000;  // Quiet NaN
            overflow <= 1'b1;
        end
        else if (is_inf_r) begin
            o_res <= {sign_res_r, 8'hFF, 23'b0};  // Infinity
            overflow <= 1'b1;
        end
        else if (is_zero_r) begin
            o_res <= {sign_res_r, 31'b0};  // Signed zero
            overflow <= 1'b0;
        end
        else if (overflow_calc_r) begin
            o_res <= {sign_res_r, 8'hFF, 23'b0};  // Overflow to infinity
            overflow <= 1'b1;
        end
        else begin
            o_res <= {sign_res_r, exp_final_r, man_final_r};
            overflow <= 1'b0;
        end
        o_res_vld <= 1'b1;
    end else begin
        o_res_vld <= 1'b0;
        o_res     <= 32'b0;
        overflow  <= 1'b0;
    end
end

endmodule