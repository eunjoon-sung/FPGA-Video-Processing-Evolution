# FPGA Video Processing Architecture: Evolution from BRAM to DDR

## 🚀 Architectural Evolution & Motivation
This repository documents the evolution of a real-time hardware video processing pipeline on the Zynq-7000 SoC. It highlights the strategic migration from a tightly coupled, BRAM-based streaming architecture to a robust, asynchronous AXI4/DDR-based full-frame buffering system to overcome severe hardware constraints.

---

## 1. Phase 1: BRAM-Based Streaming Architecture (Folder: `v1_bram_streaming`)

**Overview & Implementation:**
* **Capture & Control:** Custom RTL implementation of the I2C (SCCB) protocol for camera configuration. Designed a Data Capturer to extract valid pixels strictly synchronized with VSYNC/HREF signals.
* **Processing Pipeline:** Real-time chroma-key blending and downscaling (decimation) controlled by a deterministic FSM to minimize latency.
* **Verification:** Applied 2-stage Flip-Flop synchronizers to prevent metastability across clock domains and utilized Vivado ILA for real-time signal timing verification.

* **Critical Troubleshooting: Frequency Interference & Data-Signal Decoupling**

* **Issue:** Encountered severe screen tearing and periodic noise (5-way split) even after introducing an asynchronous FIFO to handle CDC (Clock Domain Crossing).
* **Root Cause Analysis:**
  1. **Clock Frequency Interference:** A microscopic difference between the camera's PCLK (25.000MHz) and the FPGA system clock (25.01MHz) created periodic interference, which manifested as multiple horizontal noise bands across the frame.
  2. **Data-Signal Decoupling (The Core Issue):** Despite using an Async FIFO, the two clock domains remained fundamentally unsynchronized and independent. Pixel data suffered variable latency as it passed through the FIFO, whereas control signals (VSYNC/HREF) bypassed the FIFO and propagated instantly. This timing mismatch completely decoupled the data path from the control path, causing a severe phase skew where the SRAM address reset triggered before the corresponding pixel data arrived.
* **Resolution:** Implemented a **Direct Drive (Genlock)** approach by completely removing the FIFO from the data path. Unified the entire processing pipeline strictly under the camera's PCLK. By explicitly gating data valid signals with HREF, the data and control paths were physically coupled, effectively eliminating all tearing and phase skew artifacts.

**Architectural Limitations (The "Why" behind Phase 2):**
1. **Resource Constraints:** Insufficient internal FPGA memory (BRAM) prevented the implementation of a Full Frame Buffer, forcing a rigid "Streaming Processing" architecture.
2. **Scalability Bottleneck:** The Genlock solution (tightly coupled clocks) made the system inherently inflexible. It became impossible to interface with heterogeneous systems requiring different input/output frame rates.

---

## 2. Phase 2: AXI4-Stream & DDR3 Frame Buffering Architecture (Folder: `v2_axi_ddr_buffering`)

### Module Overview
This phase upgrades the video processing pipeline by integrating external DDR3 memory via the AMBA AXI4 interface. The architecture addresses the constraints of the previous BRAM-based streaming model by isolating the Camera Capture domain (Write) from the Display domain (Read) using asynchronous FIFOs and full-frame buffering.

* **Write Path (Camera -> DDR):** OV7670 Capture -> Async FIFO (CDC) -> Custom AXI4 Master Writer -> Zynq HP Port -> DDR3
* **Read Path (DDR -> HDMI):** DDR3 -> Zynq HP Port -> Custom AXI4 Master Reader -> Async FIFO -> VTG/HDMI
* **Image Processing:** RGB565 to RGB444 slicing, real-time Chroma-key mixing.

---

## 3. Critical Troubleshooting Log

The transition to a decoupled memory architecture introduced complex synchronization and data integrity challenges. Below is the engineering log detailing the root cause analysis of critical artifacts.

### Issue 1: Image Scaling (1/4x) and Vertical Folding (Ghosting)

* **Symptom:** The output display showed severe distortion. The image appeared scaled down to 1/4 of the screen, and the right side of the physical frame wrapped around to overlay on the subsequent scanlines (Ghosting/Folding).
* **Hypothesis 1 (AXI Bandwidth/Burst):** Suspected that the AXI Writer was stalled or FIFO was overflowing. Adjusted `AWLEN` (64 -> 256 -> 80) and FIFO depths (2048 -> 8192) to prevent potential data drops. *(Result: Artifacts persisted)*
* **Hypothesis 2 (Buffer Synchronization):** Suspected Read/Write pointer collision in the double buffering scheme. Modified VSYNC synchronization and `ADDR_OFFSET` reset timing to ensure strict boundary isolation. *(Result: Offset shifted, but folding remained)*
* **Verification (Vivado ILA):** Probed the `m_axi_w_wdata` directly at the AXI Write channel. 
* **Root Cause:** The ILA waveform revealed data duplication (`0xFFAA 0xFFAA`...). The 8-bit to 16-bit word assembly logic in the `camera_capture` module lacked an explicit reset for the `pixel_valid` signal during the odd/even byte transition state. This generated a hardware latch, asserting `valid` for two clock cycles. Consequently, 1 pixel was written twice (AABB), causing the DDR address pointer to increment at 2x speed. This misalignment pushed Line N's data into Line N+1's memory address space, resulting in the folding artifact.

* **Resolution:** Implemented explicit state-machine level gating for `pixel_valid <= 0;` ensuring a strict single-cycle strobe per 16-bit word. Memory mapping restored to a 1:1 pixel-to-address ratio.

### Issue 2: Chroma-key Noise and Color Distortion
* **Symptom:** The green-screen background was not fully masked (clipping failed), and the camera output displayed abnormal color temperatures (excessive green tint).
* **Root Cause 1 (Color Temperature):** The OV7670 SCCB configuration lacked the specific AWB (Auto White Balance) algorithmic control register setup. The sensor defaulted to its physical bias (Bayer pattern's 2x green pixels).
* **Root Cause 2 (Bit Slicing Mismatch):** The logic incorrectly sliced the incoming RGB565 data as RGB444, causing the LSBs of the Green channel (noise) to bleed into the MSBs of the Blue channel.
* **Resolution:** 1. Updated SCCB ROM to assert register `0x6F` (`16'h6F_9F`) to enable Simple AWB control.
  2. Corrected hardware bit-slicing logic: `R = {rgb_data[15:11], 3'b000}; G = {rgb_data[10:5], 2'b00}; B = {rgb_data[4:0], 3'b000};`

---

## 4. Known Limitations & Future Work

While the current AXI4 architecture successfully decouples the clock domains, it relies on an "Open-loop" writing mechanism. The system assumes perfect data ingestion based strictly on the VSYNC frame boundary.

* **Vulnerability (Error Propagation):** If external EMI noise or camera glitches cause a dropped or extra pixel, the linear address pointer (`ADDR_OFFSET`) will permanently shift for the remainder of the frame, corrupting the memory map until the next VSYNC clears the error.
* **Proposed Upgrade 1 (Line-Level Synchronization):** Implement an active sub-address correction mechanism using the **HREF (HSYNC) signal**. By forcing the memory write pointer to align with the start of a new row address at every HREF rising edge, any pixel noise will be localized to a single scanline, significantly increasing system robustness.
* **Proposed Upgrade 2 (Triple Buffering):** Transition from the current rigid double-buffering architecture to a **Triple Buffering Scheme**. This will introduce a completely independent, third memory space that acts as a traffic controller, physically guaranteeing that the AXI Reader never accesses a memory block currently being modified by the AXI Writer, eliminating all residual asynchronous tearing.

## 5. Result
* **youtube link:** 🔗https://youtube.com/shorts/Bii2IKHq5Z0?feature=share
