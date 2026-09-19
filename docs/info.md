# Frequency Counter

This chip measures the frequency of a digital input signal.

## How to Use
- Connect your signal to `ui_in[0]`
- The 8-bit result appears on `uo_out[7:0]`
- Scale factor: displayed_value × 100 = frequency in Hz (over 1 ms window)
