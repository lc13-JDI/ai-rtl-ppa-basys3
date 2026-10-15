`timescale 1ns / 1ps

module tb_buzzer_player;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg tick_1ms = 1'b0;
    reg event_start = 1'b0;
    reg event_go = 1'b0;
    reg event_success = 1'b0;
    reg event_fail = 1'b0;
    wire buzz_io;

    integer i = 0;
    integer errors = 0;
    reg toggled = 1'b0;
    reg last_buzz = 1'b0;

    buzzer_player #(
        .CLK_FREQ_HZ(100000)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .tick_1ms     (tick_1ms),
        .event_start  (event_start),
        .event_go     (event_go),
        .event_success(event_success),
        .event_fail   (event_fail),
        .buzz_io      (buzz_io)
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

    task pulse_ms;
        begin
            tick_1ms = 1'b1;
            @(posedge clk);
            tick_1ms = 1'b0;
            repeat (99) @(posedge clk);
        end
    endtask

    task run_ms;
        input integer count;
        integer j;
        begin
            j = 0;
            for (j = 0; j < count; j = j + 1) begin
                pulse_ms;
            end
        end
    endtask

    initial begin
        rst           = 1'b1;
        tick_1ms     = 1'b0;
        event_start  = 1'b0;
        event_go     = 1'b0;
        event_success = 1'b0;
        event_fail   = 1'b0;
        errors        = 0;
        toggled       = 1'b0;
        last_buzz     = 1'b0;

        repeat (8) @(posedge clk);
        rst = 1'b0;
        expect(buzz_io == 1'b0, "buzzer is low when idle");

        event_go = 1'b1;
        @(posedge clk);
        event_go = 1'b0;

        last_buzz = buzz_io;
        for (i = 0; i < 300; i = i + 1) begin
            @(posedge clk);
            if (buzz_io != last_buzz) begin
                toggled = 1'b1;
            end
            last_buzz = buzz_io;
        end
        expect(toggled, "GO event creates a square wave");

        run_ms(130);
        repeat (20) @(posedge clk);
        expect(buzz_io == 1'b0, "GO tone returns to idle low after its duration");

        event_fail = 1'b1;
        @(posedge clk);
        event_fail = 1'b0;
        repeat (100) @(posedge clk);
        expect(buzz_io !== 1'bx, "Fail event drives a known output");

        if (errors == 0) begin
            $display("BUZZER TESTS PASSED");
        end else begin
            $display("BUZZER TESTS FAILED: %0d error(s)", errors);
        end

        $finish;
    end
endmodule



