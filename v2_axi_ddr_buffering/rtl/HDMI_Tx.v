module HDMI_Tx(
    input PXLCLK_I,       // 25MHz
    input PXLCLK_5X_I,    // 125MHz
    input LOCKED_I,
    input RST_I,
    input VGA_HS_I,
    input VGA_VS_I,
    input VGA_DE_I,
    input [23:0] VGA_RGB_I, // {R, G, B}

    output HDMI_CLK_P, output HDMI_CLK_N,
    output [2:0] HDMI_DATA_P, output [2:0] HDMI_DATA_N
);

    wire [9:0] TMDS_red, TMDS_green, TMDS_blue;
    
    // 1. 8b/10b 인코딩 (기존과 동일)
    TMDS_encoder encode_R(.clk(PXLCLK_I), .VD(VGA_RGB_I[23:16]), .CD(2'b00), .VDE(VGA_DE_I), .TMDS(TMDS_red));
    TMDS_encoder encode_G(.clk(PXLCLK_I), .VD(VGA_RGB_I[15:8]),  .CD(2'b00), .VDE(VGA_DE_I), .TMDS(TMDS_green));
    TMDS_encoder encode_B(.clk(PXLCLK_I), .VD(VGA_RGB_I[7:0]),   .CD({VGA_VS_I, VGA_HS_I}), .VDE(VGA_DE_I), .TMDS(TMDS_blue));

    // 2. 5단계 시프터 및 ODDR (수정된 부분!)
    reg [4:0] TMDS_mod5 = 0;
    reg [9:0] shift_red = 0, shift_green = 0, shift_blue = 0, shift_clk = 0;
    
    always @(posedge PXLCLK_5X_I) begin
        if (RST_I) TMDS_mod5 <= 0;
        else TMDS_mod5 <= (TMDS_mod5 == 4) ? 0 : TMDS_mod5 + 1;
    end

    wire shift_load = (TMDS_mod5 == 4);

    always @(posedge PXLCLK_5X_I) begin
        if (shift_load) begin
            shift_red   <= TMDS_red;
            shift_green <= TMDS_green;
            shift_blue  <= TMDS_blue;
            shift_clk   <= 10'b1111100000;
        end else begin
            // 2비트씩 밀어냄 (ODDR이 2개씩 가져가니까)
            shift_red   <= shift_red   >> 2;
            shift_green <= shift_green >> 2;
            shift_blue  <= shift_blue  >> 2;
            shift_clk   <= shift_clk   >> 2;
        end
    end

    // 3. ODDR을 이용한 고속 출력 (DDR Mode)
    // 125MHz 클럭 하나에 비트 2개(0번 비트, 1번 비트)를 실어 보냄 -> 250Mbps 달성
    wire [2:0] ddr_data;
    wire ddr_clk;

    ODDR #( .DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("ASYNC") ) 
    ODDR_r (.Q(ddr_data[2]), .C(PXLCLK_5X_I), .CE(1'b1), .D1(shift_red[0]),   .D2(shift_red[1]),   .R(RST_I), .S(1'b0));
    
    ODDR #( .DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("ASYNC") ) 
    ODDR_g (.Q(ddr_data[1]), .C(PXLCLK_5X_I), .CE(1'b1), .D1(shift_green[0]), .D2(shift_green[1]), .R(RST_I), .S(1'b0));
    
    ODDR #( .DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("ASYNC") ) 
    ODDR_b (.Q(ddr_data[0]), .C(PXLCLK_5X_I), .CE(1'b1), .D1(shift_blue[0]),  .D2(shift_blue[1]),  .R(RST_I), .S(1'b0));
    
    ODDR #( .DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0), .SRTYPE("ASYNC") ) 
    ODDR_c (.Q(ddr_clk),     .C(PXLCLK_5X_I), .CE(1'b1), .D1(shift_clk[0]),   .D2(shift_clk[1]),   .R(RST_I), .S(1'b0));

    // 4. 차동 신호 버퍼 (OBUFDS)
    OBUFDS OBUFDS_red  (.I(ddr_data[2]), .O(HDMI_DATA_P[2]), .OB(HDMI_DATA_N[2]));
    OBUFDS OBUFDS_green(.I(ddr_data[1]), .O(HDMI_DATA_P[1]), .OB(HDMI_DATA_N[1]));
    OBUFDS OBUFDS_blue (.I(ddr_data[0]), .O(HDMI_DATA_P[0]), .OB(HDMI_DATA_N[0]));
    OBUFDS OBUFDS_clk  (.I(ddr_clk),     .O(HDMI_CLK_P),     .OB(HDMI_CLK_N));

endmodule