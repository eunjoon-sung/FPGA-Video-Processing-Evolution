# FPGA Video Processing Architecture: Evolution from BRAM to DDR

## 🚀 Architectural Evolution & Motivation
This repository documents the evolution of a real-time hardware video processing pipeline on the Zynq-7000 SoC. It highlights the strategic migration from a tightly coupled, BRAM-based streaming architecture to a robust, asynchronous AXI4/DDR-based full-frame buffering system to overcome severe hardware constraints.

---

### 1. Phase 1: BRAM-Based Streaming Architecture (Folder: `v1_bram_streaming`)

**Overview & Implementation:**
* **Capture & Control:** Custom RTL implementation of the I2C (SCCB) protocol for camera configuration. Designed a Data Capturer to extract valid pixels strictly synchronized with VSYNC/HREF signals.
* **Processing Pipeline:** Real-time chroma-key blending and downscaling (decimation) controlled by a deterministic FSM to minimize latency.
* **Verification:** Applied 2-stage Flip-Flop synchronizers to prevent metastability across clock domains and utilized Vivado ILA for real-time signal timing verification.

**Critical Troubleshooting: Data-Signal Decoupling**
* **Issue:** Encountered severe screen tearing and periodic noise (5-way split) after introducing an asynchronous FIFO to handle CDC (Clock Domain Crossing).
* **Root Cause:** Phase skew caused by signal decoupling. While the control signal (VSYNC) propagated immediately, the pixel data experienced variable latency through the FIFO, causing address/data mismatch.
* **Resolution:** Implemented a **Direct Drive (Genlock)** approach, unifying the entire pipeline under the camera's PCLK as the master clock. This forced data and control signals to share the exact same pipeline delay, successfully eliminating the tearing.

**Architectural Limitations (The "Why" behind Phase 2):**
1.  **Resource Constraints:** Insufficient internal FPGA memory (BRAM) prevented the implementation of a Full Frame Buffer, forcing a rigid "Streaming Processing" architecture.
2.  **Scalability Bottleneck:** The Genlock solution (tightly coupled clocks) made the system inherently inflexible. It became impossible to interface with heterogeneous systems requiring different input/output frame rates.

---

### 2. Phase 2: AXI4 & DDR-Based Asynchronous Architecture (Folder: `v2_axi_ddr_buffering`) [Current]

**Migration Strategy & Objectives:**
To overcome the severe limitations of Phase 1, the architecture was completely redesigned using the **AMBA AXI4 / AXI4-Stream** interfaces to leverage external PS-DDR memory.

**Key Architectural Upgrades:**
* **High-Capacity Frame Buffering:** Transitioned from BRAM to external 512MB DDR3 memory. This enabled the implementation of a **Full Frame Buffer** capable of handling high-resolution video without forced streaming.
* **Clock Domain Decoupling:** Successfully isolated the camera input domain from the HDMI output domain. By building a robust asynchronous video processing system, the architecture is now highly tolerant of differing I/O speeds and heterogeneous data streams.
* **Robust Synchronization:** Designed to support advanced buffering techniques (e.g., Triple Buffering) to ensure completely tear-free video output regardless of input latency.

*(Note: Detailed troubleshooting logs regarding AXI-Stream interface integration and DDR memory map alignment during this phase can be found in the `v2` folder's README).*
