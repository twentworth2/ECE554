module istft_tb();

reg clk, rst_n, full_set;
reg [27:0] coeff_mon;

wire samp_ready_mon;
wire signed [15:0] aud_out_mon;
reg signed [15:0] aud_out_valid_mon;

always #10 clk = ~clk;
            
istft iISTFT(.clk(clk), .rst_n(rst_n), .full(full_set), .ready(samp_ready_mon),
            .all_done(), .coeff_one(coeff_mon), .aud_out(aud_out_mon));

integer f; // File to store results

initial begin

    // Set up testing environment
    rst_n = 1'b0;
    clk = 1'b0;
    
    f = $fopen("istft_test_samp.out");
    
    //////////////// Get a sinusoid out /////////////
    $fwrite(f, "---- ISTFT samples are below ----\n");
    
    repeat (2) @(posedge clk);
    
    rst_n = 1'b1;
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    for (int i = 1; i <= 180; i++) begin
        if (i == 1)
            coeff_mon = 28'd838_8608;
        /*else if (i == 20)
            coeff_mon = 28'd100_8731;*/
        else
            coeff_mon = 28'h0;
        @(posedge clk);
    end
    
        // Print out each coefficient to the file
    for (int i = 1; i <= 2047; i++) begin
        @(posedge samp_ready_mon);
        $fwrite(f, "I [%d] :: %d\n", i, aud_out_mon);
        aud_out_valid_mon = aud_out_mon;
    end
    
    $fclose(f);
    $stop;
    
end

endmodule