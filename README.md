# Approximate ALU: Trade-off Analysis on FPGA

Does approximate computing actually improve hardware efficiency? This project implements an 8-bit ALU on FPGA across two design phases — first a configurable multi-mode design, then a fixed isolated implementation to explore the same.
---

## Project Overview

Approximate computing introduces controlled inaccuracies in arithmetic operations to potentially reduce power, area, or delay. This project evaluates whether such benefits hold true in FPGA implementations.

---

## Repository Structure

Approximate-ALU/
│
├── configurable/
│   ├── rtl/
│   ├── testbench/
│   ├── constraints/
│   └── results/
│
├── isolated_comparison/
│   ├── rtl/
│   │   ├── approx_adder_k2.v
│   │   ├── exact_adder.v
│   │   ├── approx_wrapper.v
│   │   ├── exact_wrapper.v
│   │   └── top.v
│   │
│   ├── testbench/
│   │   └── tb.v
│   │
│   ├── constraints/
│   │   └── constraints.xdc
│   │
│   └── results/
│       ├── power/
│       ├── timing/
│       └── utilization/
│
└── README.md

---

# Phase 1: Configurable Approximate ALU

## Design

A parameterized ALU supporting:
- Multiple approximation techniques
- Variable approximation depth (K)
- Mode selection via control signals

### Techniques Used
- ADD Truncation  
- LSB Masking  
- Partial Product Truncation  

---

## Evaluation Metrics

- Mean Error Distance (MED)  
- Error Rate  
- Maximum Error  
- Timing (WNS)  
- Power Consumption  

---

## Results Summary (Phase 1)

| Metric         | Exact ALU  | Approx ALU  |
|----------------|------------|-------------|
| Dynamic Power  | 0.007 W    | 0.012 W     |
| WNS            | 3.922 ns   | 0.271 ns    |
| LUTs           | baseline   | 514         |

---

## Key Observations

- Approximation does not guarantee performance improvement  
- Timing degraded due to:
  - Control logic (muxes)
  - Disruption of carry-chain optimization  
- Power increased due to:
  - Additional switching activity  
- Error increases non-linearly with approximation depth  

---

## Insight

Configurable flexibility introduces hardware overhead that can negate the expected benefits of approximation.

---

The observations from the configurable design motivated a controlled experiment to isolate the effect of approximation without control overhead.

---

# Phase 2: Controlled Approximate ALU (Fixed Design)

## Design Approach

To eliminate overhead, a simplified design was implemented:

- Fixed approximation method (K = 2)  
- No multiplexers or control logic  
- Dedicated datapath for approximation  

The approximate adder operates as follows:

- Lower 2 bits are computed using bitwise OR  
- Upper bits are computed using standard addition without carry propagation from lower bits  

This removes carry dependency in the lower bits and reduces switching activity.

See `isolated_comparison/rtl/` for full implementation.

---

## Results Comparison (Phase 2)

| Metric | Exact | Approx (K=2) | Change |
|------|------|-------------|--------|
| Total On-Chip Power | 0.111 W | 0.109 W | −1.8% |
| Dynamic Power | 0.006 W | 0.005 W | −17% |
| Signal Power | 7% of dynamic | 2% of dynamic | −71% |
| Slice LUTs | 8 | 8 | No change |
| Slices | 2 | 4 | +2 (routing only) |
| CARRY4 | 2 | 2 | No change |

---

## Observations

- Approximate ALU reduces dynamic power by 17%  
- Signal switching activity drops significantly (~71% reduction)  
- LUT usage remains unchanged due to FPGA carry-chain mapping  
- Slice count increases from 2 to 4 due to routing of the split datapath, not additional logic  

---

## Key Insight

The 71% reduction in signal switching activity confirms that approximate computing's power benefit is real — but only when control overhead is eliminated. A configurable multi-mode design can negate all gains through mux and mode-select logic alone.

---

## FPGA-Specific Observation

Total power is dominated by static power (~90%), limiting the overall impact of logic-level optimizations.

---

# Final Conclusion

This project demonstrates that approximate computing's benefits are highly implementation-dependent. Overhead from control logic can completely negate power savings, while a clean fixed-mode design delivers measurable improvement. The methodology matters as much as the technique.
Approximate computing must therefore be carefully aligned with both hardware architecture and implementation methodology.

---

# Tools Used

- Verilog HDL  
- Xilinx Vivado  

---

# Author

Aditya Dwivedi  
VLSI Design & Technology  
