`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 8 // 2^8 = 256 depth (충분한 공간)
)(
    input  wire rst, // 비동기 리셋

    // --- Write Domain (pclk: 24MHz) ---
    input  wire wr_clk,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire full,
    output wire prog_full,

    // --- Read Domain (clk_100Mhz: 100MHz) ---
    input  wire rd_clk,
    input  wire rd_en,
    output wire [DATA_WIDTH-1:0] dout,
    output wire empty,
    output wire [ADDR_WIDTH:0] rd_data_count
);

    // 1. 메모리 배열 (Registers)
    // ASIC 합성 시 엄청난 면적을 차지하겠지만, 논리적 검증을 위해 플립플롭 배열로 선언합니다.
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // 2. 포인터 (Binary & Gray)
    reg [ADDR_WIDTH:0] wr_ptr_bin = 0, wr_ptr_gray = 0;
    reg [ADDR_WIDTH:0] rd_ptr_bin = 0, rd_ptr_gray = 0;

    wire [ADDR_WIDTH:0] wr_ptr_gray_next, wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next, rd_ptr_bin_next;

    // 3. CDC Synchronizers (2-stage Flip-Flops)
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1 = 0, wr_ptr_gray_sync2 = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1 = 0, rd_ptr_gray_sync2 = 0;

    // ==========================================
    // Write Domain Logic (pclk)
    // ==========================================
    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en & ~full);
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next; // Binary to Gray 변환 공식

    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            if (wr_en && !full) begin
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
            end
        end
    end

    // Read 포인터를 Write 도메인으로 동기화 (Full 조건 판단용)
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Full 조건: MSB 2자리는 다르고, 나머지는 같을 때 (Gray Code 특성)
    assign full = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    // Prog_full (거의 참): Write 포인터와 동기화된 Read 포인터의 차이가 250 이상일 때 (간략화)
    assign prog_full = (wr_ptr_bin - rd_ptr_gray_sync2) > 250; 

    // ==========================================
    // Read Domain Logic (clk_100Mhz)
    // ==========================================
    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en & ~empty);
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next; // Binary to Gray 변환

    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end

    // Write 포인터를 Read 도메인으로 동기화 (Empty 및 Data Count 판단용)
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Empty 조건: Write 포인터와 Read 포인터가 완벽히 같을 때
    assign empty = (rd_ptr_gray_next == wr_ptr_gray_sync2);

    // FWFT(First-Word Fall-Through) 출력: 클럭을 기다리지 않고 현재 Read 포인터가 가리키는 값을 즉시 출력
    assign dout = mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

    // rd_data_count 계산 로직 (Gray to Binary 역변환 후 차이 계산)
    integer i;
    reg [ADDR_WIDTH:0] wr_ptr_bin_sync;
    always @(*) begin
        wr_ptr_bin_sync[ADDR_WIDTH] = wr_ptr_gray_sync2[ADDR_WIDTH];
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
            wr_ptr_bin_sync[i] = wr_ptr_bin_sync[i+1] ^ wr_ptr_gray_sync2[i];
        end
    end
    assign rd_data_count = wr_ptr_bin_sync - rd_ptr_bin;

endmodule
