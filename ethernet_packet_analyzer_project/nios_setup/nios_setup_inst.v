	nios_setup u0 (
		.clk_clk                           (<connected-to-clk_clk>),                           //                        clk.clk
		.clock_bridge_0_in_clk_clk         (<connected-to-clock_bridge_0_in_clk_clk>),         //      clock_bridge_0_in_clk.clk
		.led_external_connection_export    (<connected-to-led_external_connection_export>),    //    led_external_connection.export
		.onchip_memory_s2_address          (<connected-to-onchip_memory_s2_address>),          //           onchip_memory_s2.address
		.onchip_memory_s2_chipselect       (<connected-to-onchip_memory_s2_chipselect>),       //                           .chipselect
		.onchip_memory_s2_clken            (<connected-to-onchip_memory_s2_clken>),            //                           .clken
		.onchip_memory_s2_write            (<connected-to-onchip_memory_s2_write>),            //                           .write
		.onchip_memory_s2_readdata         (<connected-to-onchip_memory_s2_readdata>),         //                           .readdata
		.onchip_memory_s2_writedata        (<connected-to-onchip_memory_s2_writedata>),        //                           .writedata
		.onchip_memory_s2_byteenable       (<connected-to-onchip_memory_s2_byteenable>),       //                           .byteenable
		.reset_reset_n                     (<connected-to-reset_reset_n>),                     //                      reset.reset_n
		.switch_external_connection_export (<connected-to-switch_external_connection_export>)  // switch_external_connection.export
	);

