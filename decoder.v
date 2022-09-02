`timescale 1ns/1ps

`include "defs.v"

module mips_decoder (
    input wire [5:0] opcode_i,
    input wire [5:0] funccode_i,

    input wire  rt0_i, 
    input wire  rt4_i, 

    output wire         c_immExtOp,
    // ALUSrc specifications:
    // ALUSrc1: 11 or for const 16, 01 for shamt, 00 for reg value
    // ALUSrc2: 1 for reg value, 0 for imm
    output wire [1:0]   c_AluSrc1,
    output wire         c_AluSrc2,
    output wire [4:0]   c_aluop,


    output reg [2:0]    c_BranchOption,
    output wire         c_jump, 
    output wire         c_jumpReg,

    // specifications: 
    // WBSrc1: 1 for PC + 4 and 0 for aluresult
    // WBSrc2: 0 for previous result, and 1 for memdata
    // RegDst: 00 for rd, 01 for rt, 10 or 11 for 31
    output wire [1:0]   c_RegDst,
    output wire         c_WBSrc1,
    output wire         c_WBSrc2,
    output wire         c_RegWrite,

    output reg [1:0]    c_MemRdOp,
    output reg [1:0]    c_MemWrOp,
    output wire         c_MemRdSign,

    output wire         use_data1,
    output wire         use_data2
);
    
    wire is_lui = (opcode_i == `OP_lui);
    wire shift = (opcode_i == `OP_R && funccode_i[5:3] == 3'b000);
    wire shift_shamt = shift && (~funccode_i[2]);
    assign c_AluSrc1[1] = is_lui;
    // c_ALUSrc1[0]: represents shift by "shamt" or const shamt
    assign c_AluSrc1[0] = shift_shamt || is_lui;

    // all instructions that need *rt as ALU operand:
    // - all R instructions;
    // - BEQ and BNE
    assign c_AluSrc2 = (
        (opcode_i == `OP_R) ||
        (opcode_i == `OP_beq) ||
        (opcode_i == `OP_bne)
    );


    // this signal means: jump by concated address
    assign c_jump = (opcode_i == `OP_j || opcode_i == `OP_jal); 
    // this expression: jump by reg address
    assign c_jumpReg = (
        opcode_i == `OP_R          &&
        (funccode_i == `FUNC_jr || funccode_i == `FUNC_jalr)
    );


    // branching
    // as for linking (4 instructions starting with 000001: BGEZ, BGEZAL, BLTZ, BLTZAL)
    // "AL" is indicated by rt[4], while rt[0] tells GE(1) from LT(0)
    always @(*) begin
        if (opcode_i[5:3] == 3'b000) begin
            case (opcode_i[2:0]) 
                3'b100:            c_BranchOption <= `BO_beq;
                3'b001: if (rt0_i) c_BranchOption <= `BO_gez;
                        else       c_BranchOption <= `BO_ltz;
                3'b111:            c_BranchOption <= `BO_gtz;
                3'b110:            c_BranchOption <= `BO_lez;
                3'b101:            c_BranchOption <= `BO_ueq;
                default:           c_BranchOption <= `BO_none;
            endcase
        end
        else begin
            c_BranchOption <= `BO_none;
        end
    end

    // memory operations
    assign c_MemRdSign = ~opcode_i[2];
    always @(*) begin
        if (opcode_i[5] == 1'b0) begin
            c_MemRdOp <= `not_read;
            c_MemWrOp <= `not_write;
        end
        else begin
            if (opcode_i[3] == 1'b0) begin
                c_MemRdOp <= opcode_i[1:0];
                c_MemWrOp <= `not_write;
            end
            else begin
                c_MemRdOp <= `not_read;
                c_MemWrOp <= opcode_i[1:0];
            end
        end
    end

    // Write Back: jal, jalr, bgezal, bltzal
    wire link = (
        (opcode_i == 6'b000001 && rt4_i ) ||
        (opcode_i == `OP_jal )            ||
        ((opcode_i == `OP_R) && (funccode_i == `FUNC_jalr))
    );
    assign c_RegDst[1] = link;

    // cases where write to rd
    assign c_RegDst[0] = ~(
        opcode_i == `OP_R
    );


    // the only exception when an instruction starting with 6'000000 
    // does not write reg (in this implementation) is jr
    // additionally: other numerical instructions and load instructions, linking instructions
    assign c_RegWrite = (
        (opcode_i == `OP_R && funccode_i != `FUNC_jr)   || // R type
        (opcode_i[5:3] == 3'b001)                       || // numerical
        (opcode_i[5:3] == 3'b100)                       || // load
        link
    );


    // cases where pc is written to regfile
    assign c_WBSrc1 = link;
    // as a choice has already been made between PCP4 and ALURESULT
    // c_WBSrc2 only needs to tell whether this instruction has loaded anything from mem
    assign c_WBSrc2 = (opcode_i[5:3] == 3'b100);



    // instructions that use rs:
    // - all instructions except: sra, sll, srl, j, jal, lui
    assign use_data1 = ~(
        shift_shamt ||
        (opcode_i == `OP_j) || (opcode_i == `OP_jal) || (opcode_i == `OP_lui)
    );

    // instructions that use rt:
    // - all starting with 6'b000000, except jr and jalr
    // - beq, bne
    // - store instructions (this is a special case, to be dealt with latter)
    assign use_data2 = (
        (opcode_i == `OP_R && funccode_i != `FUNC_jr && funccode_i != `FUNC_jalr) ||
        (opcode_i == `OP_beq) || (opcode_i == `OP_bne) ||
        (opcode_i[5:3] == 3'b101)
    );

    // cases that use UNsigned immediate number extrapolation:
    // andi, ori, xori (lui does not matter)
    assign c_immExtOp = ~(
        opcode_i == `OP_andi || opcode_i == `OP_ori || opcode_i == `OP_xori
    );

    // ALUOP signal generation
    // - add: add, addi, addiu, addu, memory access (because no need for branching)
    // - sub: sub, subu
    // - slt: slt, slti
    // - sltu: sltu, sltiu
    wire ALU_issub = (
        opcode_i == `OP_R && (
            funccode_i == `FUNC_sub || funccode_i == `FUNC_subu
        ) 
    );

    wire ALU_isslt = (
        opcode_i == `OP_R && (
            funccode_i == `FUNC_slt || funccode_i == `FUNC_sltu
        ) ||
        opcode_i == `OP_slti || opcode_i == `OP_sltiu
    );


    wire ALU_isand = (
        (opcode_i == `OP_andi) || (opcode_i == `OP_R && funccode_i == `FUNC_and)
    );
    wire ALU_isor = (
        (opcode_i == `OP_ori) || (opcode_i == `OP_R && funccode_i == `FUNC_or)
    );
    wire ALU_isnor = (
        opcode_i == `OP_R && funccode_i == `FUNC_nor
    );
    wire ALU_isxor = (
        (opcode_i == `OP_xori) || (opcode_i == `OP_R && funccode_i == `FUNC_xor)
    );

    wire ALU_islogical = (ALU_isand || ALU_isnor || ALU_isxor || ALU_isor);

    wire ALU_issll = (
        (opcode_i == `OP_R && (
            funccode_i == `FUNC_sll || funccode_i == `FUNC_sllv
        )) || 
        (opcode_i == `OP_lui)   // don't forget this
    );

    wire ALU_issrl = (
        opcode_i == `OP_R && (funccode_i == `FUNC_srl || funccode_i == `FUNC_srlv)
    );

    wire ALU_issra = (
        opcode_i == `OP_R && (funccode_i == `FUNC_sra || funccode_i == `FUNC_srav)
    );

    wire ALU_isshift = (opcode_i == `OP_R && funccode_i[5:3] == 3'b000) || (opcode_i == `OP_lui);

    wire ALU_sign = ~(
        (opcode_i == `OP_R && (
            funccode_i == `FUNC_addu || funccode_i == `FUNC_subu || funccode_i == `FUNC_sltu
        )) ||
        (opcode_i == `OP_addiu) || (opcode_i == `OP_sltiu)
    );

    wire [1:0] ALU_subcatop;
    assign ALU_subcatop[1] = (
        ALU_isslt || ALU_isxor || ALU_isnor || ALU_issrl || ALU_issra
    );
    assign ALU_subcatop[0] = (
        ALU_issub || ALU_isnor || ALU_isor || ALU_issra
    );

    assign c_aluop = {
        ALU_isshift, ALU_islogical, ALU_sign, ALU_subcatop
    };
    
endmodule