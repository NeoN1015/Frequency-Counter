import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

async def drive_signal(dut, period_ns):
    """Background task to generate continuous pulses on ui_in[0]."""
    half_period = period_ns / 2
    while True:
        dut.ui_in.value = (int(dut.ui_in.value) & 0xFE) | 1
        await Timer(half_period, unit="ns")
        dut.ui_in.value = int(dut.ui_in.value) & 0xFE
        await Timer(half_period, unit="ns")

@cocotb.test()
async def test_freq_counter_1mhz(dut):
    """Test the frequency counter with a 1 MHz input (Expected output: 10)."""
    
    # 1. Start 50 MHz System Clock (20 ns period)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # 2. Initial Setup & Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # 3. Start 1 MHz Signal Generator Task (1,000 ns period)
    cocotb.start_soon(drive_signal(dut, period_ns=1000))

    # 4. Wait for 2 full gate windows (100,000 clock cycles = 2 ms)
    # This guarantees at least one complete 1 ms sampling window finishes.
    await ClockCycles(dut.clk, 100_000)

    # 5. Read Output
    result = int(dut.uo_out.value)
    dut._log.info(f"Frequency counter output = {result}")

    # 1 MHz inside a 1 ms gate divided by 100 prescaler = 10 counts
    assert result == 10, f"Expected 10, got {result}"
