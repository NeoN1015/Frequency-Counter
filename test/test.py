import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_freq_counter(dut):
    """Test the frequency counter with a known input frequency."""

    # Start the 50 MHz system clock
    clock = Clock(dut.clk, 20, units="ns")  # 20 ns period = 50 MHz
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")

    # Generate a test signal: 1 kHz on ui_in[0]
    # 1 kHz = 1 ms period = 500 us high, 500 us low
    # But we need to simulate for a while to see results
    # Window is 1 ms (50,000 cycles of 50 MHz)
    # Divided by 100, so counter counts 10 pulses per window for 1 kHz input
    # Expected output: 10

    period_ns = 1_000_000  # 1 ms = 1 kHz
    half_period_ns = period_ns // 2

    # Run for 3 windows (3 ms) so the output latches
    for _ in range(3):
        dut.ui_in.value = 1
        await Timer(half_period_ns, units="ns")
        dut.ui_in.value = 0
        await Timer(half_period_ns, units="ns")

    # Wait a bit more for the latch to update
    await Timer(10_000, units="ns")

    result = int(dut.uo_out.value)
    dut._log.info(f"Frequency counter output = {result}")

    # For 1 kHz input with /100 prescaler and 1 ms window:
    # 1000 Hz * 0.001 s / 100 = 10
    assert result == 10, f"Expected 10, got {result}"
