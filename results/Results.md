# Analysis Report

## Comparison of LibreLane Optimization Runs

This document presents a detailed comparison of three OpenLane optimization runs:

* **Optimize Power**
* **Optimize Area**
* **Tradeoff / Balance**

The goal is to understand how different configuration strategies influence power, area, and timing in the final physical implementation.

---

## 1. Configuration & Strategy Differences

The three runs used distinct synthesis and floorplanning strategies. The key configuration differences are summarized below.

| Feature                                   | Optimize Power (`config_power.json`) | Optimize Area (`config_area.json`) | Tradeoff / Balance (`config_balance.json`) |
| ----------------------------------------- | ------------------------------------ | ---------------------------------- | ------------------------------------------ |
| **Synthesis Strategy**                    | `DELAY 1`                            | `AREA 2`                           | `AREA 1`                                   |
| **Clock Period**                          | 10.0 ns                              | 10.0 ns                            | 10.0 ns                                    |
| **Core Utilization (FP_CORE_UTIL)**       | 50% (Low Density)                    | 65% (High Density)                 | 55% (Medium Density)                       |
| **Placement Density (PL_TARGET_DENSITY)** | 0.55                                 | 0.70                               | 0.60                                       |
| **Max Fanout (SYNTH_MAX_FANOUT)**         | 5                                    | 5                                  | 5                                          |

### Notes

* **Optimize Power** prioritizes timing and signal integrity with relaxed density.
* **Optimize Area** aggressively packs logic to minimize die size.
* **Tradeoff / Balance** aims for a practical middle ground.

---

## 2. Performance Metrics Comparison

Final results extracted from the `metrics_*.csv` files are shown below.

| Metric                      | Optimize Power | Optimize Area   | Tradeoff / Balance |
| --------------------------- | -------------- | --------------- | ------------------ |
| **Total Power**             | 1.63 mW        | 1.81 mW         | 1.72 mW            |
| **Die Area**                | 0.0094 mm²     | 0.0075 mm²      | 0.0084 mm²         |
| **Instance Count**          | 1542 cells     | 1489 cells      | 1512 cells         |
| **Setup Violations**        | 0 (Clean)      | 2 (Violated)    | 0 (Clean)          |
| **Hold Violations**         | 0              | 0               | 0                  |
| **Worst Setup Slack (WNS)** | +1.24 ns       | -0.15 ns (Fail) | +0.45 ns           |
| **Worst Hold Slack**        | +0.18 ns       | +0.12 ns        | +0.15 ns           |
| **Flow Status**             | Flow Complete  | Flow Complete   | Flow Complete      |

---

## 3. Detailed Analysis of Results

### A. Power Optimization

| Aspect          | Observation                       |
| --------------- | --------------------------------- |
| **Total Power** | Lowest at **1.63 mW**             |
| **Timing**      | Best margin with **+1.24 ns WNS** |
| **Density**     | Low (50%), reduced congestion     |

**Reasoning:**

* `DELAY 1` synthesis reduces excessive buffering.
* Lower density enables cleaner routing and reduced wire capacitance.
* Strong timing margin avoids power-hungry gate upsizing.

---

### B. Area Optimization

| Aspect         | Observation                                 |
| -------------- | ------------------------------------------- |
| **Die Area**   | Smallest at **0.0075 mm²**                  |
| **Cell Count** | Lowest at **1489 cells**                    |
| **Timing**     | Failed (−0.15 ns WNS, 2 setup violations) |

**Trade-off:**

* High utilization (65%) causes routing congestion.
* Longer interconnects degrade timing.

**Actionable Fixes:**

* Increase clock period to **~11 ns**, **or**
* Reduce core utilization to **~60%** to recover timing.

---

### C. Balanced / Tradeoff Run

| Metric     | Comparison                   |
| ---------- | ---------------------------- |
| **Area**   | ~10% smaller than Power run  |
| **Power**  | ~6% lower than Area run      |
| **Timing** | Clean, with **+0.45 ns WNS** |

**Conclusion:**
This configuration is the **most suitable for general-purpose tape-out**, balancing power, area, and timing without pushing the design close to failure limits.

---

## 4. Violation Summary

| Violation Type       | Optimize Power | Optimize Area | Tradeoff / Balance |
| -------------------- | -------------- | ------------- | ------------------ |
| **Setup Violations** | 0              | 2            | 0                  |
| **Hold Violations**  | 0              | 0             | 0                  |
| **DRC/LVS**          | Clean          | Clean         | Clean              |

### Interpretation

* Only the **Area-optimized run** failed timing at 100 MHz.
* All designs are physically manufacturable.
* Hold timing was successfully fixed in all runs via CTS/resizer stages.

---

## Final Conclusion

* **Best Power:** Optimize Power
* **Best Area:** Optimize Area (with timing risk)
* **Best Overall:** Tradeoff / Balance
