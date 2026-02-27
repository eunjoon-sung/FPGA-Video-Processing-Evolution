lock Definitions (클럭 정의)
# ==========================================
# pclk (카메라 클럭): 약 24MHz -> 41.66ns
create_clock -name pclk -period 41.66 [get_ports pclk]

# clk_100Mhz (AXI 시스템 클럭): 100MHz -> 10.0ns
create_clock -name clk_100Mhz -period 10.00 [get_ports clk_100Mhz]

# 클럭 불확실성 (Jitter/Margin 부여)
set_clock_uncertainty 0.5 [get_clocks pclk]
set_clock_uncertainty 0.5 [get_clocks clk_100Mhz]

# ==========================================
# 2. Clock Domain Crossing (비동기 클럭 그룹 설정) - [핵심]
# ==========================================
# 두 클럭 간의 타이밍 경로는 검사하지 않도록(False Path) 툴에 지시합니다.
set_clock_groups -asynchronous -group pclk -group clk_100Mhz

# ==========================================
# 3. Input Delays
# ==========================================
# pclk 도메인 입력 (카메라 쪽에서 들어오는 데이터)
set_input_delay -max 2.0 -clock pclk [get_ports {rst mixed_data[*] pixel_valid frame_done}]

# clk_100Mhz 도메인 입력 (AXI Slave/Interconnect 쪽에서 들어오는 신호)
set_input_delay -max 1.0 -clock clk_100Mhz [get_ports {FRAME_BASE_ADDR[*] AWREADY WREADY BVALID BRESP[*]}]

# ==========================================
# 4. Output Delays
# ==========================================
# clk_100Mhz 도메인 출력 (AXI Bus로 나가는 신호들)
set_output_delay -max 1.0 -clock clk_100Mhz [get_ports {AWADDR[*] AWVALID AWLEN[*] AWSIZE[*] AWBURST[*] AWCACHE[*] AWPROT[*] WDATA[*] WVALID WLAST WSTRB[*] BREADY o_prog_full state[*] ADDR_OFFSET[*]}#]
