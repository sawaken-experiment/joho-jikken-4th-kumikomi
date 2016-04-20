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
	reg [6:0] top;
	reg [6:0] direct;
	reg [1:0] mode;
	reg [2:0] color;
	
	always @(posedge cnt[18] or negedge RST_X) begin
		if (!RST_X) begin
			direct <= 1;
			top    <= 0;
			mode   <= 0;
		end else begin
			if (mode == 0) begin
				x      <= top;
				color  <= 3'b111;
				mode   <= 1;
			end else if (mode == 1) begin
				top    <= top + direct;
				x      <= top;
				color  <= 3'b111;
				mode   <= 2;				
			end else if (mode == 2) begin
				top    <= top + direct;
				x      <= top;
				color  <= 3'b111;
				mode   <= 3;
			end else if (mode == 3) begin
				x      <= top - 2*direct;
				color  <= 3'b000;
				mode   <= 2;
				if (top == 0 || top == 127) begin
					top    <= top - 2*direct;
					direct <= direct * (-1);
				end
			end
		end
	end
	
	wire [6:0] y = 33;
							 
	minilcd_con lcdcon(.CLK(FCLK), .RST_X(RST_X),
	                   .VRAM_ADDR({y, x}), .VRAM_DATA({1'b0, color}), .VRAM_WE(1),
							 .LCD_CS0(LCD_CS0), .LCD_CD(LCD_CD),
							 .LCD_RSTB(LCD_RSTB), .LCD_D(LCD_D), .LCD_WR(LCD_WR));
endmodule
	