// Date Created: March 5, 2020
// Date Modified: March 5, 2020
// Authors:  Alex Jarnutowski, 
// Summary: This is our top-level module for our project. We will instantiate
// our processor and our other modules here
//
module DE1_soc_musicGroup(clk, reset, act, hlt);
  input clk, reset;
  
  wire[15:0] pc;
  output hlt;
  output act;
  wire[6:0] octaves;
  wire octaves_en;

  APU apu1(.clk(clk), .rst_n(reset), .octaves(octaves), .octaves_en(octaves_en), .act(act));
  cpu CPU1(.clk(clk), .rst_n(reset), .octaves(octaves), .octaves_en(octaves_en), .pc(pc), .hlt(hlt));
  





endmodule
