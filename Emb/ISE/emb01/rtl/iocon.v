/******************************************************************************************************/
/* MieruPC2010                                                                    ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none

/** I/O Controller                                                                                    */
/******************************************************************************************************/
module IOCON(CLK, RST_X, KEY_CLK, KEY_IN, LCD, GPIO, ADDR, DATA_IN, DATA_OUT, WE, MEM_WE, MEM_Q,
             MMC_CSX, MMC_DIN, MMC_DOUT, MMC_SCLK, SW, GPI);
    input         CLK, RST_X, GPI; // clock & reset
    input         KEY_CLK, KEY_IN; // keyboard block and keyboard data
    input [`ADDR] ADDR;
    input [7:0]   DATA_OUT;
    input         WE;  
    input [7:0]   MEM_Q;
    input         MMC_DOUT;
    input [2:0]   SW;
    output        LCD;
    output [7:0]  DATA_IN;
    output        MEM_WE;
    output        MMC_CSX, MMC_DIN, MMC_SCLK;
    inout [15:0]  GPIO;

    wire          kbcon_ack;
    reg           kbcon_busy;
    wire [7:0]    vk_on;
    wire [7:0]    vk_off;
    wire          lcd_rdy, lcd_txd;
    reg  [7:0]    lcd_val;
    reg           lcd_we;
    wire [31:0]   counter;

    reg           ior_we;
    reg [5:0]     ior_ain;
    reg  [31:0]   ior_din;
    wire [31:0]   ior_dout;
    wire [7:0]    ior_q;

    wire [8:0]    cc_ram_addr, cr_addr;
    wire [7:0]    cc_ram_d, cr_din, cr_dout;
    wire          cc_ram_we, cc_we, cc_rdy, cr_we;
    reg           cc_dirty;
    wire [22:0]   cc_block;

    wire targ_kc  = (ADDR >> 1 == 'h400080); // 'h800100 - 'h800101, Keyboard
    wire targ_cnt = (ADDR >> 2 == 'h200043); // 'h80010c - 'h80010f, 1kHz Counter
    wire targ_cc  = (ADDR >> 2 == 'h200042); // 'h800108 - 'h80010b, MMC Control
    wire targ_cr  = (ADDR >> 9 == 'h4001);   // 'h800200 - 'h8003ff, MMC Data
    
    /**************************************************************************************************/  
    gpiocon gpiocon(CLK, RST_X, GPIO, WE, ADDR, DATA_OUT[0]); 
    counter1kHz cnt1kHz(.CLK(CLK), .RST_X(RST_X), .CNT_OUT(counter));

    /* Keyboard controller */
    /**************************************************************************************************/
//  kbcon_mieru kcb(.CLK(CLK), .RST_X(RST_X), .KEY_CLK(KEY_CLK), .KEY_IN(KEY_IN), .ACK(kbcon_ack), 
//                  .VK_ON(vk_on), .VK_OFF(vk_off));

    assign kbcon_ack = (ADDR == 'h800100) && kbcon_busy;

    always @(posedge CLK or negedge RST_X) begin
        if (!RST_X)                      kbcon_busy <= 0;
        else if (ior_ain == 0 && ior_we) kbcon_busy <= (ior_din != 0);
    end
    
    /* LCD controller */
    /**************************************************************************************************/
//  lcdcon lc(.CLK(CLK), .RST_X(RST_X), .VALUE(lcd_val), .WE(lcd_we), .TXD(lcd_txd), .READY(lcd_rdy));
    
    assign LCD  = ~lcd_txd;
    
    always @(posedge CLK or negedge RST_X) begin
        if (!RST_X) begin
            lcd_val <= 0;
            lcd_we  <= 0;
        end else begin
            lcd_val <= DATA_OUT;
            lcd_we  <= WE & (ADDR == 'h800104);
        end
    end

    /* MMC Controller & MMC Sector RAM                                                                */
    /**************************************************************************************************/
    mmccon mmcc(.CLK(CLK), .RST_X(RST_X),
                .MMC_CSX(MMC_CSX), .MMC_DIN(MMC_DIN), .MMC_DOUT(MMC_DOUT), .MMC_SCLK(MMC_SCLK),
                .RAM_ADDR(cc_ram_addr), .RAM_D(cc_ram_d), .RAM_WE(cc_ram_we), .RAM_Q(cr_dout),
                .RAM_DIRTY(cc_dirty), .CORE_WE(cc_we), .CORE_D(DATA_OUT), .CORE_ADDR(ADDR[1:0]),
                .BLOCK(cc_block), .READY(cc_rdy));

    mmcram mmcr (.CLK(CLK), .WE(cr_we), .ADDR(cr_addr), .DIN(cr_din), .DOUT(cr_dout));
    
    assign cc_we     = WE & targ_cc;
    assign cr_we     = (cc_rdy) ? WE & targ_cr : cc_ram_we;
    assign cr_addr   = (cc_rdy) ? ADDR[8:0]    : cc_ram_addr;
    assign cr_din    = (cc_rdy) ? DATA_OUT     : cc_ram_d;
    always @(posedge CLK or negedge RST_X) begin
        if (!RST_X)            cc_dirty <= 0;
        else if (cc_ram_we)    cc_dirty <= 0;
        else if (WE & targ_cr) cc_dirty <= 1;
    end

    /**************************************************************************************************/
    ioram ior(.CLK(CLK), .WE(ior_we), 
              .AIN(ior_ain), .DIN(ior_din), .AOUT(ADDR[7:2]), .DOUT(ior_dout));
    
    reg  [2:0] ior_state;              
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) ior_state <= 0;
        else       ior_state <= (lcd_we) ? 1 :(WE & targ_cc) ? 2 : ior_state + 1;
    end

    always @(ior_state or vk_off or vk_on or targ_kc or lcd_rdy or cc_block or cc_rdy or
             cc_dirty or counter or targ_cnt or GPIO) begin
        ior_we = 1;
        if (ior_state == 0) begin
            ior_ain    = 6'h00;     // 0x800100
            ior_din    = {16'h0000, vk_off, vk_on};
            ior_we     = ~targ_kc; // don't update while reading
        end else if (ior_state == 1) begin
            ior_ain    = 6'h01;     // 0x800104, LCD
            ior_din    =  {31'b0, lcd_rdy};
        end else if (ior_state == 2) begin
            ior_ain    = 6'h02;     // 0x800108, MMC control
            ior_din    =  {cc_block, 7'h00, cc_dirty, cc_rdy};
        end else if (ior_state == 3) begin
            ior_ain    = 6'h03;     // 0x80010c, 1kHz counter
            ior_din    = counter;
            ior_we     = ~targ_cnt;   // don't update while reading
        end else if (ior_state == 4) begin
            ior_ain    = 6'h3c;     // 0x8001f0, GPIO
            ior_din    = {7'b0, GPIO[ 3], 7'b0, GPIO[ 2], 7'b0, GPIO[ 1], 7'b0, GPIO[ 0]};
        end else if (ior_state == 5) begin
            ior_ain    = 6'h3d;     // 0x8001f4, GPIO
            ior_din    = {7'b0, GPIO[ 7], 7'b0, GPIO[ 6], 7'b0, GPIO[ 5], 7'b0, GPIO[ 4]};
        end else if (ior_state == 6) begin
            ior_ain    = 6'h3e;     // 0x8001f8, GPIO
            ior_din    = {7'b0, GPIO[11], 7'b0, GPIO[10], 7'b0, GPIO[ 9], 7'b0, GPIO[ 8]};
        end else if (ior_state == 7) begin
            ior_ain    = 6'h3f;     // 0x8001fc, GPIO
            ior_din    = {7'b0,      GPI, 7'b0,   SW[ 2], 7'b0,   SW[ 1], 7'b0,   SW[ 0]};
        end
    end
 
    reg [1:0] byte_select;
    reg  targr_io, targr_mm;    
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) begin
            targr_io    <= 0;
            targr_mm    <= 0;
            byte_select <= 0;
        end else begin
            targr_io    <= (ADDR >> 8 == 'h8001); // 0x800100 - 0x8001ff
            targr_mm    <= targ_cr;               // 0x800200 - 0x8003ff
            byte_select <= ADDR[1:0];
        end
    end

    assign ior_q = (byte_select==0) ? ior_dout[7:0]   : 
                   (byte_select==1) ? ior_dout[15:8]  : 
                   (byte_select==2) ? ior_dout[23:16] : ior_dout[31:24];

    /**************************************************************************************************/
    assign MEM_WE  = WE && ((ADDR >> 19) == 0); // SRAM Write Enable, higher bits must be zero
    assign DATA_IN = (targr_io) ? ior_q   :     // general memory mapped I/O, 0x800100 - 0x8001ff
                     (targr_mm) ? cr_dout :     // MMC data,                  0x800200 - 0x8003ff
                     MEM_Q;                     // SRAM data                  0x000000 - 0x7fffff
endmodule

/******************************************************************************************************/
module counter1kHz(CLK, RST_X, CNT_OUT);
    input         CLK, RST_X;
    output [31:0] CNT_OUT;
    
    reg [31:0]    CNT_OUT;
    reg [15:0]    cntwait;
    
    always @(posedge CLK or negedge RST_X) begin
        if (!RST_X) begin 
            CNT_OUT <= 0;
            cntwait <= 1;
        end else begin
            if(cntwait >= `TIMER_CNT_WAIT) begin
                CNT_OUT <= CNT_OUT + 1;
                cntwait <= 1;
            end
            else cntwait <= cntwait + 1;
        end
    end
endmodule

/******************************************************************************************************/
module ioram(CLK, WE, AIN, DIN, AOUT, DOUT);
    input          CLK, WE;
    input [5:0]    AIN, AOUT;
    input [31:0]   DIN;
    output [31:0]  DOUT;

    reg [31:0]     DOUT;
    reg [31:0]     mem[0:63]; // 256B

    always @(posedge CLK) begin // synthesis attribute ram_style of mem is block;
        if (WE) mem[AIN] <= DIN;
        DOUT <= mem[AOUT];
    end 
endmodule

/******************************************************************************************************/
module mmcram(CLK, WE, ADDR, DIN, DOUT);
    input         CLK, WE;
    input [8:0]   ADDR;
    input [7:0]   DIN;
    output [7:0]  DOUT;

    reg [7:0]     DOUT;
    reg [7:0]     mem[0:511]; // 512B

    always @(posedge CLK) begin // synthesis attribute ram_style of mem is block;
        if (WE) mem[ADDR] <= DIN;
        DOUT <= mem[ADDR];
    end 
endmodule

/******************************************************************************************************/
