import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer


@cocotb.test()
async def test_freq_counter(dut):
    """Test the frequency counter with a 1 MHz input."""

    # Start the 50 MHz system clock (20 ns period)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Apply reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await Timer(100, unit="ns")

    # Generate a 1 MHz test signal on ui_in[0]
    # 1 MHz = 1 us period = 500 ns high, 500 ns low
    # Expected: 1,000,000 Hz * 0.001 s / 100 = 10
    half_period_ns = 500

    # Run for 3 windows (3 ms) so the output latches
    for _ in range(3):
        dut.ui_in.value = 1
        await Timer(half_period_ns, unit="ns")
        dut.ui_in.value = 0
        await Timer(half_period_ns, unit="ns")

    # Wait a bit more for the latch to update
    await Timer(10_000, unit="ns")

    result = int(dut.uo_out.value)
    dut._log.info(f"Frequency counter output = {result}")

    assert result == 10, f"Expected 10, got {result}"
