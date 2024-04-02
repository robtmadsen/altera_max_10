
module nios_setup (
	clk_clk,
	clock_bridge_0_in_clk_clk,
	led_external_connection_export,
	onchip_memory_s2_address,
	onchip_memory_s2_chipselect,
	onchip_memory_s2_clken,
	onchip_memory_s2_write,
	onchip_memory_s2_readdata,
	onchip_memory_s2_writedata,
	onchip_memory_s2_byteenable,
	reset_reset_n,
	switch_external_connection_export);	

	input		clk_clk;
	input		clock_bridge_0_in_clk_clk;
	output	[7:0]	led_external_connection_export;
	input	[11:0]	onchip_memory_s2_address;
	input		onchip_memory_s2_chipselect;
	input		onchip_memory_s2_clken;
	input		onchip_memory_s2_write;
	output	[31:0]	onchip_memory_s2_readdata;
	input	[31:0]	onchip_memory_s2_writedata;
	input	[3:0]	onchip_memory_s2_byteenable;
	input		reset_reset_n;
	input	[7:0]	switch_external_connection_export;
endmodule
