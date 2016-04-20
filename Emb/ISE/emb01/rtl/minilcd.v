/******************************************************************************************************/
/* MieruEMB System Version 1.0 since 2011-09                                      ArchLab. TOKYO TECH */
/******************************************************************************************************/
`default_nettype none

/******************************************************************************************************/
/***** MiniLCD controller,  128x128 pixel LCD                                                     *****/
/******************************************************************************************************/
module minilcd_con(CLK, RST_X, VRAM_ADDR, VRAM_DATA, VRAM_WE, 
                   LCD_CS0, LCD_CD, LCD_RSTB, LCD_D, LCD_WR);
    input            CLK, RST_X;
    input [13:0]     VRAM_ADDR;
    input [7:0]      VRAM_DATA;
    input            VRAM_WE;
    output           LCD_WR;    
    output reg       LCD_CS0, LCD_CD, LCD_RSTB;
    output reg [7:0] LCD_D;
    
    reg          init;
    reg [14:0]   cmdcnt;
    reg [2:0]    writecnt;
    reg [23:0]   waitcnt;
    wire [15:0]  dout;
    wire [7:0]   D;
    
    assign LCD_WR = ~writecnt[2];
   
    minilcd_initmem mlcdmem(CLK, cmdcnt[5:0], dout);

    minilcd_vram vram(.CLK(CLK), .DIN(VRAM_DATA[3:0]), .WADDR(VRAM_ADDR), .WE(VRAM_WE), 
                      .DOUT(D), .RADDR(cmdcnt[14:1]));
        
    always @(posedge CLK or negedge RST_X) begin
      if (!RST_X) begin
        LCD_CS0  <= 0;
        LCD_CD   <= 0;
        LCD_RSTB <= 0;
        LCD_D    <= 0;
        init     <= 1;
        cmdcnt   <= 0;
        writecnt <= 0;
        waitcnt  <= 0;
      end 
      else if (writecnt != 0) writecnt <= writecnt - 1;
      else if (waitcnt  != 0) waitcnt  <= waitcnt  - 1;
      else if (init == 1) begin
        waitcnt  <= {dout[15:11], 18'h00000};
        LCD_RSTB <= ~dout[10];
        LCD_CS0  <= dout[9];
        LCD_CD   <= dout[8];
        LCD_D    <= dout[7:0];
        init     <= (cmdcnt != 'h3a);
        cmdcnt   <= (cmdcnt == 'h3a) ? 0 : cmdcnt + 1;
        writecnt <= 7;
      end 
      else begin // after initialized
        LCD_RSTB <= 1;
        LCD_CS0  <= 0;
        LCD_CD   <= 1;
        LCD_D    <= (cmdcnt[0]) ? // convert 3 bit to 16 bit color
                     {D[1], D[0], D[0], D[0], D[0], D[0], D[0], D[0]} :
                     {D[2], D[2], D[2], D[2], D[1], D[1], D[1], D[1]} ;
        cmdcnt   <= (cmdcnt == 'h7fff) ? 0 : cmdcnt + 1;
        writecnt <= 7;
      end
    end
endmodule

/******************************************************************************************************/
/* MiniLCD Video Memory 8KB (128x128=16K pixel, 4bit per pixel = 8KB)                                 */
/******************************************************************************************************/
module minilcd_vram(CLK, DIN, DOUT, RADDR, WADDR, WE);
    input        CLK, WE;
    input [3:0]  DIN;
    input [13:0] RADDR, WADDR;
    output reg [3:0] DOUT;
    
    reg [3:0] mem [16383:0]; /* 4bit x 16K pixel = 8KB VRAM */

    always @(posedge CLK) begin
        if (WE) mem[WADDR] <= DIN;
        DOUT <= mem[RADDR];
    end
endmodule

/******************************************************************************************************/
/* MiniLCD initialize memory, [WAIT(5)] [RST] [CSX] [DC] [DATA(8)]                                    */
/******************************************************************************************************/
module minilcd_initmem(CLK, ADDR, DATA);
    input             CLK;
    input       [5:0] ADDR;
    output reg [15:0] DATA;

    always @(posedge CLK) begin
        case (ADDR)
        'h00: DATA = 16'h1200;
        'h01: DATA = 16'h1600; // Hardware Reset
        'h02: DATA = 16'h6200;
        'h03: DATA = 16'h2801; // Software Reset
        'h04: DATA = 16'ha011; // Sleep Out
        'h05: DATA = 16'h00ff; // VCOM 4 Level Control
        'h06: DATA = 16'h0140; //   - TC2 4clk, TC3 3clk delay
        'h07: DATA = 16'h0103;
        'h08: DATA = 16'h011a;
        'h09: DATA = 16'h00b1; // Frame Rate Control (Normal)
        'h0a: DATA = 16'h0104; //   - RTN         24
        'h0b: DATA = 16'h0125; //   - Front Porch 37
        'h0c: DATA = 16'h0118; //   - Back Porch  24
        'h0d: DATA = 16'h00b4; // Display Inversion Control
        'h0e: DATA = 16'h0103; //   - Line Inversion
        'h0f: DATA = 16'h00b6; // Display Function set 5
        'h10: DATA = 16'h0105; //   (Output waveform configure)
        'h11: DATA = 16'h0102;
        'h12: DATA = 16'h00c1; // Power Control 2
        'h13: DATA = 16'h0107; //   - VGHH 14.7V, VGLL -12.25V
        'h14: DATA = 16'h00fc; // Power Control 6
        'h15: DATA = 16'h0111;
        'h16: DATA = 16'h0117;
        'h17: DATA = 16'h00c5; // VCOM Control 1
        'h18: DATA = 16'h013c; //   - VCOMH +4V
        'h19: DATA = 16'h014f; //   - VCOML -0.525V
        'h1a: DATA = 16'h0036; // Memory Data Access Control
        'h1b: DATA = 16'h01c8; //   - XY mirror, BGR order
        'h1c: DATA = 16'h003a; // Interface Pixel Format
        'h1d: DATA = 16'h0105; //   - 16-bit per pixel
        'h1e: DATA = 16'h00e1; // Gamma Correction Negative
        'h1f: DATA = 16'h0101; //   - VRH
        'h20: DATA = 16'h011c; //   - VRL
        'h21: DATA = 16'h0105; //   - PK0(V3)
        'h22: DATA = 16'h0111; //   - PK1(V6)
        'h23: DATA = 16'h0117; //   - PK2(V11)
        'h24: DATA = 16'h011a; //   - PK3(V19)
        'h25: DATA = 16'h011C; //   - PK4(V27)
        'h26: DATA = 16'h0121; //   - PK5(V36)
        'h27: DATA = 16'h011F; //   - PK6(V44)
        'h28: DATA = 16'h011D; //   - PK7(V52)
        'h29: DATA = 16'h0127; //   - PK8(V57)
        'h2a: DATA = 16'h012F; //   - PK9(V60)
        'h2b: DATA = 16'h0105; //   - SELV0
        'h2c: DATA = 16'h0103; //   - SELV1
        'h2d: DATA = 16'h0100; //   - SELV62
        'h2e: DATA = 16'h013F; //   - SELV63
        'h2f: DATA = 16'h002a; // Column Address Set
        'h30: DATA = 16'h0100; //   - start   2
        'h31: DATA = 16'h0102;
        'h32: DATA = 16'h0100; //   - end   129
        'h33: DATA = 16'h0181;
        'h34: DATA = 16'h002b; // Row Address Set
        'h35: DATA = 16'h0100; //   - start   3
        'h36: DATA = 16'h0103;
        'h37: DATA = 16'h0100; //   - end   130
        'h38: DATA = 16'h0182;
        'h39: DATA = 16'h5029; // Display On
        'h3a: DATA = 16'h002c; // Memory Write
        'h3b: DATA = 16'h0000;
        'h3c: DATA = 16'h0000;
        'h3d: DATA = 16'h0000;
        'h3e: DATA = 16'h0000;
        'h3f: DATA = 16'h0000;
        endcase
    end     
endmodule     
/******************************************************************************************************/
