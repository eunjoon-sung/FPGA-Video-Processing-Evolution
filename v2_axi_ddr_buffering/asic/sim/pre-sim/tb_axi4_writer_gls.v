`timescale 1ns / 1ps

module tb_axi4_writer_gls;

    // 파라미터 설정
    parameter AXI_ADDR_WIDTH = 32;
    parameter AXI_DATA_WIDTH = 64;

    // 입력 레지스터 선언
    reg pclk;
    reg clk_100Mhz;
    reg rst;
    reg [15:0] mixed_data;
    reg pixel_valid;
    reg frame_done;
    reg [31:0] FRAME_BASE_ADDR;
    
    // AXI Slave 응답용 레지스터
    reg AWREADY;
    reg WREADY;
    reg BVALID;
    reg [1:0] BRESP;

    // 출력 와이어 선언
    wire [AXI_ADDR_WIDTH-1:0] AWADDR;
    wire AWVALID;
    wire [7:0] AWLEN;
    wire [2:0] AWSIZE;
    wire [1:0] AWBURST;
    wire [3:0] AWCACHE;
    wire [2:0] AWPROT;
    wire [AXI_DATA_WIDTH-1:0] WDATA;
    wire WVALID;
    wire WLAST;
    wire [7:0] WSTRB;
    wire BREADY;
    wire o_prog_full;
    wire [1:0] state;
    wire [AXI_ADDR_WIDTH-1:0] ADDR_OFFSET;

    // ==========================================
    // 1. 클럭 생성 (비동기 도메인)
    // ==========================================
    initial begin
        pclk = 0;
        forever #20.83 pclk = ~pclk; // 24MHz (주기 41.66ns)
    end

    initial begin
        clk_100Mhz = 0;
        forever #5.0 clk_100Mhz = ~clk_100Mhz; // 100MHz (주기 10.0ns)
    end

    // ==========================================
    // 2. DUT (Device Under Test) 인스턴스화
    // 합성된 넷리스트 모듈을 연결합니다.
    // ==========================================
    AXI4_writer #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) uut (
        .pclk(pclk),
        .clk_100Mhz(clk_100Mhz),
        .rst(rst),
        .mixed_data(mixed_data),
        .pixel_valid(pixel_valid),
        .frame_done(frame_done),
        .FRAME_BASE_ADDR(FRAME_BASE_ADDR),
        .AWADDR(AWADDR), .AWVALID(AWVALID), .AWREADY(AWREADY),
        .AWLEN(AWLEN), .AWSIZE(AWSIZE), .AWBURST(AWBURST),
        .AWCACHE(AWCACHE), .AWPROT(AWPROT),
        .WDATA(WDATA), .WVALID(WVALID), .WREADY(WREADY),
        .WLAST(WLAST), .WSTRB(WSTRB),
        .BVALID(BVALID), .BREADY(BREADY), .BRESP(BRESP),
        .o_prog_full(o_prog_full),
        .state(state),
        .ADDR_OFFSET(ADDR_OFFSET)
    );

    // ==========================================
    // 3. SDF Annotation (GLS의 핵심)
    // ==========================================

     initial begin
      // 합성 툴이 뽑아낸 SDF 파일을 읽어 게이트 딜레이를 주입합니다.
      //$sdf_annotate("SDF경로", 타겟인스턴스, [설정파일], "로그파일", "MTM조건");
         
        $sdf_annotate(
            "../../syn/outputs/AXI4_writer_sdf.sdf",  // 1. SDF 파일 경로
            tb_axi4_writer_gls.uut,         // 2. TB 이름(tb_axi_writer_gls) 내부의 DUT 이름(uut)
            ,                              // 3. Config (생략)
            "sdf_axi4_writer.log",          // 4. Annotation 에러/경고 기록용 로그
            "MAXIMUM"                      // 5. 최악의 조건(Setup 딜레이) 테스트
        );
     end
    
    /* sdf 파일 경로를 알려줌.
    - sdf 파일을 tb_simple_spi.u1에 적용시키는 것임 (여기서 u1은 module 이름),
    - 세번째는 보통 매핑 정보가 들어가는데 기본적으로 같으므로 비워놓음.
    - 네번째 log file 이름
    - "MAXIMUM"은 공정상에서 발생할 수 있는 가장 최악의 조건을 설정한다는 뜻 
    ; delay 값이 최대로 늘어나게 되면서 timing 조건(setup, hold time)도 달라지게 되기 때문
    */


    // ==========================================
    // 4. 테스트 시나리오 (Stimulus)
    // ==========================================
    initial begin
        // 초기화
        rst = 1;
        mixed_data = 0;
        pixel_valid = 0;
        frame_done = 0;
        FRAME_BASE_ADDR = 32'h1000_0000;
        
        // AXI Slave (DDR 메모리) 가상 응답 초기화
        AWREADY = 0;
        WREADY = 0;
        BVALID = 0;
        BRESP = 2'b00; // OKAY

        // 파형 덤프 (필요 시 주석 해제)
        // $dumpfile("axi_gls.vcd");
        // $dumpvars(0, tb_axi_writer_gls);

        #100;
        rst = 0; // 리셋 해제
        
        // 시나리오 1: 카메라 데이터 유입 시작 (pclk 기준)
        #50;
        repeat(30) begin
            @(posedge pclk);
            mixed_data = mixed_data + 1;
            pixel_valid = 1;
        end
        @(posedge pclk);
        pixel_valid = 0; // 데이터 유입 중단

        // 시나리오 2: AXI Master 상태 머신 동작 확인 및 Slave 응답 (clk_100Mhz 기준)
        // AWVALID가 뜨면 AWREADY로 응답
        wait(AWVALID == 1'b1);
        @(posedge clk_100Mhz);
        AWREADY = 1;
        @(posedge clk_100Mhz);
        AWREADY = 0;

        // WVALID가 뜨면 데이터를 받아줌 (WREADY)
        wait(WVALID == 1'b1);
        @(posedge clk_100Mhz);
        WREADY = 1;
        
        // WLAST 신호가 뜰 때까지 대기
        wait(WLAST == 1'b1);
        @(posedge clk_100Mhz);
        WREADY = 0;

        // BVALID 응답 (Write Response)
        #20;
        @(posedge clk_100Mhz);
        BVALID = 1;
        @(posedge clk_100Mhz);
        BVALID = 0;

        #200;
        $display("=== GLS Simulation Completed ===");
        $finish;
    end

endmodule
