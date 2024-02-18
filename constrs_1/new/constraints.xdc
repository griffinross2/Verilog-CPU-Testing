create_clock -period 100.000 -name clk -waveform {0.000 50.000} [get_ports clk]
set_input_jitter clk 0.500
