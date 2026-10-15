`timescale 1ns / 1ps

module tb_reaction_fsm;
    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_WAIT_RANDOM = 3'd1;
    localparam [2:0] ST_GO          = 3'd2;
    localparam [2:0] ST_RESULT      = 3'd3;
    localparam [2:0] ST_AVG         = 3'd4;

    localparam [1:0] MODE_BAR       = 2'd1;
    localparam [1:0] MODE_NUMBER    = 2'd2;
    localparam [1:0] MODE_FAIL      = 2'd3;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg tick_1ms = 1'b0;
    reg start_pulse = 1'b0;
    reg react_pulse = 1'b0;
    reg [12:0] random_delay_ms = 13'd500;

    wire avg_valid;
    wire [12:0] avg_time_ms;
    wire [2:0] state;
    wire [1:0] display_mode;
    wire [12:0] display_value_ms;
    wire result_wr_en;
    wire [12:0] result_time_ms;
    wire last_result_fail;
    wire [12:0] last_result_time_ms;
    wire [1:0] valid_count;
    wire [12:0] history0_ms;
    wire [12:0] history1_ms;
    wire [12:0] history2_ms;
    wire event_start;
    wire event_go;
    wire event_success;
    wire event_fail;

    integer errors = 0;

    reaction_fsm dut_fsm (
        .clk                 (clk),
        .rst                 (rst),
        .tick_1ms            (tick_1ms),
        .start_pulse         (start_pulse),
        .react_pulse         (react_pulse),
        .random_delay_ms     (random_delay_ms),
        .avg_valid           (avg_valid),
        .avg_time_ms         (avg_time_ms),
        .state               (state),
        .display_mode        (display_mode),
        .display_value_ms    (display_value_ms),
        .result_wr_en        (result_wr_en),
        .result_time_ms      (result_time_ms),
        .last_result_fail    (last_result_fail),
        .last_result_time_ms (last_result_time_ms),
        .event_start         (event_start),
        .event_go            (event_go),
        .event_success       (event_success),
        .event_fail          (event_fail)
    );

    score_history dut_history (
        .clk           (clk),
        .rst           (rst),
        .result_wr_en  (result_wr_en),
        .result_time_ms(result_time_ms),
        .avg_valid     (avg_valid),
        .avg_time_ms   (avg_time_ms),
        .valid_count   (valid_count),
        .history0_ms   (history0_ms),
        .history1_ms   (history1_ms),
        .history2_ms   (history2_ms)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect;
        input condition;
        input [1023:0] message;
        begin
            if (!condition) begin
                errors = errors + 1;
                $display("FAIL: %0s", message);
            end else begin
                $display("PASS: %0s", message);
            end
        end
    endtask

    task pulse_start;
        begin
            start_pulse = 1'b1;
            @(posedge clk);
            start_pulse = 1'b0;
            @(posedge clk);
        end
    endtask

    task pulse_react;
        begin
            react_pulse = 1'b1;
            @(posedge clk);
            react_pulse = 1'b0;
            @(posedge clk);
        end
    endtask

    task ms_tick;
        begin
            tick_1ms = 1'b1;
            @(posedge clk);
            tick_1ms = 1'b0;
            @(posedge clk);
        end
    endtask

    task wait_ms;
        input integer ms_count;
        integer i;
        begin
            for (i = 0; i < ms_count; i = i + 1) begin
                ms_tick;
            end
        end
    endtask

    task start_next_test_from_result;
        begin
            pulse_start;
            expect(state == ST_AVG, "START from result enters average display");
            pulse_start;
            expect(state == ST_WAIT_RANDOM, "START from average begins next test");
        end
    endtask

    task wait_to_go;
        begin
            wait_ms(500);
            expect(state == ST_GO, "random wait reaches GO state");
            expect(display_mode == MODE_BAR, "GO keeps bar display mode");
            expect(display_value_ms == 13'd0, "GO timer starts at 0ms");
        end
    endtask

    initial begin
        errors          = 0;
        rst             = 1'b1;
        tick_1ms        = 1'b0;
        start_pulse     = 1'b0;
        react_pulse     = 1'b0;
        random_delay_ms = 13'd500;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        expect(state == ST_IDLE, "reset enters IDLE");

        pulse_start;
        expect(state == ST_WAIT_RANDOM, "START begins random wait");
        wait_ms(50);
        pulse_react;
        expect(state == ST_RESULT, "early reaction ends test");
        expect(last_result_fail == 1'b1, "early reaction is Fail");
        expect(avg_valid == 1'b0, "early Fail is not recorded");

        pulse_start;
        expect(state == ST_AVG, "START shows average after Fail");
        expect(display_mode == MODE_FAIL, "no valid average displays Fail");
        pulse_start;
        expect(state == ST_WAIT_RANDOM, "START begins test after average page");

        wait_to_go;
        wait_ms(99);
        expect(display_value_ms == 13'd99, "GO timer reaches 99ms before reaction");
        pulse_react;
        expect(last_result_fail == 1'b1, "99ms reaction is Fail");
        expect(avg_valid == 1'b0, "99ms Fail is not recorded");

        start_next_test_from_result;

        wait_to_go;
        wait_ms(100);
        expect(display_value_ms == 13'd100, "GO timer reaches 100ms before reaction");
        pulse_react;
        expect(last_result_fail == 1'b0, "100ms reaction is valid");
        expect(last_result_time_ms == 13'd100, "100ms result is captured");
        expect(avg_valid == 1'b1, "first valid result enables average");
        expect(avg_time_ms == 13'd100, "average after one result is 100ms");
        expect(valid_count == 2'd1, "one valid result is counted");
        expect(history0_ms == 13'd100, "latest history stores first valid result");

        pulse_start;
        expect(state == ST_AVG, "average page after first valid result");
        expect(display_mode == MODE_NUMBER, "valid average displays as a number");
        expect(display_value_ms == 13'd100, "average page displays 100ms");
        pulse_start;
        expect(state == ST_WAIT_RANDOM, "second valid test begins");

        wait_to_go;
        wait_ms(250);
        pulse_react;
        expect(last_result_fail == 1'b0, "250ms reaction is valid");
        expect(avg_time_ms == 13'd175, "average of 100ms and 250ms is 175ms");
        expect(valid_count == 2'd2, "two valid results are counted");
        expect(history0_ms == 13'd250, "latest history stores second valid result");
        expect(history1_ms == 13'd100, "previous history stores first valid result");

        start_next_test_from_result;

        wait_to_go;
        wait_ms(400);
        pulse_react;
        expect(last_result_fail == 1'b0, "400ms reaction is valid");
        expect(avg_time_ms == 13'd250, "average of 100ms, 250ms, and 400ms is 250ms");
        expect(valid_count == 2'd3, "three valid results are counted");
        expect(history0_ms == 13'd400, "latest history stores third valid result");
        expect(history1_ms == 13'd250, "second history stores prior valid result");
        expect(history2_ms == 13'd100, "third history stores oldest valid result");

        pulse_start;
        expect(state == ST_AVG, "average page after three valid results");
        expect(display_value_ms == 13'd250, "average page displays 250ms");
        pulse_start;
        expect(state == ST_WAIT_RANDOM, "test after average page begins");

        wait_to_go;
        wait_ms(5000);
        pulse_react;
        expect(last_result_fail == 1'b0, "5000ms reaction is still valid");
        expect(last_result_time_ms == 13'd5000, "5000ms result is captured");
        expect(avg_time_ms == 13'd1883, "average keeps the latest three valid results");
        expect(history0_ms == 13'd5000, "latest history stores 5000ms result");
        expect(history1_ms == 13'd400, "history shifts 400ms to second");
        expect(history2_ms == 13'd250, "history shifts 250ms to third");

        start_next_test_from_result;

        wait_to_go;
        wait_ms(5001);
        expect(state == ST_RESULT, "timeout ends test");
        expect(last_result_fail == 1'b1, "timeout is Fail");
        expect(avg_time_ms == 13'd1883, "timeout Fail does not change average");
        expect(history0_ms == 13'd5000, "timeout does not change latest history");
        expect(history1_ms == 13'd400, "timeout does not change second history");
        expect(history2_ms == 13'd250, "timeout does not change third history");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TESTS FAILED: %0d error(s)", errors);
        end

        $finish;
    end
endmodule


