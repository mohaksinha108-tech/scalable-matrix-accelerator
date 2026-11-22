`timescale 1ns/1ps

module tb_matrix_multiplier;

    parameter DATA_W = 8;
    parameter ACC_W  = 24;
    parameter N     = 3;

    reg clk;
    reg reset;
    reg start;
    wire done;

    reg wr_en;
    reg wr_sel;
    integer wr_addr;
    reg signed [DATA_W-1:0] wr_data;

    integer rd_addr;
    wire signed [ACC_W-1:0] rd_data;

    matrix_multiplier #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .N(N)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done),
        .wr_en(wr_en),
        .wr_sel(wr_sel),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg signed [DATA_W-1:0] A_in [0:N*N-1];
    reg signed [DATA_W-1:0] B_in [0:N*N-1];
    integer C_gold [0:N*N-1];

    integer errors;
    integer tests;
    integer i, r, c, k;
    integer sum;
    integer cycles;
    integer got;
    integer seed;

    task compute_golden;
        begin
            for (r = 0; r < N; r = r + 1) begin
                for (c = 0; c < N; c = c + 1) begin
                    sum = 0;
                    for (k = 0; k < N; k = k + 1) begin
                        sum = sum + A_in[r*N+k] * B_in[k*N+c];
                    end
                    C_gold[r*N+c] = sum;
                end
            end
        end
    endtask

    task write_one(input which, input integer address, input signed [DATA_W-1:0] value);
        begin
            @(negedge clk);
            wr_en = 1;
            wr_sel = which;
            wr_addr = address;
            wr_data = value;
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task load_matrices;
        begin
            for (i = 0; i < N*N; i = i + 1) begin
                write_one(0, i, A_in[i]);
                write_one(1, i, B_in[i]);
            end
        end
    endtask

    task run_and_check(input [255:0] test_name);
        integer wrong;
        begin
            compute_golden;
            load_matrices;

            @(negedge clk);
            start = 1;
            cycles = 0;

            while (done == 0 && cycles < 1000) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            tests = tests + 1;
            wrong = 0;

            if (done == 0) begin
                $display("FAIL: %0s -> done never came", test_name);
                errors = errors + 1;
            end
            else begin
                for (i = 0; i < N*N; i = i + 1) begin
                    rd_addr = i;
                    #1;
                    got = rd_data;

                    if (got != C_gold[i]) begin
                        $display("FAIL: %0s -> C[%0d][%0d] is %0d, expected %0d",
                            test_name, i/N, i%N, got, C_gold[i]);
                        wrong = wrong + 1;
                    end
                end

                if (wrong == 0)
                    $display("PASS: %0s (took %0d cycles)", test_name, cycles);
                else
                    errors = errors + 1;
            end

            @(negedge clk);
            start = 0;
            repeat (3) @(posedge clk);
        end
    endtask

    task fill_same(input signed [DATA_W-1:0] a_val, input signed [DATA_W-1:0] b_val);
        begin
            for (i = 0; i < N*N; i = i + 1) begin
                A_in[i] = a_val;
                B_in[i] = b_val;
            end
        end
    endtask

    task fill_random;
        begin
            for (i = 0; i < N*N; i = i + 1) begin
                A_in[i] = $random(seed);
                B_in[i] = $random(seed);
            end
        end
    endtask

    integer t;
    integer busy_wrong;

    initial begin
        $dumpfile("matrix_multiplier.vcd");
        $dumpvars(0, tb_matrix_multiplier);

        errors = 0;
        tests = 0;
        seed = 12345;
        reset = 1;
        start = 0;
        wr_en = 0;
        wr_sel = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_addr = 0;

        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 0;

        $display("MATRIX MULTIPLIER TESTBENCH (N=%0d)", N);

        for (i = 0; i < N*N; i = i + 1) begin
            A_in[i] = i + 1;
            B_in[i] = N*N - i;
        end

        run_and_check("known example");

        if (N == 3) begin
            if (C_gold[0] == 30 && C_gold[4] == 69 && C_gold[8] == 90)
                $display("PASS: golden model matches expected values");
            else begin
                $display("FAIL: golden model does not match expected values");
                errors = errors + 1;
            end
        end

        fill_same(-128, -128);
        run_and_check("all -128 times -128");

        fill_same(127, 127);
        run_and_check("all 127 times 127");

        fill_same(-128, 127);
        run_and_check("all -128 times 127");

        fill_same(0, 55);
        run_and_check("zeros times 55");

        fill_same(-1, 1);
        run_and_check("all -1 times 1");

        for (i = 0; i < N*N; i = i + 1) begin
            A_in[i] = i - 4;

            if ((i/N) == (i%N))
                B_in[i] = 1;
            else
                B_in[i] = 0;
        end

        run_and_check("A times identity");

        for (t = 0; t < 50; t = t + 1) begin
            fill_random;
            run_and_check("random matrices");
        end

        fill_random;
        load_matrices;

        @(negedge clk);
        start = 1;
        repeat (8) @(posedge clk);

        @(negedge clk);
        reset = 1;

        @(posedge clk);
        #1;

        if (done == 1) begin
            $display("FAIL: done is still high after reset");
            errors = errors + 1;
        end
        else
            $display("PASS: reset in the middle stopped the run");

        @(negedge clk);
        reset = 0;
        start = 0;
        repeat (2) @(posedge clk);

        fill_random;
        run_and_check("normal run after reset");

        fill_random;
        compute_golden;
        load_matrices;

        @(negedge clk);
        start = 1;
        repeat (6) @(posedge clk);

        @(negedge clk);
        wr_en = 1;
        wr_sel = 0;
        wr_addr = 0;
        wr_data = 99;

        @(negedge clk);
        wr_en = 0;

        cycles = 0;

        while (done == 0 && cycles < 1000) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        busy_wrong = 0;

        for (i = 0; i < N*N; i = i + 1) begin
            rd_addr = i;
            #1;
            got = rd_data;

            if (got != C_gold[i])
                busy_wrong = busy_wrong + 1;
        end

        tests = tests + 1;

        if (busy_wrong == 0)
            $display("PASS: write while busy was ignored");
        else begin
            $display("FAIL: write while busy changed %0d result values", busy_wrong);
            errors = errors + 1;
        end

        @(negedge clk);
        start = 0;
        repeat (3) @(posedge clk);

        $display("Multiplications run: %0d", tests);
        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $finish;
    end

endmodule
