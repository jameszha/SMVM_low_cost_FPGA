`default_nettype none

module row_accumulator (
	input clk,    // Clock
	input rst_l,  // Asynchronous reset active low


	// Sparse matrix inputs are:
	// format1: row number, number of elements in the row
	// format2: column#, data 
	input [31:0] data_a, // This acts as the number of rows, and also acts as the address 
	input [31:0] data_b, // This acts as the value to get multiplied 
	input compute_start,    // This starts the computation for a given sparse row

	/* Rows are formatted in buffer as */
	/* col_idx3 | col_idx2 | col_idx1 | col_idx0 | row_num
	 * col_val3 | col_val2 | col_val1 | col_val0 | num_cols
	 *                                           | compute_start
	 */

	output [31:0] accum,   // accumulated sum for the row multiplied with the vector
	output [31:0] row_num, // Row number that the accumulated sum is done for
	output done            // Done signal signifying finished 
);
	
	/* Number of columns to still be executed */
	logic [31:0] column_count;
	logic stage0_en, stage1_en;
	assign stage0_en = (column_count >= 2);
	assign stage1_en = (column_count >= 1);

	/* The row number of the currently executing job */
	logic [31:0] curr_row_num;

	/* Components of first fetching stage */
	/* The index of the column */
	logic [9:0] column_idx_0;
	assign column_idx_0 = data_a[9:0];

	/* The value of the matrix column */
	logic [31:0] column_value_0, column_value_1;
	assign column_value_0 = data_b;

	/* The value of the vector at a given column */
	logic [31:0] vector_value_1;

	ROM mem(
		.address_a(column_idx_0),
		.address_b(),
		.clock(clk),
		.q_a(),
		.q_b(vector_value_1));

	register storage(
    .clk, .rst_l, 
    .en(stage0_en), 
    .clear(1'b0),
    .D(column_value_0),
    .Q(column_value_1)); 

	/* Components for 2nd multiplication stage */
	logic [63:0] mult_result_1;

	MULT multiplier (
		.dataa(column_value_1), // Matrix column value
		.datab(vector_value_1), // Vector column value
		.result(mult_result_1));

	/* Components for final storage */
	logic [63:0] accum_2;
	register accumulator(
		.clk, .rst_l, 
		.clear(done),
		.en(stage1_en),
		.D(mult_result_1 + accum_2),
		.Q(accum_2));

	/* Counter for checking when computation is done */
	counter_down COUNT(
		.clk,  .rst_l,
		.en(1'b1),
	 	.set(compute_start),        // Set the counter on the start of each row
	 	.clear(1'b0),
	 	// Set value to 1 larger
	 	.set_val(data_b + 1),    // Set the value to be the number of columns in the sparse row
	 	.count(column_count));
	register row_holder(
		.clk, .rst_l,
		.en(compute_start), // Hold the row number on start
		.clear(1'b0),
		.D(data_a),
		.Q(curr_row_num));


	/* Assign outputs */
	assign row_num = curr_row_num;
	assign done = (column_count == 0);




endmodule