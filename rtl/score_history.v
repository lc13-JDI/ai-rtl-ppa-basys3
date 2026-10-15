`timescale 1ns / 1ps

module score_history (
    input  wire        clk,
    input  wire        rst,
    input  wire        result_wr_en,
    input  wire [12:0] result_time_ms,
    output reg         avg_valid,
    output reg  [12:0] avg_time_ms,
    output reg  [1:0]  valid_count,
    output wire [12:0] history0_ms,
    output wire [12:0] history1_ms,
    output wire [12:0] history2_ms
);
    reg [12:0] score0;
    reg [12:0] score1;
    reg [12:0] score2;
    reg [14:0] sum;

    initial begin
        score0      = 13'd0;
        score1      = 13'd0;
        score2      = 13'd0;
        valid_count = 2'd0;
    end

    assign history0_ms = score0;
    assign history1_ms = score1;
    assign history2_ms = score2;

    always @(posedge clk) begin
        if (rst) begin
            score0      <= 13'd0;
            score1      <= 13'd0;
            score2      <= 13'd0;
            valid_count <= 2'd0;
        end else if (result_wr_en) begin
            score2 <= score1;
            score1 <= score0;
            score0 <= result_time_ms;

            if (valid_count < 2'd3) begin
                valid_count <= valid_count + 1'b1;
            end
        end
    end

    always @* begin
        avg_valid   = 1'b0;
        avg_time_ms = 13'd0;
        sum         = 15'd0;

        case (valid_count)
            2'd1: begin
                avg_valid   = 1'b1;
                avg_time_ms = score0;
            end
            2'd2: begin
                avg_valid   = 1'b1;
                sum         = {2'b00, score0} + {2'b00, score1};
                avg_time_ms = sum / 2;
            end
            2'd3: begin
                avg_valid   = 1'b1;
                sum         = {2'b00, score0} + {2'b00, score1} + {2'b00, score2};
                avg_time_ms = sum / 3;
            end
            default: begin
                avg_valid   = 1'b0;
                avg_time_ms = 13'd0;
            end
        endcase
    end
endmodule


