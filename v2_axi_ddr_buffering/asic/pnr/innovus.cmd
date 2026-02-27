# ==========================================================
# 1. 초기 디자인 로드 (Design Import)
# ==========================================================
set init_gnd_net VSS
set init_pwr_net VDD
set init_lef_file {../edu_lib/lef/gsclib045_tech.lef ../edu_lib/lef/gsclib045_macro.lef}
set init_verilog ../syn/outputs/AXI4_writer_netlist.v
set init_mmmc_file 20260227.view

init_design

# ==========================================================
# 2. Floorplan (면적 70%, 여백 10um, 정사각형)
# ==========================================================
floorPlan -site CoreSite -r 0.98949398777 0.699999 10.0 10.0 10.0 10.0

# 글로벌 전원망 논리적 연결 (물리적 배선 아님)
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -instanceBasename * -hierarchicalInstance {}
globalNetConnect VSS -type pgpin -pin VSS -instanceBasename * -hierarchicalInstance {}

# ==========================================================
# 3. Pin Editor (자동 정렬 배치)
# ==========================================================
# 1. [Left] 입력 포트 배치 (가로 방향인 Metal 2 사용)
editPin -side Left -layer 2 -pin {pclk clk_100Mhz rst mixed_data* pixel_valid frame_done FRAME_BASE_ADDR*} -spreadType center -spacing 2.0

# 2. [Right] AXI 출력 포트 배치 (가로 방향인 Metal 2 사용)
editPin -side Right -layer 2 -pin {AWVALID AWADDR* AWLEN* AWSIZE* AWBURST* AWCACHE* AWPROT* WVALID WDATA* WSTRB* WLAST BREADY} -spreadType center -spacing 2.0

# 3. [Top] AXI 응답 포트 및 상태 디버깅 핀 배치 (세로 방향인 Metal 3 사용)
editPin -side Top -layer 3 -pin {AWREADY WREADY BVALID BRESP* o_prog_full state* ADDR_OFFSET*} -spreadType center -spacing 2.0

# 화면 줌 피트
fit
