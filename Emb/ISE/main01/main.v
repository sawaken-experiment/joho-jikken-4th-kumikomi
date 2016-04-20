`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:08:03 10/22/2013 
// Design Name: 
// Module Name:    main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module main(CLK, SW, ULED
    );
	input CLK;
	input  [2:0] SW;
	output [3:0] ULED;
	
	reg [25:0] cnt;
	
	always @(posedge CLK) begin
		cnt <= cnt + 1;
	end
	/*
	wire sw0 = ~SW[0];
	wire sw1 = ~SW[1];
	wire sw2 = ~SW[2];
	
	assign ULED[0] = sw0 & sw1;
	assign ULED[1] = sw0 | sw1 | sw2;
	assign ULED[2] = 0;
	assign ULED[3] = 1;
	*/
	assign ULED[0] = cnt[22];
	assign ULED[1] = cnt[23];
	assign ULED[2] = cnt[24];
	assign ULED[3] = cnt[25];
endmodule
