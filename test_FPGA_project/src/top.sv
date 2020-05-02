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
	 inout  wire [7:0]		     bd_inout,

   //input logic CLOCK_50, // Testing

     // LED
	 output logic   [35:0]      LED,

     // Button
     input logic    [1:0]       BUTTON,

     // SD Card
     output logic               SD_CLK,
     inout wire                 SD_CMD,
     input logic    [3:0]       SD_DATA
	);

	//**************************************************
	//* 	Clock and Reset
	//**************************************************
	logic clk, rst_l;
  	assign clk = aa[1];
    assign rst_l = aa[0];
	
    //**************************************************
    //*     Button Control
    //**************************************************

    //**************************************************
    //*     SD Card Control
    //*     Se: https://github.com/WangXuan95/FPGA-SDcard-Reader
    //*     TODO: Needs Fixing
    //**************************************************
    //**************************************************
    //*     LED Control
    //**************************************************
    logic [35:0] led_data;
    logic led_en, led_data_ld;
    assign led_en = BUTTON[0];
    assign led_data_ld = 1'b1;

    led_controller LED_Control (.clk, .rst_l,
                                .en(led_en),
                                .led_data_ld(led_data_ld),
                                .led_data(led_data),

                                .out_to_led(LED));

    //**************************************************
    //*     Data Transfer
    //**************************************************

    // Controller-to-Endterm bus
    logic [23:0] UC_IN;
    logic [21:0] UC_OUT;

    active_transfer_library Active_Transfer_Controller (.aa(aa),
                                                        .bc_in(bc_in),
                                                        .bc_out(bc_out),
                                                        .bd_inout(bd_inout),

                                                        .UC_IN(UC_IN),
                                                        .UC_OUT(UC_OUT));

    /* Testing out the ROM module */
    logic counter_set, counter_clear, counter_en;
    logic [31:0] counter_set_val, counter_count;
    counter_down CD
    (.clk, .rst_l,
    .en(counter_en),
    .set(counter_set), .clear(counter_clear),
    .set_val(counter_set_val),
    .count(counter_count));

    logic [6:0] address_a, address_b;
    logic [7:0] q_a, q_b;
    romB_128x1 RB(
    .address_a(address_a),
    .address_b(address_b),
    .clock(clk),
    .q_a(q_a),
    .q_b(q_b));

    assign led_data = {28'h0, q_a};

    logic up;
    assign up = counter_count == 32'h0;

    always_ff @(posedge clk, negedge rst_l) begin
      if(~rst_l) begin
         address_a <= 0;

         counter_en <= 1;
         counter_clear <= 1'b0; 

         counter_set <= 1'b1;
         counter_set_val <= 32'h03FF_FFFF; // i second at 50Mhz

      end else if (up) begin
         address_a <= address_a + 1;

         counter_en <= 1;
         counter_clear <= 1'b0; 

         counter_set <= 1'b1;
         counter_set_val <= 32'h03FF_FFFF; // i second at 50Mhz
      end else begin
        address_a <= address_a;

        counter_en <= 1;
        counter_clear <= 1'b0; 

        counter_set <= 1'b0;
        counter_set_val <= 32'h03FF_FFFF; // i second at 50Mhz
      end
    end


    // wire [22*5-1:0]  uc_out_m;
    // eptWireOR # (.N(5)) wireOR (UC_OUT, uc_out_m);

    //  active_trigger             ACTIVE_TRIGGER_INST
    //  (
    //   .uc_clk                   (clk),
    //   .uc_reset                 (rst_l),
    //   .uc_in                    (UC_IN),
    //   .uc_out                   (uc_out_m[ 0*22 +: 22 ]),

    //   .trigger_to_host          ({7'b0, BUTTON[1]}),
    //   .trigger_to_device        ()
        
    //  );

    // logic transfer_out_en;
    // logic transfer_in_received;
    // logic transfer_out_start;
    // logic [7:0] transfer_in_byte;
    // logic [7:0] transfer_out_byte;

    //  active_transfer            ACTIVE_TRANSFER_INST
    //  (
    //   .uc_clk                   (clk),
    //   .uc_reset                 (rst_l),
    //   .uc_in                    (UC_IN),
    //   .uc_out                   (uc_out_m[ 2*22 +: 22 ]),
        
    //   .start_transfer           (transfer_out_start),
    //   .transfer_received        (transfer_in_received),
        
    //   .transfer_busy            (),
        
    //   .uc_addr                  (3'h2),

    //   .transfer_to_host         (transfer_out_byte),
    //   .transfer_to_device       (transfer_in_byte)   
    //  );

    // int bytes_received;
    // logic[35:0][7:0] temp_memory;
    // // Receive data using single byte transfer - slow. TODO: switch to block transfer
    // always_ff @(posedge transfer_in_received or negedge rst_l) begin
    //     if(~rst_l) begin
    //         bytes_received = 0;
    //     end else begin
    //         if (transfer_in_received) begin
    //             //led_data <= 36'b1 << transfer_in_byte;
    //             temp_memory[bytes_received] = transfer_in_byte;
    //             bytes_received = bytes_received + 1;
    //             //transfer_out_byte = temp_memory[bytes_received - 1];
    //             //transfer_out_start = 1;
    //         end
    //     end
    // end

    // always_ff @(posedge clk, negedge rst_l) begin
    //   if (~rst_l) 
    //     led_data <= 0;
    //   else 
    //     led_data <= 36'b1 << bytes_received;
    // end

    // logic toggle;
    // always_ff @(posedge clk or negedge rst_l) begin : proc_transfer_out_start
    //   if(~rst_l) begin
    //     toggle <= 0;
    //     transfer_out_start <= 0;
    //   end else if (~toggle & transfer_out_start) begin
    //     transfer_out_start <= 1;
    //     toggle <= 1;
    //   end else if (toggle & transfer_out_start) begin
    //     transfer_out_start <= 0;
    //     toggle <= 0;
    //   end else begin
    //     toggle <= 0;
    //     transfer_out_start <= 0;
    //   end
    // end

    //always_ff @(posedge clk, negedge rst_l) begin
    //  if (~rst_l)
    //    led_data <= 
    //end

    // logic block_out_reg, block_byte_ready;
    // logic [8:0] block_out_byte;
    // logic [8:0] bytes_sent;
    // active_block               BLOCK_TRANSFER_INST
    //  (
    //   .uc_clk                   (clk),
    //   .uc_reset                 (rst_l),
    //   .uc_in                    (UC_IN),
    //   .uc_out                   (uc_out_m[ 3*22 +: 22 ]),
        
    //   .start_transfer           (block_out_reg),
    //   .transfer_received        (),
         
    //   .transfer_ready           (block_byte_ready),
    //   .transfer_busy            (),

    //   .ept_length               (),
        
    //   .uc_addr                  (3'h3),
    //   .uc_length                (8'd36),

    //   .transfer_to_host         (block_out_byte),
    //   .transfer_to_device       ()
        
    //  );
    // assign block_out_reg = (bytes_received == 36) ? 1'b1 : 1'b0;
    // always_ff @(posedge block_byte_ready or negedge rst_l) begin
    //     if(~rst_l) begin
    //         bytes_sent <= 0;
    //         block_out_byte <= temp_memory[0];
    //     end else begin
    //         bytes_sent <= bytes_sent + 1;
    //         block_out_byte <= temp_memory[bytes_sent];
    //     end
    // end



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

