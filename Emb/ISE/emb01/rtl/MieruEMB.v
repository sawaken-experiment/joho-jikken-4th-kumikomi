/******************************************************************************************************/
/* MieruEMB System Version 1.1 since 2011-09 (Version 2012-09-19)                 ArchLab. TOKYO TECH */
/*  See the README file on the parent directory for license information.                              */
/******************************************************************************************************/
/******************************************************************************************************/
/* MieruPC2010 Version 1.4.0, 2011-10-05: Top Level Module                        ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none

/******************************************************************************************************/
module MieruEMB(CLK, SW, LCD, ULED, GPIO, GPI, MMC_CS_X, MMC_DIN, MMC_SCLK, MMC_DOUT, 
               SRAM_A, SRAM_D, SRAM_OE_X, SRAM_WE_X,
               LCD_CS0, LCD_CD, LCD_WR, LCD_RSTB, LCD_D);               
    input             CLK, GPI;     // input clock & general purpose input 
    input [2:0]       SW;           // input switch
    input             MMC_DOUT;     // MMC Data Output
    output            LCD;          // LCD Serial Output
    output            MMC_CS_X;     // MMC Chip Select
    output            MMC_DIN;      // MMC Data Input
    output            MMC_SCLK;     // MMC Clock
    output [2:0]      ULED;         // User LED
    output reg [18:0] SRAM_A;       // SRAM Address
    output reg        SRAM_OE_X;    // SRAM Output Enable
    output            SRAM_WE_X;    // SRAM Write Enable
    inout [1:0]       GPIO;         // General Purpose I/O
    inout [7:0]       SRAM_D;       // SRAM Data Bus

    output            LCD_CS0, LCD_CD, LCD_WR, LCD_RSTB;
    output [7:0]      LCD_D;
    
    wire              FCLK, RST_OX;                  // system clock and reset signal
    wire              WE, CORE_WE, MEM_WE, PLOAD_WE; // Write Enable signals
    wire              PLOAD_DONE;                    // Program load is done
    wire [`ADDR]      ADDR, PLOAD_ADDR, CORE_ADDR;   // memory address
    wire [7:0]        DATA_IN, DATA_OUT, CORE_DATA, PLOAD_DATA; // data

    reg [26:0]        rst_c; // counter for reset signal
    always @(posedge FCLK) rst_c <= (SW[0] | SW[1] | SW[2]) ? 0 : (!rst_c[26]) ? rst_c+1 : rst_c;
    
    CLKGEN clkgen(.CLK_I(CLK), .RST_X_I(!rst_c[26]), .CLK_O(FCLK), .RST_X_O(RST_OX));
    
    MIPSCORE core(.CLK(FCLK), .RST_X(RST_OX & PLOAD_DONE), 
                  .ADDR(CORE_ADDR), .DATA_IN(DATA_IN), .DATA_OUT(CORE_DATA), .WE(CORE_WE));

    PROGLOADER pload(.CLK(FCLK), .RST_X(RST_OX), 
                     .DATA_IN(DATA_IN), 
                     .ADDR(PLOAD_ADDR), .DATA_OUT(PLOAD_DATA), .WE(PLOAD_WE), .DONE(PLOAD_DONE));
                   
    IOCON iocon(.CLK(FCLK), .RST_X(RST_OX), 
                .LCD(LCD), .GPIO(GPIO), .SW(SW), .GPI(GPI),
                .ADDR(ADDR), .DATA_IN(DATA_IN), .DATA_OUT(DATA_OUT), 
                .WE(WE), .MEM_WE(MEM_WE), .MEM_Q(SRAM_D),
                .MMC_CSX(MMC_CS_X), .MMC_DIN(MMC_DIN), .MMC_DOUT(MMC_DOUT), .MMC_SCLK(MMC_SCLK));

    reg lcd_reg;
    always @(posedge FCLK) lcd_reg <= ~LCD;
    
    assign ULED[0]  = (!PLOAD_DONE) ? 1          : lcd_reg;
    assign ADDR     = (!PLOAD_DONE) ? PLOAD_ADDR : CORE_ADDR;
    assign DATA_OUT = (!PLOAD_DONE) ? PLOAD_DATA : CORE_DATA;
    assign WE       = (!PLOAD_DONE) ? PLOAD_WE   : CORE_WE;
    
    reg [7:0] D_KEEP;
    always @(posedge FCLK or negedge RST_OX) begin
         if (!RST_OX) begin
             SRAM_A    <= 0;
             D_KEEP    <= 0;
             SRAM_OE_X <= 0;
         end else begin
             SRAM_A    <= ADDR[18:0];
             D_KEEP    <= DATA_OUT; 
             SRAM_OE_X <= MEM_WE;
         end
    end

    assign SRAM_D = (SRAM_OE_X) ? D_KEEP : 8'hzz;
    assign SRAM_WE_X = ~FCLK | ~SRAM_OE_X;

    reg [24:0] cnt_t;
    always @(posedge FCLK) cnt_t <= cnt_t + 1;
    assign ULED[2] = cnt_t[24];
    assign ULED[1] = (~SW[0]) | (~SW[1]) | (~SW[2]);
    
    minilcd_con lcdcon (FCLK, (RST_OX & PLOAD_DONE), CORE_ADDR[13:0], CORE_DATA, 
                        (CORE_WE & CORE_ADDR[23:16]==8'h90),
                        LCD_CS0, LCD_CD, LCD_RSTB, LCD_D, LCD_WR);    
endmodule

/******************************************************************************************************/
