`timescale 1ns/1ps

module tb_mac;

    parameter DATA_W = 8;
    parameter ACC_W  = 24;

    reg clk;
    reg reset;
    reg enable;

    reg signed [DATA_W-1:0] a;
    reg signed [DATA_W-1:0] b;

    wire signed [ACC_W-1:0] acc;

    mac #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .a(a),
        .b(b),
        .acc(acc)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg signed [63:0] golden;
    reg signed [63:0] a_ref;
    reg signed [63:0] b_ref;

    integer errors;
    integer tests;
    integer i;
    integer ra;
    integer rb;
    integer seed;

    task check_step;
        input integer raw_a;
        input integer raw_b;
        input en_val;
        input rst_val;

        begin
            @(negedge clk);

            a = raw_a;
            b = raw_b;
            enable = en_val;
            reset = rst_val;

            @(posedge clk);
            #1;

            a_ref = a;
            b_ref = b;

            if (rst_val)
                golden = 0;
            else if (en_val)
                golden = golden + (a_ref * b_ref);

            tests = tests + 1;

            if (acc !== golden[ACC_W-1:0]) begin
                $display("FAIL | Test %0d | a=%0d b=%0d en=%b reset=%b | Expected=%0d Got=%0d",
                    tests, a, b, en_val, rst_val,
                    $signed(golden[ACC_W-1:0]), acc);
                errors = errors + 1;
            end
            else begin
                $display("PASS | Test %0d | a=%0d b=%0d en=%b reset=%b | acc=%0d",
                    tests, a, b, en_val, rst_val, acc);
            end
        end
    endtask

    initial begin
        reset  = 0;
        enable = 0;
        a      = 0;
        b      = 0;

        golden = 0;
        errors = 0;
        tests  = 0;
        seed   = 12345;

        $dumpfile("mac.vcd");
        $dumpvars(0, tb_mac);

        $display("MAC UNIT TESTBENCH");

        check_step(0, 0, 0, 1);

        check_step(5, 4, 1, 0);
        check_step(3, 6, 1, 0);
        check_step(2, 2, 1, 0);

        check_step(-5, 4, 1, 0);
        check_step(5, -4, 1, 0);
        check_step(-5, -4, 1, 0);

        check_step(127, 127, 1, 0);
        check_step(-128, 127, 1, 0);
        check_step(-128, -128, 1, 0);
        check_step(0, 127, 1, 0);

        check_step(10, 10, 0, 0);
        check_step(-20, 5, 0, 0);

        check_step(2, 3, 1, 0);

        check_step(0, 0, 0, 1);

        check_step(4, 5, 1, 0);
        check_step(2, 3, 1, 0);

        $display("RANDOMIZED TESTS");

        for (i = 0; i < 100; i = i + 1) begin
            ra = $random(seed);
            rb = $random(seed);

            check_step(ra, rb, 1, 0);
        end

        @(negedge clk);

        $display("TEST SUMMARY");
        $display("Total tests : %0d", tests);
        $display("Passed      : %0d", tests - errors);
        $display("Failed      : %0d", errors);

        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $finish;
    end

endmodule
