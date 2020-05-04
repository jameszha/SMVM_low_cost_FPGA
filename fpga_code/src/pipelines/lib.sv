`default_nettype none

/**
 * Latches and stores values of WIDTH bits and initializes to RESET_VAL.
 *
 * This register uses an asynchronous active-low reset and a synchronous
 * active-high clear. Upon clear or reset, the value of the register becomes
 * RESET_VAL.
 *
 * Parameters:
 *  - WIDTH         The number of bits that the register holds.
 *  - RESET_VAL     The value that the register holds after a reset.
 *
 * Inputs:
 *  - clk           The clock to use for the register.
 *  - rst_l         An active-low asynchronous reset.
 *  - clear         An active-high synchronous reset.
 *  - en            Indicates whether or not to load the register.
 *  - D             The input to the register.
 *
 * Outputs:
 *  - Q             The latched output from the register.
 **/
module register
    (input  logic               clk, en, rst_l, clear,
     input  logic [31:0]   D,
     output logic [31:0]   Q);

     always_ff @(posedge clk, negedge rst_l) begin
         if (!rst_l)
             Q <= 0;
         else if (clear)
             Q <= 0;
         else if (en)
             Q <= D;
     end

endmodule:register