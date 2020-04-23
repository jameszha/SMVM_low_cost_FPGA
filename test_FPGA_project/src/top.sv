//************************************************************************
//*
//* top.sv
//* 
//* Author: James Zhang
//* Date: 4/22/2020
//* Version 0.0
//*
//* Description: Top level module for FPGA project
//*              Modified from EPT_4CE6_AF_D1_Top.v, Earth People Technology Inc., 2015
//*
//*
//************************************************************************



//************************************************************************
//* Module Declaration
//************************************************************************

module top 
	(// Clock and Reset
	 input  logic [1:0]          aa,

	 // Serial Communication
	 input  logic [1:0]          bc_in,
	 output logic [2:0]          bc_out,
	 inout  logic [7:0]		     bd_inout,

     // LED
	 output logic   [35:0]      LED,

     // Button
     input logic    [1:0]       BUTTON,

     // SD Card
     output logic               SD_CLK,
     inout                      SD_CMD,
     input logic    [3:0]       SD_DATA
	);

	//**************************************************
	//* 	Clock and Reset
	//**************************************************
	logic clk, rst_l;
  	assign            clk = aa[1];
  	assign            rst_l = aa[0];
	
    //**************************************************
    //*     Button Control
    //**************************************************

    //**************************************************
    //*     SD Card Control
    //*     Se: https://github.com/WangXuan95/FPGA-SDcard-Reader
    //*     TODO: Needs Fixing
    //**************************************************
    logic       outreq;    // when outreq=1, a byte of file content is read out from outbyte
    logic [7:0] outbyte;   // a byte of file content

    logic [3:0] sdcardstate;
    logic [1:0] sdcardtype;
    logic [2:0] fatstate;
    logic [1:0] filesystemtype;
    logic       file_found;

    SDFileReader #(.CLK_DIV(1), .FILE_NAME("data.txt")) SD_Card_Read (.clk, .rst_n(rst_l), 
                                                                      .sdclk(SD_CLK),.sdcmd(SD_CMD), .sddat(SD_DATA),
            
                                                                      // SD Card Information
                                                                      .sdcardstate(sdcardstate),
                                                                      .sdcardtype(sdcardtype),          // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2
                                                                      .fatstate(fatstate),              // 3'd6 = DONE
                                                                      .filesystemtype(filesystemtype),  // 0=Unknown, 1=invalid, 2=FAT16, 3=FAT32
                                                                      .file_found(file_found),          // 0=file not found, 1=file found
                                                                      
                                                                      // SD Card Data
                                                                      .outreq(outreq), .outbyte(outbyte));

    //**************************************************
    //*     LED Control
    //**************************************************
    logic [35:0] led_data;
    logic led_en, led_data_ld;
    assign led_en = BUTTON[0];
    assign led_data_ld = 1'b1;
    assign led_data = (file_found) ? // Smiley = File found; Frowny = File not found
                      {1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0,
                       1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0,
                       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                       1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1,
                       1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0,
                       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0} :
                      {1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0,
                       1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0,
                       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                       1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                       1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0,
                       1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1};

    led_controller LED_Control (.clk, .rst_l,
                                .en(led_en),
                                .led_data_ld(led_data_ld),
                                .led_data(led_data),

                                .out_to_led(LED));

    //**************************************************
    //*     Data Transfer
    //**************************************************


//    //-----------------------------------------------
//    // State Machine: Control Register from Transfer In 
//    //-----------------------------------------------


//   /* Control Register - Used for demo program only. Take in bytes received from host, interpret them, and output control signals
//      Control Register Register Map
	 
// 	 control_register[0]  =  transfer_in_loop_back
// 	 control_register[1]  =  load_block_image//block_in_loopback 
// 	 control_register[2]  =  load_ept_image
// 	 control_register[3]  =  load_face_1_image
// 	 control_register[4]  =  LED Select Mode[0]
// 	 control_register[5]  =  LED Select Mode[1]
// 	 control_register[6]  =  LED Select Mode[2]
// 	 control_register[7]  =  LED Select Mode[3]
//   */
//   active_control_register      ACTIVE_CONTROL_REG_INST
//   (
//    .CLK                        (CLK_66),
//    .RST                        (RST),
//    .TRANSFER_IN_RECEIVED       (transfer_in_received),
//    .TRANSFER_IN_BYTE           (transfer_in_byte),

//    .CONTROL_REGISTER           (control_register)
//    );
   
//    //-----------------------------------------------
//    // Instantiate the EPT Library
//    //-----------------------------------------------

// 	active_transfer_library	   Active_Transfer_Controller
// 	(	
// 	.aa                        (aa),
// 	.bc_in                     (bc_in),
// 	.bc_out                    (bc_out),
// 	.bd_inout                  (bd_inout),

// 	.UC_IN                     (UC_IN),
// 	.UC_OUT                    (UC_OUT)
	
// 	);
	
//    //-----------------------------------------------
//    // Instantiate the EPT Library
//    //-----------------------------------------------
// wire [22*5-1:0]  uc_out_m;
// eptWireOR # (.N(5)) wireOR (UC_OUT, uc_out_m);

// /*
//     Active Trigger Register Mapping
	
// 	trigger_in_byte[0]  =  Load Static Value
// 	trigger_in_byte[1]  =  Load shift_count_value
// 	trigger_in_byte[2]  =  
// 	trigger_in_byte[3]  =  
// 	trigger_in_byte[4]  =  Load Timer Value, timer_value[15:8]
// 	trigger_in_byte[5]  =  Load Timer Value, timer_value[23:16]
// 	trigger_in_byte[6]  =  Load linear_feedback_shift_register
// 	trigger_in_byte[7]  =  start_block_transfer = 1'b1
	

// */
// 	active_trigger             ACTIVE_TRIGGER_INST
// 	(
// 	 .uc_clk                   (CLK_66),
// 	 .uc_reset                 (RST),
// 	 .uc_in                    (UC_IN),
// 	 .uc_out                   (uc_out_m[ 0*22 +: 22 ]),

// 	 .trigger_to_host          (trigger_out),
// 	 .trigger_to_device        (trigger_in_byte)
	
// 	);
	
// 	active_transfer            ACTIVE_TRANSFER_INST
// 	(
// 	 .uc_clk                   (CLK_66),
// 	 .uc_reset                 (RST),
// 	 .uc_in                    (UC_IN),
// 	 .uc_out                   (uc_out_m[ 2*22 +: 22 ]),
	
// 	 .start_transfer           (transfer_out_reg),
// 	 .transfer_received        (transfer_in_received),
	
// 	 .transfer_busy            (),
	
// 	 .uc_addr                  (3'h2),

// 	 .transfer_to_host         (transfer_out_byte),
// 	 .transfer_to_device       (transfer_in_byte)	
// 	);
	
	
// 	active_block               BLOCK_TRANSFER_INST
// 	(
// 	 .uc_clk                   (CLK_66),
// 	 .uc_reset                 (RST),
// 	 .uc_in                    (UC_IN),
// 	 .uc_out                   (uc_out_m[ 3*22 +: 22 ]),
	
// 	 .start_transfer           (block_out_reg),
// 	 .transfer_received        (block_in_rcv),
	 
// 	 .transfer_ready           (block_byte_ready),
// 	 .transfer_busy            (block_busy),

// 	 .ept_length               (ept_length),
	
// 	 .uc_addr                  (3'h4),
// 	 .uc_length                (ept_length),

// 	 .transfer_to_host         (block_out_byte),
// 	 .transfer_to_device       (block_in_data)
	
// 	);

// 	active_block               BLOCK_IMAGE_INST
// 	(
// 	 .uc_clk                   (CLK_66),
// 	 .uc_reset                 (RST),
// 	 .uc_in                    (UC_IN),
// 	 .uc_out                   (uc_out_m[ 4*22 +: 22 ]),
	
// 	 .start_transfer           (block_out_image_start),
// 	 .transfer_received        (block_in_image_rcv),
	 
// 	 .transfer_ready           (block_byte_image_ready),
// 	 .transfer_busy            (block_image_busy),

// 	 .ept_length               (ept_length_image),
	
// 	 .uc_addr                  (3'h2),
// 	 .uc_length                (ept_length_image),

// 	 .transfer_to_host         (block_out_byte_image),
// 	 .transfer_to_device       (block_in_data_image)
	
// 	);

	
endmodule

