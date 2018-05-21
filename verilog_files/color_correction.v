////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 21/05/18
// Design Name: color_correction algorithm
////////////////////////////////////////////////////////////////////////////////

module color_correction#(
parameter Nline    = 349, //  amount of pixels in line
parameter Nscreen  = 349) //  amount of lines  in frame
(
    input  clk,
    input  rst,
// slave axi stream interface   
    input  s_axis_tvalid,
    input  s_axis_tuser,
    input  s_axis_tlast,
    input  [23 : 0] s_axis_tdata,
// master axi stream interface    
    output m_axis_tvalid,
    output m_axis_tuser,
    output m_axis_tlast,
    output [23 : 0] m_axis_tdata
    );
	
	reg  [11 : 0] line_counter;		// Lines Counter
	wire EOF; 						// End Of Frame 
	reg  [47 : 0] AccumR, AccumG, AccumB; 
	reg  [47 : 0] AccumR_out, AccumG_out, AccumB_out;
	
	wire [7   : 0] quotR, quotG, quotB;
	wire [7   : 0] quotAve;
	reg  [7   : 0] sum_R, sum_G, sum_B;
	reg  [7   : 0] sum_Rpx, sum_Gpx, sum_Bpx;
	reg  [15  : 0] sum_Rppx, sum_Gppx, sum_Bppx;

	
	
	

		function integer multiply;
			input integer a, b;
			multiply = a * b;
		endfunction
		
	localparam Nmult = multiply(Nline, Nscreen);
	
	/*************************************************************/
	/************** average for RGB channels ********************/
		div_uu	#(16) devR   (.clk(clk), .ena(1'b1), .z(16'd255), .d(sum_R), .q(quotR),   .s(), .div0(), .ovf());
		div_uu	#(16) devG   (.clk(clk), .ena(1'b1), .z(16'd255), .d(sum_G), .q(quotG),   .s(), .div0(), .ovf());
		div_uu	#(16) devB   (.clk(clk), .ena(1'b1), .z(16'd255), .d(sum_B), .q(quotB),   .s(), .div0(), .ovf());

	always@(posedge clk) begin
		if(rst)begin
			sum_R  		<= 0;
		    sum_G  		<= 0;
			sum_B  		<= 0;
			
			sum_Rpx		<= 0;
		    sum_Gpx		<= 0;
			sum_Bpx		<= 0;
			
			sum_Rppx	<= 0;
		    sum_Gppx	<= 0;
			sum_Bppx	<= 0;
		end else begin
		// fixed during frame
		    sum_R  		<= R_max - R_min;
		    sum_G  		<= G_max - G_min;
			sum_B  		<= B_max - B_min;
		// change every pixel
			sum_Rpx 	<= s_axis_tdata[23 : 16] - R_min;
		    sum_Gpx 	<= s_axis_tdata[15 :  8] - G_min;
			sum_Bpx 	<= s_axis_tdata[7  :  0] - B_min;
		// change every pixel
			sum_Rppx	<= sum_Rpx * quotR;
		    sum_Gppx	<= sum_Gpx * quotG;
			sum_Bppx	<= sum_Bpx * quotB;
		end // rst	
	end     // always
	
		
	/*********************************************************************************/
	/************************* calculating EOF signal *******************************/
	always@(posedge clk) begin
		if(rst)begin	               
				line_counter <= 0;
		end else if (s_axis_tlast) begin	
			if(line_counter == Nscreen - 1)begin
				line_counter <= 0;
			end else begin
				line_counter <= line_counter + 1;
			end // line_counter
		end     // rst
	end         // always
								
	assign EOF = (s_axis_tlast & line_counter == Nscreen - 1)? 1'b1: 1'b0;
	
	
	/*********************************************************************************/
	/******************* accumulate every RGB channel per frame**********************/
	
	
	reg [7 : 0] R_min, R_max, R_minOut, R_maxOut;
	reg [7 : 0] G_min, G_max, G_minOut, G_maxOut;
	reg [7 : 0] B_min, B_max, B_minOut, B_maxOut;
	
	reg [23: 0] s_axi_data_delay;
	
	
	always@(posedge clk)begin
		if(rst) begin 
					
							   R_min     <= 8'd255;
							   R_max     <= 0;
							   R_minOut  <= 0;
							   R_maxOut  <= 0;
					
							   G_min     <= 8'd255;
							   G_max     <= 0;
							   G_minOut  <= 0;
							   G_maxOut  <= 0;
							
							   B_min     <= 8'd255;
							   B_max     <= 0;
							   B_minOut  <= 0;
							   B_maxOut  <= 0;
					   
		end else if (s_axis_tvalid) begin 
			if(EOF)begin
					
							   R_minOut  <= R_min;
							   R_maxOut  <= R_max;
							
							   G_minOut  <= G_min;
							   G_maxOut  <= G_max;
						
							   B_minOut  <= B_min;
							   B_maxOut  <= B_max;
												
			end else if (s_axis_tuser) begin
			
			
							R_min     <= 8'd255;
							R_max     <= 0;
							R_minOut  <= 0;
							R_maxOut  <= 0;
			
							G_min     <= 8'd255;
							G_max     <= 0;
							G_minOut  <= 0;
							G_maxOut  <= 0;
							
						    B_min     <= 8'd255;
						    B_max     <= 0;
						    B_minOut  <= 0;
						    B_maxOut  <= 0;
			
			end else begin
			
				if(s_axis_tdata[23 : 16] >= R_max) R_max <= s_axis_tdata[23 : 16];
				if(s_axis_tdata[23 : 16] <  R_min) R_min <= s_axis_tdata[23 : 16];
				
				if(s_axis_tdata[23 : 16] >= G_max) G_max <= s_axis_tdata[15 : 8];
				if(s_axis_tdata[23 : 16] <  G_min) G_min <= s_axis_tdata[15 : 8];
				
				if(s_axis_tdata[23 : 16] >= B_max) B_max <= s_axis_tdata[7  : 0];
				if(s_axis_tdata[23 : 16] <  B_min) B_min <= s_axis_tdata[7  : 0];
							
			end
			
			
		end  // rst
	end      // always
	
	reg [10 : 0] s_axis_tvalid_shift; // piplined s_axis_tvalid
	always @(posedge clk) 
	if(rst)s_axis_tvalid_shift <= 0;
	else   s_axis_tvalid_shift <= {s_axis_tvalid_shift[9 : 0], s_axis_tvalid};
	 
	reg [10 : 0] s_axis_tlast_shift; // piplined s_axis_tlast
	always @(posedge clk) 
	if(rst)s_axis_tlast_shift <= 0;
	else   s_axis_tlast_shift <= {s_axis_tlast_shift[9 : 0], s_axis_tlast};
	 
	reg [10 : 0] s_axis_tuser_shift; // piplined s_axis_tuser
	always @(posedge clk) 
	if(rst)s_axis_tuser_shift <= 0;
	else   s_axis_tuser_shift <= {s_axis_tuser_shift[9 : 0], s_axis_tuser};	 
	 
	 // piplined axi stream interface
	assign m_axis_tvalid   = s_axis_tvalid_shift[1];
	assign m_axis_tlast    = s_axis_tlast_shift [1];
	assign m_axis_tuser    = s_axis_tuser_shift [1];
	
	
	assign m_axis_tdata = {sum_Rppx[7 : 0], sum_Gppx[7 : 0], sum_Bppx[7 : 0]};
	
	
			
			
	
	
	
	
	
	
endmodule
