/******************************************************************************************************/
/* MieruPC 2010: MultiMediaCard Controller                                        ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none
  
/******************************************************************************************************/
`define CMD_SPI 8'b01000000 // SPI mode cmd  0
`define CMDINIT 8'b01000001 // SPI mode cmd  1
`define CMD_CSD 8'b01001001 // SPI mode cmd  9
`define CMD_CID 8'b01001010 // SPI mode cmd 10
`define CMDREAD 8'b01010001 // SPI mode cmd 17
`define CMDWRIT 8'b01011000 // SPI mode cmd 24
`define SPI_CRC 8'b10010101 // CMD_SPI CRC
  
`define RX_FMT_IDLE 0
`define RX_FMT_R1   1
`define RX_FMT_RD   2
`define RX_FMT_R1B  3

`define MMCC_RESET  0
`define MMCC_INIT   1
`define MMCC_READY  2
`define MMCC_CSD    3
`define MMCC_CID    4
`define MMCC_READ   5
`define MMCC_WRITE  6

/******************************************************************************************************/
module mmccon(CLK, RST_X, MMC_CSX, MMC_DIN, MMC_DOUT, MMC_SCLK,
              RAM_ADDR, RAM_D, RAM_WE, RAM_Q, RAM_DIRTY, CORE_WE, CORE_D, CORE_ADDR, BLOCK, READY);
    input         CLK, RST_X;
    /* <-> MMC */
    input         MMC_DOUT;
    output        MMC_CSX, MMC_DIN, MMC_SCLK;

    /* <-> sector RAM */
    output  [8:0] RAM_ADDR;
    output  [7:0] RAM_D;
    output        RAM_WE;
    input   [7:0] RAM_Q;
    input         RAM_DIRTY;

    /* <-> core */
    input         CORE_WE;
    input   [7:0] CORE_D;
    input   [1:0] CORE_ADDR;

    /* <-> memcon */
    output [22:0] BLOCK;
    output        READY;

    reg           MMC_CSX;
    reg     [8:0] RAM_ADDR, next_addr;
    reg           RAM_WE;
    reg    [22:0] BLOCK, newblock;
    reg    [47:0] cmd;
    reg           cmd_we;
    reg     [1:0] format;
    wire    [7:0] rx_data;
    wire          rx_drdy;
    
    reg     [2:0] state;
    reg     [3:0] phase;
    reg    [31:0] cnt;

    wire          init, sclk, sclk_pos, sclk_neg;
    reg           last_sclk;

    mmccon_sclkgen mcscg (CLK, RST_X, init, sclk);
    mmc_sender     ms    (CLK, RST_X, sclk_neg, MMC_DIN, cmd, cmd_we);
    mmc_receiver   mr    (CLK, RST_X, sclk_pos, MMC_DOUT, rx_data, rx_drdy, format);

    assign RAM_D    = rx_data;
    assign READY    = (state == `MMCC_READY && BLOCK == newblock);
    assign init     = (state == `MMCC_RESET || state == `MMCC_INIT);
    assign MMC_SCLK = sclk | READY;
    assign sclk_pos =  sclk & ~last_sclk;
    assign sclk_neg = ~sclk &  last_sclk;
    
    always @(negedge RST_X or posedge CLK)
      if (!RST_X) last_sclk <= 1; else last_sclk <= MMC_SCLK;

    // address register
    always @(negedge RST_X or posedge CLK)
      if (!RST_X) begin
          newblock  <= 0;
      end else if (CORE_WE) begin
              if      (CORE_ADDR == 1) newblock[ 6: 0] <= CORE_D[7:1];
          else if (CORE_ADDR == 2) newblock[14: 7] <= CORE_D;
          else if (CORE_ADDR == 3) newblock[22:15] <= CORE_D;
      end

    // controller
    always @(negedge RST_X or posedge CLK)
      if (!RST_X) begin
          MMC_CSX   <= 0;
          cmd       <= 0;
          cmd_we    <= 0;
          format    <= `RX_FMT_IDLE;
          BLOCK     <= 0;
          RAM_ADDR  <= 0;
          next_addr <= 0;
          RAM_WE    <= 0;
          state     <= `MMCC_RESET;
          phase     <= 0;
          cnt       <= 0;
      end else if (~sclk_neg) begin
          // it works only when negedge of SCLK
      end else if (state == `MMCC_RESET) begin
          if (phase == 0) begin          // wait 100 cycle
              MMC_CSX   <= 1;
              BLOCK     <= 0;
              phase     <= (cnt == 100) ? 1 : phase;
              cnt       <= cnt + 1;
          end else if (phase == 1) begin // send reset command
              MMC_CSX   <= 0;
              cmd       <= {`CMD_SPI, 32'h00000000, `SPI_CRC};
              cmd_we    <= 1;
              format    <= `RX_FMT_R1;
              phase     <= 2;
              cnt       <= 0;
          end else if (phase == 2) begin // no error?
              cmd_we    <= 0;
              if (rx_drdy) begin
                  state     <= (rx_data[7:1] == 0) ? `MMCC_INIT : state;
                  phase     <= 0;
                  cnt       <= 0;
              end else begin
                  phase     <= (cnt == 10000) ? 0 : phase;
                  cnt       <= cnt + 1;
              end
          end
      end else if (state == `MMCC_INIT) begin
          if (phase == 0) begin          // send init command
              cmd       <= {`CMDINIT, 32'h00000000, 8'h01};
              cmd_we    <= 1;
              format    <= `RX_FMT_R1;
              phase     <= 1;
          end else if (phase == 1) begin // wait until init bit is cleared
              cmd_we    <= 0;
              if (rx_drdy) begin
                  state     <= (rx_data == 0) ? `MMCC_READ : state;
                  phase     <= 0;
              end else begin
                  state     <= (cnt == 500000) ? `MMCC_RESET : state;
                  phase     <= (cnt == 500000) ? 0 : phase;
                  cnt       <= cnt + 1;
              end
          end
      end else if (state == `MMCC_READY) begin
          if (BLOCK != newblock) begin
              state     <= (RAM_DIRTY) ? `MMCC_WRITE : `MMCC_READ;
              phase     <= 0;
          end
      end else if (state == `MMCC_READ) begin
          if (phase == 0) begin          // send read command
              cmd       <= {`CMDREAD, newblock, 9'h000, 8'h01};
              cmd_we    <= 1;
              format    <= `RX_FMT_R1;
              BLOCK     <= newblock;
              RAM_ADDR  <= 0;
              next_addr <= 0;
              RAM_WE    <= 0;
              phase     <= 1;
              cnt       <= 0;
          end else if (phase == 1) begin // wait for command response
              cmd_we    <= 0;
              if (rx_drdy) begin
                  if (rx_data == 8'h00) begin
                      format    <= `RX_FMT_RD;
                      phase     <= 2;
                  end else begin
                      phase     <= 0;
                  end
              end
          end else if (phase == 2) begin // wait for data
              if (rx_drdy) begin
                  next_addr <= next_addr + 1;
                  RAM_WE    <= 1;
                  phase     <= (next_addr == 'h1ff) ? 3 : phase;
              end else begin
                  RAM_ADDR  <= next_addr;
                  RAM_WE    <= 0;
              end
          end else if (phase == 3) begin // wait for CRC
              RAM_WE    <= 0;
              if (rx_drdy) begin
                  cnt       <= cnt + 1;
                  if (cnt == 1) begin
                      format    <= `RX_FMT_IDLE;
                      state     <= `MMCC_READY;
                      phase     <= 0;
                  end
              end
          end
      end else if (state == `MMCC_WRITE) begin
          if (phase == 0) begin          // send write command
              cmd       <= {`CMDWRIT, BLOCK, 9'h000, 8'h01};
              cmd_we    <= 1;
              format    <= `RX_FMT_R1;
              RAM_ADDR  <= 0;
              next_addr <= 0;
              RAM_WE    <= 0;
              phase     <= 1;
              cnt       <= 0;
          end else if (phase == 1) begin // wait for command response
              cmd_we    <= 0;
              if (rx_drdy) begin
                  if (rx_data == 8'h00) begin
                      format    <= `RX_FMT_RD;
                      phase     <= 2;
                  end else begin
                      phase     <= 0;
                  end
              end
          end else if (phase == 2) begin // send data token
              cmd       <= 48'hfffffffffffe;
              cmd_we    <= 1;
              format    <= `RX_FMT_R1B;
              phase     <= 3;
              cnt       <= 0;
          end else if (phase == 3) begin // wait
              cmd_we    <= 0;
              RAM_ADDR  <= 0;
              phase     <= (cnt == 46) ? 4 : phase;
              cnt       <= (cnt == 46) ? 0 : cnt + 1;
          end else if (phase == 4) begin // enqueue
              cnt       <= (cnt == 7) ? 0 : cnt + 1;
              if (cnt == 0) begin
                  cmd       <= {RAM_Q, 40'h0000ffffff};
                  cmd_we    <= 1;
              end else if (cnt == 7) begin
                  cmd_we    <= 0;
                  RAM_ADDR  <= RAM_ADDR + 1;
                  phase     <= (RAM_ADDR == 511) ? 5 : phase;
              end else begin
                  cmd_we    <= 0;
              end
          end else if (phase == 5) begin // send CRC(dummy)
              format    <= `RX_FMT_R1B;
              phase     <= (cnt == 15) ? 6 : phase;
              cnt       <= (cnt == 15) ? 0 : cnt + 1;
          end else if (phase == 6) begin // wait for return from busy
              if (rx_drdy) begin
                  phase     <= 0;
                  if (rx_data[7:3] == 5'b00101) begin
                      format    <= `RX_FMT_IDLE;
                      state     <= `MMCC_READ;
                  end
              end
          end else begin // not implemented
              format    <= `RX_FMT_IDLE;
              state     <= `MMCC_READY;
          end
      end
endmodule
                      
/******************************************************************************************************/
module mmccon_sclkgen(CLK, RST_X, INIT, SCLK);
    input     CLK, RST_X, INIT;
    output    SCLK;
    reg [8:0] cnt;

    assign SCLK = ((INIT) ? cnt[8] : cnt[1]);
    always @(posedge CLK or negedge RST_X)
      if (!RST_X) cnt <= 9'h100; else cnt <= cnt + 1;
endmodule
    
/******************************************************************************************************/
module mmc_sender (CLK, RST_X, EN, DIN, CMD, WE);
    input        CLK, RST_X, EN;
    output       DIN; //to MMC
    input [47:0] CMD;
    input        WE;
    
    reg   [47:0] current_cmd;
    assign DIN = current_cmd[47];
    
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) begin
            current_cmd <= ~(48'b0);
        end else if (EN) begin
            if (WE) begin
                current_cmd <= CMD;
            end else begin
                current_cmd <= {current_cmd[46:0], 1'b1};
            end
        end
    end    
endmodule

/******************************************************************************************************/
module mmc_receiver (CLK, RST_X, EN, DOUT, DATA, D_RDY, FORMAT);
    input        CLK, RST_X, EN;
    input        DOUT; // from MMC
    output [7:0] DATA;
    output       D_RDY;
    input  [1:0] FORMAT;

    reg    [7:0] DATA, databuf;
    reg          D_RDY;
    reg          dout_buf;
    reg    [1:0] state;

    reg          rd_wait, r1b_wait;
    reg   [12:0] cnt;

    // data buffer
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) begin
            DATA  <= 0;
            D_RDY <= 0;
            databuf  <= 0;
            dout_buf <= 1'b1;
        end else if (EN) begin
            databuf  <= {databuf[6:0], dout_buf};
            dout_buf <= DOUT;
            if (cnt[2:0] == 3'h7) begin
                if (state != `RX_FMT_R1B) begin
                    DATA  <= databuf;
                    D_RDY <= 1;
                end else begin
                    DATA  <= (!r1b_wait) ? databuf : DATA;
                    D_RDY <= dout_buf;
                end
            end else begin
                D_RDY <= 0;
            end
        end
    end
    
    // state machine
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) begin
            cnt      <= 0;
            state    <= `RX_FMT_IDLE;
            rd_wait  <= 0;
            r1b_wait <= 0;
        end else if (EN) begin
            if(state == `RX_FMT_IDLE && !dout_buf) begin
                cnt      <= 0;
                state    <= FORMAT;
                rd_wait  <= 0;
                r1b_wait <= 0;
            end else if(state == `RX_FMT_R1) begin
                cnt      <= (cnt == 7) ? 0 : cnt + 1;
                state    <= (cnt == 7) ? `RX_FMT_IDLE : state;
            end else if(state == `RX_FMT_R1B) begin
                r1b_wait <= (cnt == 7) ? 1 : 0;
                cnt      <= (cnt == 7 && !dout_buf) ? 7 :
                            (cnt == 7 &&  dout_buf) ? 0 : cnt + 1;
                state    <= (cnt == 7 &&  dout_buf) ? `RX_FMT_IDLE : state;
            end else if(state == `RX_FMT_RD) begin
                rd_wait <= 1;
                if (rd_wait) begin // 4096 bit sector + 16 bit CRC
                    cnt   <= (cnt == 4111) ? 0: cnt + 1;
                    state <= (cnt == 4111) ? `RX_FMT_IDLE : state;
                end
            end else begin
                cnt      <= 0;
                state    <= `RX_FMT_IDLE;
            end
        end
    end    
endmodule

/******************************************************************************************************/