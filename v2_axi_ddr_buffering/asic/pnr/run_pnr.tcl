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
# 3. Pin Editor (자동 정렬 배치 - 간격 조정 및 배치 모드 적용)
# ==========================================================
# 툴 권장사항: 핀 배치를 한꺼번에 처리하여 속도와 정확도를 높임
setPinAssignMode -pinEditInBatch true

# [Left] (핀 개수가 적으므로 간격 2.0 유지 가능)
editPin -side Left -layer 2 -pin {pclk clk_100Mhz rst mixed_data* pixel_valid frame_done FRAME_BASE_ADDR*} -spreadType center -spacing 2.0

# [Right] (핀이 128개로 너무 많으므로 간격 1.5로 축소)
editPin -side Right -layer 2 -pin {AWVALID AWADDR* AWLEN* AWSIZE* AWBURST* AWCACHE* AWPROT* WVALID WDATA* WSTRB* WLAST BREADY} -spreadType center -spacing 1.5

# [Top]
editPin -side Top -layer 3 -pin {AWREADY WREADY BVALID BRESP* o_prog_full state* ADDR_OFFSET*} -spreadType center -spacing 2.0

setPinAssignMode -pinEditInBatch false
fit

# ==========================================================
# 4. 전원망 링 설계 (Add Ring)
# ==========================================================
addRing -nets {VDD VSS} \
        -type core_rings \
        -follow core \
        -layer {top Metal6 bottom Metal6 left Metal5 right Metal5} \
        -width 2.0 \
        -spacing 1.0 \
        -offset 2.0
# 화면 줌 피트
fit

# ==========================================================
# 5. 내부 전원망 설계 (Add Stripe)
# ==========================================================
addStripe -nets {VDD VSS} \
          -layer Metal5 \
          -direction vertical \
          -width 1.0 \
          -spacing 0.5 \
          -set_to_set_distance 20.0 \
          -start_from left
# 화면 줌 피트
fit

# ==========================================================
# 6. 스탠다드 셀 전원 레일 및 Via 연결 (SRoute)
# ==========================================================
sroute -connect { corePin floatingStripe } \
       -layerChangeRange { Metal1 Metal6 } \
       -blockPinTarget { nearestTarget } \
       -corePinTarget { firstAfterRowEnd } \
       -allowJogging 1 \
       -crossoverViaLayerRange { Metal1 Metal6 } \
       -nets { VDD VSS } \
       -allowLayerChange 1 \
       -targetViaLayerRange { Metal1 Metal6 }
# ==========================================================
# 7. 부품 배치 (Placement)
# ==========================================================
setPlaceMode -timingDriven true -reorderScan false
placeDesign

# ==========================================================
# 8. Pre-CTS 타이밍 분석 (Setup Check)
# ==========================================================
# 가상 배선을 기반으로 타이밍 리포트 생성
timeDesign -preCTS -idealClock -pathReports -drvReports -slackReports -numPaths 50 -outDir reports/preCTS

# ==========================================================
# 9. 클럭 트리 합성 (CTS) 실행
# ==========================================================
# 클럭 트리 사양 자동 생성 및 합성
create_ccopt_clock_tree_spec
ccopt_design




