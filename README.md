# AMBA APB Subsystem (4KB Memory Aperture)

A fully synthesizable, parameterizable AMBA 3 APB (Advanced Peripheral Bus) Master-Slave subsystem implemented in Verilog HDL and verified using Xilinx Vivado.

---

## 📌 Architecture Overview
- **Protocol:** AMBA APB v1.0 / v2.0 compliant sequencer and peripheral.
- **Bus Parameters:** 16-bit address bus (`paddr`), 32-bit data bus (`pwdata`, `prdata`).
- **Memory Footprint:** 4KB slave address aperture ($1024 \times 32\text{-bit}$ register space).
- **Flow Control:** Dynamic hardware wait-state insertion via `pready` (`WAITSTATE = 4`).
- **Exception Handling:** Boundary fault checking detecting illegal accesses ($PADDR \ge 1024$) via `pslverr` and host-side `resp_err`.

---

## 🏗️ Hardware Architecture & Interconnect
The top-level wrapper interconnects the sequence controller (Master) and the peripheral memory block (Slave) over dedicated point-to-point buses.

![RTL Schematic](rtl_schematic.png)

---

## 🔬 Functional Verification & Timing Results
Simulated on Vivado Simulator with a self-checking testbench covering single write/read transfers, wait-state handshake delays, and fault assertions.

![Simulation Waveform](simulation_waveform.png)

### Key Transaction Milestones:
1. **Write Transfer:** Driven to address `0x0002` with payload `0xDEADBEEF`. Master stalls for 4 wait cycles before asserting single-cycle `done`.
2. **Read Verification:** Data read back from `0x0002` accurately matches `0xDEADBEEF` with zero data corruption.
3. **PSLVERR Assertion:** Accessing illegal address `0x0400` ($1024 \ge \text{REGS}$) asserts `pslverr`, successfully latching `resp_err = 1` on the CPU host.

---

## 📊 FPGA Synthesis & Resource Utilization
Synthesized targeting the Kintex-7 FPGA architecture (`xc7k70tfbv676-1`):

![Resource Utilization](resource_utilization.png)

| Resource | Master_inst | Slave_inst | Total Used | Available | Utilization (%) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | 1,178 | 8,755 | 9,933 | 41,000 | 24% |
| **Slice Registers (FF)** | 631 | 32,807 | 33,438 | 82,000 | 41% |
| **F7 Muxes** | 0 | 4,352 | 4,352 | 20,500 | 21% |
| **F8 Muxes** | 0 | 2,176 | 2,176 | 10,250 | 21% |
| **Bonded IOB** | - | - | 86 | 300 | 28% |
| **Global Clock (BUFG)** | - | - | 1 | 32 | 3% |

---

## 📁 Repository Structure
```text
├── APB_Master.v    # Protocol Sequencer / Bridge FSM
├── APB_Slave.v     # 4KB Register Memory Array with Wait Generator
├── APB_Top.v       # Interconnect Module
├── tb_apb_top.v    # Self-checking Testbench
└── README.md       # Project Documentation & Verification Proofs
