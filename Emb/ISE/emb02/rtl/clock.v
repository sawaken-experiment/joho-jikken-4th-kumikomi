/******************************************************************************************************/
/* MieruPC2010: Clock/Reset Generator                                             ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none

/* Clock & Reset Generator                                                                            */
/******************************************************************************************************/
module CLKGEN(CLK_I, RST_X_I, CLK_O, RST_X_O);
    input CLK_I, RST_X_I;
    output CLK_O, RST_X_O;
    
    wire LOCKED;
    clockgen clkgen(CLK_I, CLK_O, LOCKED);
    resetgen rstgen(CLK_O, (RST_X_I & LOCKED), RST_X_O);
endmodule

/* Clock Generator : 27MHz input clock -> output clock (freq. is specified in define.v)               */
/* Note : this module uses DCM_SP just for Xilinx FPGA                                                */
/******************************************************************************************************/
module clockgen(CLK_IN, CLK_OUT, LOCKED);
    input  CLK_IN;
    output CLK_OUT, LOCKED;
    
    wire   CLK_OBUF, CLK_IBUF, CLK0, CLK0_OUT;

    BUFG   obuf (.I(CLK_OBUF), .O(CLK_OUT));
    BUFG   fbuf (.I(CLK0),     .O(CLK0_OUT));
    IBUFG  ibuf (.I(CLK_IN),   .O(CLK_IBUF));
    
    DCM_SP dcm (.CLKIN(CLK_IBUF), .CLKFX(CLK_OBUF), .CLK0(CLK0), .CLKFB(CLK0_OUT), .LOCKED(LOCKED),
                .RST(0), .DSSEN(0), .PSCLK(0), .PSEN(0), .PSINCDEC(0));
    defparam dcm.CLKFX_DIVIDE   = `DCM_CLKFX_DIVIDE;
    defparam dcm.CLKFX_MULTIPLY = `DCM_CLKFX_MULTIPLY;
    defparam dcm.CLKIN_PERIOD   = 37.037; // 27MHz Clock
endmodule

/* Reset Generator :  generate about 100 cycle reset signal                                           */
/******************************************************************************************************/
module resetgen(CLK, RST_X_I, RST_X_O);
    input  CLK, RST_X_I;
    output RST_X_O;

    reg [7:0] cnt;
    assign RST_X_O = cnt[7];

    always @(posedge CLK or negedge RST_X_I) begin
        if      (!RST_X_I) cnt <= 0;
        else if (~RST_X_O) cnt <= (cnt + 1'b1);
    end
endmodule

/******************************************************************************************************/
