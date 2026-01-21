\# Design Space Exploration Report: ALU



\## 1. Executive Summary

This report compares three LibreLane runs with different objectives. The results highlight the impact of Clock Period and Core Utilization on the final Power, Performance, and Area (PPA) metrics.



\*\*Top Performer:\*\*

\* \*\*`Optimize Area`\*\* was the most successful run. It achieved \*\*Timing Closure\*\* (positive slack) and the \*\*Lowest Power Consumption\*\*. \*Note: This run utilized a relaxed clock period of 25.0ns.\*



\*\*Comparison High-Level:\*\*

\* \*\*Power Run:\*\* Failed timing (WNS -1.74ns) despite a 20ns clock. Smallest Area (101595 units).

\* \*\*Area Run:\*\* Passed timing (WNS +7.71ns). Lowest Power (0.0060W).

\* \*\*Balance Run:\*\* Failed timing (WNS -5.44ns) with the tightest clock (15ns). Largest Area (145214 units).



---



\## 2. Configuration Parameters



| Parameter | Optimize Power | Optimize Area | Balance |

| :--- | :--- | :--- | :--- |

| \*\*Clock Period\*\* | 20.0 ns | 25.0 ns | 15.0 ns |

| \*\*Synthesis Strategy\*\* | Default | AREA 3 | Default |

| \*\*Core Utilization\*\* | Default | 60 % | 35 % |

| \*\*Target Density\*\* | Default | 0.65 | 0.4 |



---



\## 3. Results Comparison (PPA)



| Metric | Optimize Power | Optimize Area | Balance |

| :--- | :--- | :--- | :--- |

| \*\*Total Power (W)\*\* | 0.0104 | \*\*0.0060\*\* | 0.0161 |

| \*\*Core Area (units)\*\* | \*\*101595\*\* | 107053 | 145214 |

| \*\*Setup Slack (WNS)\*\* | -1.74 ns (Fail) | \*\*+7.71 ns (Pass)\*\* | -5.44 ns (Fail) |

| \*\*Total Neg Slack (TNS)\*\* | -24.86 ns | \*\*0.00 ns\*\* | -188.02 ns |



---



\## 4. Observations \& Recommendations



\### A. Performance (Timing)

The \*\*Optimize Area\*\* run was the only one to meet timing constraints. However, this is primarily because it was given a significantly easier target (\*\*25ns\*\* clock) compared to the Balance run (\*\*15ns\*\*).

\* Recommendation: If the design requires 15ns (66MHz) operation, further optimization (pipeline stages or logic restructuring) is needed, as the Balance run failed significantly (-5.43ns slack).



\### B. Power

The \*\*Optimize Area\*\* run consumed the least power. This correlates with the slower clock frequency (dynamic power is proportional to frequency).

\* Observation: The Power Run consumed \*more\* power than the Area run, likely due to the tighter timing constraints (20ns vs 25ns) forcing the tool to use higher drive-strength cells.



\### C. Area

The \*\*Optimize Power\*\* run achieved the smallest core area (101595), slightly beating the Area run. The \*\*Balance\*\* run was significantly larger, likely due to the low `FP\_CORE\_UTIL` setting (35%) which forces a larger floorplan to ease routing congestion.

