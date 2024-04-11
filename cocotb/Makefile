# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = ../altera_max_10/altera_max_10.v
#VERILOG_SOURCES =  $(shell cat filelist.vf)

# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = altera_max_10

# MODULE is the basename of the Python test file
MODULE = testbench

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
