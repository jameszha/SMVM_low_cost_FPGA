module row_length_receiver
   #(parameter NUM_CHANNELS=4, 
	 parameter ADDRESS=3'h1)
	(input logic clk,
	 input logic rst_l,
	 input logic rst_trigger,
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
    logic [1:0] curr_byte_in_word;			       // Track which byte to write to (in order to reconstruct 4-byte word)

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
	 input logic rst_trigger,
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
    logic [1:0] curr_byte_in_word;			       // Track which byte to write to (in order to reconstruct 4-byte word)
    logic toggle_val_index; 					   // Track whether current word is value or column index. 0 = value; 1 = index

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
        end else begin   
            case (block_transfer_state)
                IDLE: begin
                    byte_in_count <= 0;
                    curr_channel <= 0;
            		curr_byte_in_word <= 0;
            		values <= 'b0;
            		column_indices <= 'b0;
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
                    	toggle_val_index = ~toggle_val_index;
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
