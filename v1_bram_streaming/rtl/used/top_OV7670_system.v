`timescale 1ns / 1ps

module top_OV7670_system(
    input wire sys_clk,       // 보드 기본 클럭 (예: 50MHz or 100MHz)
    input wire sys_rst_n,     // 보드 리셋 버튼 (Active Low 가정)
    
    // OV7670 Camera Interface
    input wire ov7670_pclk,
    input wire ov7670_vsync,
    input wire ov7670_href,
    input wire [7:0] ov7670_data,
    
    output wire ov7670_xclk,  // 카메라에 공급할 24~25MHz 클럭 (MCLK)
    output wire ov7670_sioc,  // I2C Clock
    inout  wire ov7670_siod,  // I2C Data
    output wire ov7670_pwdn,  // Power Down (0)
    output wire ov7670_reset, // Reset (1)
    
    // --- Debug LED (옵션) ---
    output wire [3:0] led
    );
    
    // ILA 파형
    ila_0 ila(
        .probe0(ov7670_pclk),
        .probe1(ov7670_vsync),
        .probe2(ov7670_href),
        .probe3(ov7670_data),
        .probe4(config_done),
        .probe5(w_cam_valid),
        .clk(sys_clk),
        .probe6(w_frame_done)
    );

    // 1. 시스템 리셋 처리 (Active Low -> Active High 변환 등)
    wire rst = ~sys_rst_n; 
    
    // 2. Clock Wizard (25MHz 생성)
    // 50MHz를 받아서 25MHz를 만듦.
    wire clk_25Mhz; 
    wire locked; // PLL 락 신호
    
    clk_wiz_0 u_clock_gen (
        .clk_out1(clk_25Mhz),     // 25MHz for Logic & Camera XCLK
        .reset(rst),
        .locked(locked),
        .clk_in1(sys_clk)
    );
    
    // 카메라 기본 신호 연결
    assign ov7670_xclk = clk_25Mhz; // 카메라에게 MCLK 공급
    assign ov7670_pwdn = 0;       // 항상 켜짐
    assign ov7670_reset = 1;      // (주의: 회로도에 따라 0일수도 1일수도 있음. 보통 1=Reset이면 0이어야 함)
    
    // -------------------------------------------------------
    // 3. Camera Configuration (I2C 설정)
    // -------------------------------------------------------
    wire config_done;
    
    // Camera_configure 연결
    Camera_configure #(.CLK_FREQ(25000000)) u_config (
        .rst(!locked),      // 락이 풀리면 리셋 해제 (Active High면 !locked, Low면 locked)
        .clk(clk_25Mhz),      // [핵심] 위에서 만든 25MHz를 넣어줌!
        .start(1'b1),
        .sioc(ov7670_sioc),
        .siod(ov7670_siod),
        .done(config_done)
    );

    // -------------------------------------------------------
    // 4. Data Capture Pipeline
    // -------------------------------------------------------
    
    // (A) Camera_read -> FIFO
    wire [11:0] w_cam_data;
    wire w_cam_valid;
    wire w_frame_done;
    
    Camera_read u_cam_read (
        .rst(!locked),   // 설정이 끝나면 동작 시작
        .p_clock(ov7670_pclk),
        .vsync(ov7670_vsync),
        .href(ov7670_href),
        .p_data(ov7670_data),
        .pixel_data(w_cam_data),
        .pixel_valid(w_cam_valid),
        .frame_done(w_frame_done)
    );
    
    // (B) FIFO (Async)
    wire [11:0] w_fifo_out;
    wire w_fifo_empty;
    wire w_fifo_rd_en;
    wire w_fifo_full; // 디버깅용
    
    fifo_camera u_fifo (
        .rst(!locked), // *** !config_done 하면 pulse 한번만 뛰고 다시 막혀버림
        .wr_clk(ov7670_pclk),     // 쓰기: PCLK
        .din(w_cam_data),
        .wr_en(w_cam_valid),
        .full(w_fifo_full),
        .rd_clk(clk_25Mhz),         // 읽기: SYS_CLK (25MHz)
        .dout(w_fifo_out),
        .rd_en(w_fifo_rd_en),
        .empty(w_fifo_empty)
    );
    
    // (C) Downscaler
    wire [11:0] w_scaled_data;
    wire w_scaled_valid;
    
    Downscaling u_downscaler (
        .clk(clk_25Mhz),
        .rst(!locked),
        .fifo_dout(w_fifo_out),
        .fifo_empty(w_fifo_empty),
        .fifo_rd_en(w_fifo_rd_en),
        .scaled_data(w_scaled_data),
        .scaled_valid(w_scaled_valid),
        .href_in(ov7670_href)
    );
    
    // (D) SRAM Writer
    wire [16:0] w_bram_addr;
    wire [11:0] w_bram_data;
    wire w_bram_we;
    
    SRAM_writer u_writer (
        .clk(clk_25Mhz),
        .rst(!locked),
        .scaled_data(w_scaled_data),
        .scaled_valid(w_scaled_valid),
        .bram_addr(w_bram_addr),
        .bram_data(w_bram_data),
        .bram_we(w_bram_we)
    );
    
    // (E) BRAM (Storage)
    // Port A: Write Only (Camera)
    // Port B: Read Only (HDMI - 나중에 연결)
    
    blk_mem_gen_0 u_buffer (
        .ena(1'b1),
        .clka(clk_25Mhz),
        .wea(w_bram_we),       // IP 설정에 따라 [0:0] 벡터일 수도 있음
        .addra(w_bram_addr),
        .dina(w_bram_data),
        
        // Port B는 나중에 HDMI 모듈 연결할 곳 !
        // Port B: 가짜 읽기 연결
        .clkb(clk_25Mhz),
        .addrb(r_dummy_addr),      // [수정] 주소가 계속 변하도록 연결
        .doutb(w_bram_dout_dummy)  // [수정] 데이터를 뽑아냄
    );

    // Debugging LEDs
    assign led[0] = config_done; // 설정 완료되면 켜짐
    assign led[1] = w_frame_done;// 프레임마다 깜빡임
    assign led[2] = w_fifo_full; // FIFO 꽉 차면 켜짐 (에러)
    assign led[3] = locked;      // 클럭 락 되면 켜짐

endmodule
