`timescale 1ns / 1ps

module reaction_top #(
    parameter integer CLK_FREQ_HZ = 100000000,
    parameter integer DEBOUNCE_MS = 20
) (
    input  wire        CLK100MHZ,
    input  wire        btn_start,
    input  wire        btn_react,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an,
    output wire [15:0] led,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync,
    output wire        buzz_io
);
    reg [15:0] por_counter = 16'd0;

    wire por_done;
    wire rst;
    wire tick_1ms;
    wire start_level;
    wire start_pulse;
    wire react_level;
    wire react_pulse;
    wire [15:0] lfsr_value;
    wire [12:0] random_delay_ms;
    wire [2:0]  fsm_state;
    wire [1:0]  display_mode;
    wire [12:0] display_value_ms;
    wire        result_wr_en;
    wire [12:0] result_time_ms;
    wire        last_result_fail;
    wire [12:0] last_result_time_ms;
    wire        avg_valid;
    wire [12:0] avg_time_ms;
    wire [1:0]  valid_count;
    wire [12:0] history0_ms;
    wire [12:0] history1_ms;
    wire [12:0] history2_ms;
    wire        event_start;
    wire        event_go;
    wire        event_success;
    wire        event_fail;
    wire        pixel_tick;
    wire        video_on;
    wire [9:0]  pixel_x;
    wire [9:0]  pixel_y;

    assign por_done = &por_counter;
    assign rst      = ~por_done;

    always @(posedge CLK100MHZ) begin
        if (!por_done) begin
            por_counter <= por_counter + 1'b1;
        end
    end

    tick_1ms #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_tick_1ms (
        .clk (CLK100MHZ),
        .rst (rst),
        .tick(tick_1ms)
    );

    debounce_onepulse #(
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_start (
        .clk      (CLK100MHZ),
        .rst      (rst),
        .tick_1ms (tick_1ms),
        .noisy    (btn_start),
        .level    (start_level),
        .pulse    (start_pulse)
    );

    debounce_onepulse #(
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) u_debounce_react (
        .clk      (CLK100MHZ),
        .rst      (rst),
        .tick_1ms (tick_1ms),
        .noisy    (btn_react),
        .level    (react_level),
        .pulse    (react_pulse)
    );

    lfsr_random u_lfsr_random (
        .clk       (CLK100MHZ),
        .rst       (rst),
        .lfsr_value(lfsr_value),
        .wait_ms   (random_delay_ms)
    );

    reaction_fsm u_reaction_fsm (
        .clk                 (CLK100MHZ),
        .rst                 (rst),
        .tick_1ms            (tick_1ms),
        .start_pulse         (start_pulse),
        .react_pulse         (react_pulse),
        .random_delay_ms     (random_delay_ms),
        .avg_valid           (avg_valid),
        .avg_time_ms         (avg_time_ms),
        .state               (fsm_state),
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

    score_history u_score_history (
        .clk           (CLK100MHZ),
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

    seg7_scan u_seg7_scan (
        .clk         (CLK100MHZ),
        .rst         (rst),
        .tick_1ms    (tick_1ms),
        .display_mode(display_mode),
        .value_ms    (display_value_ms),
        .seg         (seg),
        .dp          (dp),
        .an          (an)
    );

    led_effect u_led_effect (
        .clk        (CLK100MHZ),
        .rst        (rst),
        .tick_1ms   (tick_1ms),
        .state      (fsm_state),
        .result_fail(last_result_fail),
        .led        (led)
    );

    vga_timing u_vga_timing (
        .clk       (CLK100MHZ),
        .rst       (rst),
        .pixel_tick(pixel_tick),
        .hsync     (Hsync),
        .vsync     (Vsync),
        .video_on  (video_on),
        .pixel_x   (pixel_x),
        .pixel_y   (pixel_y)
    );

    vga_renderer u_vga_renderer (
        .video_on        (video_on),
        .pixel_x         (pixel_x),
        .pixel_y         (pixel_y),
        .state           (fsm_state),
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

    buzzer_player #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) u_buzzer_player (
        .clk          (CLK100MHZ),
        .rst          (rst),
        .tick_1ms     (tick_1ms),
        .event_start  (event_start),
        .event_go     (event_go),
        .event_success(event_success),
        .event_fail   (event_fail),
        .buzz_io      (buzz_io)
    );
endmodule
