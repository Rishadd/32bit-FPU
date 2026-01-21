# Test Case Summary

## `adder_32Bit.v` Test Case Summary

| Test # | Input A (Decimal) | Hex A | Input B (Decimal) | Hex B | Expected Result | Result (Hex) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 3.5 | 0x40600000 | -2.25 | 0xC0100000 | 1.25 | 0x3FA00000 |
| 2 | 1.0 | 0x3F800000 | 2.0 | 0x40000000 | 3.0 | 0x40400000 |
| 3 | -4.5 | 0xC0900000 | 2.5 | 0x40200000 | -2.0 | 0xC0000000 |
| 4 | 0.5 | 0x3F000000 | 0.25 | 0x3E800000 | 0.75 | 0x3F400000 |
| 5 | -0.0 | 0x80000000 | +0.0 | 0x00000000 | +0.0 | 0x00000000 |
| 6 | NaN | 0x7FC00000 | 1.0 | 0x3F800000 | NaN | 0x7FC00000 |
| 7 | +Infinity | 0x7F800000 | 1.0 | 0x3F800000 | +Infinity | 0x7F800000 |
| 8 | -Infinity | 0xFF800000 | 1.0 | 0x3F800000 | -Infinity | 0xFF800000 |
| 9 | +Infinity | 0x7F800000 | +Infinity | 0x7F800000 | +Infinity | 0x7F800000 |
| 10 | -Infinity | 0xFF800000 | -Infinity | 0xFF800000 | -Infinity | 0xFF800000 |
| 11 | +Infinity | 0x7F800000 | -Infinity | 0xFF800000 | NaN | 0x7FC00000 |
| 12 | -Infinity | 0xFF800000 | +Infinity | 0x7F800000 | NaN | 0x7FC00000 |

## `multiplier_32Bit.v` Test Case Summary

| Test # | Input A (Hex) | Input B (Hex) | Description | Expected Output (Hex) | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | 0x40600000 | 0x40000000 | 3.5 * 2.0 | 0x40E00000 | Result: 7.0 (Normal) |
| 2 | 0xBFC00000 | 0x40800000 | -1.5 * 4.0 | 0xC0C00000 | Result: -6.0 (Normal) |
| 3 | 0x00000000 | 0x40A00000 | 0.0 * 5.0 | 0x00000000 | Zero result |
| 4 | 0x7F800000 | 0x40000000 | +INF * 2.0 | 0x7F800000 | +INF (Infinity) |
| 5 | 0xFF800000 | 0x40000000 | -INF * 2.0 | 0xFF800000 | -INF (Infinity) |
| 6 | 0x7F800000 | 0x00000000 | +INF * 0.0 | 0x7FC00000 | Invalid -> NaN |
| 7 | 0x7FC00000 | 0x3F800000 | NaN * 1.0 | 0x7FC00000 | NaN propagates |
| 8 | 0x5A0A1F0A | 0x5A0A1F0A | Large * Large | 0x7F800000 | Overflow -> +INF |
| 9 | 0xC0400000 | 0xC0000000 | -3.0 * -2.0 | 0x40C00000 | Result: 6.0 (Normal) |
| 10 | 0x3F800000 | 0x3F800000 | 1.0 * 1.0 | 0x3F800000 | Result: 1.0 (Normal) |
