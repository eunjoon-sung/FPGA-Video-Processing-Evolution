// -----------------------------------------------------------
// [ASIC/FPGA 표준] 리셋 동기화 모듈 : Reset Bridge
// 기능: 100Mhz에서 만들어진 입력 리셋을 받아서, 타겟 클럭에 맞는 리셋을 만들어줌.
// -----------------------------------------------------------
// [수정된 모듈] 복잡한 거 다 뺀 2-FF 싱크로나이저
// 기능: 입력(din)이 0이면 출력(dout)도 0, 1이면 1. (단, 클럭에 맞춰서)
module Reset_bridge (
    input wire clk,
    input wire rst_in_n,  // 0: Reset, 1: Run
    output reg rst_out_n  // 0: Reset, 1: Run
);
    reg r1;

    // 비동기 리셋(negedge) 같은 거 안 씁니다. 
    // 무조건 클럭 따라서만 움직이게(Synchronous) 변경.
    always @(posedge clk) begin
        r1        <= rst_in_n;
        rst_out_n <= r1;
    end

endmodule