`default_nettype none

module tb();
	logic clk, rst_l;

	initial begin 
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin 
		#10000
		$display("@%0t: Error timeout!", $time);
		$finish;
	end

	initial begin
		rst_l = 1;
		rst_l <= 0;
		rst_l <= #5 1;
	end

	logic [31:0] data_a, data_b;
	logic compute_start;

	logic [31:0] accum;
	logic [31:0] row_num;
	logic done;


	row_accumulator dut(.*);

	initial begin
		@(posedge clk);
		@(posedge clk);
	end

endmodule : tb