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

## Calculation
