`timescale 1ns/1ps

`include "defs.v"

// Since comparison is done during the ID stage,
// there is no need for the ALU to ouput the "zero" signal

module alu_wo_comp (
    input wire [31:0] op1,
    input wire [31:0] op2,
    input wire [4:0]  aluop,
    input wire [2:0]  branchOp,

    output reg [31:0] result,
    output reg        branch
);
    wire [1:0] catogary  = aluop[4:3];
    wire       op_sign   = aluop[2];
    wire [1:0] operation = aluop[1:0];

    wire [4:0] sft = op1[4:0];

    // parsing ALU options
    always @(*) begin
        if (catogary[0]) case (operation)
            2'b10: result <= op1 ^ op2;
            2'b11: result <= ~(op1 | op2);
            2'b01: result <= op1 | op2;
            2'b00: result <= op1 & op2;
        endcase

        else if (catogary[1]) begin
            if (operation[0])       result <= $signed(op2) >> sft;
            else if (operation[1])  result <= op2 >> sft;
            else                    result <= op2 << sft;
        end

        else begin
            // substraction
            if (operation[0])                       result <= op1 - op2;

            else if (operation[1]) begin
                // slt
                if (op_sign) begin
                    if (op1[31] && ~op2[31])        result <= 32'd1;
                    else if (~op1[31] && op2[31])   result <= 32'd0;
                    else                            result <= {31'b0, op1[30:0] < op2[30:0]};
                end
                // sltu
                else                                result <= {31'b0, op1 < op2};
            end

            // addition
            else                                    result <= op1 + op2;
        end
            
    end


    // 5 types of branches in total:
    // branch on:  
    //      Equal
    //      Unequal
    //      Greater than 0
    //      Greater of Equal to 0
    //      Less than 0
    // And in some case, links
    wire equal          = (op1     == op2);
    wire is_zero        = (op1     == 32'b0);
    wire is_negative    = (op1[31] == 1'b1);

    always @(*) begin
        case (branchOp) 
            `BO_beq:    branch <= equal;
            `BO_gez:    branch <= ~is_negative;
            `BO_gtz:    branch <= ~(is_zero || is_negative);
            `BO_ltz:    branch <= is_negative;
            `BO_ueq:    branch <= ~equal;
            `BO_lez:    branch <= is_zero || is_negative;
            `BO_none:   branch <= 1'b0;
            default:    branch <= 1'b0;
        endcase
    end
    
endmodule