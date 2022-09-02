`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/12 09:57:41
// Design Name: 
// Module Name: testbench_cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench_cpu;


wire [31:0] addr;
wire [31:0] wdata; // data written by CPU
wire [31:0] rdata; // data read by CPU (send to CPU)
wire [1:0]  rdop;
wire [1:0]  wrop;
wire        rdsign;
reg sys_clk;
reg reset; 
initial begin
    sys_clk = 0;
    reset = 1;
    #20
    reset = 0;
end

always #(5) sys_clk = ~sys_clk;
    
wire locked;
wire clk;
clk_wiz_0 clkwiz_t (
    .clk_out1(clk),
    .clk_in1(sys_clk),
    .locked(locked)
);


CPU_top
cpu_test(
    .clk(clk),
    .reset(reset || ~locked),
    .rdata(rdata),
    .wdata(wdata),
    .addr(addr),
    .rdop(rdop),
    .wrop(wrop),
    .rdsign(rdsign)
);

    datamem2 dmem (
        .clk(clk),
        .wdata(wdata),
        .address(addr),
        .read_option(rdop),
        .write_option(wrop),
        .extra_op(rdsign),
        .rdata(rdata)
    );

    wire [31:0] pc_ = cpu_test.ID.pcp4_reg;
    wire [31:0] ra_ = cpu_test.ID.regfile.regdata[31];
    wire [31:0] sp_ = cpu_test.ID.regfile.regdata[29];
    wire [31:0] a0_ = cpu_test.ID.regfile.regdata[4];
    wire [31:0] a1_ = cpu_test.ID.regfile.regdata[5];
    wire [31:0] v0_ = cpu_test.ID.regfile.regdata[2];
    wire [31:0] t0_ = cpu_test.ID.regfile.regdata[8];
    wire [31:0] t1_ = cpu_test.ID.regfile.regdata[9];
    wire [31:0] t2_ = cpu_test.ID.regfile.regdata[10];
    wire [31:0] t3_ = cpu_test.ID.regfile.regdata[11];
    wire [31:0] s0_ = cpu_test.ID.regfile.regdata[16];
    wire [31:0] s1_ = cpu_test.ID.regfile.regdata[17];
    wire [31:0] s2_ = cpu_test.ID.regfile.regdata[18];
    wire [31:0] op1_ = cpu_test.EX.aluop1;
    wire [31:0] op2_ = cpu_test.EX.aluop2;
    wire alusrc1 = cpu_test.EX.c_AluSrc1_reg;
    wire alusrc2 = cpu_test.EX.c_AluSrc2_reg;
//    wire [1:0] fwd1 = cpu_test.EX.c_fwdsrc1_reg;
//    wire [1:0] fwd2 = cpu_test.EX.c_fwdsrc2_reg;
    wire [4:0] rs_ID = cpu_test.rs_fID;
    wire [4:0] rt_ID = cpu_test.rt_fID;
//    wire regR_EX = cpu_test.RegWrite_fEX;
//    wire regR_MEM = cpu_test.RegWrite_fMEM;
//    wire [4:0] wbaddr_EX = cpu_test.WBAddr_fEX;
//    wire [4:0] wbaddr_MEM = cpu_test.WBAddr_fMEM;
    
    wire [31:0] wbdata = cpu_test.WBData_fWB;
    wire [4:0] wbaddr = cpu_test.WBAddr_fWB;
    wire RegWrite = cpu_test.RegWrite_fWB;
//    wire [1:0] alusrc1 = cpu_test.EX.alusrc1;
//    wire [1:0] alusrc2 = cpu_test.EX.alusrc2;

//    wire [5:0] inst_pre = cpu_test.IF.inst_readout[31:26];
    wire RegWrite_ID = cpu_test.ID.c_RegWrite;
    wire [5:0] inst = cpu_test.ID.opcode;

    wire [1:0] WBSrc = {cpu_test.ID.c_WBSrc1,cpu_test.ID.c_WBSrc2};
    wire jrOrBranch = cpu_test.jrOrBranch_fEX;
    wire stall = cpu_test.stall_e;
    wire jump = cpu_test.jump_fID;
//    wire jr = cpu_test.c_Jr_fEX;
//    wire indicator = cpu_test.PCSrc_jr_fe;
//    wire [1:0] pcsrc = cpu_test.PCSrc_e2IF;
    wire [31:0] fwdpcsrc = cpu_test.jrOrBranchDesti_EX2IF;
//    wire [31:0] jr_fex = cpu_test.JrDesti_fEX;
//    wire [31:0] jr_fe = cpu_test.JrDesti_fe;
endmodule
