`timescale 1ns / 1ps

module ALU_tb;
    // ======================
    // CLOCK AND RESET
    // ======================
    reg clk;
    reg rst;
    always #5 clk = ~clk;  // 100 MHz clock
    
    // ======================
    // DUT SIGNALS
    // ======================
    reg [31:0] i_a, i_b;
    reg ALUctrl; // 0 for addition, 1 for multiplication
    reg i_vld;   // like an ALU enable pin
    wire [31:0] o_res;
    wire o_res_vld; 
    wire overflow;
    
    // ======================
    // TEST VARIABLES
    // ======================
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer cycle_count = 0;
    
    // Pipeline delay constant (3 cycles for V2)
    parameter PIPELINE_DELAY = 3;
    
    // ======================
    // DUT INSTANTIATION
    // ======================
    ALU dut (    
        .clk(clk),
        .rst(rst),
        .i_a(i_a), 
        .i_b(i_b),
        .opcode(ALUctrl),
        .i_vld(i_vld),
        .o_res(o_res),
        .o_res_vld(o_res_vld),
        .overflow(overflow)
    );
    
    // ======================
    // CLOCK COUNTER
    // ======================
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
    end
    
    // ======================
    // TEST TASK: APPLY INPUT
    // ======================
    task apply_input;
        input [31:0] a;
        input [31:0] b;
        input op;
        begin
            @(posedge clk);
            i_a = a;
            i_b = b;
            ALUctrl = op;
            i_vld = 1;
            @(posedge clk);
            i_vld = 0;
        end
    endtask
    
    // ======================
    // TEST TASK: CHECK RESULT
    // ======================
    task check_result;
        input [31:0] expected;
        input expected_ovf;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;
            
            // Wait for pipeline delay
            repeat(PIPELINE_DELAY) @(posedge clk);
            
            if (o_res_vld) begin
                if (o_res === expected && overflow === expected_ovf) begin
                    $display("[PASS %0d @ cycle %0d] %s: Result = %h, Overflow = %b", 
                             test_count, cycle_count, test_name, o_res, overflow);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL %0d @ cycle %0d] %s", test_count, cycle_count, test_name);
                    $display("  Expected: Result = %h, Overflow = %b", expected, expected_ovf);
                    $display("  Got:      Result = %h, Overflow = %b", o_res, overflow);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("[ERROR %0d @ cycle %0d] %s: No valid output!", 
                         test_count, cycle_count, test_name);
                fail_count = fail_count + 1;
            end
            
            // Small gap between tests
            repeat(2) @(posedge clk);
        end
    endtask
    
    // ======================
    // MAIN TEST SEQUENCE
    // ======================
    initial begin
        // Initialize
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, ALU_tb);
        clk = 0;
        rst = 1;
        i_vld = 0;
        i_a = 0;
        i_b = 0;
        ALUctrl = 0;
        
        // Reset sequence
        #100;
        @(posedge clk);
        rst = 0;
        #100;
        
        $display("==========================================");
        $display("ALU V2 TESTBENCH - 3-Stage Pipeline");
        $display("Pipeline Delay: %0d cycles", PIPELINE_DELAY);
        $display("==========================================");
        
        // ======================
        // ADDITION TESTS
        // ======================
        $display("\n--- ADDITION TESTS ---");
        ALUctrl = 0;
        
        // Test Case 1: 3.5 + (-2.25) = 1.25
        apply_input(32'h40600000, 32'hC0100000, 0);
        check_result(32'h3FA00000, 1'b0, "3.5 + (-2.25) = 1.25");
        
        // Test Case 2: 1.0 + 2.0 = 3.0
        apply_input(32'h3F800000, 32'h40000000, 0);
        check_result(32'h40400000, 1'b0, "1.0 + 2.0 = 3.0");
        
        // Test Case 3: -4.5 + 2.5 = -2.0
        apply_input(32'hC0900000, 32'h40200000, 0);
        check_result(32'hC0000000, 1'b0, "-4.5 + 2.5 = -2.0");
        
        // Test Case 4: 0.5 + 0.25 = 0.75
        apply_input(32'h3F000000, 32'h3E800000, 0);
        check_result(32'h3F400000, 1'b0, "0.5 + 0.25 = 0.75");
        
        // Test Case 5: Addition of +0.0 and -0.0 = +0.0
        apply_input(32'h80000000, 32'h00000000, 0);
        check_result(32'h00000000, 1'b0, "+0.0 + -0.0 = +0.0");
        
        // Test Case 6: Addition with NaN = NaN
        apply_input(32'h7FC00000, 32'h3F800000, 0);
        check_result(32'h7FC00000, 1'b1, "NaN + 1.0 = NaN");
        
        // Test Case 7: Addition with positive infinity = +Inf
        apply_input(32'h7F800000, 32'h3F800000, 0);
        check_result(32'h7F800000, 1'b1, "+Inf + 1.0 = +Inf");
        
        // Test Case 8: Addition with negative infinity = -Inf
        apply_input(32'hFF800000, 32'h3F800000, 0);
        check_result(32'hFF800000, 1'b1, "-Inf + 1.0 = -Inf");
        
        // Test Case 9: +Infinity + +Infinity = +Inf
        apply_input(32'h7F800000, 32'h7F800000, 0);
        check_result(32'h7F800000, 1'b1, "+Inf + +Inf = +Inf");
        
        // Test Case 10: -Infinity + -Infinity = -Inf
        apply_input(32'hFF800000, 32'hFF800000, 0);
        check_result(32'hFF800000, 1'b1, "-Inf + -Inf = -Inf");
        
        // Test Case 11: +Infinity + -Infinity = NaN
        apply_input(32'h7F800000, 32'hFF800000, 0);
        check_result(32'h7FC00000, 1'b1, "+Inf + -Inf = NaN");
        
        // Test Case 12: -Infinity + +Infinity = NaN
        apply_input(32'hFF800000, 32'h7F800000, 0);
        check_result(32'h7FC00000, 1'b1, "-Inf + +Inf = NaN");
        
        // Wait before switching to multiplication
        repeat(10) @(posedge clk);
        
        // ======================
        // MULTIPLICATION TESTS
        // ======================
        $display("\n--- MULTIPLICATION TESTS ---");
        ALUctrl = 1;
        
        // Test Case 13: 3.5 * 2.0 = 7.0
        apply_input(32'h40600000, 32'h40000000, 1);
        check_result(32'h40E00000, 1'b0, "3.5 * 2.0 = 7.0");
        
        // Test Case 14: -1.5 * 4.0 = -6.0
        apply_input(32'hBFC00000, 32'h40800000, 1);
        check_result(32'hC0C00000, 1'b0, "-1.5 * 4.0 = -6.0");
        
        // Test Case 15: 0 * 5.0 = 0
        apply_input(32'h00000000, 32'h40A00000, 1);
        check_result(32'h00000000, 1'b0, "0 * 5.0 = 0");
        
        // Test Case 16: INF * 2.0 = INF
        apply_input(32'h7F800000, 32'h40000000, 1);
        check_result(32'h7F800000, 1'b1, "INF * 2.0 = INF");
        
        // Test Case 17: -INF * 2.0 = -INF
        apply_input(32'hFF800000, 32'h40000000, 1);
        check_result(32'hFF800000, 1'b1, "-INF * 2.0 = -INF");
        
        // Test Case 18: INF * 0 = NaN
        apply_input(32'h7F800000, 32'h00000000, 1);
        check_result(32'h7FC00000, 1'b1, "INF * 0 = NaN");
        
        // Test Case 19: NaN * 1.0 = NaN
        apply_input(32'h7FC00001, 32'h3F800000, 1);
        check_result(32'h7FC00000, 1'b1, "NaN * 1.0 = NaN");
        
        // Test Case 20: 1e20 * 1e20 = overflow to INF
        apply_input(32'h5A0A1F0A, 32'h5A0A1F0A, 1);
        check_result(32'h7F800000, 1'b1, "1e20 * 1e20 = +INF (overflow)");
        
        // Test Case 21: -3.0 * -2.0 = 6.0
        apply_input(32'hC0400000, 32'hC0000000, 1);
        check_result(32'h40C00000, 1'b0, "-3.0 * -2.0 = 6.0");
        
        // Test Case 22: 1.0 * 1.0 = 1.0
        apply_input(32'h3F800000, 32'h3F800000, 1);
        check_result(32'h3F800000, 1'b0, "1.0 * 1.0 = 1.0");
        
        // ======================
        // EXTRA TESTS
        // ======================
        $display("\n--- EXTRA TESTS ---");
        
        // Test Case 23: Quick back-to-back test
        $display("Testing back-to-back operations...");
        repeat(2) @(posedge clk);
        
        // Apply two operations quickly
        @(posedge clk);
        i_a = 32'h3F800000;  // 1.0
        i_b = 32'h40000000;  // 2.0
        ALUctrl = 0;         // ADD
        i_vld = 1;
        
        @(posedge clk);
        i_a = 32'h40600000;  // 3.5
        i_b = 32'h40000000;  // 2.0
        ALUctrl = 0;         // ADD
        
        @(posedge clk);
        i_vld = 0;
        
        // Collect both results
        test_count = test_count + 1;
        repeat(3) @(posedge clk);  // Wait for first result
        
        if (o_res_vld && o_res === 32'h40400000) begin  // 3.0
            $display("[PASS %0d] Back-to-back test 1: 1.0 + 2.0 = 3.0", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL %0d] Back-to-back test 1 failed", test_count);
            fail_count = fail_count + 1;
        end
        
        @(posedge clk);  // Next cycle, second result should appear
        test_count = test_count + 1;
        if (o_res_vld && o_res === 32'h40E00000) begin  // 7.0
            $display("[PASS %0d] Back-to-back test 2: 3.5 + 2.0 = 7.0", test_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL %0d] Back-to-back test 2 failed", test_count);
            fail_count = fail_count + 1;
        end
        
        // ======================
        // TEST SUMMARY
        // ======================
        repeat(10) @(posedge clk);
        
        $display("\n==========================================");
        $display("TEST SUMMARY");
        $display("==========================================");
        $display("Total Clock Cycles: %0d", cycle_count);
        $display("Total Tests:        %0d", test_count);
        $display("Tests Passed:       %0d", pass_count);
        $display("Tests Failed:       %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("✅ ALL TESTS PASSED!");
        end else begin
            $display("❌ SOME TESTS FAILED!");
            $display("Success Rate: %0.1f%%", (pass_count*100.0)/test_count);
        end
        $display("==========================================");
        
        // End simulation
        #100;
        $finish;
    end
    
    // ======================
    // WAVEFORM MONITOR
    // ======================
    initial begin
        // Optional: Monitor key signals
        /*
        $monitor("Time=%0tns Cycle=%0d: i_vld=%b op=%b a=%h b=%h res=%h vld=%b ovf=%b",
                 $time, cycle_count, i_vld, ALUctrl, i_a, i_b, 
                 o_res, o_res_vld, overflow);
        */
    end
    
endmodule