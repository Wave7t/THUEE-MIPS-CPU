`timescale 1ns/1ps

`include "defs.v"

module CPU_top(
    input wire clk,
    input wire reset,

    // memory interface
    output wire [31:0] wdata, // data written to memory
    output wire [31:0] addr,
    input wire [31:0] rdata, // data read from memory
    output wire [1:0] rdop,
    output wire [1:0] wrop,
    output wire       rdsign
);


//    // outputs to e
//    wire [4:0]  rs_ID2e;
//    wire [4:0]  rt_ID2e;
//    wire [4:0]  rs_EX2e;
//    wire [4:0]  rt_EX2e;
//    wire [4:0]  WBAddr_MEM2e;
//    wire        RegWrite_MEM2e;
//    wire        memRead_EX2e;

    // inputs to IF stage
    wire        PCHold_e2IF;
    wire [31:0] jumpDesti_ID2IF;
    wire [31:0] jrOrBranchDesti_EX2IF;
    wire [1:0]  PCSrc_e2IF;
`ifdef OPT_3
    wire [31:0] jrOrBranchDesti_fe;
    wire        jrOrBranch_fe;
`endif

    // inputs to ID stage
    wire        IFIDHold_e2ID;
    wire        RegWrite_WB2ID;
    wire [4:0]  WBAddr_WB2ID;
    wire [31:0] WBData_WB2ID;

    wire        jump_fID;
    wire [31:0] jumpDesti_fID;
    wire        UseData1_ID2e;
    wire        UseData2_ID2e; 
    wire [4:0]  rs_fID;
    wire [4:0]  rt_fID;

    // inputs to EX stage
    wire        IDEX_clean_e2EX;
    wire [31:0] fwd_exmem_data_MEM2EX;
    wire [31:0] fwd_memwb_data_WB2EX = WBData_WB2ID;
`ifndef OPT_2
    wire [1:0]  fwd_alusrc1_e2EX;
    wire [1:0]  fwd_alusrc2_e2EX;
`endif
    wire [31:0] jrOrBranchDesti_fEX;
    wire        jrOrBranch_fEX;

    wire [4:0]  rs_fEX;
    wire [4:0]  rt_fEX;
    wire        memRead_fEX;
`ifdef OPT_2
    wire       RegWrite_fEX;
    wire [4:0] WBAddr_fEX;
    wire [1:0] fwdsrc1_e2EX;
    wire [1:0] fwdsrc2_e2EX;
`endif

    // MEM
    wire [1:0]  MemRdOp_MEM2e;
    wire [1:0]  MemWrOp_MEM2e;
    wire        MemRdSign_MEM2e;

    wire [31:0] memWData_MEM2e;
    wire [31:0] memAddr_MEM2e;
    wire [31:0] memData_e2MEM;

    wire [4:0]  WBAddr_fMEM;
    wire        RegWrite_fMEM;

    wire [31:0] aluresult_fwd_fMEM;

    // Load-Use Hanzard Detector
    wire stall_e;

    // forward engine
`ifndef OPT_2
    wire [1:0] fwd_alusrc1_fe;
    wire [1:0] fwd_alusrc2_fe;
`endif

    // WB
    wire [31:0] WBData_fWB;
    wire        RegWrite_fWB;
    wire [4:0]  WBAddr_fWB;


    // pipeline signals: IF to ID
    wire [31:0] pcp4_IF2ID;
    wire [31:0] inst_IF2ID;

    // pipeline signals: ID to EX
    wire [31:0] pcp4_ID2EX;
    wire [31:0] regdata1_ID2EX;
    wire [31:0] regdata2_ID2EX;
    wire [31:0] imm32_ID2EX;
    wire [4:0] rs_ID2EX;
    wire [4:0] rt_ID2EX;
    wire [4:0] rd_ID2EX;
    wire [4:0] shamt_ID2EX;

    wire        c_AluSrc1_ID2EX;
    wire        c_AluSrc2_ID2EX;
    wire [4:0]  c_aluop_ID2EX;

    wire [2:0]  c_BranchOption_ID2EX;
    wire        c_jumpReg_ID2EX;

    wire        c_WBSrc1_ID2EX;
    wire        c_WBSrc2_ID2EX;
    wire [1:0]  c_RegDst_ID2EX;
    wire        c_RegWrite_ID2EX;

    wire [1:0]  c_MemRdOp_ID2EX;
    wire [1:0]  c_MemWrOp_ID2EX;
    wire        c_MemRdSign_ID2EX;

    // pipelinw signals: EX to MEM
    wire [31:0] aluresult_EX2MEM;
    wire [31:0] memWrData_EX2MEM;
    wire [31:0] pcp4_EX2MEM;
    wire  [4:0]  wb_addr_EX2MEM;

    wire        c_WBSrc1_EX2MEM;
    wire        c_WBSrc2_EX2MEM;
    wire        c_RegWrite_EX2MEM;
    wire [1:0]  c_MemRdOp_EX2MEM;
    wire [1:0]  c_MemWrOp_EX2MEM;
    wire        c_MemRdSign_EX2MEM;

    // pipeline signals: MEM to WB
    wire [31:0] wbData_temp_MEM2WB;
    wire [31:0] memData_MEM2WB;
    wire [4:0]  wb_addr_MEM2WB;

    wire        c_WBSrc2_MEM2WB;
    wire        c_RegWrite_MEM2WB;

    // WB to IF signals
    IF_stage IFs (
        .clk(clk),
        .reset(reset),
        .e_PCHold(PCHold_e2IF),
        .e_PCSrc(PCSrc_e2IF),
        .e_jrOrBranchDesti(jrOrBranchDesti_EX2IF),
        .e_jumpDesti(jumpDesti_ID2IF),

        .pcp4_o(pcp4_IF2ID),
        .inst_o(inst_IF2ID)
    );

`ifdef OPT_3
    assign PCHold_e2IF = stall_e && (~jrOrBranch_fEX);
    assign PCSrc_e2IF  = {jrOrBranch_fe,jump_fID};
    assign jrOrBranchDesti_EX2IF = jrOrBranchDesti_fe;    
    assign jumpDesti_ID2IF = jumpDesti_fID;
`else
    assign PCHold_e2IF = stall_e && (~jrOrBranch_fEX);
    assign PCSrc_e2IF  = {jrOrBranch_fEX,jump_fID};
    assign jrOrBranchDesti_EX2IF = jrOrBranchDesti_fEX;    
    assign jumpDesti_ID2IF = jumpDesti_fID;
`endif

    ID_stage ID (
        .clk(clk),
        .reset(reset),

        .inst_i(inst_IF2ID),
        .pcp4_i(pcp4_IF2ID),

        .pcp4_o(pcp4_ID2EX),
        .regdata1_o(regdata1_ID2EX),
        .regdata2_o(regdata2_ID2EX),
        .imm32_o(imm32_ID2EX),
        .rs_o(rs_ID2EX),
        .rt_o(rt_ID2EX),
        .rd_o(rd_ID2EX),
        .shamt_o(shamt_ID2EX),

        .c_AluSrc1_o(c_AluSrc1_ID2EX),
        .c_AluSrc2_o(c_AluSrc2_ID2EX),
        .c_aluop_o(c_aluop_ID2EX),
        .c_BranchOption_o(c_BranchOption_ID2EX),
        .c_jumpReg_o(c_jumpReg_ID2EX),
        .c_WBSrc1_o(c_WBSrc1_ID2EX),
        .c_WBSrc2_o(c_WBSrc2_ID2EX),
        .c_RegDst_o(c_RegDst_ID2EX),
        .c_RegWrite_o(c_RegWrite_ID2EX),
        .c_MemRdOp_o(c_MemRdOp_ID2EX),
        .c_MemWrOp_o(c_MemWrOp_ID2EX),
        .c_MemRdSign_o(c_MemRdSign_ID2EX),

        .e_IFIDHold(IFIDHold_e2ID),
        .e_RegWrite(RegWrite_WB2ID),
        .e_WBAddr(WBAddr_WB2ID),
        .e_WBData(WBData_WB2ID),

        .e_jump(jump_fID),
        .e_jumpDesti(jumpDesti_fID),
        .e_UseData1(UseData1_ID2e),
        .e_UseData2(UseData2_ID2e),
        .e_rs(rs_fID),
        .e_rt(rt_fID)
`ifdef OPT_3
        ,
        .e_IFID_clean(jrOrBranch_fEX)
`endif
    );

`ifdef OPT_3
    assign IFIDHold_e2ID = stall_e && (~jrOrBranch_fe);
`else
    assign IFIDHold_e2ID = stall_e && (~jrOrBranch_fEX);
`endif
    assign RegWrite_WB2ID = RegWrite_fWB;
    assign WBAddr_WB2ID = WBAddr_fWB;
    assign WBData_WB2ID = WBData_fWB;


    EX_stage EX (
        .clk(clk),
        .reset(reset),

        .pcp4_i(pcp4_ID2EX),
        .rfdata1_i(regdata1_ID2EX),
        .rfdata2_i(regdata2_ID2EX),
        .imm32_i(imm32_ID2EX),
        .rs_i(rs_ID2EX),
        .rt_i(rt_ID2EX),
        .rd_i(rd_ID2EX),
        .shamt_i(shamt_ID2EX),
`ifdef OPT_2
        .c_fwdsrc1_i(fwdsrc1_e2EX),
        .c_fwdsrc2_i(fwdsrc2_e2EX),
`endif
        .c_AluSrc1_i(c_AluSrc1_ID2EX),
        .c_AluSrc2_i(c_AluSrc2_ID2EX),
        .c_aluop_i(c_aluop_ID2EX),
        .c_BranchOption_i(c_BranchOption_ID2EX),
        .c_jumpReg_i(c_jumpReg_ID2EX),
        .c_RegDst_i(c_RegDst_ID2EX),
        .c_RegWrite_i(c_RegWrite_ID2EX),
        .c_WBSrc1_i(c_WBSrc1_ID2EX),
        .c_WBSrc2_i(c_WBSrc2_ID2EX),
        .c_MemRdOp_i(c_MemRdOp_ID2EX),
        .c_MemWrOp_i(c_MemWrOp_ID2EX),
        .c_MemRdSign_i(c_MemRdSign_ID2EX),

        .aluresult_o(aluresult_EX2MEM),
        .memWrData_o(memWrData_EX2MEM),
        .pcp4_o(pcp4_EX2MEM),
        .wb_addr_o(wb_addr_EX2MEM),

        .c_WBSrc1_o(c_WBSrc1_EX2MEM),
        .c_WBSrc2_o(c_WBSrc2_EX2MEM),
        .c_RegWrite_o(c_RegWrite_EX2MEM),
        .c_MemRdOp_o(c_MemRdOp_EX2MEM),
        .c_MemWrOp_o(c_MemWrOp_EX2MEM),
        .c_MemRdSign_o(c_MemRdSign_EX2MEM),

        .e_IDEX_clean(IDEX_clean_e2EX),
        .e_jrOrBranchDesti(jrOrBranchDesti_fEX),
        .e_jrOrBranch(jrOrBranch_fEX),

        .e_fwd_exmem_data(fwd_exmem_data_MEM2EX),
        .e_fwd_memwb_data(fwd_memwb_data_WB2EX),
`ifndef OPT_2
        .e_fwd_alusrc1(fwd_alusrc1_e2EX),
        .e_fwd_alusrc2(fwd_alusrc2_e2EX),
`endif
        .e_rs(rs_fEX),
        .e_rt(rt_fEX),
        .e_memRead(memRead_fEX)
`ifdef OPT_2
        ,
        .e_RegWrite(RegWrite_fEX),
        .e_WBAddr(WBAddr_fEX)
`endif
    );


    assign IDEX_clean_e2EX = jrOrBranch_fEX || stall_e;
    assign fwd_exmem_data_MEM2EX = aluresult_fwd_fMEM;
    assign fwd_memwb_data_WB2EX = WBData_fWB;
`ifndef OPT_2
    assign fwd_alusrc1_e2EX = fwd_alusrc1_fe;
    assign fwd_alusrc2_e2EX = fwd_alusrc2_fe;
`endif

    MEM_stage MEM (
        .clk(clk),
        .reset(reset),
        
        .aluresult_i(aluresult_EX2MEM),
        .memWrData_i(memWrData_EX2MEM),
        .pcp4_i(pcp4_EX2MEM),
        .wb_addr_i(wb_addr_EX2MEM),

        .c_WBSrc1_i(c_WBSrc1_EX2MEM),
        .c_WBSrc2_i(c_WBSrc2_EX2MEM),
        .c_RegWrite_i(c_RegWrite_EX2MEM),
        .c_MemRdOp_i(c_MemRdOp_EX2MEM),
        .c_MemWrOp_i(c_MemWrOp_EX2MEM),
        .c_MemRdSign_i(c_MemRdSign_EX2MEM),

        .wbData_temp_o(wbData_temp_MEM2WB),
        .memData_o(memData_MEM2WB),
        .wb_addr_o(wb_addr_MEM2WB),
        .c_WBSrc2_o(c_WBSrc2_MEM2WB),
        .c_RegWrite_o(c_RegWrite_MEM2WB),

        // memory interface
        .e_MemRdOp(MemRdOp_MEM2e),
        .e_MemWrOp(MemWrOp_MEM2e),
        .e_MemRdSign(MemRdSign_MEM2e),
        .e_memWData(memWData_MEM2e),
        .e_memAddr(memAddr_MEM2e),
        .e_memData(memData_e2MEM),

        .e_WBAddr(WBAddr_fMEM),
        .e_RegWrite(RegWrite_fMEM),
        .e_aluresult_fwd(aluresult_fwd_fMEM)
    );

    assign wdata = memWData_MEM2e;
    assign addr = memAddr_MEM2e;
    assign rdop = MemRdOp_MEM2e;
    assign wrop = MemWrOp_MEM2e;
    assign rdsign = MemRdSign_MEM2e;
    assign memData_e2MEM = rdata;

    WB_stage WB (
        .clk(clk),
        .reset(reset),

        .wbData_temp_i(wbData_temp_MEM2WB),
        .memData_i(memData_MEM2WB),
        .wb_addr_i(wb_addr_MEM2WB),
        .c_WBSrc2_i(c_WBSrc2_MEM2WB),
        .c_RegWrite_i(c_RegWrite_MEM2WB),

        .e_WBData(WBData_fWB),
        .e_RegWrite(RegWrite_fWB),
        .e_WBAddr(WBAddr_fWB)
    );


    LoadUseHanzardDetector_wo_wt luh_dtc (
        .EX_is_load(memRead_fEX),
        .ID_use_data1(UseData1_ID2e),
        .ID_use_data2(UseData2_ID2e),
        .ID_raddr1(rs_fID),
        .ID_raddr2(rt_fID),
        .EX_waddr(rt_fEX), // in the case of load instructions, WBAddress is exactly rt
        .stall(stall_e)
    );
    
`ifdef OPT_2
    DataHanzardDetector dhd (
        .EX_rs(rs_fID),
        .EX_rt(rt_fID),
        .MEM_RegWrite(RegWrite_fEX),
        .MEM_WBAddr(WBAddr_fEX),

        .WB_RegWrite(RegWrite_fMEM),
        .WB_WBAddr(WBAddr_fMEM),

        .datafwd_1(fwdsrc1_e2EX),
        .datafwd_2(fwdsrc2_e2EX)
    );
`else
    DataHanzardDetector dhd (
        .EX_rs(rs_fEX),
        .EX_rt(rt_fEX),
        .MEM_RegWrite(RegWrite_fMEM),
        .MEM_WBAddr(WBAddr_fMEM),

        .WB_RegWrite(RegWrite_fWB),
        .WB_WBAddr(WBAddr_fWB),

        .datafwd_1(fwd_alusrc1_fe),
        .datafwd_2(fwd_alusrc2_fe)
    );
`endif

`ifdef OPT_3
    JrTempReg jtr (
        .clk(clk),
        .reset(reset),
        .data_in(jrOrBranchDesti_fEX),
        .data_out(jrOrBranchDesti_fe),
        .is_jr(jrOrBranch_fEX),
        .indicator(jrOrBranch_fe)
    );
`endif

endmodule