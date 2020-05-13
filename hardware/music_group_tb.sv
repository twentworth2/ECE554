`timescale 1 ps / 1 ps

module music_group_tb();
  reg clk, reset;
  wire hlt, act;
  always begin
    #5 clk = ~clk;
  end
  // top level module
  DE1_soc_musicGroup iDUT(.clk(clk), .reset(reset), .act(act), .hlt(hlt));
  
  initial begin
    clk = 1'b0;
    reset = 1'b0;

    #100;
    reset = 1'b1;
    @(posedge act);
    #100;

    #5000;
    $stop;
  end

endmodule
