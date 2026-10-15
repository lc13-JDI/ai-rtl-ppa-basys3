`timescale 1ns / 1ps

module lfsr_random (
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] lfsr_value,
    output wire [12:0] wait_ms
);
    reg [15:0] lfsr;

    wire feedback;
    wire [25:0] scaled_wait;

    assign feedback    = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    assign scaled_wait = {13'd0, lfsr[12:0]} * 26'd4501;
    assign wait_ms     = 13'd500 + scaled_wait[25:13];
    assign lfsr_value  = lfsr;

    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 16'hACE1;
        end else if (lfsr == 16'h0000) begin
            lfsr <= 16'hACE1;
        end else begin
            lfsr <= {lfsr[14:0], feedback};
        end
    end
endmodule
