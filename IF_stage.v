`timescale 1ns/1ps

`include "defs.v"

`ifdef OPT_1
module IF_stage(
    input wire clk,
    input wire reset,

    // pipeline outputs
    output wire [31:0] pcp4_o, 
    output wire [31:0] inst_o,

    input wire e_PCHold,
    input wire [31:0] e_jumpDesti,
    input wire [31:0] e_jrOrBranchDesti,
    input wire [1:0]  e_PCSrc
//`ifdef OPT_3
//    ,
//    input wire [31:0] e_JrDesti,
//    input wire [31:0] e_JrP4
//`endif
);
    wire [31:0] pc_out;
    reg [31:0] pc_src;
    
    reg [31:0] inst_addr;
    wire [31:0] inst_readout;

    wire [31:0] jump_p4 = e_jumpDesti + 32'd4;
    wire [31:0] jrOrBranch_p4 = e_jrOrBranchDesti + 32'd4;
    wire [31:0] pc_p4 = pc_out + 32'd4;

    PC pc (
        .clk(clk),
        .reset(reset),
        .PCWrite(~e_PCHold), // if e_PCHold is set 1, then PC would not write
        .addr_in(pc_src),
        .addr_out(pc_out)
    );

    instMem3 ti1 (
        .a(inst_addr[9:2]),
        .spo(inst_readout)
    );
    
    assign inst_o = inst_readout;
    assign pcp4_o = pc_src;

    always @(*) begin
        case (e_PCSrc)
            2'b00: begin
                inst_addr <= pc_out;
                pc_src <= pc_p4;
            end 
            
            2'b01: begin
                inst_addr <= e_jumpDesti;
                pc_src <= jump_p4;
            end
            
            default: begin
                inst_addr <= e_jrOrBranchDesti;
                pc_src <= jrOrBranch_p4;
            end
        endcase
    end
    
endmodule

`else

module IF_stage(
    input wire clk,
    input wire reset,

    // pipeline outputs
    output wire [31:0] pcp4_o, 
    output wire [31:0] inst_o,

    input wire e_PCHold,
    input wire [31:0] e_jumpDesti,
    input wire [31:0] e_jrOrBranchDesti,
    input wire [1:0]  e_PCSrc
);

    wire [31:0] pc_out; 
    reg  [31:0] inst_addr;
    wire [31:0] inst_readout;
    wire [31:0] pcp4 = inst_addr + 32'd4;

    // pc_o is carried to the next stage along with the fetched instruction
    // whatever source used to renew PC, the value passed to the next stage is the PC of this instruction + 4
    assign pcp4_o = pcp4;

    PC pc (
        .clk(clk),
        .reset(reset),
        .PCWrite(~e_PCHold), // if e_PCHold is set 1, then PC would not write
        .addr_in(pcp4),
        .addr_out(pc_out)
    );

    // NOTE here that forwarding is not implemented for instruction fetch,
    // so IF stage ALWAYS fetches the instruction indexed by PC
//    InstMem 
//    im (
//        .addr_i(inst_addr),
//        .inst_o(inst_readout)
//    );
    
instMem3 ti3 (
    .a(inst_addr[11:2]),
    .spo(inst_readout)
);


    assign inst_o = inst_readout;

    always @(*) begin
        case (e_PCSrc)
            2'b00: inst_addr <= pc_out;
            2'b01: inst_addr <= e_jumpDesti;
            default: inst_addr <= e_jrOrBranchDesti;
        endcase
    end
    
endmodule
`endif


module PC (
    input wire clk,
    input wire reset,
    input wire PCWrite,
    input wire [31:0] addr_in,
    output reg [31:0] addr_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) 
            addr_out <= 32'b0;
        else if (PCWrite) 
            addr_out <= addr_in;
    end
    
endmodule