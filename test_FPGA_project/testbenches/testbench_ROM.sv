`default_nettype none

module tb();
	logic clk, rst_l;

	initial begin 
		clock = 0;
		forever #5 clock = ~clock;
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

	logic [6:0] address_a, address_b;
    logic [7:0] q_a, q_b;
    romB_128x1 RB(
    .address_a(address_a),
    .address_b(address_b),
    .clock(clk),
    .q_a(q_a),
    .q_b(q_b));

    always_ff @(posedge clk, negedge rst_l) begin : proc_
    	if(~rst_l) begin
    		 address_a <= 0;
    	end else begin
    		 address_a <= address_a + 1;
    	end
    end

endmodule : tb