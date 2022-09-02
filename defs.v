`ifndef GENERAL_DEFS_
`define GENERAL_DEFS_

`define OPT_1
`define OPT_2
`define OPT_3
`define USE_GEN_MEM
`define FREQ_DIVIDE
`define MEM_WR_USE_CASE

`ifdef DEBUG_
`define ra_ 31
`define sp_ 29
`define a0_ 4
`define v0_ 2
`endif
// whether forward the branched address to the InstMem
// `define FWD_branch

// define this macro to enable load-store write-through
// `define WRITE_THROUGH


// ================== ALU protocol ================== 
// the design philosophy:
// higher 2 bits specify the catogary of the operation (i.e. carry logic-based or bit-wise or shift logic with many MUXs)
// the middle bit specifies the sign of computation
// the lower 2 bits specify the sub-catogory operations

// the sign: mainly used for:
// - comparison modes
// - overflow detection

`define ALU_add         5'b00000
`define ALU_addu        5'b00100
`define ALU_sub         5'b00001
`define ALU_subu        5'b00101
`define ALU_slt         5'b00110
`define ALU_sltu        5'b00010

`define ALU_xor         5'b01010
`define ALU_nor         5'b01011
`define ALU_or          5'b01001
`define ALU_and         5'b01000

`define ALU_sll         5'b10000
`define ALU_srl         5'b10010
`define ALU_sra         5'b10011

`define ALUCAT_carry    2'b00
`define ALUCAR_bw       2'b01
`define ALUCAT_sft      2'b10


// ================== branch options ================== 
// branch on:  
//      Equal
//      Unequal
//      Greater than 0
//      Greater than or Equal to 0
//      Less than 0
//      Less than of Equal to 0

// On the design of BO codes:
// maximize the branch predicting speed. As register reading is usually slower than
// signal generation, the branch predicting part should be the NO.1 consideration.
// 
`define BO_none     3'b000
`define BO_beq      3'b010
`define BO_ueq      3'b110
`define BO_ltz      3'b001
`define BO_gez      3'b101
`define BO_lez      3'b111
`define BO_gtz      3'b011

// ================== mem IO options ================== 
`define not_read 2'b10
`define read_word 2'b11
`define read_byte 2'b00
`define read_hfwd 2'b01
`define not_write 2'b10
`define write_word 2'b11
`define write_byte 2'b00
`define write_hfwd 2'b01

// ======================= OpCpdes =========================
`define OP_R        6'h00

`define OP_addi     6'b001000
`define OP_addiu    6'b001001
`define OP_andi     6'b001100
`define OP_lui      6'b001111
`define OP_ori      6'b001101 
`define OP_slti     6'b001010
`define OP_sltiu    6'b001011
`define OP_xori     6'b001110

// memory access
`define OP_lb       6'b100000
`define OP_lbu      6'b100100
`define OP_lh       6'b100001
`define OP_lhu      6'b100101
`define OP_lw       6'b100011
`define OP_sb       6'b101000
`define OP_sh       6'b101001
`define OP_sw       6'b101011

// flow control
`define OP_beq      6'b000100
`define OP_bgez     6'b000001
`define OP_bgtz     6'b000111
`define OP_blez     6'b000110
`define OP_bne      6'b000101

`define OP_j        6'b000010
`define OP_jal      6'b000011
// =========================================================


// ======================= Function codes =========================
`define FUNC_add 6'h20
`define FUNC_addu 6'h21
`define FUNC_and 6'h24
`define FUNC_nor 6'h27
`define FUNC_or 6'h25
`define FUNC_slt 6'h2a
`define FUNC_sltu 6'h2b
`define FUNC_sub 6'h22
`define FUNC_subu 6'h23
`define FUNC_xor 6'h26

`define FUNC_sll 6'h00
`define FUNC_sllv 6'b000100
`define FUNC_sra 6'h03
`define FUNC_srav 6'b000111
`define FUNC_srl 6'h02
`define FUNC_srlv 6'b000110

`define FUNC_jr 6'h08
`define FUNC_jalr 6'h09
// =========================================================


`endif