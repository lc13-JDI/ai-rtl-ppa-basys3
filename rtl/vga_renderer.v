`timescale 1ns / 1ps

module vga_renderer (
    input  wire        video_on,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [2:0]  state,
    input  wire [1:0]  display_mode,
    input  wire [12:0] display_value_ms,
    input  wire [1:0]  valid_count,
    input  wire [12:0] history0_ms,
    input  wire [12:0] history1_ms,
    input  wire [12:0] history2_ms,
    output reg  [3:0]  vgaRed,
    output reg  [3:0]  vgaGreen,
    output reg  [3:0]  vgaBlue
);
    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_WAIT_RANDOM = 3'd1;
    localparam [2:0] ST_GO          = 3'd2;
    localparam [2:0] ST_RESULT      = 3'd3;
    localparam [2:0] ST_AVG         = 3'd4;

    localparam [1:0] MODE_NUMBER    = 2'd2;
    localparam [1:0] MODE_FAIL      = 2'd3;

    reg title_pixel;
    reg main_pixel;
    reg value_pixel;
    reg history_pixel;
    reg panel_pixel;
    reg border_pixel;

    function glyph_pixel;
        input [7:0] ch;
        input [2:0] row;
        input [2:0] col;
        reg [4:0] bits;
        begin
            bits = 5'b00000;
            case (ch)
                "0": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10011;
                    3'd3: bits = 5'b10101; 3'd4: bits = 5'b11001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "1": case (row)
                    3'd0: bits = 5'b00100; 3'd1: bits = 5'b01100; 3'd2: bits = 5'b00100;
                    3'd3: bits = 5'b00100; 3'd4: bits = 5'b00100; 3'd5: bits = 5'b00100;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "2": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b00001;
                    3'd3: bits = 5'b00010; 3'd4: bits = 5'b00100; 3'd5: bits = 5'b01000;
                    3'd6: bits = 5'b11111; default: bits = 5'b00000;
                endcase
                "3": case (row)
                    3'd0: bits = 5'b11110; 3'd1: bits = 5'b00001; 3'd2: bits = 5'b00001;
                    3'd3: bits = 5'b01110; 3'd4: bits = 5'b00001; 3'd5: bits = 5'b00001;
                    3'd6: bits = 5'b11110; default: bits = 5'b00000;
                endcase
                "4": case (row)
                    3'd0: bits = 5'b00010; 3'd1: bits = 5'b00110; 3'd2: bits = 5'b01010;
                    3'd3: bits = 5'b10010; 3'd4: bits = 5'b11111; 3'd5: bits = 5'b00010;
                    3'd6: bits = 5'b00010; default: bits = 5'b00000;
                endcase
                "5": case (row)
                    3'd0: bits = 5'b11111; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b11110; 3'd4: bits = 5'b00001; 3'd5: bits = 5'b00001;
                    3'd6: bits = 5'b11110; default: bits = 5'b00000;
                endcase
                "6": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b11110; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "7": case (row)
                    3'd0: bits = 5'b11111; 3'd1: bits = 5'b00001; 3'd2: bits = 5'b00010;
                    3'd3: bits = 5'b00100; 3'd4: bits = 5'b01000; 3'd5: bits = 5'b01000;
                    3'd6: bits = 5'b01000; default: bits = 5'b00000;
                endcase
                "8": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b01110; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "9": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b01111; 3'd4: bits = 5'b00001; 3'd5: bits = 5'b00001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "A": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b11111; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b10001; default: bits = 5'b00000;
                endcase
                "C": case (row)
                    3'd0: bits = 5'b01111; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b10000; 3'd4: bits = 5'b10000; 3'd5: bits = 5'b10000;
                    3'd6: bits = 5'b01111; default: bits = 5'b00000;
                endcase
                "D": case (row)
                    3'd0: bits = 5'b11110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b10001; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b11110; default: bits = 5'b00000;
                endcase
                "E": case (row)
                    3'd0: bits = 5'b11111; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b11110; 3'd4: bits = 5'b10000; 3'd5: bits = 5'b10000;
                    3'd6: bits = 5'b11111; default: bits = 5'b00000;
                endcase
                "F": case (row)
                    3'd0: bits = 5'b11111; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b11110; 3'd4: bits = 5'b10000; 3'd5: bits = 5'b10000;
                    3'd6: bits = 5'b10000; default: bits = 5'b00000;
                endcase
                "G": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b10111; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "I": case (row)
                    3'd0: bits = 5'b11111; 3'd1: bits = 5'b00100; 3'd2: bits = 5'b00100;
                    3'd3: bits = 5'b00100; 3'd4: bits = 5'b00100; 3'd5: bits = 5'b00100;
                    3'd6: bits = 5'b11111; default: bits = 5'b00000;
                endcase
                "L": case (row)
                    3'd0: bits = 5'b10000; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b10000; 3'd4: bits = 5'b10000; 3'd5: bits = 5'b10000;
                    3'd6: bits = 5'b11111; default: bits = 5'b00000;
                endcase
                "M": case (row)
                    3'd0: bits = 5'b10001; 3'd1: bits = 5'b11011; 3'd2: bits = 5'b10101;
                    3'd3: bits = 5'b10101; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b10001; default: bits = 5'b00000;
                endcase
                "N": case (row)
                    3'd0: bits = 5'b10001; 3'd1: bits = 5'b11001; 3'd2: bits = 5'b10101;
                    3'd3: bits = 5'b10011; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b10001; default: bits = 5'b00000;
                endcase
                "O": case (row)
                    3'd0: bits = 5'b01110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b10001; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "R": case (row)
                    3'd0: bits = 5'b11110; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b11110; 3'd4: bits = 5'b10100; 3'd5: bits = 5'b10010;
                    3'd6: bits = 5'b10001; default: bits = 5'b00000;
                endcase
                "S": case (row)
                    3'd0: bits = 5'b01111; 3'd1: bits = 5'b10000; 3'd2: bits = 5'b10000;
                    3'd3: bits = 5'b01110; 3'd4: bits = 5'b00001; 3'd5: bits = 5'b00001;
                    3'd6: bits = 5'b11110; default: bits = 5'b00000;
                endcase
                "T": case (row)
                    3'd0: bits = 5'b11111; 3'd1: bits = 5'b00100; 3'd2: bits = 5'b00100;
                    3'd3: bits = 5'b00100; 3'd4: bits = 5'b00100; 3'd5: bits = 5'b00100;
                    3'd6: bits = 5'b00100; default: bits = 5'b00000;
                endcase
                "U": case (row)
                    3'd0: bits = 5'b10001; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b10001; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b10001;
                    3'd6: bits = 5'b01110; default: bits = 5'b00000;
                endcase
                "V": case (row)
                    3'd0: bits = 5'b10001; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b10001; 3'd4: bits = 5'b10001; 3'd5: bits = 5'b01010;
                    3'd6: bits = 5'b00100; default: bits = 5'b00000;
                endcase
                "W": case (row)
                    3'd0: bits = 5'b10001; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b10101; 3'd4: bits = 5'b10101; 3'd5: bits = 5'b10101;
                    3'd6: bits = 5'b01010; default: bits = 5'b00000;
                endcase
                "Y": case (row)
                    3'd0: bits = 5'b10001; 3'd1: bits = 5'b10001; 3'd2: bits = 5'b01010;
                    3'd3: bits = 5'b00100; 3'd4: bits = 5'b00100; 3'd5: bits = 5'b00100;
                    3'd6: bits = 5'b00100; default: bits = 5'b00000;
                endcase
                default: bits = 5'b00000;
            endcase
            glyph_pixel = (col < 3'd5) ? bits[4 - col] : 1'b0;
        end
    endfunction

    function draw_char4;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        input [7:0] ch;
        reg [9:0] rel_x;
        reg [9:0] rel_y;
        reg [2:0] font_col;
        reg [2:0] font_row;
        begin
            draw_char4 = 1'b0;
            if ((px >= x0) && (px < x0 + 10'd24) &&
                (py >= y0) && (py < y0 + 10'd28)) begin
                rel_x    = px - x0;
                rel_y    = py - y0;
                font_col = rel_x[4:2];
                font_row = rel_y[4:2];
                if (font_col < 3'd5) begin
                    draw_char4 = glyph_pixel(ch, font_row, font_col);
                end
            end
        end
    endfunction

    function draw_char8;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        input [7:0] ch;
        reg [9:0] rel_x;
        reg [9:0] rel_y;
        reg [2:0] font_col;
        reg [2:0] font_row;
        begin
            draw_char8 = 1'b0;
            if ((px >= x0) && (px < x0 + 10'd48) &&
                (py >= y0) && (py < y0 + 10'd56)) begin
                rel_x    = px - x0;
                rel_y    = py - y0;
                font_col = rel_x[5:3];
                font_row = rel_y[5:3];
                if (font_col < 3'd5) begin
                    draw_char8 = glyph_pixel(ch, font_row, font_col);
                end
            end
        end
    endfunction

    function draw_char16;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        input [7:0] ch;
        reg [9:0] rel_x;
        reg [9:0] rel_y;
        reg [2:0] font_col;
        reg [2:0] font_row;
        begin
            draw_char16 = 1'b0;
            if ((px >= x0) && (px < x0 + 10'd96) &&
                (py >= y0) && (py < y0 + 10'd112)) begin
                rel_x    = px - x0;
                rel_y    = py - y0;
                font_col = rel_x[6:4];
                font_row = rel_y[6:4];
                if (font_col < 3'd5) begin
                    draw_char16 = glyph_pixel(ch, font_row, font_col);
                end
            end
        end
    endfunction

    function draw_value8;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        input [12:0] value_ms;
        reg [3:0] ones;
        reg [3:0] tens;
        reg [3:0] hundreds;
        reg [3:0] thousands;
        begin
            ones      = value_ms % 10;
            tens      = (value_ms / 10) % 10;
            hundreds  = (value_ms / 100) % 10;
            thousands = (value_ms / 1000) % 10;

            draw_value8 = draw_char8(px, py, x0,           y0, 8'd48 + thousands) |
                          draw_char8(px, py, x0 + 10'd48,  y0, 8'd48 + hundreds) |
                          draw_char8(px, py, x0 + 10'd96,  y0, 8'd48 + tens) |
                          draw_char8(px, py, x0 + 10'd144, y0, 8'd48 + ones) |
                          draw_char8(px, py, x0 + 10'd216, y0, "M") |
                          draw_char8(px, py, x0 + 10'd264, y0, "S");
        end
    endfunction

    function draw_value4;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        input [12:0] value_ms;
        reg [3:0] ones;
        reg [3:0] tens;
        reg [3:0] hundreds;
        reg [3:0] thousands;
        begin
            ones      = value_ms % 10;
            tens      = (value_ms / 10) % 10;
            hundreds  = (value_ms / 100) % 10;
            thousands = (value_ms / 1000) % 10;

            draw_value4 = draw_char4(px, py, x0,           y0, 8'd48 + thousands) |
                          draw_char4(px, py, x0 + 10'd32,  y0, 8'd48 + hundreds) |
                          draw_char4(px, py, x0 + 10'd64,  y0, 8'd48 + tens) |
                          draw_char4(px, py, x0 + 10'd96,  y0, 8'd48 + ones) |
                          draw_char4(px, py, x0 + 10'd144, y0, "M") |
                          draw_char4(px, py, x0 + 10'd176, y0, "S");
        end
    endfunction

    always @* begin
        title_pixel = draw_char4(pixel_x, pixel_y, 10'd176, 10'd34, "R") |
                      draw_char4(pixel_x, pixel_y, 10'd212, 10'd34, "E") |
                      draw_char4(pixel_x, pixel_y, 10'd248, 10'd34, "A") |
                      draw_char4(pixel_x, pixel_y, 10'd284, 10'd34, "C") |
                      draw_char4(pixel_x, pixel_y, 10'd320, 10'd34, "T") |
                      draw_char4(pixel_x, pixel_y, 10'd356, 10'd34, "I") |
                      draw_char4(pixel_x, pixel_y, 10'd392, 10'd34, "O") |
                      draw_char4(pixel_x, pixel_y, 10'd428, 10'd34, "N");

        value_pixel   = 1'b0;
        history_pixel = 1'b0;

        main_pixel = 1'b0;
        case (state)
            ST_IDLE: begin
                main_pixel = draw_char8(pixel_x, pixel_y, 10'd200, 10'd172, "R") |
                             draw_char8(pixel_x, pixel_y, 10'd248, 10'd172, "E") |
                             draw_char8(pixel_x, pixel_y, 10'd296, 10'd172, "A") |
                             draw_char8(pixel_x, pixel_y, 10'd344, 10'd172, "D") |
                             draw_char8(pixel_x, pixel_y, 10'd392, 10'd172, "Y");
            end
            ST_WAIT_RANDOM: begin
                main_pixel = draw_char8(pixel_x, pixel_y, 10'd224, 10'd172, "W") |
                             draw_char8(pixel_x, pixel_y, 10'd272, 10'd172, "A") |
                             draw_char8(pixel_x, pixel_y, 10'd320, 10'd172, "I") |
                             draw_char8(pixel_x, pixel_y, 10'd368, 10'd172, "T");
            end
            ST_GO: begin
                main_pixel = draw_char16(pixel_x, pixel_y, 10'd224, 10'd150, "G") |
                             draw_char16(pixel_x, pixel_y, 10'd320, 10'd150, "O");
                value_pixel = draw_value8(pixel_x, pixel_y, 10'd170, 10'd300,
                                          display_value_ms);
            end
            ST_RESULT: begin
                if (display_mode == MODE_FAIL) begin
                    main_pixel = draw_char8(pixel_x, pixel_y, 10'd224, 10'd172, "F") |
                                 draw_char8(pixel_x, pixel_y, 10'd272, 10'd172, "A") |
                                 draw_char8(pixel_x, pixel_y, 10'd320, 10'd172, "I") |
                                 draw_char8(pixel_x, pixel_y, 10'd368, 10'd172, "L");
                end else begin
                    main_pixel = draw_char4(pixel_x, pixel_y, 10'd176, 10'd134, "R") |
                                 draw_char4(pixel_x, pixel_y, 10'd212, 10'd134, "E") |
                                 draw_char4(pixel_x, pixel_y, 10'd248, 10'd134, "S") |
                                 draw_char4(pixel_x, pixel_y, 10'd284, 10'd134, "U") |
                                 draw_char4(pixel_x, pixel_y, 10'd320, 10'd134, "L") |
                                 draw_char4(pixel_x, pixel_y, 10'd356, 10'd134, "T");
                    value_pixel = draw_value8(pixel_x, pixel_y, 10'd170, 10'd300,
                                              display_value_ms);
                end
            end
            ST_AVG: begin
                if (display_mode == MODE_FAIL) begin
                    main_pixel = draw_char8(pixel_x, pixel_y, 10'd224, 10'd172, "F") |
                                 draw_char8(pixel_x, pixel_y, 10'd272, 10'd172, "A") |
                                 draw_char8(pixel_x, pixel_y, 10'd320, 10'd172, "I") |
                                 draw_char8(pixel_x, pixel_y, 10'd368, 10'd172, "L");
                end else begin
                    main_pixel = draw_char8(pixel_x, pixel_y, 10'd248, 10'd134, "A") |
                                 draw_char8(pixel_x, pixel_y, 10'd296, 10'd134, "V") |
                                 draw_char8(pixel_x, pixel_y, 10'd344, 10'd134, "G");
                    value_pixel = draw_value8(pixel_x, pixel_y, 10'd170, 10'd190,
                                              display_value_ms);

                    if (valid_count >= 2'd1) begin
                        history_pixel = history_pixel |
                                        draw_char4(pixel_x, pixel_y, 10'd140, 10'd290, "S") |
                                        draw_char4(pixel_x, pixel_y, 10'd172, 10'd290, "1") |
                                        draw_value4(pixel_x, pixel_y, 10'd260, 10'd290,
                                                    history0_ms);
                    end

                    if (valid_count >= 2'd2) begin
                        history_pixel = history_pixel |
                                        draw_char4(pixel_x, pixel_y, 10'd140, 10'd324, "S") |
                                        draw_char4(pixel_x, pixel_y, 10'd172, 10'd324, "2") |
                                        draw_value4(pixel_x, pixel_y, 10'd260, 10'd324,
                                                    history1_ms);
                    end

                    if (valid_count >= 2'd3) begin
                        history_pixel = history_pixel |
                                        draw_char4(pixel_x, pixel_y, 10'd140, 10'd358, "S") |
                                        draw_char4(pixel_x, pixel_y, 10'd172, 10'd358, "3") |
                                        draw_value4(pixel_x, pixel_y, 10'd260, 10'd358,
                                                    history2_ms);
                    end
                end
            end
            default: begin
                main_pixel = 1'b0;
            end
        endcase

        panel_pixel  = (pixel_x >= 10'd80) && (pixel_x < 10'd560) &&
                       (pixel_y >= 10'd112) && (pixel_y < 10'd408);
        border_pixel = ((pixel_x >= 10'd76) && (pixel_x < 10'd564) &&
                        (pixel_y >= 10'd108) && (pixel_y < 10'd112)) ||
                       ((pixel_x >= 10'd76) && (pixel_x < 10'd564) &&
                        (pixel_y >= 10'd408) && (pixel_y < 10'd412)) ||
                       ((pixel_y >= 10'd108) && (pixel_y < 10'd412) &&
                        (pixel_x >= 10'd76) && (pixel_x < 10'd80)) ||
                       ((pixel_y >= 10'd108) && (pixel_y < 10'd412) &&
                        (pixel_x >= 10'd560) && (pixel_x < 10'd564));

        if (!video_on) begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h0;
        end else if (title_pixel) begin
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;
        end else if (main_pixel) begin
            if ((state == ST_RESULT || state == ST_AVG) && display_mode == MODE_FAIL) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'h2;
                vgaBlue  = 4'h1;
            end else if (state == ST_GO) begin
                vgaRed   = 4'h3;
                vgaGreen = 4'hF;
                vgaBlue  = 4'h5;
            end else if (state == ST_WAIT_RANDOM) begin
                vgaRed   = 4'hF;
                vgaGreen = 4'hC;
                vgaBlue  = 4'h1;
            end else begin
                vgaRed   = 4'h7;
                vgaGreen = 4'hE;
                vgaBlue  = 4'hF;
            end
        end else if (((state == ST_RESULT || state == ST_AVG) &&
                      (display_mode == MODE_NUMBER) && value_pixel) ||
                     (state == ST_GO && value_pixel)) begin
            if (state == ST_GO) begin
                vgaRed   = 4'h3;
                vgaGreen = 4'hF;
                vgaBlue  = 4'h5;
            end else begin
                vgaRed   = 4'hF;
                vgaGreen = 4'hF;
                vgaBlue  = 4'h8;
            end
        end else if (history_pixel) begin
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;
        end else if (border_pixel) begin
            vgaRed   = 4'h2;
            vgaGreen = 4'hC;
            vgaBlue  = 4'hF;
        end else if (panel_pixel) begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h2;
            vgaBlue  = 4'h4;
        end else begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h1;
        end
    end
endmodule




