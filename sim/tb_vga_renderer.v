`timescale 1ns / 1ps

module tb_vga_renderer;
    localparam [2:0] ST_GO      = 3'd2;
    localparam [2:0] ST_AVG     = 3'd4;

    localparam [1:0] MODE_BAR    = 2'd1;
    localparam [1:0] MODE_NUMBER = 2'd2;
    localparam [1:0] MODE_FAIL   = 2'd3;

    reg        video_on = 1'b1;
    reg [9:0]  pixel_x = 10'd0;
    reg [9:0]  pixel_y = 10'd0;
    reg [2:0]  state = ST_GO;
    reg [1:0]  display_mode = MODE_NUMBER;
    reg [12:0] display_value_ms = 13'd0;
    reg [1:0]  valid_count = 2'd0;
    reg [12:0] history0_ms = 13'd0;
    reg [12:0] history1_ms = 13'd0;
    reg [12:0] history2_ms = 13'd0;

    wire [3:0] vgaRed;
    wire [3:0] vgaGreen;
    wire [3:0] vgaBlue;

    integer errors = 0;

    vga_renderer dut (
        .video_on        (video_on),
        .pixel_x         (pixel_x),
        .pixel_y         (pixel_y),
        .state           (state),
        .display_mode    (display_mode),
        .display_value_ms(display_value_ms),
        .valid_count     (valid_count),
        .history0_ms     (history0_ms),
        .history1_ms     (history1_ms),
        .history2_ms     (history2_ms),
        .vgaRed          (vgaRed),
        .vgaGreen        (vgaGreen),
        .vgaBlue         (vgaBlue)
    );

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

    task sample_pixel;
        input [9:0] x;
        input [9:0] y;
        begin
            pixel_x = x;
            pixel_y = y;
            #1;
        end
    endtask

    task expect_rgb;
        input [3:0] red;
        input [3:0] green;
        input [3:0] blue;
        input [1023:0] message;
        begin
            expect((vgaRed == red) && (vgaGreen == green) && (vgaBlue == blue),
                   message);
        end
    endtask

    initial begin
        errors = 0;

        state            = ST_GO;
        display_mode     = MODE_BAR;
        display_value_ms = 13'd1234;
        valid_count      = 2'd0;
        sample_pixel(10'd186, 10'd300);
        expect_rgb(4'h3, 4'hF, 4'h5, "GO timer digit is drawn in GO color");

        state            = ST_AVG;
        display_mode     = MODE_NUMBER;
        display_value_ms = 13'd250;
        valid_count      = 2'd3;
        history0_ms      = 13'd400;
        history1_ms      = 13'd250;
        history2_ms      = 13'd100;

        sample_pixel(10'd178, 10'd190);
        expect_rgb(4'hF, 4'hF, 4'h8, "AVG value digit is drawn in value color");

        sample_pixel(10'd264, 10'd290);
        expect_rgb(4'hF, 4'hF, 4'hF, "S1 latest history value is drawn");

        sample_pixel(10'd176, 10'd324);
        expect_rgb(4'hF, 4'hF, 4'hF, "S2 history label is drawn");

        sample_pixel(10'd172, 10'd358);
        expect_rgb(4'hF, 4'hF, 4'hF, "S3 history label is drawn");

        display_mode = MODE_FAIL;
        sample_pixel(10'd224, 10'd172);
        expect_rgb(4'hF, 4'h2, 4'h1, "AVG Fail text is drawn in fail color");

        sample_pixel(10'd144, 10'd290);
        expect(!((vgaRed == 4'hF) && (vgaGreen == 4'hF) && (vgaBlue == 4'hF)),
               "AVG Fail mode suppresses history rows");

        if (errors == 0) begin
            $display("VGA RENDERER TESTS PASSED");
        end else begin
            $display("VGA RENDERER TESTS FAILED: %0d error(s)", errors);
        end

        $finish;
    end
endmodule
