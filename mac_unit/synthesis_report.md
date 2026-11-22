# MAC Unit — Vivado Synthesis Report

## 1. Overview

This document summarizes the Vivado synthesis results provided for the multiply-accumulate (MAC) hardware module.

- **Tool:** Xilinx Vivado 2025.2
- **Target device:** `xc7z020clg400-1`
- **Top module:** `mac`

## 2. Synthesis summary

| Item | Result |
|---|---|
| Synthesis status | Successful |
| Errors | 0 |
| Critical warnings | 0 |
| Warnings | 0 |
| Reported elapsed synthesis time | Approximately 30 seconds |
| Synthesized design checkpoint | `mac.dcp` |

## 3. FPGA resource utilization

| FPGA resource | Quantity |
|---|---:|
| LUT2 | 46 |
| LUT3 | 7 |
| LUT4 | 25 |
| LUT5 | 6 |
| LUT6 | 26 |
| FDRE flip-flops | 24 |
| CARRY4 | 18 |
| BUFG | 1 |
| IBUF | 19 |
| OBUF | 24 |

The synthesis report lists 196 cells in the top-level instance area summary. The 24 FDRE flip-flops correspond to the 24-bit accumulator register. LUTs implement combinational logic, and CARRY4 cells provide carry-chain arithmetic. The report lists 220 DSPs and 280 BRAMs as available on the target device, but no DSP or BRAM instances are reported as used; the arithmetic is mapped to LUT and carry-chain resources.

## 4. Timing and constraints

The synthesis log states **“No constraint files found.”** Synthesis and timing optimization completed without errors, but this log alone does not establish a maximum operating frequency or prove timing closure against a target. An XDC clock constraint and post-implementation timing analysis are needed to evaluate timing performance.

## 5. Result and conclusion

Synthesis completed successfully with zero errors, critical warnings, and warnings. Vivado generated a synthesized netlist and saved the design checkpoint as `mac.dcp`.

This is a hardware synthesis/resource-mapping report, not a functional simulation report. It does not demonstrate that the MAC passed its testbench. Functional correctness is documented separately in the simulation results. Timing performance likewise requires constraints and implementation timing reports.

> Report details were transcribed from the results supplied for this repository; they have not been independently reproduced here.
