module ov7670_controller(
    input clk,
    input rstb,
    output sioc,
    output reg siod,
    output wire done
);
    assign done = set_done;
    localparam REG_WR_NUM = 100;
    reg [7:0] clk_cnt;
    reg clk_250k_reg;
    reg [7:0] init_cnt;
    reg [3:0] clk_phase;
    reg [7:0] camera_address = 8'h42;
    reg [7:0] byte_cnt;
    reg init_done;
    reg set_done;
    reg [7:0] reg_addr;
    reg [7:0] reg_data;
    reg [7:0] reg_wr_cnt;
    
    // 레지스터 주소/데이터 설정 FSM
    always @ (posedge clk) begin
        if(reg_wr_cnt == 0) begin
            reg_addr <= 8'h12;
            reg_data <= 8'h80;
        end
        else if(reg_wr_cnt == 2) begin
            reg_addr <= 8'h12;
            reg_data <= 8'h04;
        end
        else if(reg_wr_cnt == 3) begin
            reg_addr <= 8'h11;
            reg_data <= 8'h80;
        end
        else if(reg_wr_cnt == 4) begin
            reg_addr <= 8'h0C;
            reg_data <= 8'h00;
        end 
        else if(reg_wr_cnt == 5) begin
            reg_addr <= 8'h3E;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 6) begin
            reg_addr <= 8'h04;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 7) begin
            reg_addr <= 8'h40;
            reg_data <= 8'hd0;
        end
        else if(reg_wr_cnt == 8) begin
            reg_addr <= 8'h3a;
            reg_data <= 8'h04;
        end
        else if(reg_wr_cnt == 9) begin
            reg_addr <= 8'h14;
            reg_data <= 8'h18;
        end
        else if(reg_wr_cnt == 10) begin
            reg_addr <= 8'h4F;
            reg_data <= 8'hB3;
        end
        else if(reg_wr_cnt == 11) begin
            reg_addr <= 8'h50;
            reg_data <= 8'hB3;
        end
        else if(reg_wr_cnt == 12) begin
            reg_addr <= 8'h51;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 13) begin
            reg_addr <= 8'h52;
            reg_data <= 8'h3D;
        end
        
        //----------------------------
        else if(reg_wr_cnt == 14) begin
            reg_addr <= 8'h53;
            reg_data <= 8'hA7;
        end
        else if(reg_wr_cnt == 15) begin
            reg_addr <= 8'h54;
            reg_data <= 8'hE4;
        end
        else if(reg_wr_cnt == 16) begin
            reg_addr <= 8'h58;
            reg_data <= 8'h9E;
        end
        else if(reg_wr_cnt == 17) begin
            reg_addr <= 8'h3D;
            reg_data <= 8'hC0;
        end
        else if(reg_wr_cnt == 18) begin
            reg_addr <= 8'h17;
            reg_data <= 8'h14;
        end
        else if(reg_wr_cnt == 19) begin
            reg_addr <= 8'h18;
            reg_data <= 8'h02;
        end
        else if(reg_wr_cnt == 20) begin
            reg_addr <= 8'h32;
            reg_data <= 8'h80;
        end
        else if(reg_wr_cnt == 21) begin
            reg_addr <= 8'h19;
            reg_data <= 8'h03;
        end
        else if(reg_wr_cnt == 22) begin
            reg_addr <= 8'h1A;
            reg_data <= 8'h7B;
        end
        else if(reg_wr_cnt == 23) begin
            reg_addr <= 8'h03;
            reg_data <= 8'h0A;
        end
        else if(reg_wr_cnt == 24) begin
            reg_addr <= 8'h0F;
            reg_data <= 8'h41;
        end
        else if(reg_wr_cnt == 25) begin
            reg_addr <= 8'h1E;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 26) begin
            reg_addr <= 8'h33;
            reg_data <= 8'h0B;
        end
        else if(reg_wr_cnt == 27) begin
            reg_addr <= 8'h3C;
            reg_data <= 8'h78;
        end
        else if(reg_wr_cnt == 28) begin
            reg_addr <= 8'h69;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 29) begin
            reg_addr <= 8'h74;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 30) begin
            reg_addr <= 8'hB0;
            reg_data <= 8'h84;
        end
        else if(reg_wr_cnt == 31) begin
            reg_addr <= 8'hB1;
            reg_data <= 8'h0C;
        end
        else if(reg_wr_cnt == 32) begin
            reg_addr <= 8'hB2;
            reg_data <= 8'h0E;
        end
        else if(reg_wr_cnt == 33) begin
            reg_addr <= 8'hB2;
            reg_data <= 8'h80;
        end
        else if(reg_wr_cnt == 34) begin
            reg_addr <= 8'h70;
            reg_data <= 8'h3A;
        end
        else if(reg_wr_cnt == 35) begin
            reg_addr <= 8'h71;
            reg_data <= 8'h35;
        end 
        else if(reg_wr_cnt == 36) begin
            reg_addr <= 8'h72;
            reg_data <= 8'h11;
        end 
        else if(reg_wr_cnt == 37) begin
            reg_addr <= 8'h73;
            reg_data <= 8'hF0;
        end 
        else if(reg_wr_cnt == 38) begin
            reg_addr <= 8'hA2;
            reg_data <= 8'h02;
        end 
        else if(reg_wr_cnt == 39) begin
            reg_addr <= 8'h7A;
            reg_data <= 8'h20;
        end 
        else if(reg_wr_cnt == 40) begin
            reg_addr <= 8'h7B;
            reg_data <= 8'h10;
        end 
        else if(reg_wr_cnt == 41) begin
            reg_addr <= 8'h7C;
            reg_data <= 8'h7E;
        end 
        else if(reg_wr_cnt == 42) begin
            reg_addr <= 8'h7D;
            reg_data <= 8'h35;
        end 
        else if(reg_wr_cnt == 43) begin
            reg_addr <= 8'h7E;
            reg_data <= 8'h5A;
        end 
        else if(reg_wr_cnt == 44) begin
            reg_addr <= 8'h7F;
            reg_data <= 8'h69;
        end 
        else if(reg_wr_cnt == 45) begin
            reg_addr <= 8'h80;
            reg_data <= 8'h76;
        end 
        else if(reg_wr_cnt == 46) begin
            reg_addr <= 8'h81;
            reg_data <= 8'h80;
        end 
        else if(reg_wr_cnt == 47) begin
            reg_addr <= 8'h82;
            reg_data <= 8'h88;
        end 
        else if(reg_wr_cnt == 48) begin
            reg_addr <= 8'h83;
            reg_data <= 8'h8F;
        end 
        else if(reg_wr_cnt == 49) begin
            reg_addr <= 8'h84;
            reg_data <= 8'h96;
        end 
        else if(reg_wr_cnt == 50) begin
            reg_addr <= 8'h85;
            reg_data <= 8'hA3;
        end 
        else if(reg_wr_cnt == 51) begin
            reg_addr <= 8'h86;
            reg_data <= 8'hAF;
        end 
        else if(reg_wr_cnt == 52) begin
            reg_addr <= 8'h87;
            reg_data <= 8'hC4;
        end 
        else if(reg_wr_cnt == 53) begin
            reg_addr <= 8'h88;
            reg_data <= 8'hD7;
        end 
        else if(reg_wr_cnt == 54) begin
            reg_addr <= 8'h89;
            reg_data <= 8'hE8;
        end
        else if(reg_wr_cnt == 55) begin
             reg_addr <= 8'h12; // COM7
             reg_data <= 8'h04; // RGB 모드 (이제는 먹힐 겁니다!)
        end
        else if(reg_wr_cnt == 56) begin
             reg_addr <= 8'h40; // COM15
             reg_data <= 8'hC0; // RGB565 Full Range
        end
        else if(reg_wr_cnt == 57) begin
             reg_addr <= 8'h71; reg_data <= 8'hB5; 
        end

        //-------------------------------------------------
        /*else if(reg_wr_cnt == 55) begin
            reg_addr <= 8'h13;
            reg_data <= 8'he0;
        end
        else if(reg_wr_cnt == 56) begin
            reg_addr <= 8'h00;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 57) begin
            reg_addr <= 8'h10;
            reg_data <= 8'h00;
        end
        else if(reg_wr_cnt == 58) begin
            reg_addr <= 8'h0D;
            reg_data <= 8'h40;
        end
        else if(reg_wr_cnt == 59) begin
            reg_addr <= 8'h14;
            reg_data <= 8'h18;
        end
        else if(reg_wr_cnt == 60) begin
            reg_addr <= 8'ha5;
            reg_data <= 8'h05;
        end
        else if(reg_wr_cnt == 61) begin
            reg_addr <= 8'hab;
            reg_data <= 8'h07;
        end
        else if(reg_wr_cnt == 62) begin
            reg_addr <= 8'h24;
            reg_data <= 8'h95;
        end
        else if(reg_wr_cnt == 63) begin
            reg_addr <= 8'h25;
            reg_data <= 8'h33;
        end
        else if(reg_wr_cnt == 64) begin
            reg_addr <= 8'h26;
            reg_data <= 8'he3;
        end
        else if(reg_wr_cnt == 65) begin
            reg_addr <= 8'h9f;
            reg_data <= 8'h78;
        end
        else if(reg_wr_cnt == 66) begin
            reg_addr <= 8'ha0;
            reg_data <= 8'h68;
        end
        else if(reg_wr_cnt == 67) begin
            reg_addr <= 8'ha1;
            reg_data <= 8'h03;
        end
        else if(reg_wr_cnt == 68) begin
            reg_addr <= 8'ha6;
            reg_data <= 8'hd8;
        end
        else if(reg_wr_cnt == 69) begin
            reg_addr <= 8'ha7;
            reg_data <= 8'hd8;
        end
        else if(reg_wr_cnt == 70) begin
            reg_addr <= 8'ha8;
            reg_data <= 8'hf0;
        end
        else if(reg_wr_cnt == 71) begin
            reg_addr <= 8'ha9;
            reg_data <= 8'h90;
        end
        else if(reg_wr_cnt == 72) begin
            reg_addr <= 8'haa;
            reg_data <= 8'h94;
        end
        else if(reg_wr_cnt == 73) begin
            reg_addr <= 8'h13;
            reg_data <= 8'he5;
        end
        else if(reg_wr_cnt == 74) begin
            reg_addr <= 8'h13;
            reg_data <= 8'he5;
        end
        else if(reg_wr_cnt == 75) begin
            reg_addr <= 8'h13;
            reg_data <= 8'he5;
        end*/
        //--------------
        else begin
            reg_addr <= 8'hFF;
            reg_data <= 8'hFF;
        end
    end
    assign sioc = (init_done)? clk_250k_reg : 1'b0 ; // 250kHz
    
    // 초기화 카운터
    always @ (posedge clk_250k_reg, negedge rstb) begin
        if(!rstb) init_cnt <= 0;
        else if(init_cnt == 255) init_cnt <= init_cnt;
        else init_cnt <= init_cnt + 1;
    end
    always @ (posedge clk_250k_reg, negedge rstb) begin
        if(!rstb) init_done <= 0;
        else if(init_cnt == 255) init_done <= 1;
        else init_done <= init_done;
    end

    // 250kHz 클럭 생성
    always @ (posedge clk, negedge rstb) begin
        if(!rstb) clk_cnt <= 0;
        else if(clk_cnt == 99) clk_cnt <= 0;
        else clk_cnt <= clk_cnt + 1;
    end
    always @ (posedge clk, negedge rstb) begin
        if(!rstb) clk_250k_reg <= 0;
        else if(clk_cnt == 50) clk_250k_reg <= 1;
        else if(clk_cnt == 0) clk_250k_reg <= 0;
        else clk_250k_reg <= clk_250k_reg;
    end

    // 클럭 페이즈 FSM
    always @ (posedge clk, negedge rstb) begin
        if(!rstb) clk_phase <= 1;
        else if(clk_cnt == 0) clk_phase <= 1;
        else if(clk_cnt == 10) clk_phase <= 2;
        else if(clk_cnt == 20) clk_phase <= 3;
        else if(clk_cnt == 30) clk_phase <= 4;
        else if(clk_cnt == 40) clk_phase <= 5;
        else if(clk_cnt == 50) clk_phase <= 6;
        else if(clk_cnt == 60) clk_phase <= 7;
        else if(clk_cnt == 70) clk_phase <= 8;
        else if(clk_cnt == 80) clk_phase <= 9;
        else if(clk_cnt == 90) clk_phase <= 0;
        else clk_phase <= clk_phase;
    end
    
    // 설정 완료 플래그
    always @(posedge clk, negedge rstb) begin
        if(!rstb) set_done <= 0;
        else if(reg_wr_cnt == REG_WR_NUM) reg_wr_cnt <= 0;//set_done <= 1;
        else set_done <= set_done;
    end
    
    // 바이트 카운터 및 레지스터 카운터 FSM
    always @ (posedge clk, negedge rstb) begin
        if(!rstb) begin
            byte_cnt <= 0;
            reg_wr_cnt <= 0;
        end
        else if(init_done) begin
            if(set_done) begin
                byte_cnt <= byte_cnt;
                reg_wr_cnt <= reg_wr_cnt;
            end
            else begin
                if(clk_cnt == 90) begin
                    if(byte_cnt == 280) begin
                        byte_cnt <= 0;
                        reg_wr_cnt <= reg_wr_cnt + 1;
                    end
                    else begin
                        byte_cnt <= byte_cnt + 1;
                        reg_wr_cnt <= reg_wr_cnt;
                    end
                end
                else begin
                    byte_cnt <= byte_cnt;
                end
            end
        end
        else begin
            byte_cnt <= byte_cnt;
            reg_wr_cnt <= reg_wr_cnt;
        end
    end
    
    // SIOD 신호 생성 (SCCB 프로토콜)
    always @ (posedge clk, negedge rstb) begin
        if(!rstb) siod <= 1;
        else if(init_done) begin
            if(byte_cnt == 0) begin // start
                 if(clk_phase == 8) siod <= 0;
                 else siod <= siod;
            end
            else if(byte_cnt == 1) begin //addr 7
                if(clk_phase == 3) siod <= camera_address[7];
                 else siod <= siod;
            end
            else if(byte_cnt == 2) begin //addr 6
                if(clk_phase == 3) siod <= camera_address[6];
                 else siod <= siod;
            end
            else if(byte_cnt == 3) begin//addr 5
                if(clk_phase == 3) siod <= camera_address[5];
                 else siod <= siod;
            end 
            else if(byte_cnt == 4) begin//addr 4
                if(clk_phase == 3) siod <= camera_address[4];
                 else siod <= siod;
            end
            else if(byte_cnt == 5) begin//addr 3
                if(clk_phase == 3) siod <= camera_address[3];
                 else siod <= siod;
            end
            else if(byte_cnt == 6) begin//addr 2
                if(clk_phase == 3) siod <= camera_address[2];
                 else siod <= siod;
            end
            else if(byte_cnt == 7) begin//addr 1
                if(clk_phase == 3) siod <= camera_address[1];
                 else siod <= siod;
            end
            else if(byte_cnt == 8) begin//addr 0
                if(clk_phase == 3) siod <= camera_address[0];
                 else siod <= siod;
            end
            else if(byte_cnt == 9) begin //hold
                if(clk_phase == 3) siod <= 1;
                 else siod <= siod;
            end
            else if(byte_cnt == 10) begin // reg addr 7
                if(clk_phase == 3) siod <= reg_addr[7];
                 else siod <= siod;
            end
            else if(byte_cnt == 11) begin // reg addr 6
                if(clk_phase == 3) siod <= reg_addr[6];
                 else siod <= siod;
            end
            else if(byte_cnt == 12) begin // reg addr 5
                if(clk_phase == 3) siod <= reg_addr[5];
                 else siod <= siod;
            end
            else if(byte_cnt == 13) begin // reg addr 4
                if(clk_phase == 3) siod <= reg_addr[4];
                 else siod <= siod;
            end
            else if(byte_cnt == 14) begin // reg addr 3
                if(clk_phase == 3) siod <= reg_addr[3];
                 else siod <= siod;
            end
            else if(byte_cnt == 15) begin // reg addr 2
                if(clk_phase == 3) siod <= reg_addr[2];
                 else siod <= siod;
            end
            else if(byte_cnt == 16) begin // reg addr 1
                if(clk_phase == 3) siod <= reg_addr[1];
                 else siod <= siod;
            end
            else if(byte_cnt == 17) begin // reg addr 0
                if(clk_phase == 3) siod <= reg_addr[0];
                 else siod <= siod;
            end
            else if(byte_cnt == 18) begin // hold
                if(clk_phase == 3) siod <= 1;
                 else siod <= siod;
            end
            else if(byte_cnt == 19) begin // data 7
                if(clk_phase == 3) siod <= reg_data[7];
                 else siod <= siod;
            end
            else if(byte_cnt == 20) begin // data 6
                if(clk_phase == 3) siod <= reg_data[6];
                 else siod <= siod;
            end
            else if(byte_cnt == 21) begin // data 5
                if(clk_phase == 3) siod <= reg_data[5];
                 else siod <= siod;
            end
            else if(byte_cnt == 22) begin // data 4
                if(clk_phase == 3) siod <= reg_data[4];
                 else siod <= siod;
            end
            else if(byte_cnt == 23) begin // data 3
                if(clk_phase == 3) siod <= reg_data[3];
                 else siod <= siod;
            end
            else if(byte_cnt == 24) begin // data 2
                if(clk_phase == 3) siod <= reg_data[2];
                 else siod <= siod;
            end
            else if(byte_cnt == 25) begin // data 1
                if(clk_phase == 3) siod <= reg_data[1];
                 else siod <= siod;
            end
            else if(byte_cnt == 26) begin // data 0
                if(clk_phase == 3) siod <= reg_data[0];
                 else siod <= siod;
            end
            else if(byte_cnt == 27) begin // end
                if(clk_phase == 8) siod <= 1;
                 else siod <= siod;
            end
            else siod <= 1;
        end
        else siod <= 1;
    end
endmodule

