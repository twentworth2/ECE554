module BitCell(clk, rst, D, WriteEnable, ReadEnable1, ReadEnable2, Bitline1, Bitline2); 
input clk, rst, D, WriteEnable, ReadEnable1, ReadEnable2; 
inout Bitline1, Bitline2;

wire q;

assign Bitline1 = (ReadEnable1) ? q : 1'bz;
assign Bitline2 = (ReadEnable2) ? q : 1'bz;

dff ff(.q(q), .d(D), .wen(WriteEnable), .clk(clk), .rst(rst)); 

endmodule


