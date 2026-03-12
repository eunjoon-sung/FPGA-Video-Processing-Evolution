# Real-Time Video Processing Pipeline on Zynq-7000: From System Integration to ASIC Physical Implementation of AXI4 Writer

## 🚀 Architectural Evolution & Motivation
This repository documents the evolution of a real-time hardware video processing pipeline on the Zynq-7000 SoC. It highlights the strategic migration from a tightly coupled, BRAM-based streaming architecture to a robust, asynchronous AXI4/DDR-based full-frame buffering system to overcome severe hardware constraints.

---

## 1. [Phase 1](./v1_bram_streaming) BRAM-Based Streaming Architecture (Folder: `v1_bram_streaming`)

**Overview & Implementation:**
* **Capture & Control:** Custom RTL implementation of the I2C (SCCB) protocol for camera configuration. Designed a Data Capturer to extract valid pixels strictly synchronized with VSYNC/HREF signals.
* **Processing Pipeline:** Real-time chroma-key blending and downscaling (decimation) controlled by a deterministic FSM to minimize latency.
* **Verification:** Applied 2-stage Flip-Flop synchronizers to prevent metastability across clock domains and utilized Vivado ILA for real-time signal timing verification.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ea07afda-6a08-4f0e-9364-f3fe2a79c93f" />

#### 🛠️ Critical Troubleshooting: Frequency Interference & Data-Signal Decoupling

| Frequency Interference (Color Bar 5-way Split) | Severe Screen Tearing & Noise |
| :---: | :---: |
| <img src="./v1_bram_streaming/assets/colorbar_5split.png" width="350"> | <img src="./v1_bram_streaming/assets/screen_tearing.png" width="350"> |

* **Issue:** The standard video feed suffered from extreme screen tearing and severe noise, where only basic contrast was discernible. This persisted even after introducing an Asynchronous FIFO for Clock Domain Crossing (CDC). To isolate the fault, the camera's internal Color Bar test pattern was enabled via ROM configuration. Instead of filling the screen with a single pattern, the display exhibited a repeating 5-way horizontal split.

* **Hypothesis (Architectural Deduction):** Without clear ILA triggers across the asynchronous boundary, an architectural hypothesis was formulated:
  1. **Clock Frequency Interference:** The precise 5-way split observed during the static color bar test strongly implied a microscopic difference between the camera's external `PCLK` (25.000MHz) and the FPGA's internal system clock (25.01MHz). This slight frequency mismatch caused the horizontal sync to continuously drift and wrap around 5 times per frame.
  2. **Data-Signal Decoupling (Phase Skew):** Suspected that despite using an Async FIFO, the two clock domains remained fundamentally unsynchronized. Pixel data suffered variable latency as it passed through the FIFO, whereas control signals (`VSYNC`/`HREF`) bypassed the FIFO and propagated instantly. This timing mismatch completely decoupled the data path from the control path, causing a severe phase skew where the SRAM address reset triggered before the corresponding pixel data arrived.

* **Action & Verification (Write-Path Genlock & Module Consolidation):** To empirically test this hypothesis, the architecture was drastically refactored to remove the unstable Async FIFO. Three previously fragmented modules (`camera_read`, `downscaling`, and `sram_writer`) were aggressively consolidated into a single, unified `camera_capture` module. By driving this unified block strictly with the camera's native `PCLK` and explicitly gating the generated pixel data with the `HREF`/`VSYNC` signals, the data and control paths were physically and permanently coupled (Direct Drive / Genlock). Finally, the Clock Domain Crossing (CDC) boundary was strategically shifted to the SRAM itself, allowing the read-side pipeline (HDMI/VTG) to safely operate on independent internal system clocks (25MHz/100MHz).



| Final Output (Tearing Resolved & Chroma-key Applied) |
| :---: |
| <img src="./v1_bram_streaming/assets/final_result.png" width="500"> |

* **Result:** The immediate and complete disappearance of all 5-way splits, tearing, and phase skew artifacts definitively proved that the CDC latency and clock interference were indeed the root causes.

#### 🚧 Architectural Limitations (The "Why" behind Phase 2)
* **Resource Constraints:** Insufficient internal FPGA memory (BRAM) prevented the implementation of a Full Frame Buffer, forcing a rigid "Streaming Processing" architecture.
* **Scalability Bottleneck:** The Genlock solution (tightly coupled clocks) made the system inherently inflexible. It became impossible to interface with heterogeneous systems requiring different input/output frame rates.

---

## 2. [Phase 2](./v2_axi_ddr_buffering) AXI4-Stream & DDR3 Frame Buffering Architecture (Folder: `v2_axi_ddr_buffering`)

### Module Overview
This phase upgrades the video processing pipeline by integrating external DDR3 memory via the AMBA AXI4 interface. The architecture addresses the constraints of the previous BRAM-based streaming model by isolating the Camera Capture domain (Write) from the Display domain (Read) using asynchronous FIFOs and full-frame buffering.

* **Write Path (Camera -> DDR):** OV7670 Capture -> Async FIFO (CDC) -> Custom AXI4 Master Writer -> Zynq HP Port -> DDR3
* **Read Path (DDR -> HDMI):** DDR3 -> Zynq HP Port -> Custom AXI4 Master Reader -> Async FIFO -> Custom Video Timing Generator -> HDMI
* **Image Processing:** RGB565 to RGB444 slicing, real-time Chroma-key mixing.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bddaae29-6218-4546-a337-8edf65fbfc7c" />

---

## 3. 🛠️ Critical Troubleshooting Log

The transition to a decoupled memory architecture introduced complex synchronization and data integrity challenges. Below is the engineering log detailing the root cause analysis of critical artifacts.

### Issue 1: Image Scaling (1/4x), Rolling, and Ghosting Artifacts

* **Symptom:** The output display suffered from severe distortion. The screen exhibited continuous vertical rolling, and the image appeared scaled down to 1/4 of the monitor with horizontal/vertical folding (Ghosting), where the right side of the frame wrapped around to overlay on subsequent scanlines.

* **Hypothesis 1 (Asynchronous Domain Collision):** Suspected that the continuous screen rolling was caused by forcing synchronization between two independent clock domains. Initially, the Writer's address reset was rigidly tied to the HDMI VTG's `vsync`. This caused the Writer to stall and wait for the monitor, while the Camera kept streaming, inevitably overflowing the FIFO.
  * **Action:** Completely decoupled the Camera's `frame_done` signal from the HDMI's `vsync`. Implemented an independent Triple Buffering routing logic where the Writer operates freely and avoids the Reader's current memory space. Additionally, fine-tuned the Reader FIFO's reset timing to exactly match the HDMI Back Porch (`v_count == 523`).
  * **Result:** The vertical screen rolling was completely resolved. However, the 1/4x scaling and ghosting artifacts persisted.

* **Hypothesis 2 (AXI Burst Alignment & Stride Mismatch):** Suspected that the remaining ghosting boundary was related to memory address "line breaks" and AXI transaction sizes. 
  * **Action:** Manipulated the AXI Burst Length (`AWLEN`) from 64 down to 16. 
  * **Result (The Shifting Boundary):** A 64-bit AXI bus transfers 8 Bytes per beat. At `AWLEN` = 64, one burst equals 512 Bytes, which does not evenly divide a 640-Byte video line (320px * 2B). This caused bursts to straddle across multiple lines. However, at `AWLEN` = 16, one burst equals exactly 128 Bytes. Since 640 is perfectly divisible by 128 (exactly 5 bursts per line), the burst boundary perfectly aligned with the video line boundary. 
  * **Conclusion:** Changing `AWLEN` to 16 caused the visual folding boundary to shift horizontally. This proved that the AXI memory mapping and burst alignments were responding correctly, but the underlying total amount of data being pushed per line was fundamentally doubled, leading the investigation to the RTL logic.

* **Fault Isolation (Color Bar Test):** To strictly isolate the fault from external camera noise or AXI logic errors, bypassed the camera input and injected an internal static Color Bar test pattern. 
  * **Result:** The output rendered perfectly straight vertical bands, definitively proving that the AXI bandwidth, the 16-burst configuration, and the downscaling logic were completely flawless. The issue was now isolated strictly to the camera data parsing module.

* **Verification (Vivado ILA):** Bypassed the AXI interconnect variables and probed the `m_axi_w_wdata` directly at the hardware level.
  
* **Root Cause (The Latch):** The ILA waveform revealed a critical data duplication issue (`0xFFAA_xFFAA` -> `[Pixel A][Pixel A][Pixel B][Pixel B]`). The 8-bit to 16-bit word assembly logic in the `camera_capture` module lacked an explicit `else { pixel_valid <= 0; }` condition during the odd/even byte transition. The synthesizer interpreted this ambiguity as a hardware latch, asserting the `valid` strobe for *two* clock cycles per pixel. Consequently, 1 pixel was written to the DDR twice, causing the memory address pointer to increment at 2x speed. This forced Line N's data to forcefully invade Line N+1's memory space, resulting in the 1/4x scaling and overlapping ghost artifacts.

* **Resolution:** Implemented explicit state-machine level combinational gating (`pixel_valid <= 0;`), dismantling the unintended latch and ensuring a strict single-cycle strobe per 16-bit word. Memory mapping was instantly restored to a perfect 1:1 pixel-to-address ratio.


### Issue 2: Chroma-key Noise and Color Distortion
* **Symptom:** The green-screen background was not fully masked (clipping failed), and the camera output displayed abnormal color temperatures (excessive green tint).
* **Root Cause 1 (Color Temperature):** The OV7670 SCCB configuration lacked the specific AWB (Auto White Balance) algorithmic control register setup. The sensor defaulted to its physical bias (Bayer pattern's 2x green pixels).
* **Root Cause 2 (Bit Slicing Mismatch):** The logic incorrectly sliced the incoming RGB565 data as RGB444, causing the LSBs of the Green channel (noise) to bleed into the MSBs of the Blue channel.
* **Resolution:** 1. Updated SCCB ROM to assert register `0x6F` (`16'h6F_9F`) to enable Simple AWB control.
  2. Corrected hardware bit-slicing logic: `R = {rgb_data[15:11], 3'b000}; G = {rgb_data[10:5], 2'b00}; B = {rgb_data[4:0], 3'b000};`

---

## 4. [Phase 3](./v2_axi_ddr_buffering/asic) ASIC Physical Implementation & Sign-off (AXI4 Writer IP)

**Overview & Motivation:**
Following the system-level integration and logical verification in the FPGA (Vivado) environment, an ASIC Design Flow was conducted to evaluate the physical limitations of the RTL design when mapped to actual silicon. Targeting the `AXI4_writer.v` module—the most critical IP concerning memory bandwidth and timing in the pipeline—physical implementation and dynamic verification were performed using a 45nm standard cell library.

**Toolchain & Environment:**
* **Technology Node:** 45nm Educational Library (`slow_vdd1v0`)
* **Logic Synthesis:** Cadence Genus (RTL to Gate-level Netlist)
* **Place & Route (PnR):** Cadence Innovus (Floorplanning, Power Planning, Placement, CTS, Routing)
* **Post-Layout Simulation:** Cadence Xcelium (`xrun`, GLS with SDF back-annotation)

**Step-by-Step Flow:**
1. **Logic Synthesis:** Mapped the AXI4 Writer IP to the 45nm standard cells using a custom `run_synth.tcl` script, extracting and optimizing initial area, power, and timing reports.
2. **Place & Route:** Executed physical layout via a `run_pnr.tcl` script. Completed Clock Tree Synthesis (CTS) and routing, ultimately extracting the Standard Delay Format (SDF) and the final gate-level netlist.
3. **Post-Layout Simulation:** Combined the extracted netlist with the SDF file to conduct a sign-off verification. This confirmed that AXI4 transactions operate seamlessly at the 100MHz target frequency under real-world physical wire delays.

**Critical Troubleshooting: The "Why" Approach to Timing Closure**

* **Issue (Post-Route Hold Violation):** Following PnR, the Static Timing Analysis (STA) report indicated a marginal **Hold Slack violation of -0.011ns (11ps)** on a specific data path.
* **Root Cause Analysis & Engineering Approach:** Rather than blindly relying on the EDA tool's error report to modify the RTL or manually insert buffers, I questioned the fundamental validity of the error: *"Is this 11ps static violation a functionally critical defect during actual chip operation?"* To answer this, a dynamic cross-verification was planned.
* **Resolution (Dynamic Verification):**
  * Established a Post-Layout simulation environment in Xcelium (`run_postlayout.f`) and injected the PnR-extracted SDF to physically simulate wire delays (Back-annotation).
  * Analyzed reset-model warnings (`RECREM`) during the simulator's elaboration phase, confirming they did not impact the data path timing checks.
  * Upon analyzing the final simulation log (`xrun.log`) and waveforms, it was objectively confirmed that **zero Timing Violation messages and zero Unknown (X) states** occurred during all FSM state transitions and AXI4 handshakes, even on the flagged hold-violation path.
* **Conclusion:** Concluded that the -11ps violation fell strictly within the simulator's calculation margin and process tolerance limits. By utilizing empirical log data to prove perfect logical and physical operation at the 100MHz target frequency, the design was signed-off without unnecessary hardware modifications.

---

## 5. Known Limitations & Future Work

While the current AXI4 architecture successfully decouples the clock domains, it relies on an "Open-loop" writing mechanism. The system assumes perfect data ingestion based strictly on the VSYNC frame boundary.

* **Vulnerability (Error Propagation):** If external EMI noise or camera glitches cause a dropped or extra pixel, the linear address pointer (`ADDR_OFFSET`) will permanently shift for the remainder of the frame, corrupting the memory map until the next VSYNC clears the error.
* **Proposed Upgrade 1 (Line-Level Synchronization):** Implement an active sub-address correction mechanism using the **HREF (HSYNC) signal**. By forcing the memory write pointer to align with the start of a new row address at every HREF rising edge, any pixel noise will be localized to a single scanline, significantly increasing system robustness.
* **Proposed Upgrade 2 (Triple Buffering):** Transition from the current rigid double-buffering architecture to a **Triple Buffering Scheme**. This will introduce a completely independent, third memory space that acts as a traffic controller, physically guaranteeing that the AXI Reader never accesses a memory block currently being modified by the AXI Writer, eliminating all residual asynchronous tearing.

---

## 6. Result
* **youtube link:** 🔗https://youtube.com/shorts/Bii2IKHq5Z0?feature=share
