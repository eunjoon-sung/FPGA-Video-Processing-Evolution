# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.16-s062_1 on Wed Feb 25 03:33:59 KST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design Camera_capture

create_clock -name "p_clock" -period 41.66 -waveform {0.0 20.83} [get_ports p_clock]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports rst]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports vsync]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports href]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[7]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[6]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[5]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[4]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[3]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[2]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[1]}]
set_input_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {p_data[0]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[15]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[14]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[13]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[12]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[11]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[10]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[9]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[8]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[7]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[6]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[5]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[4]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[3]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[2]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[1]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {pixel_data[0]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports frame_done]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[9]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[8]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[7]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[6]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[5]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[4]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[3]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[2]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[1]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_x_count[0]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[8]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[7]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[6]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[5]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[4]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[3]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[2]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[1]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports {o_y_count[0]}]
set_output_delay -clock [get_clocks p_clock] -add_delay -max 2.0 [get_ports pixel_valid]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.5 [get_clocks p_clock]
set_clock_uncertainty -hold 0.5 [get_clocks p_clock]
