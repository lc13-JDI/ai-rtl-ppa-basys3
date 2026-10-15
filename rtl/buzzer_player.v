`timescale 1ns / 1ps

module buzzer_player #(
    parameter integer CLK_FREQ_HZ = 100000000
) (
    input  wire clk,
    input  wire rst,
    input  wire tick_1ms,
    input  wire event_start,
    input  wire event_go,
    input  wire event_success,
    input  wire event_fail,
    output reg  buzz_io
);
    localparam [2:0] MODE_OFF     = 3'd0;
    localparam [2:0] MODE_START   = 3'd1;
    localparam [2:0] MODE_GO      = 3'd2;
    localparam [2:0] MODE_SUCCESS = 3'd3;
    localparam [2:0] MODE_FAIL    = 3'd4;

    localparam [31:0] HALF_2K0 = CLK_FREQ_HZ / 4000;
    localparam [31:0] HALF_2K5 = CLK_FREQ_HZ / 5000;
    localparam [31:0] HALF_3K0 = CLK_FREQ_HZ / 6000;
    localparam [31:0] HALF_4K0 = CLK_FREQ_HZ / 8000;

    reg [2:0]  mode;
    reg [15:0] elapsed_ms;
    reg [31:0] tone_count;
    reg [31:0] half_period;
    reg        tone_active;

    initial begin
        mode       = MODE_OFF;
        elapsed_ms = 16'd0;
        tone_count = 32'd0;
        buzz_io    = 1'b0;
    end

    always @* begin
        tone_active = 1'b0;
        half_period = HALF_2K0;

        case (mode)
            MODE_START: begin
                tone_active = (elapsed_ms < 16'd80);
                half_period = HALF_2K5;
            end
            MODE_GO: begin
                tone_active = (elapsed_ms < 16'd120);
                half_period = HALF_4K0;
            end
            MODE_SUCCESS: begin
                tone_active = (elapsed_ms < 16'd220);
                if (elapsed_ms < 16'd100) begin
                    half_period = HALF_3K0;
                end else begin
                    half_period = HALF_4K0;
                end
            end
            MODE_FAIL: begin
                tone_active = (elapsed_ms < 16'd350);
                half_period = HALF_2K0;
            end
            default: begin
                tone_active = 1'b0;
                half_period = HALF_2K0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            mode       <= MODE_OFF;
            elapsed_ms <= 16'd0;
            tone_count <= 32'd0;
            buzz_io    <= 1'b0;
        end else begin
            if (event_fail) begin
                mode       <= MODE_FAIL;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else if (event_success) begin
                mode       <= MODE_SUCCESS;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else if (event_go) begin
                mode       <= MODE_GO;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else if (event_start) begin
                mode       <= MODE_START;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else begin
                if (tick_1ms && mode != MODE_OFF) begin
                    if (!tone_active) begin
                        mode       <= MODE_OFF;
                        elapsed_ms <= 16'd0;
                    end else begin
                        elapsed_ms <= elapsed_ms + 1'b1;
                    end
                end

                if (tone_active) begin
                    if (tone_count >= half_period - 1'b1) begin
                        tone_count <= 32'd0;
                        buzz_io    <= ~buzz_io;
                    end else begin
                        tone_count <= tone_count + 1'b1;
                    end
                end else begin
                    tone_count <= 32'd0;
                    buzz_io    <= 1'b0;
                end
            end
        end
    end
endmodule


