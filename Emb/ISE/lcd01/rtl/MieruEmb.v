/*************************************************************************************************/
/* LCD Test Module for MieruEMB System Version 1.0 since 2011-09             ArchLab. TOKYO TECH */
/*************************************************************************************************/
`default_nettype none

/* Clock Interval Definition                                                                     */
/*************************************************************************************************/
`define DCM_CLKFX_MULTIPLY 15      // 40MHz * 15 / 20 = 30MHz
`define DCM_CLKFX_DIVIDE   20      // CLKFX_DIVIDE must be 1~32, CLKFX_MULTIPLY must be 2~32

/*************************************************************************************************/
/* MieruEmb Top Module                                                                           */
/*************************************************************************************************/
module MieruEMB(CLK, SW, ULED, LCD_CS0, LCD_CD, LCD_WR, LCD_RSTB, LCD_D);
    input         CLK;
    input [2:0]   SW;
    output [3:0]  ULED;
    output        LCD_CS0, LCD_CD, LCD_WR, LCD_RSTB;
    output [7:0]  LCD_D;
    
    assign ULED = 0;
    wire FCLK, RST_X, LOCKED;

    clockgen clkgen(CLK, FCLK, LOCKED);
    resetgen rstgen(FCLK, ((SW[0] | SW[1] | SW[2]) & LOCKED), RST_X);
    
    reg [14:0] cnt;
    always @(posedge FCLK or negedge RST_X) begin
        if (!RST_X) cnt <= 0;
        else        cnt <= cnt + 1;
    end 
    
    reg [13:0] adr;
    always @(posedge cnt[14] or negedge RST_X) begin
        if (!RST_X) adr <= 0;
        else        adr <= adr + 1;
    end 
    
    wire [2:0] color = adr[12:10];
    minilcd_con lcdcon(.CLK(FCLK), .RST_X(RST_X),
                       .VRAM_ADDR(adr), .VRAM_DATA({1'b0, color}), .VRAM_WE(1),
                       .LCD_CS0(LCD_CS0), .LCD_CD(LCD_CD), 
                       .LCD_RSTB(LCD_RSTB), .LCD_D(LCD_D), .LCD_WR(LCD_WR));
endmodule

/*************************************************************************************************/
/* Clock Generator : 40MHz input clock -> output clock (freq. is specified in define.v)          */
/*************************************************************************************************/
module clockgen(CLK_IN, CLK_OUT, LOCKED);
    input  CLK_IN;
    output CLK_OUT, LOCKED;

    wire   CLK_OBUF, CLK_IBUF, CLK0, CLK0_OUT, GND;
    assign GND = 0;

    BUFG   obuf (.I(CLK_OBUF), .O(CLK_OUT));
    BUFG   fbuf (.I(CLK0),     .O(CLK0_OUT));
    IBUFG  ibuf (.I(CLK_IN),   .O(CLK_IBUF));

    DCM dcm(.CLKIN(CLK_IBUF), .CLKFX(CLK_OBUF), .CLK0(CLK0), .CLKFB(CLK0_OUT), .LOCKED(LOCKED),
            .RST(GND), .DSSEN(GND), .PSCLK(GND), .PSEN(GND), .PSINCDEC(GND));
    defparam dcm.CLKFX_DIVIDE   = `DCM_CLKFX_DIVIDE;
    defparam dcm.CLKFX_MULTIPLY = `DCM_CLKFX_MULTIPLY;
endmodule

/*************************************************************************************************/
/* Reset Generator :  generate reset signal                                                      */
/*************************************************************************************************/
module resetgen(CLK, RST_X_I, RST_X_O);
    input  CLK, RST_X_I;
    output RST_X_O;

    reg [7:0] cnt;
    assign RST_X_O = cnt[7];

    always @(posedge CLK or negedge RST_X_I) begin
        if      (!RST_X_I) cnt <= 0;
        else if (~RST_X_O) cnt <= cnt + 1;
    end
endmodule
/*************************************************************************************************/
