`timescale 1ns / 1ps

module vga_timing (
    input  wire       clk,
    input  wire       rst,
    output reg        pixel_tick,
    output reg        hsync,
    output reg        vsync,
    output wire       video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);
    localparam H_VISIBLE = 10'd640;
    localparam H_FRONT   = 10'd16;
    localparam H_SYNC    = 10'd96;
    localparam H_BACK    = 10'd48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE = 10'd480;
    localparam V_FRONT   = 10'd10;
    localparam V_SYNC    = 10'd2;
    localparam V_BACK    = 10'd33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    reg [1:0] clk_div;
    reg [9:0] h_count;
    reg [9:0] v_count;

    initial begin
        clk_div    = 2'd0;
        h_count    = 10'd0;
        v_count    = 10'd0;
        pixel_tick = 1'b0;
        hsync      = 1'b1;
        vsync      = 1'b1;
    end

    assign pixel_x  = h_count;
    assign pixel_y  = v_count;
    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    always @(posedge clk) begin
        if (rst) begin
            clk_div    <= 2'd0;
            pixel_tick <= 1'b0;
            h_count    <= 10'd0;
            v_count    <= 10'd0;
            hsync      <= 1'b1;
            vsync      <= 1'b1;
        end else begin
            pixel_tick <= 1'b0;
            clk_div    <= clk_div + 1'b1;

            if (clk_div == 2'd3) begin
                pixel_tick <= 1'b1;

                if (h_count == H_TOTAL - 1'b1) begin
                    h_count <= 10'd0;
                    if (v_count == V_TOTAL - 1'b1) begin
                        v_count <= 10'd0;
                    end else begin
                        v_count <= v_count + 1'b1;
                    end
                end else begin
                    h_count <= h_count + 1'b1;
                end

                hsync <= ~((h_count >= H_VISIBLE + H_FRONT) &&
                           (h_count <  H_VISIBLE + H_FRONT + H_SYNC));
                vsync <= ~((v_count >= V_VISIBLE + V_FRONT) &&
                           (v_count <  V_VISIBLE + V_FRONT + V_SYNC));
            end
        end
    end
endmodule

