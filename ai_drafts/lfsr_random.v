`timescale 1ns / 1ps

// AI draft for comparison only. It keeps the original interface but uses a
// software-style pseudo-random update and modulo range mapping.
module lfsr_random (
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] lfsr_value,
    output wire [12:0] wait_ms
);
    reg [31:0] random_state;

    assign lfsr_value = random_state[15:0];
    assign wait_ms    = 13'd500 + (random_state % 13'd4501);

    always @(posedge clk) begin
        if (rst) begin
            random_state <= 32'h1234_ACE1;
        end else begin
            random_state <= random_state * 32'd1103515245 + 32'd12345;
        end
    end
endmodule
