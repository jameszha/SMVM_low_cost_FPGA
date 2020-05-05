`default_nettype none

module multiplier1
	#(parameter NUM_CHANNELS=4,
		parameter MATRIX_SIZE=128)
	(input logic clk, rst_l,

	input logic [NUM_CHANNELS-1:0][31:0] values,
    input logic [NUM_CHANNELS-1:0][31:0] col_id,
    input logic [NUM_CHANNELS-1:0][31:0] row_id,
    input logic rdy,

    output logic [MATRIX_SIZE-1:0][31:0]           accum,
    output logic done);


	/* Memory uses a full cycle of delay
	 * Need to buffer values for a full cycle */
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

	/* Buffered values through the pipeline */
	genvar k;
	logic [NUM_CHANNELS-1:0][31:0] row_id_stored0, matrix_values_stored0;
	logic [NUM_CHANNELS-1:0][31:0] row_id_stored1, matrix_values_stored1;
	logic rdy_stored0, rdy_stored1;

	generate
		for (k=0; k<NUM_CHANNELS;k++) begin: store
			register row_id_store0(
				.clk, .rst_l,
				.en(rdy),
				.clear(1'b0),
				.D(row_id[k]),
				.Q(row_id_stored0[k]));
			register matrix_value_store0(
				.clk,
				.rst_l,
				.en(rdy),
				.clear(1'b0),
				.D(values[k]),
				.Q(matrix_values_stored0[k]));
			register row_id_store1(
				.clk, .rst_l,
				.en(rdy_stored0),
				.clear(1'b0),
				.D(row_id_stored0[k]),
				.Q(row_id_stored1[k]));
			register matrix_value_store1(
				.clk,
				.rst_l,
				.en(rdy_stored0),
				.clear(1'b0),
				.D(matrix_values_stored0[k]),
				.Q(matrix_values_stored1[k]));
		end
	endgenerate
	register ready_store0(
				.clk, 
				.rst_l,
				.en(rdy), 
				.clear(1'b0),
				.D(rdy),
				.Q(rdy_stored0));
	register ready_store1(
				.clk, 
				.rst_l,
				.en(rdy_stored0), 
				.clear(1'b0),
				.D(rdy_stored0),
				.Q(rdy_stored1));


	/* Logic to calculate finished channels and multiplication */
	logic [NUM_CHANNELS-1:0] channel_finished;
	logic [NUM_CHANNELS-1:0][31:0] mult_values;
	generate
		for(k=0; k<NUM_CHANNELS; k++) begin: mul
			assign channel_finished[k] = (row_id_stored1[k] >= MATRIX_SIZE);

			MULT mul(
				.dataa(matrix_values_stored1[k]), // Matrix column value
				.datab(vector_values[k]), // Vector column value
				.result(mult_values[k]));
		end
	endgenerate

	//assign done = channel_finished[0] & channel_finished[1] & channel_finished[2] & channel_finished[3];

	typedef enum {MULT, DONE} state_t;
	state_t state;

	always_ff @(posedge clk, negedge rst_l) begin : proc_
		if(~rst_l) begin
			accum <= 0;
			state <= MULT;
		end else begin
			accum <= accum;
			done <= 1'b0;
			case (state) 
				MULT: begin
					for (int i = 0; i < NUM_CHANNELS; i++) begin
						if (!channel_finished[i] & rdy_stored1) accum[row_id_stored1[i]] <= accum[row_id_stored1[i]] + mult_values[i];
					end

					if (channel_finished[0] & channel_finished[1] & channel_finished[2] & channel_finished[3]) state <= DONE;
					else state <= MULT;
				end
				DONE: begin 
					done <= 1'b1;
					state <= DONE;
				end
			endcase
		end
	end
endmodule : multiplier1