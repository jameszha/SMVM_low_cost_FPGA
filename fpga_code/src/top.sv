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
     inout  wire [7:0]           bd_inout,

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
    //*     Trigger-from-Host signals
    //**************************************************
    logic [7:0] trigger_in, trigger_out;
    logic rst_trigger;
    assign rst_trigger = trigger_in[7];

    //**************************************************
    //*     Clock and Reset
    //**************************************************
    logic clk, rst_l;
    assign clk = aa[1];
    assign rst_l = aa[0] & BUTTON[1];

    //**************************************************
    //*     LED Control
    //**************************************************
    logic [35:0] led_data;
    logic led_en, led_data_ld;
    assign led_en = BUTTON[0];
    assign led_data_ld = 1'b1;
    // assign led_data = (file_found) ? // Smiley = File found; Frowny = File not found
    //                   {sdcardtype, sdcardstate,
    //                    1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0,
    //                    1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
    //                    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1,
    //                    1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0,
    //                    1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0} :
    //                   {sdcardtype, sdcardstate,
    //                    1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0,
    //                    1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
    //                    1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
    //                    1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0,
    //                    1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1};

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

    // Transfer-Module-to-Controller Bus
    wire [22*5-1:0]  uc_out_m;
    eptWireOR # (.N(5)) wireOR (UC_OUT, uc_out_m);

     active_trigger             ACTIVE_TRIGGER_INST
     (
      .uc_clk                   (clk),
      .uc_reset                 (rst_l),
      .uc_in                    (UC_IN),
      .uc_out                   (uc_out_m[ 0*22 +: 22 ]),

      .trigger_to_host          (0),
      .trigger_to_device        (trigger_in)
        
     );
     assign trigger_out[0] = ~BUTTON[1];
     assign trigger_out[7:1] = 'b0;

     parameter NUM_CHANNELS = 4;

    logic [NUM_CHANNELS-1:0][31:0] cisr_row_lengths;
    logic row_len_rdy, row_len_done;
    assign row_len_done = trigger_in[0];
    row_length_receiver Row_Length_Receiver (.clk, .rst_l,
                                             .uc_in(UC_IN), 
                                             .uc_out(uc_out_m[ 1*22 +: 22 ]),

                                             .row_lengths(cisr_row_lengths),
                                             .rdy(row_len_rdy),
                                             .done());
    
    logic [NUM_CHANNELS-1:0][31:0] cisr_values, cisr_column_indices;
    logic val_ind_rdy;
    value_index_receiver Value_Index_Receiver (.clk, .rst_l,
                                               .uc_in(UC_IN), 
                                               .uc_out(uc_out_m[ 2*22 +: 22 ]),

                                               .values(cisr_values),
                                               .column_indices(cisr_column_indices),
                                               .rdy(val_ind_rdy));

    logic [NUM_CHANNELS-1:0][31:0] values, col_id, row_id;
    logic rdy;
    cisr_decoder CISR_Decoder (.clk, .rst_l,
                               .cisr_row_lengths(cisr_row_lengths),
                               .row_len_rdy(row_len_rdy),
                               .row_len_done(row_len_done),

                               .cisr_values(cisr_values),
                               .cisr_column_indices(cisr_column_indices),
                               .val_ind_rdy(val_ind_rdy),

                               .values(values),
                               .col_id(col_id),
                               .row_id(row_id),
                               .rdy(rdy),

                               .row_len_fifo_overflow()); // TODO: connect to status LED later

    logic [5:0][31:0] result;
    logic done;

    multiplier1 #(.NUM_CHANNELS(4), .MATRIX_SIZE(6)) Mul (.clk, .rst_l,
                                                         .values(values),
                                                         .col_id(col_id),
                                                         .row_id(row_id),
                                                         .rdy(rdy),

                                                         .accum(result),
                                                         .done(done));

    // always_ff @(posedge clk or negedge rst_l) begin
    //     if(~rst_l) begin
    //         result <= 'b0;
    //     end else begin
    //         if (rdy) begin
    //             for (int i = 0; i < 4; i ++) begin
    //                 result[row_id[i]] <= result[row_id[i]] + values[i];
    //             end
    //         end
    //     end
    // end
    // assign done = (row_id[0] >= 6 && row_id[1] >= 6 && row_id[2] >= 6 && row_id[3] >= 6);

    // Temp latch to light up LEDs corresponding to nonzero elements in the decoded matrix
    // always_ff @(posedge clk or negedge rst_l) begin
    //     if(~rst_l) begin
    //         led_data <= 'b0;
    //     end else begin
    //         if (rdy) begin
    //             for (int i = 0; i < NUM_CHANNELS; i++) begin
    //                 if (values[i] != 0 && col_id[i] < 6) begin
    //                     // led_data = led_data + 'b1;
    //                     // led_data = {row_id[i][5:0], col_id[i][5:0]};
    //                     led_data[row_id[i]*6 + col_id[i]] = 1'b1;
    //                 end
    //             end
    //         end
    //     end
    // end
    // assign led_data[5:0] = row_id[0][5:0];
    // assign led_data[11:6] = row_id[1][5:0];
    // assign led_data[17:12] = row_id[2][5:0];
    // assign led_data[23:18] = row_id[3][5:0];


    // assign led_data[35] = done;
    assign led_data = result[1];

    logic [23:0][7:0] data_out;
    assign data_out = result;

    logic block_out_start;
    logic block_ready;
    logic transfer_busy;
    logic [7:0] block_out_byte;
    logic [7:0] num_bytes_out, byte_out_count;

    active_block               BLOCK_TRANSFER_INST
     (
      .uc_clk                   (clk),
      .uc_reset                 (rst_l),
      .uc_in                    (UC_IN),
      .uc_out                   (uc_out_m[ 3*22 +: 22 ]),
        
      .start_transfer           (block_out_start),
      .transfer_received        (),
         
      .transfer_ready           (block_ready),
      .transfer_busy            (transfer_busy),

      .ept_length               (),
        
      .uc_addr                  (3'h3),
      .uc_length                (num_bytes_out),

      .transfer_to_host         (block_out_byte),
      .transfer_to_device       ()
        
     );

    typedef enum {IDLE, TX_WAITING, TX_SEND_BYTE, TX_CHECK_DONE, DONE} transfer_state_t;
    transfer_state_t block_transfer_state;

    // Manage block transfer state. 
    always_ff @(posedge clk or negedge rst_l) begin
        if(~rst_l) begin
            block_transfer_state = IDLE;
            byte_out_count <= 0;
            block_out_start <= 0;
            block_out_byte <= 0;
            num_bytes_out <= 0;
        end else begin   
            case (block_transfer_state)
                IDLE: begin
                    byte_out_count <= 0;
                    block_out_start <= 0;
                    block_out_byte <= 0;
                    num_bytes_out <= 0;
                    if (done & ~transfer_busy) begin
                        num_bytes_out <= 6*4;
                        block_out_start <= 1'b1;
                        block_transfer_state <= TX_WAITING;
                    end
                end
                TX_WAITING: begin
                    block_out_byte <= data_out[byte_out_count];
                    if (block_ready) begin
                        block_transfer_state <= TX_SEND_BYTE;
                    end
                end
                TX_SEND_BYTE: begin
                    byte_out_count <= byte_out_count + 1;
                    block_transfer_state <= TX_CHECK_DONE;
                end
                TX_CHECK_DONE: begin
                    if (byte_out_count == num_bytes_out) begin // Done!
                        block_transfer_state <= DONE;
                    end
                    else if (block_ready) begin
                        block_transfer_state <= TX_SEND_BYTE;
                    end
                    else begin
                        block_transfer_state <= TX_WAITING;
                    end
                end
                DONE: begin
                    byte_out_count <= 0;
                    block_out_start <= 0;
                    block_out_byte <= 0;
                    num_bytes_out <= 0;
                end
            endcase
        end
    end











    // logic block_out_start, block_in_start;
    // logic block_ready;
    // logic [7:0] block_out_byte;
    // logic [7:0] num_bytes_out, byte_out_count;

    // logic [7:0] block_in_byte;
    // logic [7:0] num_bytes_in, byte_in_count;
    // active_block               BLOCK_TRANSFER_INST
    //  (
    //   .uc_clk                   (clk),
    //   .uc_reset                 (rst_l),
    //   .uc_in                    (UC_IN),
    //   .uc_out                   (uc_out_m[ 3*22 +: 22 ]),
        
    //   .start_transfer           (block_out_start),
    //   .transfer_received        (block_in_start),
         
    //   .transfer_ready           (block_ready),
    //   .transfer_busy            (),

    //   .ept_length               (num_bytes_in),
        
    //   .uc_addr                  (3'h3),
    //   .uc_length                (num_bytes_out),

    //   .transfer_to_host         (block_out_byte),
    //   .transfer_to_device       (block_in_byte)
        
    //  );
    // typedef enum {IDLE, RX_WAITING, RX_STORE_BYTE, RX_CHECK_DONE, ECHO, TX_WAITING, TX_SEND_BYTE, TX_CHECK_DONE} transfer_state_t;
    // transfer_state_t block_transfer_state;
    // logic[127:0][7:0] block_transfer_memory; // 32 Ints

    // always_comb begin
    //     for (int i = 0; i < 36; i++) begin
    //         led_data[i] = (block_transfer_memory[i]) ? 1'b1 : 1'b0;
    //     end
    // end

    // // Manage block transfer state. 
    // always_ff @(posedge clk or negedge rst_l or posedge rst_trigger) begin
    //     if(~rst_l) begin
    //         block_transfer_state = IDLE;
    //         byte_in_count <= 0;
    //         byte_out_count <= 0;
    //         block_out_start <= 0;
    //         block_out_byte <= 0;
    //         num_bytes_out <= 0;
    //         block_transfer_memory = 'b0;
    //     end else if (rst_trigger) begin
    //         block_transfer_state = IDLE;
    //         byte_in_count <= 0;
    //         byte_out_count <= 0;
    //         block_out_start <= 0;
    //         block_out_byte <= 0;
    //         num_bytes_out <= 0;
    //         block_transfer_memory = 'b0;
    //     end else begin   
    //         case (block_transfer_state)
    //             IDLE: begin
    //                 byte_in_count <= 0;
    //                 byte_out_count <= 0;
    //                 block_out_start <= 0;
    //                 block_out_byte <= 0;
    //                 num_bytes_out <= 0;
    //                 if (block_in_start) begin
    //                     block_transfer_memory = 'b0;
    //                     block_transfer_state <= RX_WAITING;
    //                 end
    //             end
    //             RX_WAITING: begin
    //                 if (block_ready) begin
    //                     block_transfer_state <= RX_STORE_BYTE;
    //                 end
    //                 if (!block_in_start) begin
    //                     block_transfer_state <= IDLE;
    //                 end
    //             end
    //             RX_STORE_BYTE: begin
    //                 block_transfer_memory[byte_in_count] <= block_in_byte;
    //                 byte_in_count <= byte_in_count + 1;
    //                 block_transfer_state <= RX_CHECK_DONE;
    //             end
    //             RX_CHECK_DONE: begin
    //                 if (byte_in_count == num_bytes_in) begin // Done!
    //                     block_transfer_state <= ECHO;
    //                 end
    //                 else if (block_ready) begin
    //                     block_transfer_state <= RX_STORE_BYTE;
    //                 end
    //                 else if (block_in_start) begin
    //                     block_transfer_state <= RX_WAITING;
    //                 end
    //                 else begin
    //                     block_transfer_state <= IDLE;
    //                 end
    //             end

    //             ECHO: begin
    //                 num_bytes_out <= num_bytes_in;
    //                 block_out_start <= 1'b1;
    //                 block_transfer_state <= TX_WAITING;
    //             end
    //             TX_WAITING: begin
    //                 block_out_byte <= block_transfer_memory[byte_out_count];
    //                 if (block_ready) begin
    //                     block_transfer_state <= TX_SEND_BYTE;
    //                 end
    //             end
    //             TX_SEND_BYTE: begin
    //                 byte_out_count <= byte_out_count + 1;
    //                 block_transfer_state <= TX_CHECK_DONE;
    //             end
    //             TX_CHECK_DONE: begin
    //                 if (byte_out_count == num_bytes_out) begin // Done!
    //                     block_transfer_state <= IDLE;
    //                 end
    //                 else if (block_ready) begin
    //                     block_transfer_state <= TX_SEND_BYTE;
    //                 end
    //                 else begin
    //                     block_transfer_state <= TX_WAITING;
    //                 end
    //             end

    //         endcase
    //     end
    // end



//    //-----------------------------------------------
//    // State Machine: Control Register from Transfer In 
//    //-----------------------------------------------


//   /* Control Register - Used for demo program only. Take in bytes received from host, interpret them, and output control signals
//      Control Register Register Map
     
//   control_register[0]  =  transfer_in_loop_back
//   control_register[1]  =  load_block_image//block_in_loopback 
//   control_register[2]  =  load_ept_image
//   control_register[3]  =  load_face_1_image
//   control_register[4]  =  LED Select Mode[0]
//   control_register[5]  =  LED Select Mode[1]
//   control_register[6]  =  LED Select Mode[2]
//   control_register[7]  =  LED Select Mode[3]
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

//  active_transfer_library    Active_Transfer_Controller
//  (   
//  .aa                        (aa),
//  .bc_in                     (bc_in),
//  .bc_out                    (bc_out),
//  .bd_inout                  (bd_inout),

//  .UC_IN                     (UC_IN),
//  .UC_OUT                    (UC_OUT)
    
//  );
    
//    //-----------------------------------------------
//    // Instantiate the EPT Library
//    //-----------------------------------------------
// wire [22*5-1:0]  uc_out_m;
// eptWireOR # (.N(5)) wireOR (UC_OUT, uc_out_m);

// /*
//     Active Trigger Register Mapping
    
//  trigger_in_byte[0]  =  Load Static Value
//  trigger_in_byte[1]  =  Load shift_count_value
//  trigger_in_byte[2]  =  
//  trigger_in_byte[3]  =  
//  trigger_in_byte[4]  =  Load Timer Value, timer_value[15:8]
//  trigger_in_byte[5]  =  Load Timer Value, timer_value[23:16]
//  trigger_in_byte[6]  =  Load linear_feedback_shift_register
//  trigger_in_byte[7]  =  start_block_transfer = 1'b1
    

// */
//  active_trigger             ACTIVE_TRIGGER_INST
//  (
//   .uc_clk                   (CLK_66),
//   .uc_reset                 (RST),
//   .uc_in                    (UC_IN),
//   .uc_out                   (uc_out_m[ 0*22 +: 22 ]),

//   .trigger_to_host          (trigger_out),
//   .trigger_to_device        (trigger_in_byte)
    
//  );
    
//  active_transfer            ACTIVE_TRANSFER_INST
//  (
//   .uc_clk                   (CLK_66),
//   .uc_reset                 (RST),
//   .uc_in                    (UC_IN),
//   .uc_out                   (uc_out_m[ 2*22 +: 22 ]),
    
//   .start_transfer           (transfer_out_reg),
//   .transfer_received        (transfer_in_received),
    
//   .transfer_busy            (),
    
//   .uc_addr                  (3'h2),

//   .transfer_to_host         (transfer_out_byte),
//   .transfer_to_device       (transfer_in_byte)   
//  );
    
    
//  active_block               BLOCK_TRANSFER_INST
//  (
//   .uc_clk                   (CLK_66),
//   .uc_reset                 (RST),
//   .uc_in                    (UC_IN),
//   .uc_out                   (uc_out_m[ 3*22 +: 22 ]),
    
//   .start_transfer           (block_out_reg),
//   .transfer_received        (block_in_rcv),
     
//   .transfer_ready           (block_byte_ready),
//   .transfer_busy            (block_busy),

//   .ept_length               (ept_length),
    
//   .uc_addr                  (3'h4),
//   .uc_length                (ept_length),

//   .transfer_to_host         (block_out_byte),
//   .transfer_to_device       (block_in_data)
    
//  );

//  active_block               BLOCK_IMAGE_INST
//  (
//   .uc_clk                   (CLK_66),
//   .uc_reset                 (RST),
//   .uc_in                    (UC_IN),
//   .uc_out                   (uc_out_m[ 4*22 +: 22 ]),
    
//   .start_transfer           (block_out_image_start),
//   .transfer_received        (block_in_image_rcv),
     
//   .transfer_ready           (block_byte_image_ready),
//   .transfer_busy            (block_image_busy),

//   .ept_length               (ept_length_image),
    
//   .uc_addr                  (3'h2),
//   .uc_length                (ept_length_image),

//   .transfer_to_host         (block_out_byte_image),
//   .transfer_to_device       (block_in_data_image)
    
//  );

    
endmodule

