/******************************************************************************************************/
/* MieruPC2010: MipsCore - Coprocessor 0 -            Version 1.3.1 (2010-04-23)  ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none
`define EXCEPTION_ENTRY 'h100

/******************************************************************************************************/
module MIPSCP0(CLK, RST_X, REG_NUM, REG_IN, REG_WE, REG_OUT, 
			EXC_SET, EXC_CLR, EXC_ACK, EXC_CODE, EXC_EPC, EXC_BD, EXC_OCCUR, EXC_NPC);
    input          CLK, RST_X;
    input [4:0]    REG_NUM;
    input [31:0]   REG_IN;
    input [3:0]    EXC_CODE;
    input [`ADDR]  EXC_EPC;
    input          REG_WE, EXC_SET, EXC_CLR, EXC_ACK, EXC_BD;
    output [31:0]  REG_OUT;
    output         EXC_OCCUR;
    output [`ADDR] EXC_NPC;
    
    reg [31:0]  REG_OUT;
    reg         EXC_OCCUR;
    reg [`ADDR] EXC_NPC;

    //internal register
    reg [31:0]  COUNT;   //no.9
    reg [31:0]  COMPARE; //no.11
    reg [31:0]  SR;      //no.12
    reg [31:0]  CAUSE;   //no.13
    reg [`ADDR] EPC;     //no.14

    reg [9:0]   div;
    reg         int_cnt, int_cnt_ack;
    wire        int_set;

    //COUNT incrementer
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) begin
            div     <= 0;
            COUNT   <= 0;
		  int_cnt <= 0;
        end else if (div == `CP0_CNT_WAIT - 1) begin
            div     <= 0;
            COUNT   <= COUNT + 1;
		  int_cnt <= int_cnt || (COUNT + 1 == COMPARE) && ~int_cnt_ack;
	   end else begin
		  div     <= div + 1;
		  int_cnt <= int_cnt & ~int_cnt_ack;
        end
    end

    assign int_set = int_cnt & ~int_cnt_ack & SR[0] & ~SR[1];
    always @(posedge CLK or negedge RST_X) begin
	   if (!RST_X) begin
		  COMPARE     <= 0;
		  SR          <= 0;
		  CAUSE       <= 0;
		  EPC         <= 0;
		  EXC_OCCUR   <= 0;
		  EXC_NPC     <= 0;
		  int_cnt_ack <= 0;
	   end else if (EXC_SET | int_set) begin // set cause register and exception entry point
		  CAUSE[16]   <= int_cnt;
		  CAUSE[6:2]  <= (EXC_SET) ? EXC_CODE : 5'd0;
		  EXC_OCCUR   <= 1;
		  EXC_NPC     <= `EXCEPTION_ENTRY;
		  int_cnt_ack <= ~EXC_SET & int_cnt;
	   end else if (EXC_ACK) begin           // set EXL bit store exception return address
		  SR[1]       <= 1;
		  CAUSE[31]   <= (SR[1]) ? CAUSE[31] : EXC_BD;
		  EPC         <= (SR[1]) ? EPC : EXC_EPC;
		  EXC_OCCUR   <= 0;
		  int_cnt_ack <= 0;
	   end else if (EXC_CLR) begin           // clear EXL bit and set exception return address
		  SR[1]       <= 0;
		  EXC_NPC     <= EPC;
		  int_cnt_ack <= 0;
	   end else if (REG_WE) begin
		  if      (REG_NUM == 11) COMPARE <= REG_IN;
		  else if (REG_NUM == 12) SR      <= REG_IN;
		  else if (REG_NUM == 13) CAUSE   <= REG_IN;
		  else if (REG_NUM == 14) EPC     <= REG_IN[`ADDR];
		  int_cnt_ack <= 0;
	   end else begin
		  int_cnt_ack <= 0;
	   end
    end
			 
    always @(posedge CLK) begin
        REG_OUT <= (REG_NUM == 9 )? COUNT   :
                   (REG_NUM == 11)? COMPARE :
			    (REG_NUM == 12)? SR      :
                   (REG_NUM == 13)? CAUSE   :
                   (REG_NUM == 14)? EPC     : 0;
    end
endmodule