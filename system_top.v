`timescale 1ns/1ps

`include "defs.v"

module system_top (
    input wire sys_clk,
    input wire reset,

    // LED interface
    output wire [7:0] leds,
    
    // BCD interface
    output wire [3:0] an,
    output wire [7:0] digit

    // // UART interface
    // input wire Rx_Serial,
    // output wire Tx_Serial
);
    wire clk;
    
`ifdef FREQ_DIVIDE
    wire locked;
    clk_wiz_0 clkwiz (
        .clk_out1(clk),
        .locked(locked),
        .clk_in1(sys_clk)
    );
    
    wire cpu_reset = (~locked) && reset;
`else
    wire cpu_reset = reset;
    assign clk = sys_clk;
`endif
    wire [31:0] addr;
    wire [31:0] wdata; // data written by CPU
    reg  [31:0] rdata; // data read by CPU (send to CPU)
    wire [1:0]  rdop;
    wire [1:0]  wrop;
    wire        rdsign;


    // Processor
    CPU_top
    cpu(
        .clk(clk),
        .reset(cpu_reset),
        .rdata(rdata),
        .wdata(wdata),
        .addr(addr),
        .rdop(rdop),
        .wrop(wrop),
        .rdsign(rdsign)
    );
    


    wire addr_LED = (addr == 32'h4000000C);
    wire addr_BCD = (addr == 32'h40000010);
    wire addr_MEM = (addr <  32'h00000800);

    // registers
    wire [7:0] LED_data;
    wire [31:0] LED_data32 = {24'b0,LED_data};
    wire LED_wr_en = ((addr_LED) && (wrop != 2'b10));
    tempreg #(8) reg_LED (
        .clk(clk),
        .reset(reset),
        .data_i(wdata[7:0]),
        .data_o(LED_data),
        .wr_en(LED_wr_en)
    );

    wire [11:0] BCD_data;
    wire [31:0] BCD_data32 = {20'b0,BCD_data};
    wire BCD_wr_en = ((addr_BCD) && (wrop != 2'b10));
    tempreg #(12) reg_BCD (
        .clk(clk),
        .reset(reset),
        .data_i(wdata[11:0]),
        .data_o(BCD_data),
        .wr_en(BCD_wr_en)
    );

    // memory
    wire [1:0] mem_wrop = (addr_MEM) ? (wrop) : (2'b10);
    wire [31:0] MEM_data;

    parameter MEM_SIZE = 1024; // unit: word
    parameter PHYS_LW  = 10;

    datamem2#(
        .MEM_SIZE(MEM_SIZE),
        .PHYS_LW(PHYS_LW)
    ) dmem (
        .clk(clk),
        .wdata(wdata),
        .address(addr),
        .read_option(rdop),
        .write_option(mem_wrop),
        .extra_op(rdsign),
        .rdata(MEM_data)
    );

    always @(*) begin
        if (rdop != 2'b10) begin
            if (addr_MEM)           rdata <= MEM_data;
            else if (addr_LED)      rdata <= LED_data32;
            else if (addr_BCD)      rdata <= BCD_data32;
            else                    rdata <= 32'b0;
        end
        else                        rdata <= 32'b0;
    end


    assign an = BCD_data[11:8];
    assign digit = BCD_data[7:0];
    assign leds = LED_data;

    
endmodule