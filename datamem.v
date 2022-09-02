`timescale 1ns/1ps

`include "defs.v"


// This implementation assumes that all data accesses are legal,
// that is, Memory Access Exceptions are handled before this module
// wrong memory access will lead to errornous results
// meanwhile, I think I have corrected all the bugs through testing (see "dataram_tb.v")

module datamem2 #(
    parameter MEM_SIZE = 1024, // unit: word
    parameter PHYS_LW  = 10    // num of bits to address a word
) (
    input wire clk,
    input wire [31:0] wdata,
    input wire [31:0] address,
    input wire [1:0] read_option,
    input wire [1:0] write_option,
    input wire extra_op, // "1" for signed and "0" for unsigned
    output reg [31:0] rdata
);
    wire [PHYS_LW-1:0] safe_addr = {address[PHYS_LW+1:2]};
    reg [31:0] data_to_write;
    
`ifdef USE_GEN_MEM

    wire [31:0] word_out;
    dist_mem_gen_0 memgen (
        .d(data_to_write),
        .a(safe_addr),
        .clk(clk),
        .we(~(write_option == 2'b10)),
        .spo(word_out)
    );
    
`else

    reg [31:0] memdata [MEM_SIZE-1:0];
    // note that address is used to locate a byte, while we want to locate a word
    // below is the address of the word.
    // Reading Part: the only thing worth concern is extrapolation
    wire [31:0] word_out = memdata[safe_addr];
    
`endif

    always @(*) begin
        if (read_option == `read_word) rdata <= word_out;

        else if (read_option == `read_hfwd) begin
            if (address[1] == 1'b0) begin
                rdata[15:0] <= {word_out[15:0]};
                rdata[31:16] <= (word_out[15] && extra_op) ? 16'hffff : 16'b0;
            end
            else begin
                rdata[15:0] <= word_out[31:16];
                rdata[31:16] <= (word_out[31] && extra_op) ? 16'hffff : 16'b0;
            end
        end

        else if (read_option == `read_byte) begin
            if (address[1:0] == 2'b00) begin
                rdata[7:0] <= word_out[7:0];
                rdata[31:8] <= (word_out[7] && extra_op) ? 24'hffffff : 24'b0;
            end
            else if (address[1:0] == 2'b01) begin
                rdata[7:0] <= word_out[15:8];
                rdata[31:8] <= (word_out[15] && extra_op) ? 24'hffffff : 24'b0;
            end
            else if (address[1:0] == 2'b10) begin
                rdata[7:0] <= word_out[23:16];
                rdata[31:8] <= (word_out[23] && extra_op) ? 24'hffffff : 24'b0;
            end
            else begin
                rdata[7:0] <= word_out[31:24];
                rdata[31:8] <= (word_out[31] && extra_op) ? 24'hffffff : 24'b0;
            end
        end
        
        else rdata <= 32'b0;
    end



    // Writing Part

`ifdef MEM_WR_USE_CASE
always @(*) case (write_option)
    `write_word: data_to_write <= wdata;

    `write_hfwd: begin
        if (address[1] == 0) data_to_write <= {16'b0,wdata[15:0]};
        else                 data_to_write <= {wdata[15:0],16'b0};

    end

    `write_byte: begin
        if      (address[1:0] == 2'b00) data_to_write <= {24'b0,wdata[7:0]};
        else if (address[1:0] == 2'b01) data_to_write <= {16'b0,wdata[7:0],8'b0};
        else if (address[1:0] == 2'b10) data_to_write <= {8'b0,wdata[7:0],16'b0};
        else                            data_to_write <= {wdata[7:0],24'b0};
    end
    
    default: data_to_write <= 32'b0;
endcase
`else
    always @(*) begin
        if (write_option == `write_word) data_to_write <= wdata;

        else if (write_option == `write_hfwd) begin
            if (address[1] == 0) begin
                data_to_write[15:0 ] <= wdata[15:0];
                data_to_write[31:16] <= 16'b0;
            end
            else begin
                data_to_write[31:16] <= wdata[15:0];
                data_to_write[15:0] <= 16'b0;
            end
        end

        else if (write_option == `write_byte) begin
            if      (address[1:0] == 2'b00) data_to_write <= {24'b0,wdata[7:0]};
            else if (address[1:0] == 2'b01) data_to_write <= {16'b0,wdata[7:0],8'b0};
            else if (address[1:0] == 2'b10) data_to_write <= {8'b0,wdata[7:0],16'b0};
            else                            data_to_write <= {wdata[7:0],24'b0};
        end
        
        else data_to_write <= 32'b0;
    end
`endif
    
`ifndef USE_GEN_MEM
    always @(posedge clk) begin
        if (write_option != 2'b10) memdata[safe_addr] <= data_to_write;
    end
`endif
endmodule