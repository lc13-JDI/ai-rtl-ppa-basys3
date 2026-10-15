`timescale 1ns / 1ps

module seg7_scan (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_1ms,
    input  wire [1:0]  display_mode,
    input  wire [12:0] value_ms,
    output reg  [6:0]  seg,
    output reg         dp,
    output reg  [3:0]  an
);
    localparam [1:0] MODE_DASH   = 2'd0;
    localparam [1:0] MODE_BAR    = 2'd1;
    localparam [1:0] MODE_NUMBER = 2'd2;
    localparam [1:0] MODE_FAIL   = 2'd3;

    localparam [6:0] SEG_DASH = 7'b0111111;
    localparam [6:0] SEG_BAR  = 7'b1001111;
    localparam [6:0] SEG_F    = 7'b0001110;
    localparam [6:0] SEG_A    = 7'b0001000;
    localparam [6:0] SEG_I    = 7'b1111001;
    localparam [6:0] SEG_L    = 7'b1000111;

    reg [1:0] digit_sel;
    reg [3:0] digit_value;

    wire [3:0] ones;
    wire [3:0] tens;
    wire [3:0] hundreds;
    wire [3:0] thousands;

    assign ones      = value_ms % 10;
    assign tens      = (value_ms / 10) % 10;
    assign hundreds  = (value_ms / 100) % 10;
    assign thousands = (value_ms / 1000) % 10;

    function [6:0] encode_digit;
        input [3:0] value;
        begin
            case (value)
                4'd0: encode_digit = 7'b1000000;
                4'd1: encode_digit = 7'b1111001;
                4'd2: encode_digit = 7'b0100100;
                4'd3: encode_digit = 7'b0110000;
                4'd4: encode_digit = 7'b0011001;
                4'd5: encode_digit = 7'b0010010;
                4'd6: encode_digit = 7'b0000010;
                4'd7: encode_digit = 7'b1111000;
                4'd8: encode_digit = 7'b0000000;
                4'd9: encode_digit = 7'b0010000;
                default: encode_digit = 7'b1111111;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            digit_sel <= 2'd0;
        end else if (tick_1ms) begin
            digit_sel <= digit_sel + 1'b1;
        end
    end

    always @* begin
        dp          = 1'b1;
        an          = 4'b1111;
        seg         = 7'b1111111;
        digit_value = 4'd0;

        case (digit_sel)
            2'd0: an = 4'b1110;
            2'd1: an = 4'b1101;
            2'd2: an = 4'b1011;
            2'd3: an = 4'b0111;
            default: an = 4'b1111;
        endcase

        case (display_mode)
            MODE_NUMBER: begin
                case (digit_sel)
                    2'd0: digit_value = ones;
                    2'd1: digit_value = tens;
                    2'd2: digit_value = hundreds;
                    2'd3: digit_value = thousands;
                    default: digit_value = 4'd0;
                endcase
                seg = encode_digit(digit_value);
            end

            MODE_DASH: begin
                seg = SEG_DASH;
            end

            MODE_BAR: begin
                seg = SEG_BAR;
            end

            MODE_FAIL: begin
                case (digit_sel)
                    2'd0: seg = SEG_L;
                    2'd1: seg = SEG_I;
                    2'd2: seg = SEG_A;
                    2'd3: seg = SEG_F;
                    default: seg = 7'b1111111;
                endcase
            end

            default: begin
                seg = SEG_DASH;
            end
        endcase
    end
endmodule
