/******************************************************************************************************/
/* MieruPC2010: MipsCore                       Version 1.4.0-test05 (2011-10-05)  ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`include "../rtl/instn.v"
`default_nettype none

/******************************************************************************************************/
/* 32bit-32cycle mutiplier (signed or unsigned)                                                       */
/******************************************************************************************************/
module MULUNIT(CLK, RST_X, INIT, SIGNED, A, B, RSLT, BUSY);
    input         CLK;
    input         RST_X;
    input         INIT;
    input         SIGNED;
    input  [31:0] A, B;
    output [63:0] RSLT;
    output        BUSY;

    wire [31:0]   uint_a, uint_b;
    wire [63:0]   uint_rslt;
    reg           sign;

    MULUNITCORE mulcore(.CLK(CLK), .RST_X(RST_X), .INIT(INIT),
                        .A(uint_a), .B(uint_b), .RSLT(uint_rslt), .BUSY(BUSY));

    assign uint_a = (SIGNED & A[31])? ~A + 1 : A;
    assign uint_b = (SIGNED & B[31])? ~B + 1 : B;
    assign RSLT   = (SIGNED & sign)? ~uint_rslt + 1 : uint_rslt;

    always @( posedge CLK or negedge RST_X )
      if( !RST_X ) sign <= 0;
      else         sign <= (INIT)? A[31]^B[31] : sign;

endmodule

/******************************************************************************************************/
module MULUNITCORE(CLK, RST_X, INIT, A, B, RSLT, BUSY);
    input         CLK;
    input         RST_X;
    input         INIT;
    input  [31:0] A, B;
    output [63:0] RSLT;
    output        BUSY;

    reg [31:0]    multiplicand;
    reg [5:0]     count;
    wire [32:0]   sum;
    reg [63:0]    RSLT;

    assign BUSY   = (count < 32);
    assign sum    = RSLT[63:32] + multiplicand;

    always @( posedge CLK or negedge RST_X ) begin
        if( !RST_X ) begin
            multiplicand   <= 0;
            RSLT           <= 0;
            count          <= 0;
        end else if( INIT )begin
            multiplicand   <= A;
            RSLT           <= {32'h0, B};
            count          <= 0;
        end else begin
            multiplicand   <= multiplicand;
            RSLT           <= (RSLT[0]) ? {sum, RSLT[31:1]} : {1'h0, RSLT[63:1]};
            count          <= count + 1;
        end
    end
endmodule

/******************************************************************************************************/
/* 32bit-32cycle divider (signed or unsigned)                                                         */
/******************************************************************************************************/
module DIVUNIT(CLK, RST_X, INIT, SIGNED, A, B, RSLT, BUSY);
    input         CLK, RST_X, INIT, SIGNED;
    input  [31:0] A, B;
    output [63:0] RSLT;
    output        BUSY;

    wire [31:0]   uint_a, uint_b;
    wire [63:0]   uint_rslt;
    reg           sign_a, sign_b;

    DIVUNITCORE divcore(.CLK(CLK), .RST_X(RST_X), .INIT(INIT), .A(uint_a), .B(uint_b), 
                        .RSLT(uint_rslt), .BUSY(BUSY));

    assign uint_a = (SIGNED & A[31]) ? ~A + 1 : A;
    assign uint_b = (SIGNED & B[31]) ? ~B + 1 : B;
    assign RSLT[63:32] = 
        (~SIGNED)?                     uint_rslt[63:32]           :
        ({sign_a, sign_b} == 2'b00) ?  uint_rslt[63:32]           :
        ({sign_a, sign_b} == 2'b01) ?  uint_rslt[63:32]           :
        ({sign_a, sign_b} == 2'b10) ? ~uint_rslt[63:32] + 1       : ~uint_rslt[63:32] + 1;
    assign RSLT[31: 0] = 
        (~SIGNED)?                     uint_rslt[31: 0]     :
        ({sign_a, sign_b} == 2'b00) ?  uint_rslt[31: 0]     :
        ({sign_a, sign_b} == 2'b01) ? ~uint_rslt[31: 0] + 1 :
        ({sign_a, sign_b} == 2'b10) ? ~uint_rslt[31: 0] + 1 : uint_rslt[31: 0];
        
    always @( posedge CLK or negedge RST_X )
      if(!RST_X) begin
          sign_a  <= 0;
          sign_b  <= 0;
      end else begin
          sign_a  <= (INIT) ? A[31] : sign_a;
          sign_b  <= (INIT) ? B[31] : sign_b;
      end
endmodule

/******************************************************************************************************/
module DIVUNITCORE(CLK, RST_X, INIT, A, B, RSLT, BUSY);
    input         CLK, RST_X, INIT;
    input  [31:0] A, B;
    output [63:0] RSLT;
    output        BUSY;

    reg [63:0]    RSLT;
    reg [31:0]    divisor;
    reg [5:0]     count;
    wire [32:0]   differ;

    assign BUSY   = (count < 32);
    assign differ = RSLT[63:31] - {1'b0, divisor};

    always @( posedge CLK or negedge RST_X ) begin
        if(!RST_X) begin
            divisor   <= 0;
            RSLT      <= 0;
            count     <= 0;
        end else if( INIT ) begin
            divisor   <= B;
            RSLT      <= {32'h0, A};
            count     <= 0;
        end else begin
            divisor   <= divisor;
            RSLT      <= (differ[32]) ? {RSLT[62:0], 1'h0} : {differ[31:0], RSLT[30:0], 1'h1};
            count     <= count + 1;
        end
    end
endmodule

/******************************************************************************************************/
/* 32bitx32 2R/W General Purpose Registers                                                            */
/******************************************************************************************************/
module GPR(CLK, REGNUM0, REGNUM1, DIN0, DIN1, WE0, WE1, DOUT0, DOUT1);
    input         CLK;
    input [4:0]   REGNUM0, REGNUM1;
    input [31:0]  DIN0, DIN1;
    input         WE0, WE1;
    output [31:0] DOUT0, DOUT1;

    reg [31:0]    r[0:31];
    reg [31:0]    DOUT0, DOUT1;
    
    always @(posedge CLK) DOUT0 <= (REGNUM0==0) ? 0 : r[REGNUM0];
    always @(posedge CLK) DOUT1 <= (REGNUM1==0) ? 0 : r[REGNUM1];
    always @(posedge CLK) if(WE0) r[REGNUM0] <= DIN0;
    always @(posedge CLK) if(WE1) r[REGNUM1] <= DIN1; 
endmodule

/******************************************************************************************************/
/* MipsCore: 32bit-MIPS multicycle processor                                                          */
/******************************************************************************************************/
module MIPSCORE(CLK, RST_X, ADDR, DATA_IN, DATA_OUT, WE);
    input              CLK, RST_X;
    input  [7:0]       DATA_IN;
    output [7:0]       DATA_OUT;
    output [`ADDR]     ADDR;
    output             WE;
    /**************************************************************************************************/
    /***** internal register                                                                      *****/
    reg [4:0]          state;
    reg [`ADDR]        pc, delay_npc, inst_pc, inst_npc;
    reg [`ADDR]        inst_eaddr;
    reg                exec_delay;
    reg [31:0]         inst_ir;
    reg [4:0]          inst_rt, inst_rd, inst_dst;
    reg [4:0]          inst_shamt;
    reg [15:0]         inst_imm;
    reg [`JADDR]       inst_addr;
    reg [18:0]         inst_attr;
    reg [6:0]          inst_op;
    reg [31:0]         inst_rrs, inst_rrt, inst_cpr, inst_rslt, inst_rslthi;
    reg [31:0]         hi, lo;           // high and low register for multiply and divide inst.
    reg                inst_cond;
    reg [3:0]          inst_datamask;
    reg [31:0]         inst_loaddata;
    /**************************************************************************************************/
    /***** internal wire                                                                          *****/
    reg  [4:0]         IDRS, IDRT, IDRD;
    reg  [4:0]         IDSHAMT;
    reg  [15:0]        IDIMM;
    reg  [`JADDR]      IDADDR;
    reg  [18:0]        IDATTR;
    reg  [6:0]         IDOP;
    wire [4:0]         RFDST;
    reg  [31:0]        EXRSLT;
    reg  [31:0]        EXRSLTHI;
    reg  [`ADDR]       EXEADDR;
    reg  [`ADDR]       EXNPC;
    reg                EXC;    
    reg  [3:0]         EXMASK;
    reg  [1:0]         EXDATAEXT;
    reg                EXBUSY;
    wire               EXSIGNED;
    wire [31:0]        MALOADDATA, MALOADDATARAW, MALOADMASK;
    wire [63:0]        DURSLT, MURSLT;
    wire               DUBUSY, MUBUSY;
    wire               DIVMULINIT;
    wire [4:0]         GPRNUM0, GPRNUM1, CPRNUM;
    wire [31:0]        GPRREADDT0,  GPRREADDT1,  CPRREADDT;
    wire [31:0]        GPRWRITEDT0, GPRWRITEDT1, CPRWRITEDT;
    wire               GPRWE0, GPRWE1, CPRWE;
    wire               CPEXCSET, CPEXCCLR, CPEXCACK, CPEXCOCCUR, CPEXCBD;
    wire [3:0]         CPEXCCODE;
    wire [`ADDR]       CPEXCEPC, CPEXCNPC;
    wire [31:0]        SET32I; // 32bit sign extended of 16bit immediate
    wire [`ADDR]       SETADI; // sign extended address of 16bit immediate
    wire [31:0]        RRT_U, RRS_U;
    wire signed [31:0] RRT_S;
    wire               CPUEXE = 1; // signal to stall the processor!
    
    /**************************************************************************************************/
    /* Sub module declaration                                                                         */
    /**************************************************************************************************/
    DIVUNIT du(.CLK(CLK), .RST_X(RST_X), .INIT(DIVMULINIT), .SIGNED(EXSIGNED),
               .A(GPRREADDT0), .B(GPRREADDT1), .RSLT(DURSLT), .BUSY(DUBUSY));

    MULUNIT mu(.CLK(CLK), .RST_X(RST_X), .INIT(DIVMULINIT), .SIGNED(EXSIGNED),
               .A(GPRREADDT0), .B(GPRREADDT1), .RSLT(MURSLT), .BUSY(MUBUSY));

    GPR gpr(.CLK(CLK), .REGNUM0(GPRNUM0), .REGNUM1(GPRNUM1), .DIN0(GPRWRITEDT0), .DIN1(GPRWRITEDT1),
            .WE0(GPRWE0), .WE1(GPRWE1), .DOUT0(GPRREADDT0), .DOUT1(GPRREADDT1));

    MIPSCP0 cp0(.CLK(CLK), .RST_X(RST_X), .REG_NUM(CPRNUM), .REG_IN(CPRWRITEDT), .REG_WE(CPRWE),
                .REG_OUT(CPRREADDT), .EXC_SET(CPEXCSET), .EXC_CLR(CPEXCCLR), .EXC_ACK(CPEXCACK),
                .EXC_CODE(CPEXCCODE), .EXC_EPC(CPEXCEPC), .EXC_BD(CPEXCBD),
                .EXC_OCCUR(CPEXCOCCUR), .EXC_NPC(CPEXCNPC));

    /**************************************************************************************************/
    /* Mips::proceedstate()                                                                           */
    /**************************************************************************************************/
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X)                                   state <= `CPU_START;
        else if(~CPUEXE || state==`CPU_HALT)         state <= state;        
        else if(exec_delay && delay_npc==`HALT_ADDR) state <= `CPU_HALT;
        else if(state==`CPU_EX &&  EXBUSY)           state <= state;
        else if(state==`CPU_EX && ~EXBUSY)           state <= (inst_attr & `LDST) ? `CPU_MA0 : `CPU_WB;
        else if(state==`CPU_WB)                      state <= `CPU_IF0;
        else                                         state <= state + 1;
    end

    /**************************************************************************************************/
    /* Mips:: instruction fetch stage and memory access address generation                            */
    /**************************************************************************************************/
    // inst_eaddr is incremented on MA0, MA1, and MA2 stage
    assign ADDR = (state == `CPU_IF0)                      ? (pc & ~'h3)        :
                  (state == `CPU_IF1)                      ? (pc & ~'h3) | 2'h1 :
                  (state == `CPU_IF2)                      ? (pc & ~'h3) | 2'h2 :
                  (state == `CPU_IF3)                      ? (pc & ~'h3) | 2'h3 :
                  (state >= `CPU_MA0 && state <= `CPU_MA3) ? inst_eaddr : 0;
                  
    always @( posedge CLK or negedge RST_X ) begin
        if(!RST_X) inst_pc <= 0;
        else if(CPUEXE) begin
            if     (state==`CPU_IF0)  inst_pc         <= pc;
            if     (state==`CPU_IF1)  inst_ir[ 7: 0]  <= DATA_IN;
            else if(state==`CPU_IF2)  inst_ir[15: 8]  <= DATA_IN;
            else if(state==`CPU_IF3)  inst_ir[23:16]  <= DATA_IN;
            else if(state==`CPU_IF4)  inst_ir[31:24]  <= DATA_IN;
        end
    end

    /**************************************************************************************************/
    /* Mips:: instruction decode stage                                                                */
    /**************************************************************************************************/
    always@ (inst_ir) begin
        IDRS    = inst_ir[25:21];
        IDRT    = inst_ir[20:16];
        IDRD    = inst_ir[15:11];
        IDSHAMT = inst_ir[10:6];
        IDIMM   = inst_ir[15:0];
        IDADDR  = inst_ir[25:0];
        IDOP    = `NOP______;
        IDATTR  = `WRITE_NONE;
        
        case (inst_ir[31:26]) // OP
          6'd00: case (inst_ir[5:0]) // FUNCT 
                   6'd0: begin
                       if      ((IDRT | IDRD |        IDSHAMT) == 0) begin IDOP=`NOP______;        end
                       else if ((IDRT | IDRD) == 0 && IDSHAMT  == 1) begin IDOP=`NOP______;        end
                       else begin IDOP=`SLL______; IDATTR=`WRITE_RD;                               end
                   end
                   6'd2: begin IDOP=`SRL______; IDATTR=`WRITE_RD;                                  end
                   6'd3: begin IDOP=`SRA______; IDATTR=`WRITE_RD;                                  end
                   6'd4: begin IDOP=`SLLV_____; IDATTR=`WRITE_RD;                                  end
                   6'd6: begin IDOP=`SRLV_____; IDATTR=`WRITE_RD;                                  end
                   6'd7: begin IDOP=`SRAV_____; IDATTR=`WRITE_RD;                                  end
                   6'd8: begin
                       if      (IDSHAMT==0    ) begin IDOP=`JR_______; IDATTR=`BRANCH;             end 
                       else if (IDSHAMT==5'd16) begin IDOP=`JR_HB____; IDATTR=`BRANCH;             end 
                   end
                   6'd9: begin
                       if      (IDSHAMT==0    ) begin IDOP=`JALR_____; IDATTR=`BRANCH | `WRITE_RD; end
                       else if (IDSHAMT==5'd16) begin IDOP=`JALR_HB__; IDATTR=`BRANCH | `WRITE_RD; end
                   end
                   6'd10: begin IDOP=`MOVZ_____; IDATTR=`WRITE_RD_COND;                            end
                   6'd11: begin IDOP=`MOVN_____; IDATTR=`WRITE_RD_COND;                            end
                   6'd12: begin IDOP=`SYSCALL__; IDATTR=`SYSTEM_CALL;                              end 
                   6'd16: begin IDOP=`MFHI_____; IDATTR=`WRITE_RD;                                 end
                   6'd17: begin IDOP=`MTHI_____; IDATTR=`WRITE_HI;                                 end
                   6'd18: begin IDOP=`MFLO_____; IDATTR=`WRITE_RD;                                 end
                   6'd19: begin IDOP=`MTLO_____; IDATTR=`WRITE_LO;                                 end
                   6'd24: begin IDOP=`MULT_____; IDATTR=`WRITE_HILO;                               end
                   6'd25: begin IDOP=`MULTU____; IDATTR=`WRITE_HILO;                               end
                   6'd26: begin IDOP=`DIV______; IDATTR=`WRITE_HILO;                               end
                   6'd27: begin IDOP=`DIVU_____; IDATTR=`WRITE_HILO;                               end
                   6'd32: begin IDOP=`ADD______; IDATTR=`WRITE_RD;                                 end
                   6'd33: begin IDOP=`ADDU_____; IDATTR=`WRITE_RD;                                 end
                   6'd34: begin IDOP=`SUB______; IDATTR=`WRITE_RD;                                 end
                   6'd35: begin IDOP=`SUBU_____; IDATTR=`WRITE_RD;                                 end
                   6'd36: begin IDOP=`AND______; IDATTR=`WRITE_RD;                                 end
                   6'd37: begin IDOP=`OR_______; IDATTR=`WRITE_RD;                                 end
                   6'd38: begin IDOP=`XOR______; IDATTR=`WRITE_RD;                                 end
                   6'd39: begin IDOP=`NOR______; IDATTR=`WRITE_RD;                                 end
                   6'd42: begin IDOP=`SLT______; IDATTR=`WRITE_RD;                                 end
                   6'd43: begin IDOP=`SLTU_____; IDATTR=`WRITE_RD;                                 end
                 endcase
          6'd01: case ( IDRT )
                   6'd00: begin IDOP=`BLTZ_____; IDATTR=`BRANCH;                                   end
                   6'd01: begin IDOP=`BGEZ_____; IDATTR=`BRANCH;                                   end
                   6'd02: begin IDOP=`BLTZL____; IDATTR=`BRANCH_LIKELY;                            end
                   6'd03: begin IDOP=`BGEZL____; IDATTR=`BRANCH_LIKELY;                            end
                   6'd16: begin IDOP=`BLTZAL___; IDATTR=`BRANCH        | `WRITE_RRA;               end
                   6'd17: begin IDOP=`BGEZAL___; IDATTR=`BRANCH        | `WRITE_RRA;               end
                   6'd18: begin IDOP=`BLTZALL__; IDATTR=`BRANCH_LIKELY | `WRITE_RRA;               end
                   6'd19: begin IDOP=`BGEZALL__; IDATTR=`BRANCH_LIKELY | `WRITE_RRA;               end
                endcase
          6'd02: begin IDOP=`J________; IDATTR=`BRANCH;                                       end
          6'd03: begin IDOP=`JAL______; IDATTR=`BRANCH | `WRITE_RRA;                          end
          6'd04: begin IDOP=`BEQ______; IDATTR=`BRANCH;                                       end
          6'd05: begin IDOP=`BNE______; IDATTR=`BRANCH;                                       end
          6'd06: begin IDOP=`BLEZ_____; IDATTR=`BRANCH;                                       end
          6'd07: begin IDOP=`BGTZ_____; IDATTR=`BRANCH;                                       end
          6'd08: begin IDOP=`ADDI_____; IDATTR=`WRITE_RT;                                     end
          6'd09: begin IDOP=`ADDIU____; IDATTR=`WRITE_RT;                                     end
          6'd10: begin IDOP=`SLTI_____; IDATTR=`WRITE_RT;                                     end
          6'd11: begin IDOP=`SLTIU____; IDATTR=`WRITE_RT;                                     end
          6'd12: begin IDOP=`ANDI_____; IDATTR=`WRITE_RT;                                     end
          6'd13: begin IDOP=`ORI______; IDATTR=`WRITE_RT;                                     end
          6'd14: begin IDOP=`XORI_____; IDATTR=`WRITE_RT;                                     end
          6'd15: begin IDOP=`LUI______; IDATTR=`WRITE_RT;                                     end
          6'd16:
            if      (IDRS == 6'd00) begin IDOP=`MFC0_____; IDATTR=`WRITE_RT;                  end
            else if (IDRS == 6'd04) begin IDOP=`MTC0_____; IDATTR=`WRITE_CP0;                 end
            else if (IDRS == 6'd16 && inst_ir[5:0] == 6'd24) 
                 begin IDOP=`ERET_____; IDATTR=`BRANCH_ERET;                                  end
          6'd20: begin IDOP=`BEQL_____; IDATTR=`BRANCH_LIKELY;                                end
          6'd21: begin IDOP=`BNEL_____; IDATTR=`BRANCH_LIKELY;                                end
          6'd22: begin IDOP=`BLEZL____; IDATTR=`BRANCH_LIKELY;                                end
          6'd23: begin IDOP=`BGTZL____; IDATTR=`BRANCH_LIKELY;                                end
          6'd28: begin IDOP=`MUL______; IDATTR=`WRITE_RD;                                     end
          6'd32: begin IDOP=`LB_______; IDATTR=`WRITE_RT | `LOAD_1B;                          end
          6'd33: begin IDOP=`LH_______; IDATTR=`WRITE_RT | `LOAD_2B;                          end
          6'd34: begin IDOP=`LWL______; IDATTR=`WRITE_RT | `LOAD_4B_UNALIGN;                  end
          6'd35: begin IDOP=`LW_______; IDATTR=`WRITE_RT | `LOAD_4B_ALIGN;                    end
          6'd36: begin IDOP=`LBU______; IDATTR=`WRITE_RT | `LOAD_1B;                          end
          6'd37: begin IDOP=`LHU______; IDATTR=`WRITE_RT | `LOAD_2B;                          end
          6'd38: begin IDOP=`LWR______; IDATTR=`WRITE_RT | `LOAD_4B_UNALIGN;                  end
          6'd40: begin IDOP=`SB_______; IDATTR=`STORE_1B;                                     end
          6'd41: begin IDOP=`SH_______; IDATTR=`STORE_2B;                                     end
          6'd42: begin IDOP=`SWL______; IDATTR=`STORE_4B_UNALIGN;                             end
          6'd43: begin IDOP=`SW_______; IDATTR=`STORE_4B_ALIGN;                               end
          6'd46: begin IDOP=`SWR______; IDATTR=`STORE_4B_UNALIGN;                             end
        endcase
    end

    always @( posedge CLK or negedge RST_X ) begin
        if(!RST_X) {inst_rt, inst_rd, inst_shamt, inst_imm, inst_addr, inst_attr, inst_op} <= 0;
        else if(CPUEXE && state==`CPU_ID) begin
            inst_rt    <= IDRT;
            inst_rd    <= IDRD;
            inst_shamt <= IDSHAMT;
            inst_imm   <= IDIMM;
            inst_addr  <= IDADDR;
            inst_attr  <= IDATTR;
            inst_op    <= IDOP;
        end
    end
    
    /**************************************************************************************************/
    /* Mips:: register file access                                                                    */
    /**************************************************************************************************/
    assign GPRNUM0 = (state==`CPU_ID) ? IDRS : inst_dst; // use IDRS if reg_read else write to inst_dst
    assign GPRNUM1 = (state==`CPU_ID) ? IDRT : 'd7;      // use IDRT if reg_read else SYSCALL $7<=0
    assign CPRNUM  = IDRD;    
    assign RFDST   = ((inst_attr & `WRITE_RD ) || (inst_attr & `WRITE_RD_COND)) ? inst_rd :
                      (inst_attr & `WRITE_RT ) ? inst_rt :
                      (inst_attr & `WRITE_RRA) ? 'd31 : (inst_attr & `SYSTEM_CALL) ? 'd2 : 'd0;

    always @( posedge CLK or negedge RST_X ) begin
        if(!RST_X) {inst_rrs, inst_rrt, inst_cpr, inst_dst} <= 0;
        else if(CPUEXE && state==`CPU_RF) begin
            inst_rrs   <= GPRREADDT0;
            inst_rrt   <= GPRREADDT1;
            inst_cpr   <= CPRREADDT;
            inst_dst   <= RFDST;
        end
    end
    
    assign DIVMULINIT = (CPUEXE && state==`CPU_RF); // start signal for div & mul
    
    /**************************************************************************************************/
    /* Mips:: execute                                                                                 */
    /**************************************************************************************************/
    function [3:0] MASKUA; // MASK_UN_ALIGN
        input [24:0] eaddr;
        input        left;
        MASKUA = (left)? 4'b1111 << (3 - eaddr[1:0]) : 4'b1111 >> eaddr[1:0];
    endfunction

    assign SET32I = (inst_imm[15]) ? {16'hffff, inst_imm} : {16'h0000, inst_imm};
    assign SETADI = SET32I[`ADDR];
    assign RRT_S = inst_rrt;
    assign RRS_U = inst_rrs;
    assign RRT_U = inst_rrt;
    assign EXSIGNED = (inst_op == `MULT_____ || inst_op == `DIV______);
    
    always @(DUBUSY or DURSLT or MUBUSY or MURSLT or inst_shamt or inst_imm or inst_addr or
             inst_op or inst_pc or inst_rrs or inst_rrt or SET32I or SETADI or
             RRT_S or RRS_U or RRT_U or hi or lo or inst_cpr) begin
        EXRSLT     = 0;
        EXRSLTHI   = 0;
        EXNPC      = 0;
        EXC        = 0;
        EXEADDR    = 0;
        EXMASK     = 0;
        EXDATAEXT  = 0;
        EXBUSY     = 0;
        case ( inst_op )
          `SYSCALL__ : begin EXRSLT   = 1;                                                           end
          `ERET_____ : begin EXRSLT   = 1;                                                           end
          `NOP______ : begin EXRSLT   = 1;                                                           end
          `SLL______ : begin EXRSLT   = RRT_U <<  inst_shamt;                                        end
          `SRL______ : begin EXRSLT   = RRT_U >>  inst_shamt;                                        end
          `SRA______ : begin EXRSLT   = RRT_S >>> inst_shamt;                                        end
          `SLLV_____ : begin EXRSLT   = RRT_U <<  RRS_U[4:0];                                        end
          `SRLV_____ : begin EXRSLT   = RRT_U >>  RRS_U[4:0];                                        end
          `SRAV_____ : begin EXRSLT   = RRT_S >>> RRS_U[4:0];                                        end
          `JR_______ : begin EXNPC    = RRS_U;                      EXC = 1;                         end
          `JR_HB____ : begin EXNPC    = RRS_U;                      EXC = 1;                         end
          `JALR_____ : begin EXRSLT   = inst_pc + 8; EXNPC = RRS_U; EXC = 1;                         end
          `JALR_HB__ : begin EXRSLT   = inst_pc + 8; EXNPC = RRS_U; EXC = 1;                         end
          `MOVZ_____ : begin EXRSLT   = RRS_U;                      EXC  = (RRT_U == 0);             end
          `MOVN_____ : begin EXRSLT   = RRS_U;                      EXC  = (RRT_U != 0);             end
          `MFHI_____ : begin EXRSLT   = hi;                                                          end
          `MTHI_____ : begin EXRSLTHI = RRS_U;                                                       end
          `MFLO_____ : begin EXRSLT   = lo;                                                          end
          `MTLO_____ : begin EXRSLT   = RRS_U;                                                       end
          `MULT_____ : begin {EXRSLTHI, EXRSLT} = MURSLT;               EXBUSY = MUBUSY;             end
          `MULTU____ : begin {EXRSLTHI, EXRSLT} = MURSLT;               EXBUSY = MUBUSY;             end
          `MUL______ : begin {EXRSLTHI, EXRSLT} = MURSLT;               EXBUSY = MUBUSY;             end
          `DIV______ : begin {EXRSLTHI, EXRSLT} = (RRT_U) ? DURSLT : 0; EXBUSY = DUBUSY;             end
          `DIVU_____ : begin {EXRSLTHI, EXRSLT} = (RRT_U) ? DURSLT : 0; EXBUSY = DUBUSY;             end
          `ADD______ : begin EXRSLT   = RRS_U + RRT_U;                                               end
          `ADDU_____ : begin EXRSLT   = RRS_U + RRT_U;                                               end
          `SUB______ : begin EXRSLT   = RRS_U - RRT_U;                                               end
          `SUBU_____ : begin EXRSLT   = RRS_U - RRT_U;                                               end
          `AND______ : begin EXRSLT   = RRS_U & RRT_U;                                               end
          `OR_______ : begin EXRSLT   = RRS_U | RRT_U;                                               end
          `XOR______ : begin EXRSLT   = RRS_U ^ RRT_U;                                               end
          `NOR______ : begin EXRSLT   = ~(RRS_U | RRT_U);                                            end
          `SLT______ : begin EXRSLT   = (RRS_U[31] ^ RRT_U[31]) ? RRS_U[31] :
                                        (RRS_U < RRT_U)         ? 1 : 0;                             end
          `SLTU_____ : begin EXRSLT   = (RRS_U < RRT_U) ? 32'h1 : 32'h0;                             end
          `BLTZ_____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC =  RRS_U[31];               end
          `BGEZ_____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC = ~RRS_U[31];               end
          `BLTZL____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC =  RRS_U[31];               end
          `BGEZL____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC = ~RRS_U[31];               end
          `BLTZAL___ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC =  RRS_U[31];
                             EXRSLT   = inst_pc + 8;                                                 end
          `BGEZAL___ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC = ~RRS_U[31];
                             EXRSLT   = inst_pc + 8;                                                 end
          `BLTZALL__ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC =  RRS_U[31];
                             EXRSLT   = inst_pc + 8;                                                 end
          `BGEZALL__ : begin EXNPC    = inst_pc + (SETADI << 2) + 4; EXC = ~RRS_U[31];
                             EXRSLT   = inst_pc + 8;                                                 end
          `J________ : begin EXNPC    = (inst_pc & 32'hf0000000) | (inst_addr << 2); EXC = 1;        end
          `JAL______ : begin EXNPC    = (inst_pc & 32'hf0000000) | (inst_addr << 2); EXC = 1;
                             EXRSLT   = inst_pc + 8;                                                 end
          `BEQ______ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = (RRS_U == RRT_U);                                            end
          `BEQL_____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = (RRS_U == RRT_U);                                            end
          `BNE______ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = (RRS_U != RRT_U);                                            end
          `BNEL_____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = (RRS_U != RRT_U);                                            end
          `BLEZ_____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = ( RRS_U[31] || (RRS_U == 0)) ? 1 : 0;                        end
          `BLEZL____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = ( RRS_U[31] || (RRS_U == 0)) ? 1 : 0;                        end
          `BGTZ_____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = (~RRS_U[31] && (RRS_U != 0)) ? 1 : 0;                        end
          `BGTZL____ : begin EXNPC    = inst_pc + (SETADI << 2) + 4;
                             EXC      = (~RRS_U[31] && (RRS_U != 0)) ? 1 : 0;                        end
          `ADDI_____ : begin EXRSLT   = RRS_U + SET32I;                                              end
          `ADDIU____ : begin EXRSLT   = RRS_U + SET32I;                                              end
          `SLTI_____ : begin EXRSLT   = (RRS_U[31] ^ inst_imm[15]) ? RRS_U[31] :
                                        (RRS_U < SET32I)           ? 1 : 0;                          end
          `SLTIU____ : begin EXRSLT   = (RRS_U < SET32I)           ? 1 : 0;                          end
          `ANDI_____ : begin EXRSLT   = RRS_U & {16'h0, inst_imm};                                   end
          `ORI______ : begin EXRSLT   = RRS_U | {16'h0, inst_imm};                                   end
          `XORI_____ : begin EXRSLT   = RRS_U ^ {16'h0, inst_imm};                                   end
          `LUI______ : begin EXRSLT   = {inst_imm, 16'h0};                                           end
          `MFC0_____ : begin EXRSLT   = inst_cpr;                                                    end
          `MTC0_____ : begin EXRSLT   = RRT_U;                                                       end
          `LW_______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b1111;
                             EXRSLT   = 0;                                                           end
          `LB_______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b0001;
                             EXRSLT   = 0;                  EXDATAEXT = 2'b11;                       end
          `LBU______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b0001;
                             EXRSLT   = 0;                                                           end
          `LH_______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b0011;
                             EXRSLT   = 0;                  EXDATAEXT = 2'b10;                       end
          `LHU______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b0011;
                             EXRSLT   = 0;                                                           end
          `LWL______ : begin EXEADDR  = RRS_U + SETADI - 3; EXMASK = MASKUA(RRS_U + SETADI,1);
                             EXRSLT   = RRT_U;                                                       end
          `LWR______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = MASKUA(RRS_U + SETADI,0);
                             EXRSLT   = RRT_U;                                                       end
          `SWR______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = MASKUA(RRS_U + SETADI,0);
                             EXRSLT   = RRT_U;                                                       end
          `SWL______ : begin EXEADDR  = RRS_U + SETADI - 3; EXMASK = MASKUA(RRS_U + SETADI,1);
                             EXRSLT   = RRT_U;                                                       end
          `SB_______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b0001;
                             EXRSLT   = RRT_U;                                                       end
          `SH_______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b0011;
                             EXRSLT   = RRT_U;                                                       end
          `SW_______ : begin EXEADDR  = RRS_U + SETADI;     EXMASK = 4'b1111;
                             EXRSLT   = RRT_U;                                                       end
          default    : begin end
        endcase
    end

    always @( posedge CLK or negedge RST_X ) begin
        if (!RST_X) 
            {inst_rslt, inst_rslthi, inst_eaddr, inst_cond, inst_npc, inst_datamask} <= 0;
        else if (CPUEXE && state==`CPU_EX ) begin
            inst_rslt     <= EXRSLT;
            inst_rslthi   <= EXRSLTHI;
            inst_eaddr    <= EXEADDR;
            inst_cond     <= EXC;
            inst_npc      <= EXNPC;
            inst_datamask <= EXMASK;
        end else if (CPUEXE && state >= `CPU_MA0 && state <= `CPU_MA2) begin
            inst_eaddr    <= inst_eaddr + 1;
        end
    end

    /**************************************************************************************************/
    /* Mips:: memory access                                                                           */
    /**************************************************************************************************/
    ///// memory store
    assign DATA_OUT = (state == `CPU_MA0) ? inst_rslt[ 7: 0] :
                      (state == `CPU_MA1) ? inst_rslt[15: 8] :
                      (state == `CPU_MA2) ? inst_rslt[23:16] :
                      (state == `CPU_MA3) ? inst_rslt[31:24] : 0;

    assign WE       = (CPUEXE && (inst_attr & `STORE_ANY) &&
                       ((state == `CPU_MA0 && inst_datamask[0]) ||
                        (state == `CPU_MA1 && inst_datamask[1]) ||
                        (state == `CPU_MA2 && inst_datamask[2]) ||
                        (state == `CPU_MA3 && inst_datamask[3])));

    always @( posedge CLK or negedge RST_X ) begin  ///// memory load
        if (!RST_X) inst_loaddata <= 0;
        else if (CPUEXE)
          if      (state == `CPU_MA1) inst_loaddata[ 7: 0] <= DATA_IN;
          else if (state == `CPU_MA2) inst_loaddata[15: 8] <= DATA_IN;
          else if (state == `CPU_MA3) inst_loaddata[23:16] <= DATA_IN;
          else if (state == `CPU_MA4) inst_loaddata[31:24] <= DATA_IN;
    end

    /**************************************************************************************************/
    /* Mips:: write back                                                                              */
    /**************************************************************************************************/
    assign MALOADDATARAW = inst_loaddata[31:0];
    assign MALOADMASK = {{8{inst_datamask[3]}}, {8{inst_datamask[2]}},
                         {8{inst_datamask[1]}}, {8{inst_datamask[0]}}};
    assign MALOADDATA = (EXDATAEXT[0]) ? {{24{MALOADDATARAW[ 7]}}, MALOADDATARAW[ 7:0]} :
                        (EXDATAEXT[1]) ? {{16{MALOADDATARAW[15]}}, MALOADDATARAW[15:0]} :
                        (MALOADDATARAW & MALOADMASK) | (inst_rslt & ~MALOADMASK);   

    assign GPRWE0 = ((CPUEXE && state==`CPU_WB && ~CPEXCOCCUR) &&
                     ~((inst_attr & `WRITE_RD_COND) && inst_cond==0));
    assign GPRWE1 = ((CPUEXE && state==`CPU_WB && ~CPEXCOCCUR) &&   (inst_attr & `SYSTEM_CALL));
    assign CPRWE  = ((CPUEXE && state==`CPU_WB && ~CPEXCOCCUR) &&   (inst_attr & `WRITE_CP0));
    assign GPRWRITEDT0 = (inst_attr & `LDST) ? MALOADDATA : inst_rslt;
    assign GPRWRITEDT1 = 32'h0;  // 2nd write port is just for SYSCALL (REG_A3 <= 0)
    assign CPRWRITEDT  = inst_rslt;

    
    always @( posedge CLK or negedge RST_X ) begin
        if(!RST_X) {hi, lo} <= 0;
        else if(CPUEXE && state==`CPU_WB && ~CPEXCOCCUR) begin
             if(inst_attr & `WRITE_HI) hi <= inst_rslthi;
             if(inst_attr & `WRITE_LO) lo <= inst_rslt;
        end
    end

    /**************************************************************************************************/
    /* Mips:: setnpc()                                                                                */
    /**************************************************************************************************/
    assign CPEXCSET  = (CPUEXE && state==`CPU_EX && (inst_attr & `SYSTEM_CALL));
    assign CPEXCCLR  = (CPUEXE && state==`CPU_EX && (inst_attr & `BRANCH_ERET));
    assign CPEXCACK  = (CPUEXE && state==`CPU_WB && CPEXCOCCUR);
    assign CPEXCCODE = 4'd8; // EXC_SYSCALL
    assign CPEXCEPC  = (exec_delay) ? pc - 4 : pc;
    assign CPEXCBD   = exec_delay;
    
    always @( posedge CLK or negedge RST_X ) begin
        if(!RST_X) {pc, delay_npc, exec_delay} <= 0;
        else if(CPUEXE && state == `CPU_WB) begin
            if (CPEXCOCCUR) begin
                pc          <= CPEXCNPC;
                exec_delay  <= 0;
            end else if( exec_delay ) begin
                pc          <= delay_npc;
                delay_npc   <= 0;
                exec_delay  <= 0;
            end else if( ((inst_attr & `BRANCH) || (inst_attr & `BRANCH_LIKELY)) && inst_cond ) begin
                pc          <= pc + 4;
                delay_npc   <= inst_npc;
                exec_delay  <= 1;
            end else if  (inst_attr & `BRANCH_ERET) begin
                pc          <= CPEXCNPC;
            end else if( (inst_attr & `BRANCH_LIKELY) && !inst_cond ) begin
                pc          <= pc + 8;
            end else begin
                pc          <= pc + 4;
            end
        end
    end
endmodule

/******************************************************************************************************/
