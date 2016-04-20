/******************************************************************************************************/
/* MieruPC2010: Program Loader                                                    ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none

/* Program Loader: Initialize the main memory, copy memory image to SRAM                              */
/******************************************************************************************************/
module PROGLOADER (CLK, RST_X, ADDR, DATA_OUT, WE, DATA_IN, DONE);
    input          CLK, RST_X;
    input  [7:0]   DATA_IN;
    output [`ADDR] ADDR;
    output [7:0]   DATA_OUT;
    output         WE, DONE;

    reg [`ADDR]    ADDR, writeaddr;
    reg [7:0]      DATA_OUT;
    reg            WE, DONE;

    reg [3:0]      phase;
    reg [10:0]     block;
    reg [26:0]     timeout;
    reg [1:0]      cnt;
    
    always @(posedge CLK or negedge RST_X) begin
        if (!RST_X) begin 
            timeout <= 0;
            DONE    <= 0;
        end else if (!DONE) begin
            timeout <= timeout + 1;
            DONE    <= (phase == 8 || timeout == 100000000);
        end
    end
    
    always @(posedge CLK or negedge RST_X) begin
        if(!RST_X) begin
            ADDR      <= 0;
            writeaddr <= 0;
            DATA_OUT  <= 0;
            WE        <= 0;
            phase     <= 0;
            block     <= `MMC_START_BLOCK;
            cnt       <= 0;
        end else if (!DONE) begin
            if (phase == 0) begin // write block address
                ADDR      <= 'h800109;
                DATA_OUT  <= {block[6:0], 1'b0};
                WE        <= 1;
                phase     <= 1;
            end else if (phase == 1) begin
                ADDR      <= 'h80010a;
                DATA_OUT  <= {4'h0, block[10: 7]};
                WE        <= 1;
                phase     <= 2;
            end else if (phase == 2) begin
                ADDR      <= 'h80010b;
                DATA_OUT  <= 0;
                WE        <= 1;
                phase     <= 3;
            end else if (phase == 3) begin // wait for ready signal
                ADDR      <= 'h800108;
                WE        <= 0;
                phase     <= (cnt == 3) ? 4 : phase;
                cnt       <= cnt + 1;
            end else if (phase == 4) begin
                phase     <= (DATA_IN == 8'h01) ? 5 : phase;
            end else if (phase == 5) begin // copy to main memory
                ADDR      <= 'h800200 + writeaddr[8:0];
                WE        <= 0;
                phase     <= (cnt == 1) ? 6 : phase;
                cnt       <= (cnt == 1) ? 0 : 1;
            end else if (phase == 6) begin
                ADDR      <= writeaddr;
                writeaddr <= writeaddr + 1;
                DATA_OUT  <= DATA_IN;
                WE        <= 1;
                phase     <= (writeaddr[8:0] == 9'h1ff) ? 7 : 5;
            end else if (phase == 7) begin // increment block
                WE        <= 0;
                block     <= block + 1;
                phase     <= (block == `MMC_LAST_BLOCK) ? 8 : 0;
            end
        end
    end
endmodule

/******************************************************************************************************/
