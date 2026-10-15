`timescale 1ns / 1ps

module debounce_onepulse #(
    parameter integer DEBOUNCE_MS = 20
) (
    input  wire clk,
    input  wire rst,
    input  wire tick_1ms,
    input  wire noisy,
    output reg  level,
    output reg  pulse
);
    localparam [7:0] STABLE_LIMIT = DEBOUNCE_MS;

    reg sync_0;
    reg sync_1;
    reg [7:0] lock_count;

    always @(posedge clk) begin
        if (rst) begin
            sync_0       <= 1'b0;
            sync_1       <= 1'b0;
            lock_count   <= 8'd0;
            level        <= 1'b0;
            pulse        <= 1'b0;
        end else begin
            sync_0 <= noisy;
            sync_1 <= sync_0;
            pulse  <= 1'b0;

            if (lock_count != 8'd0) begin
                if (tick_1ms) begin
                    lock_count <= lock_count - 1'b1;
                end
            end else if (sync_1 != level) begin
                level      <= sync_1;
                lock_count <= STABLE_LIMIT;

                if (sync_1) begin
                    pulse <= 1'b1;
                end
            end
        end
    end
endmodule
