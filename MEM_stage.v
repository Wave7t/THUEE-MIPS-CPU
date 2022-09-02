`timescale 1ns/1ps


module MEM_stage (
    input wire clk,
    input wire reset,

    // pipeline inputs
    input wire [31:0]  aluresult_i,
    input wire [31:0]  memWrData_i,
    input wire [31:0]  pcp4_i,
    input wire  [4:0]  wb_addr_i,

    input wire         c_WBSrc1_i,
    input wire         c_WBSrc2_i,
    input wire         c_RegWrite_i,
    input wire [1:0]   c_MemRdOp_i,
    input wire [1:0]   c_MemWrOp_i,
    input wire         c_MemRdSign_i,

    // pipeline outputs
    output wire [31:0] wbData_temp_o,
    output wire [31:0] memData_o,
    output wire [4:0]  wb_addr_o,

    output wire        c_WBSrc2_o,
    output wire        c_RegWrite_o,


    // data memory interface
    output wire [1:0]  e_MemRdOp,
    output wire [1:0]  e_MemWrOp,
    output wire        e_MemRdSign,

    output wire [31:0] e_memWData,
    output wire [31:0] e_memAddr,
    input wire [31:0]  e_memData,


    // hanzard detection
    output wire [4:0]  e_WBAddr,
    output wire        e_RegWrite,

    // forwarding
    output wire [31:0] e_aluresult_fwd
);


    reg [31:0] aluresult_reg;
    reg [31:0] memWrData_reg;
    reg [31:0] pcp4_reg;
    reg  [4:0] wb_addr_reg;
    reg        c_WBSrc1_reg;
    reg        c_WBSrc2_reg;
    reg        c_RegWrite_reg;
    reg [1:0]  c_MemRdOp_reg;
    reg [1:0]  c_MemWrOp_reg;
    reg        c_MemRdSign_reg;
    
    // register update
    always @(posedge clk) begin
        aluresult_reg <= aluresult_i;
        memWrData_reg <=  memWrData_i;
        pcp4_reg <=  pcp4_i;
        c_WBSrc1_reg <= c_WBSrc1_i;
        c_WBSrc2_reg <= c_WBSrc2_i;
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wb_addr_reg <= 5'b0;
            c_RegWrite_reg <= 1'b0;
            c_MemRdOp_reg <= 2'b10;
            c_MemWrOp_reg <= 2'b10;
            c_MemRdSign_reg <= 1'b0;
        end
        else begin
            wb_addr_reg <= wb_addr_i;
            c_RegWrite_reg <= c_RegWrite_i;
            c_MemRdOp_reg <= c_MemRdOp_i;
            c_MemWrOp_reg <= c_MemWrOp_i;
            c_MemRdSign_reg <= c_MemRdSign_i;
         end
    end

    assign c_WBSrc2_o = c_WBSrc2_reg;
    assign c_RegWrite_o = c_RegWrite_reg;
    assign wb_addr_o = wb_addr_reg;

    assign e_MemRdOp = c_MemRdOp_reg;
    assign e_MemWrOp = c_MemWrOp_reg;
    assign e_MemRdSign = c_MemRdSign_reg;

    assign memData_o = e_memData;
    assign e_memWData = memWrData_reg;
    assign e_memAddr = aluresult_reg;

    assign e_WBAddr = wb_addr_reg;
    assign e_RegWrite = c_RegWrite_reg;

    assign wbData_temp_o = c_WBSrc1_reg ? pcp4_reg : aluresult_reg;

    assign e_aluresult_fwd = aluresult_reg;
    
endmodule