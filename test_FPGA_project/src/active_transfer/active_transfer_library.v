//#######################################################################
//#
//#	Copyright 	Earth People Technology Inc. 2012
//#
//#
//# File Name:  active_transfer_library.v
//# Author:     R. Jolly
//# Date:       January 4, 2012
//# Revision:   B
//#
//# Development: USB Test Tool Interface board 
//# Application: Altera MAX II CPLD
//# Description: This file contains verilog code which will allow access
//#              to an eight bit bus in the FPGA. The FPGA receives its commands via
//#				 USB.
//#               
//#              
//#
//#************************************************************************
//#
//# Revision History:	
//#			DATE		VERSION		DETAILS		
//#			01/04/12 	A			Created			RJJ
//#			10/15/12 	B			Changed name to active_transfer_library			RJJ
//#
//#									
//#
//#######################################################################
`include "../src/define.v"

`timescale 1ns/1ps


//************************************************************************
//* Module Declaration
//************************************************************************

module active_transfer_library (

	
	input  wire [`EPT_AA_END:`EPT_AA_START]         aa,
	input  wire [`EPT_BCIN_END:`EPT_BCIN_START]     bc_in,
	output wire [`EPT_BCOUT_END:`EPT_BCOUT_START]   bc_out,
    inout  wire [`EPT_DATAIN_END:`EPT_DATAIN_START] bd_inout,
	
	output  wire [`UC_IN_END:`UC_IN_START]  UC_IN,
	input wire [`UC_OUT_END:`UC_OUT_START]  UC_OUT
	);

//***************************************************************************
//* Internal Signals and Registers Declarations
//***************************************************************************
	
	//Signals passed between leaf modules
	wire	[`EPT_DATAIN_END:`EPT_DATAIN_START] register_decode;
	wire						data_byte_ready;
	wire						ept_int_enable;
	wire						ept_int_write_enable;
	wire						ft_245_state_mne_write_ready;
	wire	[`EPT_DATAIN_END:`EPT_DATAIN_START] ept_int_write_byte;
	wire						write_complete;
	wire	[`EPT_DATAIN_END:`EPT_DATAIN_START] ft_usb_data_out;
	wire	[`EPT_DATAIN_END:`EPT_DATAIN_START] ft_usb_data_in;
	
//***************************************************************************
//* 	Signal Assignments	
//***************************************************************************
	assign			bd_inout = ft_245_state_mne_write_ready ? ft_usb_data_out : 8'hzz;

   //-----------------------------------------------
   // Instantiate FT_245 State Machine
   //-----------------------------------------------

	ft_245_state_machine		FT_245_STATE_MACHINE_INST
	(	
	.CLK					(aa[1]),
	.RST_N					(aa[0]),

	
	.USB_RXF_N				(bc_in[1]),
	.USB_TXE_N				(bc_in[0]),
	.USB_RD_N				(bc_out[2]),
	.USB_WR					(bc_out[1]),
	.USB_TEST				(bc_out[0]),
	
	.USB_REGISTER_DECODE	(register_decode),
	.USB_DATA_IN			(bd_inout),
	.USB_DATA_OUT			(ft_usb_data_out),
	
	.DATA_BYTE_READY		(data_byte_ready),
	.RSB_INT_EN				(ept_int_enable),
	
	.WRITE_EN				(ept_int_write_enable),
	.WRITE_READY			(ft_245_state_mne_write_ready),
	.WRITE_BYTE				(ept_int_write_byte),
	.WRITE_COMPLETE         (write_complete)
		
	);
	
	endpoint_registers		ENDPOINT_REGISTERS_INST
	(	
	.CLK						(aa[1]),
	.RST_N						(aa[0]),
	
	.ENDPOINT_DECODE			(register_decode),
	
	.DATA_BYTE_READY			(data_byte_ready),
	.ENDPOINT_EN				(ept_int_enable),

	.WRITE_EN					(ept_int_write_enable),
	.WRITE_READY				(ft_245_state_mne_write_ready),
	.WRITE_BYTE					(ept_int_write_byte),
	.WRITE_COMPLETE				(write_complete),
	
	.UC_IN                      (UC_IN),
	.UC_OUT                     (UC_OUT)	
	);

endmodule
