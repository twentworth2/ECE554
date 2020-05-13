module stft_tb();

reg clk, rst_n, full_set;
wire ready_mon, done_mon;

reg signed [15:0] datum_set;
wire [27:0] coeff_mon;

wire slave_full_mon;
wire slave_read_sig_mon;
wire [27:0] slave_coeff_mon;

wire master_read_sig_mon;
wire [27:0] master_coeff_mon;

wire samp_ready_mon;
wire [15:0] aud_out_mon;

//reg [15:0] aud_out_valid_mon;

reg signed [15:0] sine_64 [0:2047];
reg signed [15:0] sine_512 [0:2047];

always #10 clk = ~clk;

wire [27:0] coeff_istft1, coeff_istft2, coeff_istft3;

stft iSTFT(.clk(clk), .rst_n(rst_n), .full(full_set), .done(done_mon),
            .ready(ready_mon), .istft_ack(1'b0), .datum(datum_set), .coeff(coeff_mon), .all_done());
  
slave_coeff_buf iSLV(.clk(clk), .rst_n(rst_n), .ready(ready_mon), .coeff(coeff_mon), .slave_full(slave_full_mon),
            .slave_coeff(slave_coeff_mon), .read_sig(slave_read_sig_mon));
  
master_coeff_buf iMST(.clk(clk), .rst_n(rst_n), .slave_full(slave_full_mon), .slave_coeff(slave_coeff_mon),
            .read_sig(master_read_sig_mon), .master_coeff(master_coeff_mon));

transformer iTRF(.en(slave_read_sig_mon), .slave_coeff(slave_coeff_mon), .master_coeff(master_coeff_mon),
            .quarter(coeff_istft1), .half(coeff_istft2), .three_quarters(coeff_istft3));
            
istft iISTFT(.clk(clk), .rst_n(rst_n), .full(slave_read_sig_mon), .ready(samp_ready_mon),
            .all_done(), .coeff_one(coeff_istft2/*slave_coeff_mon*/), .aud_out(aud_out_mon));

integer f; // File to store results

initial begin

    // Read file with sound sample
    
    $readmemb("signed_double_sine.txt", sine_64); // This one is in the master buffer
    $readmemb("signed_double_sine.txt", sine_512); // This one is in the slave buffer

    // Set up testing environment
    rst_n = 1'b0;
    clk = 1'b0;
    
    f = $fopen("stft_test_coeffs.out");
    
    /////////// First set of coeffs /////////////
    
    $fwrite(f, "---- STFT coefficients (1) are below ----\n");
    
    repeat (2) @(posedge clk);
    
    rst_n = 1'b1;
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform (for now, just constant)
    for (int i = 0; i < 2048; i++) begin
        //datum_set = 16'h7FFF;
        datum_set = sine_64[i];
        @(posedge clk);
    end
    
    // Wait for STFT unit to ack
    @(posedge done_mon);
    
    // Print out each coefficient to the file
    for (int i = 1; i <= 180; i++) begin
        @(posedge ready_mon);
        $fwrite(f, "<1> [%d] :: %d\n", i, coeff_mon);
    end
    
     /////////// Second set of coeffs /////////////
    
    $fwrite(f, "---- STFT coefficients (2) are below ----\n");
    
    repeat (2048) @(posedge clk);
    
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform (for now, just constant)
    for (int i = 0; i < 2048; i++) begin
        //datum_set = 16'h7FFF;
        datum_set = sine_512[i];
        @(posedge clk);
    end
    
    // Wait for STFT unit to ack
    @(posedge done_mon);
    
    // Print out each coefficient to the file
    for (int i = 1; i <= 180; i++) begin
        @(posedge ready_mon);
        $fwrite(f, "<2> [%d] :: %d\n", i, coeff_mon);
    end
    
    
    $fwrite(f, "---- Slave/Master buffer coeffs ----\n");
    // See what coeffs the slave buffer puts out
    
    @(posedge slave_read_sig_mon);
    
    for (int i = 1; i <= 180; i++) begin
        @(posedge clk);
        $fwrite(f, "<S> [%d] :: %d\n", i, slave_coeff_mon);
        $fwrite(f, "<M> [%d] :: %d\n", i, master_coeff_mon);
    end
    
    @(negedge slave_read_sig_mon);
    
    //////////////// Get the original signal back out /////////////
    //$fwrite(f, "---- ISTFT samples are below ----\n");
    
        // Print out each coefficient to the file
    for (int i = 1; i <= 2047; i++) begin
        @(posedge samp_ready_mon);
        //$fwrite(f, "I [%d] :: %d\n", i, aud_out_mon);
        //aud_out_valid_mon = aud_out_mon;
    end
    
    $fclose(f);
    $stop;
    
end

endmodule