/******************************************************************************************************/
/* MieruPC 2010: General Purpose I/O                                              ArchLab. TOKYO TECH */
/******************************************************************************************************/
`include "../rtl/define.v"
`default_nettype none

/******************************************************************************************************/
module gpiocon(CLK, RST_X, GPIO, WE, ADDR, DATA);
    input CLK, RST_X, WE, DATA;
    inout [15:0]  GPIO;    
    input [`ADDR]  ADDR;
    
    reg targ_gpio;
    reg           gp_din;
    wire [15:0]   gp_we;
    reg  [3:0]    gp_ain;
    
    gpio gp0(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 0]), .DATA(GPIO[ 0]));
    gpio gp1(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 1]), .DATA(GPIO[ 1]));
    gpio gp2(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 2]), .DATA(GPIO[ 2]));
    gpio gp3(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 3]), .DATA(GPIO[ 3]));
    gpio gp4(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 4]), .DATA(GPIO[ 4]));
    gpio gp5(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 5]), .DATA(GPIO[ 5]));
    gpio gp6(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 6]), .DATA(GPIO[ 6]));
    gpio gp7(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 7]), .DATA(GPIO[ 7]));
    gpio gp8(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 8]), .DATA(GPIO[ 8]));
    gpio gp9(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[ 9]), .DATA(GPIO[ 9]));
    gpio gpa(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[10]), .DATA(GPIO[10]));
    gpio gpb(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[11]), .DATA(GPIO[11]));
    gpio gpc(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[12]), .DATA(GPIO[12]));
    gpio gpd(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[13]), .DATA(GPIO[13]));
    gpio gpe(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[14]), .DATA(GPIO[14]));
    gpio gpf(.CLK(CLK), .RST_X(RST_X), .IN(gp_din), .WE(gp_we[15]), .DATA(GPIO[15]));
    
    assign gp_we[ 0] = (targ_gpio && gp_ain ==  0);
    assign gp_we[ 1] = (targ_gpio && gp_ain ==  1);
    assign gp_we[ 2] = (targ_gpio && gp_ain ==  2);
    assign gp_we[ 3] = (targ_gpio && gp_ain ==  3);
    assign gp_we[ 4] = (targ_gpio && gp_ain ==  4);
    assign gp_we[ 5] = (targ_gpio && gp_ain ==  5);
    assign gp_we[ 6] = (targ_gpio && gp_ain ==  6);
    assign gp_we[ 7] = (targ_gpio && gp_ain ==  7);
    assign gp_we[ 8] = (targ_gpio && gp_ain ==  8);
    assign gp_we[ 9] = (targ_gpio && gp_ain ==  9);
    assign gp_we[10] = (targ_gpio && gp_ain == 10);
    assign gp_we[11] = (targ_gpio && gp_ain == 11);
    assign gp_we[12] = (targ_gpio && gp_ain == 12);
    assign gp_we[13] = (targ_gpio && gp_ain == 13);
    assign gp_we[14] = (targ_gpio && gp_ain == 14);
    assign gp_we[15] = (targ_gpio && gp_ain == 15);
    always @(posedge CLK or negedge RST_X) begin
	   if (!RST_X) begin
		  targ_gpio <= 0;
		  gp_din    <= 0;
		  gp_ain    <= 0;
	   end else begin
		  targ_gpio <= (WE && ADDR >> 4 == 'h8001f); // 'h8001f0 - 'h8001ff, write to GPIO
		  gp_din    <= DATA;                  // input data for GPIO
		  gp_ain    <= ADDR[3:0];             // GPIO to be written
	   end
    end
endmodule

/******************************************************************************************************/
module gpio(CLK, RST_X, IN, WE, DATA);
    input  CLK, RST_X, IN, WE;
    inout  DATA;

    reg    mode; // 0 - input, 1 - output
    reg    out;

    always @(posedge CLK or negedge RST_X) begin
        if (!RST_X) begin
		  out <= 0;
		  mode <= 0;
        end else if (WE) begin
		  out <= IN;
		  mode <= 1;
        end
    end

    assign DATA = (mode) ? out : 1'bz;
endmodule

/******************************************************************************************************/

