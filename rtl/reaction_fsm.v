`timescale 1ns / 1ps

module reaction_fsm (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_1ms,
    input  wire        start_pulse,
    input  wire        react_pulse,
    input  wire [12:0] random_delay_ms,
    input  wire        avg_valid,
    input  wire [12:0] avg_time_ms,
    output reg  [2:0]  state,
    output reg  [1:0]  display_mode,
    output reg  [12:0] display_value_ms,
    output reg         result_wr_en,
    output reg  [12:0] result_time_ms,
    output reg         last_result_fail,
    output reg  [12:0] last_result_time_ms,
    output reg         event_start,
    output reg         event_go,
    output reg         event_success,
    output reg         event_fail
);
    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_WAIT_RANDOM = 3'd1;
    localparam [2:0] ST_GO          = 3'd2;
    localparam [2:0] ST_RESULT      = 3'd3;
    localparam [2:0] ST_AVG         = 3'd4;

    localparam [1:0] MODE_DASH      = 2'd0;
    localparam [1:0] MODE_BAR       = 2'd1;
    localparam [1:0] MODE_NUMBER    = 2'd2;
    localparam [1:0] MODE_FAIL      = 2'd3;

    wire [12:0] clipped_random_delay;

    reg [12:0] wait_target_ms;
    reg [12:0] wait_elapsed_ms;
    reg [12:0] reaction_ms;

    initial begin
        state               = ST_IDLE;
        result_wr_en        = 1'b0;
        result_time_ms      = 13'd0;
        last_result_fail    = 1'b0;
        last_result_time_ms = 13'd0;
        event_start         = 1'b0;
        event_go            = 1'b0;
        event_success       = 1'b0;
        event_fail          = 1'b0;
        wait_target_ms      = 13'd500;
        wait_elapsed_ms     = 13'd0;
        reaction_ms         = 13'd0;
    end

    assign clipped_random_delay =
        (random_delay_ms < 13'd500)  ? 13'd500  :
        (random_delay_ms > 13'd5000) ? 13'd5000 :
                                       random_delay_ms;

    always @(posedge clk) begin
        if (rst) begin
            state               <= ST_IDLE;
            wait_target_ms      <= 13'd500;
            wait_elapsed_ms     <= 13'd0;
            reaction_ms         <= 13'd0;
            result_wr_en        <= 1'b0;
            result_time_ms      <= 13'd0;
            last_result_fail    <= 1'b0;
            last_result_time_ms <= 13'd0;
            event_start         <= 1'b0;
            event_go            <= 1'b0;
            event_success       <= 1'b0;
            event_fail          <= 1'b0;
        end else begin
            result_wr_en  <= 1'b0;
            event_start   <= 1'b0;
            event_go      <= 1'b0;
            event_success <= 1'b0;
            event_fail    <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start_pulse) begin
                        wait_target_ms      <= clipped_random_delay;
                        wait_elapsed_ms     <= 13'd0;
                        reaction_ms         <= 13'd0;
                        last_result_fail    <= 1'b0;
                        last_result_time_ms <= 13'd0;
                        event_start         <= 1'b1;
                        state               <= ST_WAIT_RANDOM;
                    end
                end

                ST_WAIT_RANDOM: begin
                    if (react_pulse) begin
                        last_result_fail    <= 1'b1;
                        last_result_time_ms <= 13'd0;
                        event_fail          <= 1'b1;
                        state               <= ST_RESULT;
                    end else if (tick_1ms) begin
                        if (wait_elapsed_ms + 1'b1 >= wait_target_ms) begin
                            reaction_ms     <= 13'd0;
                            wait_elapsed_ms <= 13'd0;
                            event_go        <= 1'b1;
                            state           <= ST_GO;
                        end else begin
                            wait_elapsed_ms <= wait_elapsed_ms + 1'b1;
                        end
                    end
                end

                ST_GO: begin
                    if (react_pulse) begin
                        if (reaction_ms >= 13'd100 && reaction_ms <= 13'd5000) begin
                            last_result_fail    <= 1'b0;
                            last_result_time_ms <= reaction_ms;
                            result_time_ms      <= reaction_ms;
                            result_wr_en        <= 1'b1;
                            event_success       <= 1'b1;
                        end else begin
                            last_result_fail    <= 1'b1;
                            last_result_time_ms <= 13'd0;
                            event_fail          <= 1'b1;
                        end
                        state <= ST_RESULT;
                    end else if (tick_1ms) begin
                        if (reaction_ms >= 13'd5000) begin
                            last_result_fail    <= 1'b1;
                            last_result_time_ms <= 13'd0;
                            event_fail          <= 1'b1;
                            state               <= ST_RESULT;
                        end else begin
                            reaction_ms <= reaction_ms + 1'b1;
                        end
                    end
                end

                ST_RESULT: begin
                    if (start_pulse) begin
                        state <= ST_AVG;
                    end
                end

                ST_AVG: begin
                    if (start_pulse) begin
                        wait_target_ms      <= clipped_random_delay;
                        wait_elapsed_ms     <= 13'd0;
                        reaction_ms         <= 13'd0;
                        last_result_fail    <= 1'b0;
                        last_result_time_ms <= 13'd0;
                        event_start         <= 1'b1;
                        state               <= ST_WAIT_RANDOM;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

    always @* begin
        display_mode     = MODE_DASH;
        display_value_ms = 13'd0;

        case (state)
            ST_IDLE: begin
                display_mode = MODE_DASH;
            end

            ST_WAIT_RANDOM: begin
                display_mode = MODE_DASH;
            end

            ST_GO: begin
                display_mode     = MODE_BAR;
                display_value_ms = reaction_ms;
            end

            ST_RESULT: begin
                if (last_result_fail) begin
                    display_mode = MODE_FAIL;
                end else begin
                    display_mode     = MODE_NUMBER;
                    display_value_ms = last_result_time_ms;
                end
            end

            ST_AVG: begin
                if (avg_valid) begin
                    display_mode     = MODE_NUMBER;
                    display_value_ms = avg_time_ms;
                end else begin
                    display_mode = MODE_FAIL;
                end
            end

            default: begin
                display_mode = MODE_DASH;
            end
        endcase
    end
endmodule


