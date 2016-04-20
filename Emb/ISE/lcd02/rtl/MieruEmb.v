module MieruEMB(CLK, SW, ULED, LCD_CS0, LCD_CD, LCD_WR, LCD_RSTB, LCD_D);
	input        CLK;
	input  [2:0] SW;
	output [3:0] ULED;
	output       LCD_CS0, LCD_CD, LCD_WR, LCD_RSTB;
	output [7:0] LCD_D;
	
	assign ULED = 0;
	wire FCLK, RST_X, LOCKED;
	
	clockgen clkgen(CLK, FCLK, LOCKED);
	resetgen rstgen(FCLK, ((SW[0] | SW[1] | SW[2]) & LOCKED), RST_X);
	
	/**********************************************************************/
	reg [22:0] cnt;
	always @(posedge FCLK or negedge RST_X) begin
		if (!RST_X) cnt <= 0;
		else        cnt <= cnt + 1;
	end
	
	reg [6:0] x;
	always @(posedge cnt[22] or negedge RST_X) begin
		if (!RST_X) begin
			x <= 0;
		end else begin
			x <= x + 1;
		end
	end
	
	wire [2:0] color = 3'b111;
	wire [6:0] y = 33;
	
	minilcd_con lcdcon(.CLK(FCLK), .RST_X(RST_X),
	                   .VRAM_ADDR({y, x}), .VRAM_DATA({1'b0, color}), .VRAM_WE(1),
							 .LCD_CS0(LCD_CS0), .LCD_CD(LCD_CD),
							 .LCD_RSTB(LCD_RSTB), .LCD_D(LCD_D), .LCD_WR(LCD_WR));
endmodule
	