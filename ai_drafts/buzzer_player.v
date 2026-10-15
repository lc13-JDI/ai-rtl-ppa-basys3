`timescale 1ns / 1ps

// AI draft for comparison only. It selects frequency and duration at run time,
// then divides CLK_FREQ_HZ by the selected frequency in combinational logic.
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

    reg [2:0]  mode;
    reg [15:0] elapsed_ms;
    reg [31:0] tone_count;
    reg [15:0] tone_freq_hz;
    reg [15:0] tone_duration_ms;
    wire [31:0] half_period_cycles;
    wire        tone_enabled;

    assign half_period_cycles = CLK_FREQ_HZ / (tone_freq_hz * 2);
    assign tone_enabled       = (mode != MODE_OFF) && (elapsed_ms < tone_duration_ms);

    always @* begin
        tone_freq_hz     = 16'd2000;
        tone_duration_ms = 16'd0;

        if (mode == MODE_START) begin
            tone_freq_hz     = 16'd2500;
            tone_duration_ms = 16'd80;
        end else if (mode == MODE_GO) begin
            tone_freq_hz     = 16'd4000;
            tone_duration_ms = 16'd120;
        end else if (mode == MODE_SUCCESS) begin
            if (elapsed_ms < 16'd100) begin
                tone_freq_hz = 16'd3000;
            end else begin
                tone_freq_hz = 16'd4000;
            end
            tone_duration_ms = 16'd220;
        end else if (mode == MODE_FAIL) begin
            tone_freq_hz     = 16'd2000;
            tone_duration_ms = 16'd350;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            mode       <= MODE_OFF;
            elapsed_ms <= 16'd0;
            tone_count <= 32'd0;
            buzz_io    <= 1'b0;
        end else begin
            if (event_start) begin
                mode       <= MODE_START;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else if (event_go) begin
                mode       <= MODE_GO;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else if (event_success) begin
                mode       <= MODE_SUCCESS;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else if (event_fail) begin
                mode       <= MODE_FAIL;
                elapsed_ms <= 16'd0;
                tone_count <= 32'd0;
                buzz_io    <= 1'b0;
            end else begin
                if (tick_1ms && mode != MODE_OFF) begin
                    elapsed_ms <= elapsed_ms + 1'b1;
                    if (elapsed_ms >= tone_duration_ms) begin
                        mode <= MODE_OFF;
                    end
                end

                if (tone_enabled) begin
                    if (tone_count >= half_period_cycles - 1'b1) begin
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
