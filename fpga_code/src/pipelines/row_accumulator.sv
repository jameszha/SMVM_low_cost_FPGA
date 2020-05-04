`default_nettype none

module multiplier
	#(parameter NUM_CHANNELS=4)
	(input logic clk, rst_l,

	 input logic [NUM_CHANNELS-1:0][31:0] values,
     input logic [NUM_CHANNELS-1:0][31:0] column_indices,
     input logic rdy_in,

     /* Multiplied values with the column of the vector */
     output logic [NUM_CHANNELS-1:0][31:0] multiplied_values,
     output logic rdy_out);

	logic [NUM_CHANNELS-1:0][31:0] vector_values;
	ROM mem0(.address_a(column_indices[0][9:0]),
			.address_b(column_indices[1][9:0]),
			.clock(clk),
			.q_a(vector_values[0]),
			.q_b(vector_values[1]));
	ROM mem1(.address_a(column_indices[2][9:0]),
			.address_b(column_indices[3][9:0]),
			.clock(clk),
			.q_a(vector_values[2]),
			.q_b(vector_values[3]));

	logic [NUM_CHANNELS-1:0][31:0] matrix_values;
	genvar k;
	generate
		for (k = 0; k < NUM_CHANNELS; k++) begin: store_values
			register matrix_store
    		(.clk, 
    		.rst_l, .clear(1'b0),
    		.en(1'b1),
     		.D(values[k]),
     		.Q(matrix_values[k]));
     	end: store_values
	endgenerate

	typedef enum {IDLE, MULT, DONE} multiplied_state_t;
	multiplied_state_t mult_state;
	logic store_en;

	always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l) begin
			 rdy_out <= 0;
			 mult_state <= IDLE;
			 store_en <= 0;
		end else begin
			case (mult_state) 
				IDLE: begin
					rdy_out <= 0;
					store_en <= 0;
					if (rdy_in) mult_state <= MULT;
					else mult_state <= IDLE;
				end
				MULT: begin
					rdy_out <= 0;
					store_en <= 1;
					mult_state <= DONE;
				end
				DONE: begin
					rdy_out <= 1;
					store_en <= 0;
					mult_state <= IDLE;
				end
			endcase
		end
	end

	logic [NUM_CHANNELS-1:0][31:0] mult_values;
	generate
		for (k = 0; k < NUM_CHANNELS; k++) begin : multiply
			MULT mul(
				.dataa(matrix_values[k]), // Matrix column value
				.datab(vector_values[k]), // Vector column value
				.result(mult_values[k]));

			register mul_store 
				(.clk, .rst_l, 
				.clear(1'b0),
				.en(store_en),
				.D(mult_values[k]),
				.Q(multiplied_values[k]));
		end : multiply

	endgenerate

endmodule : multiplier