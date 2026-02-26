`timescale 1ns / 1ps

module tb_Camera_read;

    // Inputs
    reg p_clock;
    reg rst;
    reg vsync;
    reg href;
    reg [7:0] p_data;

    // Outputs
    wire [11:0] pixel_data;
    wire pixel_valid;
    wire frame_done;

    // Instantiate the Unit Under Test (UUT)
    Camera_read uut (
        .rst(rst), 
        .p_clock(p_clock), 
        .vsync(vsync), 
        .href(href), 
        .p_data(p_data), 
        .pixel_data(pixel_data), 
        .pixel_valid(pixel_valid), 
        .frame_done(frame_done)
    );

    // Clock generation (25MHz assuming approx)
    always #20 p_clock = ~p_clock; 

    initial begin
        // Initialize Inputs
        p_clock = 0;
        rst = 1;
        vsync = 0;
        href = 0;
        p_data = 0;

        // Reset pulse
        #100;
        rst = 0;
        #40;

        // --- Scenario Start ---
        
        // 1. Start Frame (VSYNC High)
        $display("Starting Frame...");
        vsync = 1;
        #100; // V-Blanking wait

        // 2. Start Line (HREF High)
        $display("Starting Line...");
        href = 1;

        // 3. Input Pixel 1 (Red: 0xF00)
        // First byte (Upper 8 bits: 0xF0)
        @(posedge p_clock); 
        p_data = 8'hF0; 
        
        // Second byte (Lower 4 bits: 0x00)
        @(posedge p_clock); 
        p_data = 8'h00; 

        // 4. Input Pixel 2 (Green: 0x0F0)
        // First byte (Upper 8 bits: 0x0F)
        @(posedge p_clock); 
        p_data = 8'h0F; 
        
        // Second byte (Lower 4 bits: 0x00)
        @(posedge p_clock); 
        p_data = 8'h00; 
        
        // 5. End Line
        @(posedge p_clock);
        href = 0;
        p_data = 0;
        $display("Line Ended...");

        #100;

        // 6. End Frame
        vsync = 0;
        $display("Frame Ended...");
        
        #100;
        $finish;
    end
      
endmodule
