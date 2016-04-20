/******************************************************************************************************/
/* MieruPC2010 Version 1.4.0                                                      ArchLab. TOKYO TECH */
/******************************************************************************************************/

/* Clock Interval Definition                                                                          */
/******************************************************************************************************/
`define DCM_CLKFX_MULTIPLY  7      // you can modify this value, (40MHz / 8) * 7 = 35MHz
`define DCM_CLKFX_DIVIDE    8      // CLKFX_DIVIDE must be 1~32, CLKFX_MULTIPLY must be 2~32

/******************************************************************************************************/
`define SYS_CLOCK 40                                                           // 27MHz system clock
`define TIMER_CNT_WAIT (`SYS_CLOCK/`DCM_CLKFX_DIVIDE*`DCM_CLKFX_MULTIPLY*1000) // for 1kHz timer
`define CP0_CNT_WAIT   (`SYS_CLOCK/`DCM_CLKFX_DIVIDE*`DCM_CLKFX_MULTIPLY*10)   // for 100kHz CP0 timer
`define LCD_WAIT       (`SYS_CLOCK/`DCM_CLKFX_DIVIDE*`DCM_CLKFX_MULTIPLY)      // for LCD 1Mbps

/* Memory Controller / Initializer Constants                                                          */
/******************************************************************************************************/
`define ADDR 23:0                  // Address Range 24bit
`define JADDR 21:0                 // Address Range for J format (ADDR - 2bit, 26bit max.)
`define HALT_ADDR 24'h0000         // Branch Address to Halt

`define MMC_START_BLOCK   81       // MMC Image Start Physical Address: 0x0000a200
`define MMC_LAST_BLOCK  1104       // MMC Image End   Physical Address: 0x00089fff

/* Instruction Processing Stage definition                                                            */
/******************************************************************************************************/
`define CPU_START 5'h00
`define CPU_IF0   5'h01
`define CPU_IF1   5'h02
`define CPU_IF2   5'h03
`define CPU_IF3   5'h04
`define CPU_IF4   5'h05
`define CPU_ID    5'h06
`define CPU_RF    5'h07
`define CPU_EX    5'h08
`define CPU_MA0   5'h09
`define CPU_MA1   5'h0a
`define CPU_MA2   5'h0b
`define CPU_MA3   5'h0c
`define CPU_MA4   5'h0d
`define CPU_WB    5'h0e
`define CPU_WCNT  5'h0f
`define CPU_HALT  5'h10
`define CPU_ERROR 5'h11

/* Instruction Attribute Definition                                                                   */
/******************************************************************************************************/
`define READ_NONE            19'h00000
`define READ_RS              19'h00000
`define READ_RT              19'h00000
`define READ_RD              19'h00000
`define READ_HI              19'h00000
`define READ_LO              19'h00000
`define READ_HILO            19'h00000
`define WRITE_NONE           19'h00000
`define WRITE_RS             19'h00000
`define WRITE_RT             19'h00001
`define WRITE_RD             19'h00002
`define WRITE_HI             19'h00004
`define WRITE_LO             19'h00008
`define WRITE_HILO           19'h0000c
`define WRITE_RD_COND        19'h00010
`define WRITE_RRA            19'h00020
`define LOAD_1B              19'h00040
`define LOAD_2B              19'h00080
`define LOAD_4B_ALIGN        19'h00100
`define LOAD_4B_UNALIGN      19'h00200
`define LOAD_4B              19'h00300
`define LOAD_ANY             19'h003c0
`define STORE_1B             19'h00400
`define STORE_2B             19'h00800
`define STORE_4B_ALIGN       19'h01000
`define STORE_4B_UNALIGN     19'h02000
`define STORE_4B             19'h03000
`define STORE_ANY            19'h03c00
`define LDST                 19'h03fc0
`define LOADSTORE_4B_UNALIGN 19'h02200
`define BRANCH               19'h04000
`define BRANCH_LIKELY        19'h08000
`define READ_CP0             19'h00000
`define WRITE_CP0            19'h10000
`define SYSTEM_CALL          19'h20000
`define BRANCH_ERET          19'h40000

/******************************************************************************************************/
