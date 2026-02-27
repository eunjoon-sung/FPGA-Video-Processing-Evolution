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
# 2. Floorplan 수정 (면적 확보)
# ==========================================================
# 기존: -r 0.989... 0.7 (70% 밀도)
# 수정: 밀도 목표를 0.55(55%)로 낮춰서 전체 면적을 약 15% 이상 넓힙니다.
floorPlan -site CoreSite -r 1.0 0.55 15.0 15.0 15.0 15.0

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

# ==========================================================
# 10. Post-CTS 타이밍 분석 (Skew 반영)
# ==========================================================
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -outDir reports/postCTS

# ==========================================================
# 11. 최종 신호선 배선 (Route Design)
# ==========================================================
# 가상의 선을 지우고 실제 NanoRoute 엔진으로 물리적 배선 실행
routeDesign -globalDetail

# 1. 칩 내부의 공정 오차(OCV)를 계산에 반영하도록 설정
setAnalysisMode -analysisType onChipVariation

# 2. 클럭이 갈라졌다가 다시 만나는 지점의 중복 오차(Pessimism) 제거
setAnalysisMode -cppr both

# 배선 후 최종 타이밍 분석 (Setup & Hold)
timeDesign -postRoute
timeDesign -postRoute -hold

# Hold time - slack 뜸
# ==========================================================
# 12. Post-Route 홀드 타임 최적화 (Hold Fixing)
# ==========================================================
# OCV 모드에서 Hold 위반을 잡기 위해 버퍼를 추가로 삽입

optDesign -postRoute -hold
timeDesign -postRoute -hold


# 2. 만약 위 명령어가 또 안 된다면, 툴이 허용하는 방식으로 강제 업데이트
set_interactive_constraint_modes [all_constraint_modes]
set_clock_uncertainty -hold 0.1 [get_clocks *]
set_interactive_constraint_modes {}

# 툴에게 수단과 방법을 가리지 말고(Effort High) 홀드를 잡으라고 지시
setOptMode -effort high -fixHoldAllowOverlap true

# 정석적인 Post-Route Hold 최적화 실행
optDesign -postRoute -hold

# ==========================================================
# 13. Filler insert
# ==========================================================
# 1. 라이브러리에 있는 Filler Cell들을 빈 공간에 채워넣습니다.
# (라이브러리에 따라 FILL1, FILL2, FILLER 등으로 이름이 다를 수 있으니 확인 필요)

addFiller -cell {FILL1 FILL2 FILL4 FILL8 FILL16 FILL32 FILL64} -prefix FILL

# ==========================================================
# 14. Verify (DRC / LVS)
# ==========================================================
# 1. DRC (Design Rule Check) - 선 간격, 두께 등 물리적 규칙 검사
verify_drc

# 2. Connectivity (LVS) - 회로도와 실제 배선이 일치하는지, 끊어진 곳은 없는지 검사
verify_connectivity -type all

# 3. Geometry - 부품이 겹치거나 경계를 벗어난 곳이 없는지 확인
verify_geometry
