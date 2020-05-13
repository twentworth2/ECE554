module SPU_window(
    input clk,
    input en, // Allow a read
    input [10:0] sig_num, // Current index of audio read
    output reg signed [15:0] hann_coeff // 16 bit Hann window factor (scaled by 2^16)
);

reg [15:0] vals [0:2047];

initial begin
    $readmemb("hann_window.txt", vals);
end

always @(posedge clk) begin
    if (en)
        hann_coeff <= vals[sig_num];
    else
        hann_coeff <= 16'h0;
end

endmodule