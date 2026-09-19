# Frequency Counter

A digital frequency counter that measures the frequency of a signal on `ui_in[0]`.

## How It Works

- The input signal is divided by 100 using a prescaler.
- A 1 millisecond gate window is generated from the 50 MHz system clock.
- The counter counts prescaled pulses during the window.
- The result is latched to `uo_out[7:0]` at the end of each window.

## How to Use

- Connect your signal to `ui_in[0]`.
- Read the 8-bit result from `uo_out[7:0]`.
- Frequency in Hz = displayed value × 100 / 0.001 = displayed value × 100,000.

### Example

| Input Frequency | Displayed Value |
|-----------------|-----------------|
| 1 MHz           | 10              |
| 500 kHz         | 5               |
| 2 MHz           | 20              |

## Pinout

| Pin | Name | Direction | Description |
|-----|------|-----------|-------------|
| ui_in[0] | signal_in | Input | Signal to measure |
| uo_out[7:0] | freq_bit[7:0] | Output | Frequency result |

## Parameters

- System clock: 50 MHz
- Gate window: 1 ms
- Prescaler: ÷100
- Resolution: 100 kHz per bit step
