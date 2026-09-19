import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer


@cocotb.test()
async def test_freq_counter(dut):
    """Test the frequency counter with a 1 MHz input."""

    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1
    await Timer(100, unit="ns")

    half_period_ns = 500
    total_periods = 3000

    for _ in range(total_periods):
        dut.ui_in.value = 1
        await Timer(half_period_ns, unit="ns")
        dut.ui_in.value = 0
        await Timer(half_period_ns, unit="ns")

    await Timer(10_000, unit="ns")

    result = int(dut.uo_out.value)
    dut._log.info(f"Frequency counter output = {result}")
    assert result == 10, f"Expected 10, got {result}"
