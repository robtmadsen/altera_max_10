# Simple tests for an counter module
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def basic_count(dut):
    # generate a clock
    cocotb.start_soon(Clock(dut.CLK_50_MAX10, 1, units="ns").start())

    # Reset DUT
    dut.CPU_RESETn.value = 1

    # reset the module, wait 2 rising edges until we release reset
    for _ in range(2):
        await RisingEdge(dut.CLK_50_MAX10)
    dut.CPU_RESETn.value = 0

    # run for 50ns checking count on each rising edge
    for cnt in range(50):
        await RisingEdge(dut.CLK_50_MAX10)
        v_count = dut.dummy_wait.value
        mod_cnt = cnt % 16
        assert v_count.integer == mod_cnt, "counter result is incorrect: %s != %s" % (str(dut.dummy_wait.value), mod_cnt)
