  
`default_nettype none

module tb();
	logic clk, rst_l;

	initial begin 
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin 
		#100000
		$display("@%0t: Error timeout!", $time);
		$finish;
	end

	initial begin
		rst_l = 1;
		rst_l <= 0;
		rst_l <= #5 1;
	end

	logic [3:0][31:0] values;
    logic [3:0][31:0] col_id;
    logic [3:0][31:0] row_id;
    logic rdy;

    logic [7:0][31:0]           accum;
    logic done;


	multiplier1 #(4, 8) dut(.*);

	initial begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		values <= 128'h0;
		col_id <= 128'h0;
		row_id <= 128'h0;
		rdy <= 0;
		@(posedge clk);
		values <= 128'h0;
		col_id <= 128'h0;
		row_id <= 128'h0;
		rdy <= 0;
		@(posedge clk);
		values <= 128'h0;
		col_id <= 128'h0;
		row_id <= 128'h0;
		rdy <= 0;
		@(posedge clk);
		values <= {32'h1, 32'h2, 32'h3, 32'h4};
		row_id <= {32'h1, 32'h2, 32'h3, 32'h4};
		col_id <= {32'h1, 32'h2, 32'h3, 32'h4};
		rdy <= 1'b1;
		// @(posedge clk);
		// values <= {32'h5, 32'h6, 32'h7, 32'h8};
		// row_id <= {32'h1, 32'h2, 32'h3, 32'h4};
		// col_id <= {32'h5, 32'h6, 32'h7, 32'h8};
		// rdy <= 1'b1;
		// @(posedge clk);
		// values <= {32'h9, 32'ha, 32'hb, 32'hc};
		// row_id <= {32'd128, 32'd128, 32'd128, 32'd127};
		// col_id <= {32'h9, 32'ha, 32'hb, 32'hc};
		// rdy <= 1'b1;
		// @(posedge clk)
		// values <= {32'h1, 32'h2, 32'h3, 32'h4};
		// row_id <= {32'd128, 32'd128, 32'd128, 32'd128};
		// col_id <= {32'h1, 32'h2, 32'h3, 32'h4};
		// rdy <= 1'b0;
		// @(posedge clk);
		@(posedge clk);
		values <= {32'h5, 32'h6, 32'h7, 32'h8};
		row_id <= {32'h5, 32'h6, 32'h7, 32'h8};
		col_id <= {32'h5, 32'h6, 32'h7, 32'h8};
		rdy <= 1'b1;
		@(posedge clk);
		values <= {32'h0, 32'h0, 32'h0, 32'h0};
		row_id <= {32'd128, 32'd128, 32'd128, 32'd128};
		col_id <= {32'h0, 32'h0, 32'h0, 32'h0};
		rdy <= 1'b0;
		@(posedge clk);
		values <= {32'h0, 32'h0, 32'h0, 32'h0};
		row_id <= {32'd128, 32'd128, 32'd128, 32'd128};
		col_id <= {32'h0, 32'h0, 32'h0, 32'h0};
		rdy <= 1'b0;
		@(posedge clk);
		values <= {32'h1, 32'h2, 32'h3, 32'h4};
		row_id <= {32'd1, 32'd2, 32'd3, 32'd4};
		col_id <= {32'h1, 32'h2, 32'h3, 32'h4};
		rdy <= 1'b0;
		@(posedge clk);

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		values <= {32'h8, 32'h8, 32'h8, 32'h8};
		row_id <= {32'd8, 32'd8, 32'd8, 32'd8};
		col_id <= {32'h8, 32'h8, 32'h8, 32'h8};
		rdy <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		$finish;
	end

	always_ff @(posedge clk or negedge rst_l) begin : proc_
		if (rst_l) begin
			$display("%t", $time);
			$display("values %h %h %h %h", values[3], values[2], values[1], values[0]);
			$display("col_id %h %h %h %h", col_id[3], col_id[2], col_id[1], col_id[0]);
			$display("row_id %h %h %h %h", row_id[3], row_id[2], row_id[1], row_id[0]);
			$display("ready %b", rdy);

			$display("state %s", dut.state);
			$display("address0 %h", dut.mem0.address_a);
			$display("vector_values %h", dut.vector_values);
			$display("matrix values stored %h", dut.matrix_values_stored1);
			$display("mult values %h", dut.mult_values);

			$display("row0: %h\n", accum[0]);
			$display("row1: %h\n", accum[1]);
			$display("row2: %h\n", accum[2]);
			$display("row3: %h\n", accum[3]);
			$display("row4: %h\n", accum[4]);
			$display("row126: %h\n", accum[126]);
			$display("row127: %h\n", accum[127]);

			$display("done %b", done);
		end

	end



endmodule : tb