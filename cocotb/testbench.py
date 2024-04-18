# Simple tests for an counter module
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def basic_count(dut):
    dut._log.info("Running the test ...")
    # generate a clock
    cocotb.start_soon(Clock(dut.CLK_50_MAX10, 1, units="ns").start()) # TODO set to correct freq
    cocotb.start_soon(Clock(dut.enet_mdc_clk, 1, units="ns").start()) # TODO set to correct freq
    cocotb.start_soon(Clock(dut.ENETA_RX_CLK, 1, units="ns").start()) # TODO set to correct freq

    # Reset DUT
    dut.CPU_RESETn.value = 0

    # reset the module, wait 10 rising edges until we release reset
    for _ in range(10):
        await RisingEdge(dut.CLK_50_MAX10)
    dut.CPU_RESETn.value = 1

    # run for 50ns checking count on each rising edge
    for cnt in range(500):
        if (cnt % 100 == 0):
            dut._log.info("counting ... ")
        await RisingEdge(dut.CLK_50_MAX10)
        v_count = dut.dummy_wait.value
        mod_cnt = cnt

    assert v_count.integer == mod_cnt, "counter result is incorrect: %s != %s" % (str(dut.dummy_wait.value), mod_cnt)
