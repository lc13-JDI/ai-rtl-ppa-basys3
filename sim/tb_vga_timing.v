`timescale 1ns / 1ps

module tb_vga_timing;
    reg clk = 1'b0;
    reg rst = 1'b1;
    wire pixel_tick;
    wire hsync;
    wire vsync;
    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    integer i = 0;
    integer pixel_ticks = 0;
    integer errors = 0;
    reg saw_hsync_low = 1'b0;
    reg saw_vsync_low = 1'b0;
    reg saw_visible = 1'b0;
    reg saw_blank = 1'b0;

    vga_timing dut (
        .clk       (clk),
        .rst       (rst),
        .pixel_tick(pixel_tick),
        .hsync     (hsync),
        .vsync     (vsync),
        .video_on  (video_on),
        .pixel_x   (pixel_x),
        .pixel_y   (pixel_y)
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

    initial begin
        rst            = 1'b1;
        errors         = 0;
        pixel_ticks    = 0;
        saw_hsync_low  = 1'b0;
        saw_vsync_low  = 1'b0;
        saw_visible    = 1'b0;
        saw_blank      = 1'b0;

        repeat (8) @(posedge clk);
        rst = 1'b0;

        for (i = 0; i < 1681000; i = i + 1) begin
            @(posedge clk);
            #1;
            if (pixel_tick) begin
                pixel_ticks = pixel_ticks + 1;
                if (!hsync) saw_hsync_low = 1'b1;
                if (!vsync) saw_vsync_low = 1'b1;
                if (video_on) saw_visible = 1'b1;
                if (!video_on) saw_blank = 1'b1;
            end
        end

        expect(pixel_ticks > 420000, "25MHz pixel tick advances one full VGA frame");
        expect(saw_hsync_low, "Hsync active-low pulse occurs");
        expect(saw_vsync_low, "Vsync active-low pulse occurs");
        expect(saw_visible, "visible video region occurs");
        expect(saw_blank, "blanking region occurs");

        if (errors == 0) begin
            $display("VGA TIMING TESTS PASSED");
        end else begin
            $display("VGA TIMING TESTS FAILED: %0d error(s)", errors);
        end

        $finish;
    end
endmodule


