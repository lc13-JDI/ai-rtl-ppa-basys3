`timescale 1ns / 1ps

// AI draft for comparison only. The function is close to the hand-written
// version, but the average uses a variable divisor.
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
    reg [12:0] scores [0:2];
    reg [14:0] total;
    integer i;

    assign history0_ms = scores[0];
    assign history1_ms = scores[1];
    assign history2_ms = scores[2];

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 3; i = i + 1) begin
                scores[i] <= 13'd0;
            end
            valid_count <= 2'd0;
        end else if (result_wr_en) begin
            for (i = 2; i > 0; i = i - 1) begin
                scores[i] <= scores[i - 1];
            end
            scores[0] <= result_time_ms;

            if (valid_count < 2'd3) begin
                valid_count <= valid_count + 1'b1;
            end
        end
    end

    always @* begin
        total = 15'd0;
        for (i = 0; i < 3; i = i + 1) begin
            if (i < valid_count) begin
                total = total + scores[i];
            end
        end

        avg_valid = (valid_count != 2'd0);
        if (valid_count != 2'd0) begin
            avg_time_ms = total / valid_count;
        end else begin
            avg_time_ms = 13'd0;
        end
    end
endmodule
