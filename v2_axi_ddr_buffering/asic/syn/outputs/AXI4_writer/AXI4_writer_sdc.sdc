# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.16-s062_1 on Sat Feb 28 05:43:25 KST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design AXI4_writer

create_clock -name "pclk" -period 41.66 -waveform {0.0 20.83} [get_ports pclk]
create_clock -name "clk_100Mhz" -period 10.0 -waveform {0.0 5.0} [get_ports clk_100Mhz]
set_clock_groups -name "clock_groups_pclk_to_clk_100Mhz" -asynchronous -group [get_clocks pclk] -group [get_clocks clk_100Mhz]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports rst]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[15]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[14]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[13]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[12]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[11]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[10]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[9]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[8]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[7]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[6]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[5]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[4]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[3]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[2]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[1]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports {mixed_data[0]}]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports pixel_valid]
set_input_delay -clock [get_clocks pclk] -add_delay -max 2.0 [get_ports frame_done]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[31]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[30]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[29]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[28]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[27]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[26]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[25]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[24]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[23]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[22]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[21]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[20]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[19]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[18]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[17]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[16]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[15]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[14]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[13]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[12]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[11]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[10]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[9]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[8]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[7]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[6]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[5]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[4]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[3]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[2]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[1]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {FRAME_BASE_ADDR[0]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports AWREADY]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports WREADY]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports BVALID]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {BRESP[1]}]
set_input_delay -clock [get_clocks clk_100Mhz] -add_delay -max 1.0 [get_ports {BRESP[0]}]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.5 [get_clocks pclk]
set_clock_uncertainty -hold 0.5 [get_clocks pclk]
set_clock_uncertainty -setup 0.5 [get_clocks clk_100Mhz]
set_clock_uncertainty -hold 0.5 [get_clocks clk_100Mhz]
