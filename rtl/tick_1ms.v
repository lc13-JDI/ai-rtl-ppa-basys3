`timescale 1ns / 1ps

module tick_1ms #(
    parameter integer CLK_FREQ_HZ = 100000000
) (
    input  wire clk,
    input  wire rst,
    output reg  tick
);
    localparam integer TICKS_PER_MS = CLK_FREQ_HZ / 1000;

    reg [31:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 32'd0;
            tick  <= 1'b0;
        end else if (count == TICKS_PER_MS - 1) begin
            count <= 32'd0;
            tick  <= 1'b1;
        end else begin
            count <= count + 1'b1;
            tick  <= 1'b0;
        end
    end
endmodule
