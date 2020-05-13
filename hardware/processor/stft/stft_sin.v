module stft_sin(
    input clk,
    input en, // Allow a read
    input [9:0] deg_half, // Fixed-point angle in degrees,
                           // rounded to the nearest half
    output reg signed [15:0] sin_2to14 // 16 bit sine value (must divide by 2^14)
);

reg [15:0] vals [0:720];

initial begin
    $readmemb("rough_sin_table.txt", vals);
end

always @(posedge clk) begin
    if (en)
        sin_2to14 <= vals[deg_half];
    else
        sin_2to14 <= 16'h0;
end

endmodule