`timescale 1ns / 1ps

module tb_top_OV7670_system;

    // --- Inputs (FPGA 핀으로 들어가는 신호) ---
    reg sys_clk;      // 보드 메인 클럭 (50MHz or 100MHz)
    reg sys_rst_n;    // 보드 리셋 (Active Low)
    
    // 가짜 카메라 신호
    reg ov7670_pclk;
    reg ov7670_vsync;
    reg ov7670_href;
    reg [7:0] ov7670_data;

    // --- Outputs (FPGA 핀에서 나오는 신호) ---
    wire ov7670_xclk;
    wire ov7670_sioc;
    wire ov7670_siod;
    wire ov7670_pwdn;
    wire ov7670_reset;
    wire [3:0] led;

    // --- DUT (Top Module) 인스턴스 ---
    top_OV7670_system uut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .ov7670_pclk(ov7670_pclk),
        .ov7670_vsync(ov7670_vsync),
        .ov7670_href(ov7670_href),
        .ov7670_data(ov7670_data),
        .ov7670_xclk(ov7670_xclk),
        .ov7670_sioc(ov7670_sioc),
        .ov7670_siod(ov7670_siod),
        .ov7670_pwdn(ov7670_pwdn),
        .ov7670_reset(ov7670_reset),
        .led(led)
    );

    // 1. 클럭 생성
    // sys_clk: 50MHz (20ns 주기)
    always #10 sys_clk = ~sys_clk; 
    
    // pclk: 25MHz (40ns 주기) - 카메라가 보내주는 클럭
    always #20 ov7670_pclk = ~ov7670_pclk;

    // 2. 테스트 시나리오
    initial begin
        // 초기화
        sys_clk = 0;
        sys_rst_n = 0; // 리셋 누름
        ov7670_pclk = 0;
        ov7670_vsync = 0;
        ov7670_href = 0;
        ov7670_data = 0;

        $display("=== Simulation Start ===");
        
        // 리셋 해제
        #100;
        sys_rst_n = 1;
        #200;

        // ★ [치트키] I2C 설정 시간 건너뛰기 ★
        // Top 모듈 내부의 config_done 신호를 강제로 1로 만듦
        // (이게 없으면 시뮬레이션이 멈춘 것처럼 보임)
        force uut.config_done = 1; 
        $display("Note: Forced config_done = 1 to skip I2C sequence.");
        #100;

        // ----------------------------------------------
        // 카메라 동작 시뮬레이션 (프레임 전송 시작)
        // ----------------------------------------------
        
        // 1. 프레임 시작 (VSYNC High)
        $display("Step 1: Frame Start (VSYNC=1)");
        ov7670_vsync = 1; 
        #500; // V-Blanking (잠시 대기)

        // 2. 첫 번째 라인 전송 (Line 0)
        // 640 픽셀을 보내야 함 (테스트니까 10개만 보내봅시다)
        send_line_data(10); 

        // 3. 두 번째 라인 전송 (Line 1) - 홀수 줄 (버려져야 함)
        #200; // H-Blanking
        send_line_data(10);

        // 4. 세 번째 라인 전송 (Line 2) - 짝수 줄 (저장되어야 함)
        #200; // H-Blanking
        send_line_data(10);
        
        // 5. 프레임 종료
        #500;
        ov7670_vsync = 0;
        $display("Step 2: Frame End (VSYNC=0)");

        #500;
        $finish;
    end

    // --- 픽셀 데이터 전송 태스크 (편의용 함수) ---
    task send_line_data(input integer num_pixels);
        integer i;
        begin
            $display(">> Sending Line Data (%0d pixels)...", num_pixels);
            
            // 라인 시작 전 약간의 텀
            @(negedge ov7670_pclk); 
            ov7670_href = 1; // 데이터 유효 시작

            for (i = 0; i < num_pixels; i = i + 1) begin
                // 1 픽셀 = 2 사이클 (8bit + 8bit)
                
                // 첫 번째 바이트 (상위) -> 예: 0xA0 + i
                @(negedge ov7670_pclk);
                ov7670_data = 8'hA0 + i; 
                
                // 두 번째 바이트 (하위) -> 예: 0x0B
                @(negedge ov7670_pclk);
                ov7670_data = 8'h0B;     
                
                // 예상되는 조립 결과: 0xA(i)B
            end

            // 라인 종료
            @(negedge ov7670_pclk);
            ov7670_href = 0; 
            ov7670_data = 0;
        end
    endtask

endmodule
