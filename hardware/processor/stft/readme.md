# STFT Info
Waveform input files (put into stft_tb.sv):
- random_sound.txt
- signed_64_sine.txt
- signed_512_sine.txt
- signed_double_sine.txt
- 512_sine.txt
- 1024_sine.txt

Modules to load precomputed values:
- stft_cos.v
  - rough_cos_table.txt
- stft_sin.v
  - rough_sin_table.txt
- SPU_window.v
  - hann_window.txt

Main modules:
- stft.v
- istft.v
- transformer.v
- sqrt.v

- SPU.v

- OCT_n1.v
- OCT_n2.v
- OCT_n3.v
- OCT_p1.v
- OCT_p2.v
- OCT_p3.v

Testbenches:
- stft_tb.sv
- istft_tb.sv
- OCT_tb.sv
- SPU_tb.sv

Buffers and caches:
- master_coeff_buf.v
- slave_coeff_buf.v
- FIFO.v
