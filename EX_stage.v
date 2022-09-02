`timescale 1ns/1ps

`include "defs.v"

module EX_stage (
    input wire clk,
    input wire reset,
    //==============================================================//
    // pipeline inputs
    input wire [31:0] pcp4_i,
    input wire [31:0] rfdata1_i,
    input wire [31:0] rfdata2_i,
    input wire [31:0] imm32_i,
    input wire [4:0]  rs_i,
    input wire [4:0]  rt_i,
    input wire [4:0]  rd_i,
    input wire [4:0]  shamt_i,

    // pipeline control signal inputs
`ifdef OPT_2
    input wire [1:0]  c_fwdsrc1_i,
    input wire [1:0]  c_fwdsrc2_i,
`endif
    input wire        c_AluSrc1_i,
    input wire        c_AluSrc2_i,

    input wire [4:0]  c_aluop_i,

    input wire [2:0]  c_BranchOption_i,
    input wire        c_jumpReg_i,

    input wire [1:0]  c_RegDst_i,
    input wire        c_RegWrite_i,
    input wire        c_WBSrc1_i,
    input wire        c_WBSrc2_i,

    input wire [1:0]  c_MemRdOp_i,
    input wire [1:0]  c_MemWrOp_i,
    input wire        c_MemRdSign_i,

    //==============================================================//
    // pipeline outputs
    output wire [31:0] aluresult_o,     // directly connected to ALU
    output wire [31:0] memWrData_o,     // the forwarded value
    output wire [31:0] pcp4_o,          // direct connect
    output wire [4:0]  wb_addr_o,       // selected by RegDst

    output wire        c_WBSrc1_o,
    output wire        c_WBSrc2_o,
    output wire        c_RegWrite_o,
    output wire [1:0]  c_MemRdOp_o,
    output wire [1:0]  c_MemWrOp_o,
    output wire        c_MemRdSign_o,

    //==============================================================//
    // this stage can only be cleaned, but not held
    input wire         e_IDEX_clean,

    // branching and jumping
    output wire [31:0] e_jrOrBranchDesti,
    output wire        e_jrOrBranch,

    // forwarding from latter
    input wire [31:0]  e_fwd_exmem_data,
    input wire [31:0]  e_fwd_memwb_data,
`ifndef OPT_2
    input wire [1:0]   e_fwd_alusrc1,
    input wire [1:0]   e_fwd_alusrc2,
`endif
    // other exterior ports
    output wire [4:0]  e_rs,
    output wire [4:0]  e_rt,
    output wire        e_memRead
`ifdef OPT_2
    ,
    output wire        e_RegWrite,
    output wire [4:0]  e_WBAddr
`endif 
);

    reg [31:0] pcp4_reg;
    reg [31:0] rfdata1_reg;
    reg [31:0] rfdata2_reg;
    reg [31:0] imm32_reg;
    reg [4:0]  rs_reg;
    reg [4:0]  rt_reg;
    reg [4:0]  rd_reg;
    reg [4:0]  shamt_reg;
`ifdef OPT_2
    reg [1:0]  c_fwdsrc1_reg;
    reg [1:0]  c_fwdsrc2_reg;
`endif
    reg        c_AluSrc1_reg;
    reg        c_AluSrc2_reg;

    reg [4:0]  c_aluop_reg;

    reg [2:0]  c_BranchOption_reg;
    reg        c_jumpReg_reg;

    reg        c_WBSrc1_reg;
    reg        c_WBSrc2_reg;
    reg [1:0]  c_RegDst_reg;
    reg        c_RegWrite_reg;

    reg [1:0]  c_MemRdOp_reg;
    reg [1:0]  c_MemWrOp_reg;
    reg        c_MemRdSign_reg;


    // assigning pipeline control signal outputs
    assign c_WBSrc1_o = c_WBSrc1_reg;
    assign c_WBSrc2_o = c_WBSrc2_reg;
    assign c_RegWrite_o = c_RegWrite_reg;

    assign c_MemRdOp_o = c_MemRdOp_reg;
    assign c_MemWrOp_o = c_MemWrOp_reg;
    assign c_MemRdSign_o = c_MemRdSign_reg;


    wire [31:0] aluop1;
    wire [31:0] aluop2;
    reg [31:0] aluop1_regfrd; 
    reg [31:0] aluop2_regfrd; 

    assign memWrData_o = aluop2_regfrd;
    assign pcp4_o = pcp4_reg;
    
    assign e_rs = rs_reg;
    assign e_rt = rt_reg;
    assign e_memRead = ~(c_MemRdOp_reg == 2'b10);

    always @(posedge clk) begin
        pcp4_reg <= pcp4_i;
        rfdata1_reg <= rfdata1_i;
        rfdata2_reg <= rfdata2_i;
        imm32_reg <= imm32_i;

        shamt_reg <= shamt_i;

        c_AluSrc1_reg <= c_AluSrc1_i;
        c_AluSrc2_reg <= c_AluSrc2_i;
        c_aluop_reg <= c_aluop_i;

        c_WBSrc1_reg <= c_WBSrc1_i;
        c_WBSrc2_reg <= c_WBSrc2_i;
`ifdef OPT_2
        c_fwdsrc1_reg <= c_fwdsrc1_i;
        c_fwdsrc2_reg <= c_fwdsrc2_i;
`endif
        c_MemRdSign_reg <= c_MemRdSign_i;
    end
     
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            c_BranchOption_reg <= `BO_none;
            c_jumpReg_reg <= 1'b0;
            c_RegWrite_reg <= 1'b0;
            c_MemRdOp_reg <= 2'b10;
            c_MemWrOp_reg <= 2'b10;
            c_RegDst_reg <= 2'b00;
            rs_reg <= 5'b0;
            rt_reg <= 5'b0;
            rd_reg <= 5'b0;
        end
        else if (e_IDEX_clean) begin
            c_BranchOption_reg <= `BO_none;
            c_jumpReg_reg <= 1'b0;
            c_RegWrite_reg <= 1'b0;
            c_MemRdOp_reg <= 2'b10;
            c_MemWrOp_reg <= 2'b10;
            c_RegDst_reg <= 2'b00;
            rs_reg <= 5'b0;
            rt_reg <= 5'b0;
            rd_reg <= 5'b0;
        end
        else begin
            c_BranchOption_reg <= c_BranchOption_i;
            c_jumpReg_reg <= c_jumpReg_i;
            c_RegWrite_reg <= c_RegWrite_i;
            c_MemRdOp_reg <= c_MemRdOp_i;
            c_MemWrOp_reg <= c_MemWrOp_i;
            c_RegDst_reg <= c_RegDst_i;
            rs_reg <= rs_i;
            rt_reg <= rt_i;
            rd_reg <= rd_i;
        end
    end


    always @(*) case (
`ifdef OPT_2
    c_fwdsrc1_reg
`else
    e_fwd_alusrc1
`endif
    )
            2'b00: aluop1_regfrd <= rfdata1_reg;
            2'b10: aluop1_regfrd <= e_fwd_exmem_data;
            2'b11: aluop1_regfrd <= e_fwd_memwb_data;
            default: aluop1_regfrd <= rfdata1_reg;
    endcase
    assign aluop1[31:5] = aluop1_regfrd[31:5];
    assign aluop1[4:0] = c_AluSrc1_reg ? shamt_reg : aluop1_regfrd[4:0];

    always @(*) case (
`ifdef OPT_2
    c_fwdsrc2_reg
`else
    e_fwd_alusrc2
`endif
    )
            2'b00: aluop2_regfrd <= rfdata2_reg;
            2'b10: aluop2_regfrd <= e_fwd_exmem_data;
            2'b11: aluop2_regfrd <= e_fwd_memwb_data;
            default: aluop2_regfrd <= rfdata2_reg;
    endcase
    assign aluop2  = c_AluSrc2_reg ? aluop2_regfrd : imm32_reg;

    // write back destination
    reg [4:0] wb_addr;
    always @(*) begin
        if (c_RegDst_reg[1])            wb_addr <= 5'b11111;
        else if (c_RegDst_reg[0])       wb_addr <= rt_reg;
        else                            wb_addr <= rd_reg;
    end
    
    assign wb_addr_o = wb_addr;
    
    
    wire [31:0] branchDesti = pcp4_reg + (imm32_reg << 2);
    wire branch;   
    
    // branching and jumping by reg
    assign e_jrOrBranch = branch || c_jumpReg_reg;
    assign e_jrOrBranchDesti = c_jumpReg_reg ? (aluop1_regfrd) : (branchDesti);

 
    alu_wo_comp alu (
        .op1(aluop1),
        .op2(aluop2),
        .aluop(c_aluop_reg),
        .branchOp(c_BranchOption_reg),
        .result(aluresult_o),
        .branch(branch)
    );
    
`ifdef OPT_2
    assign e_RegWrite = c_RegWrite_reg;
    assign e_WBAddr = wb_addr;
`endif



endmodule



module DataHanzardDetector (
    input wire [4:0] EX_rs,
    input wire [4:0] EX_rt,

    input wire MEM_RegWrite,
    input wire [4:0] MEM_WBAddr,

    input wire WB_RegWrite,
    input wire [4:0] WB_WBAddr,

    output reg [1:0] datafwd_1,
    output reg [1:0] datafwd_2
);

    // design logic:
    // first forward wb to ex
    // if not, mem
    
    always @(*) begin
        if (MEM_RegWrite && (MEM_WBAddr != 5'b0) && (MEM_WBAddr == EX_rs)) begin
            datafwd_1 <= 2'b10;
        end
        else if (WB_RegWrite && (WB_WBAddr != 5'b0) && (WB_WBAddr == EX_rs)) begin
            datafwd_1 <= 2'b11;
        end
        else datafwd_1 <= 2'b00;

        if (MEM_RegWrite && (MEM_WBAddr != 5'b0) && (MEM_WBAddr == EX_rt)) begin
            datafwd_2 <= 2'b10;
        end
        else if (WB_RegWrite && (WB_WBAddr != 5'b0) && (WB_WBAddr == EX_rt)) begin
            datafwd_2 <= 2'b11;
        end
        else datafwd_2 <= 2'b00;
    end
    
endmodule

`ifdef OPT_3
module JrTempReg (
    input wire clk,
    input wire reset,

    input wire [31:0] data_in,
    output reg [31:0] data_out,

    input wire is_jr,
    output reg indicator
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            indicator <= 0;
        end
        else indicator <= is_jr;
    end

    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule
`endif