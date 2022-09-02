`timescale 1ns/1ps

module tempreg #(
    parameter bitw = 32
) (
    input wire clk,
    input wire reset,
    input wire [bitw-1:0] data_i,
    output reg [bitw-1:0] data_o,
    input wire wr_en
);
    always @(posedge clk or posedge reset) begin
        if (reset) data_o <= 0;
        else if (wr_en) begin
            data_o <= data_i;
        end
    end
    
endmodule
