`timescale 1ns/1ps

module RF1 (
    input wire clk,
    input wire reset,
    input wire c_wr, // control signal: register write
    
    // reading from
    input wire [4:0] addr1_r,
    input wire [4:0] addr2_r,
    output reg [31:0] data1_o,
    output reg [31:0] data2_o,

    // writing to
    input wire [4:0] addr_w,
    input wire [31:0] data_i
);
    
    // This RegisterFile supports simultaneous writing and reading
    // in order to save resources, this RegFile does not support reset
    // all registers can be initialized using instructions

    // all choices:
    // - c_wr == 1 && w0reg == 0: if addr_r == addr_w: data_i
    // - c_wr == 1 && w0reg == 1: 5'b0
    // - c_wr == 0: regdata[addr_r]

    reg [31:0] regdata [31:1];
    wire w0reg = (addr_w == 5'b0);
    // when this signal is on, register writing is performed
    wire wvalid = ~w0reg && c_wr;

    always @(*) begin
        if      (addr1_r == 5'b0)               data1_o <= 32'b0;
        else if ((addr1_r == addr_w) && wvalid) data1_o <= data_i;
        else                                    data1_o <= regdata[addr1_r];
    end

    always @(*) begin
        if      (addr2_r == 5'b0)               data2_o <= 32'b0;
        else if ((addr2_r == addr_w) && wvalid) data2_o <= data_i;
        else                                    data2_o <= regdata[addr2_r];
    end

    always @(posedge clk) begin
        if (wvalid) regdata[addr_w] <= data_i;
    end
    
endmodule
