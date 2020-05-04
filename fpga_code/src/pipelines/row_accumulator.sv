`default_nettype none

module multiplier 
	#(parameter NUM_CHANNELS=4,
		parameter MATRIX_SIZE=128)
	(input logic clk, rst_l,

	input logic [NUM_CHANNELS-1:0][31:0] values,
    input logic [NUM_CHANNELS-1:0][31:0] col_id,
    input logic [NUM_CHANNELS-1:0][31:0] row_id,
    input logic rdy,

    output logic [MATRIX_SIZE-1:0][31:0]           accum,
    output logic done);


	logic [NUM_CHANNELS-1:0][31:0] vector_values;
	ROM mem0(.address_a(col_id[0][9:0]),
			.address_b(col_id[1][9:0]),
			.clock(clk),
			.q_a(vector_values[0]),
			.q_b(vector_values[1]));
	
	ROM mem1(.address_a(col_id[2][9:0]),
			.address_b(col_id[3][9:0]),
			.clock(clk),
			.q_a(vector_values[2]),
			.q_b(vector_values[3]));

	genvar k;
	logic [NUM_CHANNELS-1:0][31:0] row_id_stored, matrix_values_stored;
	generate
		for (k=0; k<NUM_CHANNELS;k++) begin
			register row_id_store(
				.clk, .rst_l,
				.en(rdy),
				.D(row_id[k]),
				.Q(row_id_stored[k]));
			register matrix_value_store(
				.clk,
				.rst_l,
				.en(rdy),
				.D(values[k]),
				.Q(matrix_values_stored[k]));
		end
	endgenerate

	logic [NUM_CHANNELS-1:0] channel_finished;
	logic [NUM_CHANNELS-1:0][31:0] mult_values;
	generate
		for(k=0; k<NUM_CHANNELS; k++) begin
			assign channel_finished[k] = (row_id_stored[k] >= MATRIX_SIZE);

			MULT mul(
				.dataa(matrix_values_stored[k]), // Matrix column value
				.datab(vector_values[k]), // Vector column value
				.result(mult_values[k]));
		end
	endgenerate


	typedef enum {IDLE, MULT, DONE} state_t;
	state_t state;

	always_ff @(posedge clk, negedge rst_l) begin : proc_
		if(~rst_l) begin
			accum <= 0;
			state <= IDLE;
		end else begin
			accum <= accum;
			done <= 1'b0;
			case (state) 
				IDLE: begin
					if (rdy) state <= MULT;
					else state <= IDLE;
				end
				MULT: begin
					for (int i = 0; i < NUM_CHANNELS; i++) begin
						if (!channel_finished[i]) accum[row_id_stored[i]] <= accum[row_id_stored[i]] + mult_values[i];
					end

					if (channel_finished[0] & channel_finished[1] & channel_finished[2] & channel_finished[3]) state <= DONE;
					else state <= IDLE;
				end
				DONE: begin 
					done <= 1'b1;
					state <= DONE;
				end
			endcase
		end
	end
endmodule : multiplier
