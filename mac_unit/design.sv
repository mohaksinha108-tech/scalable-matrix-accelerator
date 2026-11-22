`timescale 1ns/1ps

module mac #(
    parameter DATA_W = 8,
    parameter ACC_W  = 24
)(
    input wire clk,
    input wire reset,
    input wire enable,

    input wire signed [DATA_W-1:0] a,
    input wire signed [DATA_W-1:0] b,

    output reg signed [ACC_W-1:0] acc
);

    wire signed [2*DATA_W-1:0] product;

    assign product = a * b;

    always @(posedge clk) begin
        if (reset)
            acc <= 0;
        else if (enable)
            acc <= acc + product;
    end

endmodule
