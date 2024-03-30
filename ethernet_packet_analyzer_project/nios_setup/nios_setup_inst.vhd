	component nios_setup is
		port (
			clk_clk                           : in  std_logic                     := 'X';             -- clk
			clock_bridge_0_in_clk_clk         : in  std_logic                     := 'X';             -- clk
			led_external_connection_export    : out std_logic_vector(7 downto 0);                     -- export
			onchip_memory_s2_address          : in  std_logic_vector(11 downto 0) := (others => 'X'); -- address
			onchip_memory_s2_chipselect       : in  std_logic                     := 'X';             -- chipselect
			onchip_memory_s2_clken            : in  std_logic                     := 'X';             -- clken
			onchip_memory_s2_write            : in  std_logic                     := 'X';             -- write
			onchip_memory_s2_readdata         : out std_logic_vector(31 downto 0);                    -- readdata
			onchip_memory_s2_writedata        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			onchip_memory_s2_byteenable       : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
			reset_reset_n                     : in  std_logic                     := 'X';             -- reset_n
			switch_external_connection_export : in  std_logic_vector(7 downto 0)  := (others => 'X')  -- export
		);
	end component nios_setup;

	u0 : component nios_setup
		port map (
			clk_clk                           => CONNECTED_TO_clk_clk,                           --                        clk.clk
			clock_bridge_0_in_clk_clk         => CONNECTED_TO_clock_bridge_0_in_clk_clk,         --      clock_bridge_0_in_clk.clk
			led_external_connection_export    => CONNECTED_TO_led_external_connection_export,    --    led_external_connection.export
			onchip_memory_s2_address          => CONNECTED_TO_onchip_memory_s2_address,          --           onchip_memory_s2.address
			onchip_memory_s2_chipselect       => CONNECTED_TO_onchip_memory_s2_chipselect,       --                           .chipselect
			onchip_memory_s2_clken            => CONNECTED_TO_onchip_memory_s2_clken,            --                           .clken
			onchip_memory_s2_write            => CONNECTED_TO_onchip_memory_s2_write,            --                           .write
			onchip_memory_s2_readdata         => CONNECTED_TO_onchip_memory_s2_readdata,         --                           .readdata
			onchip_memory_s2_writedata        => CONNECTED_TO_onchip_memory_s2_writedata,        --                           .writedata
			onchip_memory_s2_byteenable       => CONNECTED_TO_onchip_memory_s2_byteenable,       --                           .byteenable
			reset_reset_n                     => CONNECTED_TO_reset_reset_n,                     --                      reset.reset_n
			switch_external_connection_export => CONNECTED_TO_switch_external_connection_export  -- switch_external_connection.export
		);

