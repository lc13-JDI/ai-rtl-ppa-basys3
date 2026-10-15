`timescale 1ns / 1ps

module led_effect (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1ms,
    input  wire [2:0] state,
    input  wire       result_fail,
    output reg [15:0] led
);
    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_WAIT_RANDOM = 3'd1;
    localparam [2:0] ST_GO          = 3'd2;
    localparam [2:0] ST_RESULT      = 3'd3;
    localparam [2:0] ST_AVG         = 3'd4;

    reg [15:0] chase;
    reg [7:0]  chase_count;
    reg [7:0]  slow_count;
    reg [5:0]  fast_count;
    reg        slow_flash;
    reg        fast_flash;

    always @(posedge clk) begin
        if (rst) begin
            chase       <= 16'h0001;
            chase_count <= 8'd0;
            slow_count  <= 8'd0;
            fast_count  <= 6'd0;
            slow_flash  <= 1'b0;
            fast_flash  <= 1'b0;
        end else if (tick_1ms) begin
            if (chase_count == 8'd99) begin
                chase_count <= 8'd0;
                chase       <= {chase[14:0], chase[15]};
            end else begin
                chase_count <= chase_count + 1'b1;
            end

            if (slow_count == 8'd199) begin
                slow_count <= 8'd0;
                slow_flash <= ~slow_flash;
            end else begin
                slow_count <= slow_count + 1'b1;
            end

            if (fast_count == 6'd49) begin
                fast_count <= 6'd0;
                fast_flash <= ~fast_flash;
            end else begin
                fast_count <= fast_count + 1'b1;
            end
        end
    end

    always @* begin
        case (state)
            ST_IDLE: begin
                led = 16'h0000;
            end

            ST_WAIT_RANDOM: begin
                led = chase;
            end

            ST_GO: begin
                led = fast_flash ? 16'hFFFF : 16'h0000;
            end

            ST_RESULT: begin
                if (result_fail) begin
                    led = slow_flash ? 16'h00FF : 16'hFF00;
                end else begin
                    led = slow_flash ? 16'h0F0F : 16'hF0F0;
                end
            end

            ST_AVG: begin
                led = slow_flash ? 16'h3333 : 16'hCCCC;
            end

            default: begin
                led = 16'h0000;
            end
        endcase
    end
endmodule
