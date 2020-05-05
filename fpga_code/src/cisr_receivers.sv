module row_length_receiver
   #(parameter NUM_CHANNELS=4, 
     parameter ADDRESS=3'h1)
    (input logic clk,
     input logic rst_l,

     input logic [23:0] uc_in, 
     input logic [21:0] uc_out,

     output logic [NUM_CHANNELS-1:0][31:0] row_lengths,
     output logic rdy,
     output logic done
    );


    logic block_in_start;
    logic block_ready;
    logic [7:0] block_in_byte;
    logic [7:0] num_bytes_in, byte_in_count;

    active_block               Block_Receiver
     (
      .uc_clk                   (clk),
      .uc_reset                 (rst_l),
      .uc_in                    (uc_in),
      .uc_out                   (uc_out),
        
      .start_transfer           (1'b0),
      .transfer_received        (block_in_start),
         
      .transfer_ready           (block_ready),
      .transfer_busy            (),

      .ept_length               (num_bytes_in),
        
      .uc_addr                  (ADDRESS),
      .uc_length                (0),

      .transfer_to_host         (0),
      .transfer_to_device       (block_in_byte)
        
     );

    typedef enum {IDLE, RX_WAITING, RX_STORE_BYTE, RX_CHECK_DONE} transfer_state_t;
    transfer_state_t block_transfer_state;

    logic [$clog2(NUM_CHANNELS)-1:0] curr_channel; // Track which channel to write the received byte to
    logic [1:0] curr_byte_in_word;                 // Track which byte to write to (in order to reconstruct 4-byte word)

    // Manage block transfer state. 
    always_ff @(posedge clk or negedge rst_l) begin
        if(~rst_l) begin
            block_transfer_state <= IDLE;
            byte_in_count <= 0;
            curr_channel <= 0;
            curr_byte_in_word <= 0;
            row_lengths <= 'b0;
            rdy <= 0;
            done <= 0;
        end else begin   
            case (block_transfer_state)
                IDLE: begin
                    byte_in_count <= 0;
                    curr_channel <= 0;
                    curr_byte_in_word <= 0;
                    rdy <= 0;
                    if (block_in_start) begin
                        block_transfer_state <= RX_WAITING;    
                    end
                end
                RX_WAITING: begin
                    if (block_ready) begin
                        block_transfer_state <= RX_STORE_BYTE;
                    end
                    if (!block_in_start) begin
                        block_transfer_state <= IDLE;
                    end
                end
                RX_STORE_BYTE: begin
                    case (curr_byte_in_word)
                        2'b00: row_lengths[curr_channel][7:0] <= block_in_byte;
                        2'b01: row_lengths[curr_channel][15:8] <= block_in_byte;
                        2'b10: row_lengths[curr_channel][23:16] <= block_in_byte;
                        2'b11: row_lengths[curr_channel][31:24] <= block_in_byte;
                    endcase
                    curr_byte_in_word <= curr_byte_in_word + 2'b01;
                    if (curr_byte_in_word == 2'b11)
                        curr_channel <= (curr_channel + 'b1) % NUM_CHANNELS;
                    if (curr_channel == NUM_CHANNELS-1 && curr_byte_in_word == 2'b11)
                        rdy <= 1;
                    byte_in_count <= byte_in_count + 'b1;
                    block_transfer_state <= RX_CHECK_DONE;
                end
                RX_CHECK_DONE: begin
                    rdy <= 0; 
                    if (byte_in_count == num_bytes_in) begin // Done!
                        done <= 1'b1;
                        block_transfer_state <= IDLE;
                    end
                    else if (block_ready) begin
                        block_transfer_state <= RX_STORE_BYTE;
                    end
                    else if (block_in_start) begin
                        block_transfer_state <= RX_WAITING;
                    end
                    else begin
                        block_transfer_state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule: row_length_receiver


module value_index_receiver
   #(parameter NUM_CHANNELS=4, 
     parameter ADDRESS=3'h2)
    (input logic clk,
     input logic rst_l,

     input logic [23:0] uc_in, 
     input logic [21:0] uc_out,

     output logic [NUM_CHANNELS-1:0][31:0] values,
     output logic [NUM_CHANNELS-1:0][31:0] column_indices,
     output logic rdy
    );

    logic block_in_start;
    logic block_ready;
    logic [7:0] block_in_byte;
    logic [7:0] num_bytes_in, byte_in_count;

    active_block               Block_Receiver
     (
      .uc_clk                   (clk),
      .uc_reset                 (rst_l),
      .uc_in                    (uc_in),
      .uc_out                   (uc_out),
        
      .start_transfer           (1'b0),
      .transfer_received        (block_in_start),
         
      .transfer_ready           (block_ready),
      .transfer_busy            (),

      .ept_length               (num_bytes_in),
        
      .uc_addr                  (ADDRESS),
      .uc_length                (0),

      .transfer_to_host         (0),
      .transfer_to_device       (block_in_byte)
        
     );

    typedef enum {IDLE, RX_WAITING, RX_STORE_BYTE, RX_CHECK_DONE} transfer_state_t;
    transfer_state_t block_transfer_state;

    logic [$clog2(NUM_CHANNELS)-1:0] curr_channel; // Track which channel to write the received byte to
    logic [1:0] curr_byte_in_word;                 // Track which byte to write to (in order to reconstruct 4-byte word)
    logic toggle_val_index;                        // Track whether current word is value or column index. 0 = value; 1 = index

    // Manage block transfer state. 
    always_ff @(posedge clk or negedge rst_l) begin
        if(~rst_l) begin
            block_transfer_state <= IDLE;
            byte_in_count <= 0;
            curr_channel <= 0;
            curr_byte_in_word <= 0;
            values <= 'b0;
            column_indices <= 'b0;
            rdy <= 0;
            toggle_val_index <= 0;
        end else begin   
            case (block_transfer_state)
                IDLE: begin
                    byte_in_count <= 0;
                    curr_channel <= 0;
                    curr_byte_in_word <= 0;
                    values <= 'b0;
                    column_indices <= 'b0;
                    rdy <= 0;
                    toggle_val_index <= 0;
                    if (block_in_start) begin
                        block_transfer_state <= RX_WAITING;    
                    end
                end
                RX_WAITING: begin
                    if (block_ready) begin
                        block_transfer_state <= RX_STORE_BYTE;
                    end
                    if (!block_in_start) begin
                        block_transfer_state <= IDLE;
                    end
                end
                RX_STORE_BYTE: begin
                    case (toggle_val_index)
                        1'b0: begin
                            case (curr_byte_in_word)
                                2'b00: values[curr_channel][7:0] <= block_in_byte;
                                2'b01: values[curr_channel][15:8] <= block_in_byte;
                                2'b10: values[curr_channel][23:16] <= block_in_byte;
                                2'b11: values[curr_channel][31:24] <= block_in_byte;
                            endcase
                        end
                        1'b1: begin
                            case (curr_byte_in_word)
                                2'b00: column_indices[curr_channel][7:0] <= block_in_byte;
                                2'b01: column_indices[curr_channel][15:8] <= block_in_byte;
                                2'b10: column_indices[curr_channel][23:16] <= block_in_byte;
                                2'b11: column_indices[curr_channel][31:24] <= block_in_byte;
                            endcase
                        end
                    endcase
                    curr_byte_in_word <= curr_byte_in_word + 2'b01;
                    if (curr_byte_in_word == 2'b11)
                        toggle_val_index <= ~toggle_val_index;
                    if (curr_byte_in_word == 2'b11 && toggle_val_index)
                        curr_channel <= (curr_channel + 'b1) % NUM_CHANNELS;
                    if (curr_byte_in_word == 2'b11 && toggle_val_index && curr_channel == NUM_CHANNELS-1)
                        rdy <= 1;
                    byte_in_count <= byte_in_count + 'b1;
                    block_transfer_state <= RX_CHECK_DONE;
                end
                RX_CHECK_DONE: begin
                    rdy <= 0; 
                    if (byte_in_count == num_bytes_in) begin // Done!
                        block_transfer_state <= IDLE;
                    end
                    else if (block_ready) begin
                        block_transfer_state <= RX_STORE_BYTE;
                    end
                    else if (block_in_start) begin
                        block_transfer_state <= RX_WAITING;
                    end
                    else begin
                        block_transfer_state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule: value_index_receiver

module cisr_decoder
   #(parameter NUM_CHANNELS=4,
     parameter ROW_LEN_FIFO_DEPTH=4)
    (input logic clk,
     input logic rst_l,

     input logic [NUM_CHANNELS-1:0][31:0] cisr_row_lengths,
     input logic row_len_rdy,
     input logic row_len_done,

     input logic [NUM_CHANNELS-1:0][31:0] cisr_values,
     input logic [NUM_CHANNELS-1:0][31:0] cisr_column_indices,
     input logic val_ind_rdy,

     output logic [NUM_CHANNELS-1:0][31:0] values,
     output logic [NUM_CHANNELS-1:0][31:0] col_id,
     output logic [NUM_CHANNELS-1:0][31:0] row_id,
     output logic rdy,

     output logic row_len_fifo_overflow);

    // The row length FIFO
    logic [ROW_LEN_FIFO_DEPTH-1:0][NUM_CHANNELS-1:0][31:0] row_len_fifo;
    logic [15:0] row_len_fifo_counter;
    assign row_len_fifo_overflow = (row_len_fifo_counter > ROW_LEN_FIFO_DEPTH);

    // Simply forward the values and column indices. The only computation that needs be performed is the calculation of row index
    assign values = cisr_values;
    assign col_id = cisr_column_indices;
    assign rdy = val_ind_rdy;

    // The next row ID to grab when a channel runs out of work to do.
    logic [31:0] next_row_id;

    typedef enum {READ_ROW_LEN, ROW_LEN_DONE, MULTIPLY} state_t;
    state_t state;
    // Manage the Row Length FIFO
    // Note from James: Using non-blocking assignment to do this is god-awful. Here's some code using blocking assignment. Quartus will hate me, but my sanity won't. 
    always_ff @(posedge clk or negedge rst_l) begin
        if(~rst_l) begin
            row_len_fifo = 'b0;
            row_len_fifo_counter = 'b1;
            row_id = 'b0;
            next_row_id = 0;
            state = READ_ROW_LEN;
        end else begin
            case (state)
                READ_ROW_LEN: begin
                    if (row_len_rdy) begin // Fill in FIFO as the row lengths are received. This should occur first, before we receive any column/index data
                        row_len_fifo[row_len_fifo_counter] = cisr_row_lengths;
                        row_len_fifo_counter = row_len_fifo_counter + 1;
                    end
                    if (row_len_done) begin
                        state = ROW_LEN_DONE;
                    end
                end
                ROW_LEN_DONE: begin
                    for (int channel_id = 0; channel_id < NUM_CHANNELS; channel_id++) begin
                        for (int i = 0; i < ROW_LEN_FIFO_DEPTH; i++) begin
                            if (row_len_fifo[i][channel_id] == 0) begin
                                row_id[channel_id] = next_row_id;
                                next_row_id = (next_row_id == 6) ? 6 : next_row_id + 'b1;
                                row_len_fifo[0][channel_id] = row_len_fifo[1][channel_id];
                            end
                            else break;
                        end
                    end
                    state = MULTIPLY;
                end
                MULTIPLY: begin
                    if (val_ind_rdy) begin
                        for (int channel_id = 0; channel_id < NUM_CHANNELS; channel_id++) begin // For each channel,
                            row_len_fifo[0][channel_id] = row_len_fifo[0][channel_id] - 'b1;    // 1. decrement the row length

                            for (int i = 0; i < ROW_LEN_FIFO_DEPTH; i++) begin
                                if (row_len_fifo[0][channel_id] == 0) begin                      // 2. If the row length becomes 0, i.e. the channel ran out of work to do,
                                    row_id[channel_id] = next_row_id;                            //    grab the next row id (next_row_id) 
                                    next_row_id = (next_row_id == 6) ? 6 : next_row_id + 'b1;    //     and 
                                    row_len_fifo[0][channel_id] = row_len_fifo[1][channel_id];   //    grab the next row length (from the next layer of the FIFO)
                                end 
                                else break;
                            end
                        end
                    end
                end

            endcase
        end
    end

endmodule: cisr_decoder