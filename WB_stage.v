`timescale 1ns/1ps


module WB_stage (
    input wire clk,
    input wire reset,

    // pipeline inputs
    input wire [31:0] wbData_temp_i,
    input wire [31:0] memData_i,
    input wire [4:0]  wb_addr_i,
    input wire        c_WBSrc2_i,
    input wire        c_RegWrite_i,

    // outputs (not pipeline)
    output wire [31:0] e_WBData,
    output wire        e_RegWrite,
    output wire [4:0]  e_WBAddr

);
    reg [31:0] wbData_temp_reg;
    reg [31:0] memData_reg;
    reg [4:0]  wb_addr_reg;
    reg c_WBSrc2_reg;
    reg c_RegWrite_reg;

    always @(posedge clk) begin
        wbData_temp_reg <= wbData_temp_i;
        memData_reg <= memData_i;
        wb_addr_reg <= wb_addr_i;
        c_WBSrc2_reg <= c_WBSrc2_i;
    end
    always @(posedge clk or posedge reset) begin
         if (reset) begin
            c_RegWrite_reg <= 1'b0;
         end
         else begin
            c_RegWrite_reg <= c_RegWrite_i;
         end
    end

    assign e_WBData = c_WBSrc2_reg ? memData_reg : wbData_temp_reg;
    assign e_RegWrite = c_RegWrite_reg;
    assign e_WBAddr = wb_addr_reg;
    
endmodule