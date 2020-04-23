//************************************************************************
//*
//* led_controller.sv
//* 
//* Author: James Zhang
//* Date: 4/22/2020
//* Version 0.0
//*
//* Description: Module to control the 6x6 LED array of the DueProLogic USB-FPGA Development System
//* Inputs:
//*  - clk
//*  - rst_l
//*  - en 				Turn the
//*  - led_data_ld 		Loading the 6x6 LED data array.
//*  - led_data			Input 6x6 LED data array]
//*
//* Outputs
//*  - out_to_led		Signals out to the LED pins to turn the LEDs on or off.
//*
//*
//************************************************************************

module led_controller
	(input logic clk, rst_l,
	 input logic en,
	 input logic led_data_ld,
	 input logic[35:0] led_data,

	 output logic[35:0] out_to_led);

	logic [35:0] flipped_data;
	always_comb begin
		for(int i=0; i <= 35; i++)
    		flipped_data[i] = led_data[35-i];
	end

	always_ff @(posedge clk or negedge rst_l) begin
		if(~rst_l) begin
			out_to_led <= ~36'b0;
		end 

		else begin
			if (en) begin
				if (led_data_ld) begin
					out_to_led <= ~(flipped_data); // Flip order and bitwise negate to get correct orientiation and voltage levels
				end
			end

			else begin
				out_to_led <= ~36'b0;
			end
		end
	end

endmodule : led_controller
