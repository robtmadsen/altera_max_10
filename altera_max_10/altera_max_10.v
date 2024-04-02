`timescale 1 ps / 1 ps
`define USER_PINS
`define USB
//`define DDR3 
`define QSPI
`define ETHERNET_A
`define ETHERNET_B
`define UART
`define HSMC
`define HDMI
`define PMOD
`define DAC 
`define GPIO
`define JTAG
 
module  altera_max_10(
    //Reset and Clocks
    input    CLK_50_MAX10, // Runs at 50MHz I think
    input    CLK_25_MAX10, // Runs at 25MHz I think 
    input    CLK_LVDS_125_p, // Runs at 125MHz I think 
    input    CLK_10_ADC,
    input    CPU_RESETn,

    output [4:0]    USER_LED,        //1.5v
    input  [3:0]    USER_PB,         //1.5v 

    output       ENETA_GTX_CLK,
    input        ENETA_TX_CLK,
    output [3:0] ENETA_TX_D,
    output       ENETA_TX_EN,
    output       ENETA_TX_ER,
    input        ENETA_RX_CLK,
    input [3:0]	 ENETA_RX_D,
    input        ENETA_RX_DV,
    input        ENETA_RX_ER,
    input        ENETA_RESETn,
    input        ENETA_RX_CRS,
    input        ENETA_RX_COL,
    output       ENETA_LED_LINK100,
    input        ENETA_INTn,
    output       ENET_MDC,
    inout        ENET_MDIO,
    
    output       ENETB_GTX_CLK,
    input        ENETB_TX_CLK,
    output [3:0] ENETB_TX_D,
    output       ENETB_TX_EN,
    output       ENETB_TX_ER,
    input        ENETB_RX_CLK, // Runs at 62.5MHz I think
    input [3:0]  ENETB_RX_D,
    input        ENETB_RX_DV,
    input        ENETB_RX_ER,
    input        ENETB_RESETn,
    input        ENETB_RX_CRS,
    input        ENETB_RX_COL,
    output       ENETB_LED_LINK100,
    input        ENETB_INTn
); 

    reg reg_LED0, reg_LED1, reg_LED2, reg_LED3;

    reg [7:0] ethA_stream;

    nios_setup nios (
        .clk_clk(CLK_50_MAX10),
        .led_external_connection_export(2'b0),
        // this connects to the on-board memory that I want my custom logic to write to
        .clock_bridge_0_in_clk_clk(ENETA_RX_CLK),
        .onchip_memory_s2_address(onchip_memory2_0_s1_address[11:0]),
        .onchip_memory_s2_chipselect(onchip_memory2_0_s1_chipselect),
        .onchip_memory_s2_clken(/*onchip_memory2_0_s1_clken*/1),
        .onchip_memory_s2_write(onchip_memory2_0_s1_write),
        .onchip_memory_s2_readdata(onchip_memory2_0_s1_readdata),
        .onchip_memory_s2_writedata(onchip_memory2_0_s1_writedata),
        .onchip_memory_s2_byteenable(/*onchip_memory2_0_s1_byteenable*/4'hF),
        .reset_reset_n(CPU_RESETn),
        .switch_external_connection_export(ethA_stream)//? Don't care? 
    );

    //address: specifies a word offset into the slave address space
    reg [12:0] onchip_memory2_0_s1_address;
    // should always be 1?
    reg        onchip_memory2_0_s1_clken = 1; // ?
    // chipselect: The slave port ignores all other Avalon-MM signal inputs unless
    // chipselect is asserted
    // The system interconnect fabric always asserts chipselect in combination
    // with read or write.
    reg        onchip_memory2_0_s1_chipselect;
    // write: because there is no read, write also means read_n
    reg        onchip_memory2_0_s1_write;
    reg [31:0] onchip_memory2_0_s1_readdata;
    // writedate: If used, write or writebyteenable must also be used,
    // and data cannot be used
    reg [31:0] onchip_memory2_0_s1_writedata;
    //reg [3:0]  onchip_memory2_0_s1_byteenable = 'hF;
    
    reg [6:0] ram_writes_per_phy_addr;
    reg [5:0] phy_regs_written_to_ram;
    
    reg[18:0] dummy_wait;
    initial begin
        dummy_wait = 0;
    end
    initial begin
        onchip_memory2_0_s1_writedata = 0;
        onchip_memory2_0_s1_write = 0;
    end
    always @ (posedge ENETA_RX_CLK) begin
        if (CPU_RESETn == 0) begin
            onchip_memory2_0_s1_address <= 0;
            onchip_memory2_0_s1_write <= 0;
            onchip_memory2_0_s1_chipselect <= 0;
            reg_LED0 <= 1'b0;
            onchip_memory2_0_s1_writedata <= {32'hBEEFBEEF};
            ram_writes_per_phy_addr <= 0;
            phy_regs_written_to_ram <= 0;
        end else begin
            if (onchip_memory2_0_s1_address < 13'h1000) begin
                dummy_wait <= dummy_wait + 1;

                if (phy_read_done == 0) begin
                // do nothing until the entire PHY register space has been read
                end else if (phy_regs_written_to_ram < 'd32) begin
                    if (dummy_wait == 0) begin
                        onchip_memory2_0_s1_address <= onchip_memory2_0_s1_address + 1;
                        ram_writes_per_phy_addr <= ram_writes_per_phy_addr + 1;
                        if (ram_writes_per_phy_addr > 'd8) begin
                            phy_regs_written_to_ram <= phy_regs_written_to_ram + 1;
                            ram_writes_per_phy_addr <= 0;
                        end
                        case(phy_regs_written_to_ram)
                        5'd0:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_0};
                        5'd1:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_1};
                        5'd2:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_2};
                        5'd3:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_3};
                        5'd4:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_4};
                        5'd5:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_5};
                        5'd6:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_6};
                        5'd7:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_7};
                        5'd8:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_8};
                        5'd9:  onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_9};
                        5'd10: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_10};
                        5'd11: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_11};
                        5'd12: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_12};
                        5'd13: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_13};
                        5'd14: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_14};
                        5'd15: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_15};
                        5'd16: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_16};
                        5'd17: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_17};
                        5'd18: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_18};
                        5'd19: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_19};
                        5'd20: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_20};
                        5'd21: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_21};
                        5'd22: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_22};
                        5'd23: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_23};
                        5'd24: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_24};
                        5'd25: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_25};
                        5'd26: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_26};
                        5'd27: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_27};
                        5'd28: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_28};
                        5'd29: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_29};
                        5'd30: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_30};
                        5'd31: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_31};
                        // Reg 2 should always be 'h0141 (the OUI), so if reg2 = FFFF there was a problem
                        default: onchip_memory2_0_s1_writedata <= {4'hA, 3'b000, 5'h2, 4'h0, 16'hFFFF};
                        endcase
                        end else if ((dummy_wait > 0) && (dummy_wait <= 5)) begin
                            onchip_memory2_0_s1_write <= 1;
                            onchip_memory2_0_s1_chipselect <= 1;
                        end else if ((dummy_wait >= 6) || (dummy_wait < 0)) begin
                            onchip_memory2_0_s1_write <= 0;
                            onchip_memory2_0_s1_chipselect <= 0;
                        end 

                // all the PHY registers have been read and saved to RAM, just rewrite them
                end else if (phy_regs_written_to_ram >= 32) begin
                    phy_regs_written_to_ram <= 0;
                end
            // wrote all the addresses, turn on the LED
            end else begin
                reg_LED0 <= 1'b1;
                onchip_memory2_0_s1_write <= 0;
                onchip_memory2_0_s1_chipselect <= 0;
            end
        end
    end

    // When GMII interface is selected, a 125 MHz transmit clock is expected on GTX_CLK
    assign ENETA_GTX_CLK = CLK_LVDS_125_p;
    assign ENETA_TX_D = 4'hF;
    // ENETA_TX_EN: The MAC (my custon logic?) must hold TX_EN (TX_CTL) low until the MAC has
    // ensured that TX_EN (TX_CTL) is operating at the same speed as the PHY
    assign    ENETA_TX_EN = 1'b1;     //2.5v
    assign ENETA_TX_ER = 1'b0;
    assign ENETA_LED_LINK100 = 1'b1;
    // MDC is the management data clock reference for the serial management interface.
    // A continuous stream is not expected. The maximum frequency suported is 8.3 MHz.
    assign ENET_MDC = enet_mdc_clk;
    // MDIA is the management data. MDIO transfers management data in and out of the device
    // synchronoulsy to MDC. This pin requires a pull-up resistor in a range from 1.5 kohm
    // to 10 kohm
    assign ENET_MDIO = (write_enet_mdio) ? enet_mdio : 'bz;
    
    parameter [3:0] PHY_READ  = 4'b0110;
    parameter [3:0] PHY_WRITE = 4'b0101;
    parameter [4:0] PHY_ADDR =  5'b0;
    
    reg [31:0] phy_wait_after_reset_count;
    reg [13:0] bits_to_read_phy; //0110 -> READ, phy addr 00000, reg addr 00000 
    reg [15:0] bits_read_from_phy;
    reg [15:0] phy_reg_0;
    reg [15:0] phy_reg_1;
    reg [15:0] phy_reg_2;
    reg [15:0] phy_reg_3;
    reg [15:0] phy_reg_4;
    reg [15:0] phy_reg_5;
    reg [15:0] phy_reg_6;
    reg [15:0] phy_reg_7;
    reg [15:0] phy_reg_8;
    reg [15:0] phy_reg_9;
    reg [15:0] phy_reg_10;
    reg [15:0] phy_reg_11;
    reg [15:0] phy_reg_12;
    reg [15:0] phy_reg_13;
    reg [15:0] phy_reg_14;
    reg [15:0] phy_reg_15;
    reg [15:0] phy_reg_16;
    reg [15:0] phy_reg_17;
    reg [15:0] phy_reg_18;
    reg [15:0] phy_reg_19;
    reg [15:0] phy_reg_20;
    reg [15:0] phy_reg_21;
    reg [15:0] phy_reg_22;
    reg [15:0] phy_reg_23;
    reg [15:0] phy_reg_24;
    reg [15:0] phy_reg_25;
    reg [15:0] phy_reg_26;
    reg [15:0] phy_reg_27;
    reg [15:0] phy_reg_28;
    reg [15:0] phy_reg_29;
    reg [15:0] phy_reg_30;
    reg [15:0] phy_reg_31;
    reg [5:0]  phy_registers_read;
    reg [5:0]  phy_preamble_count;
    reg        phy_read_done;
    reg        turnaround_z_done;
    reg        turnaround_0_ignored;

	always @ (posedge enet_mdc_clk) begin
		if (CPU_RESETn == 0) begin
			write_enet_mdio <= 0; // drive z onto inout
		    enet_mdio_bit_count <= 0;
		    enet_mdio_read_count <= 0;
			phy_wait_after_reset_count <= 0;
			phy_read_done <= 0;
			bits_read_from_phy <= 0;
			phy_preamble_count <= 0;
			turnaround_z_done  <= 0;
			turnaround_0_ignored <= 0;
			phy_reg_0  <= 0;
			phy_reg_1  <= 0;
			phy_reg_2  <= 0;
			phy_reg_3  <= 0;
			phy_reg_4  <= 0;
			phy_reg_5  <= 0;
			phy_reg_6  <= 0;
			phy_reg_7  <= 0;
			phy_reg_8  <= 0;
			phy_reg_9  <= 0;
			phy_reg_10 <= 0;
			phy_reg_11 <= 0;
			phy_reg_12 <= 0;
			phy_reg_13 <= 0;
			phy_reg_14 <= 0;
			phy_reg_15 <= 0;
			phy_reg_16 <= 0;
			phy_reg_17 <= 0;
			phy_reg_18 <= 0;
			phy_reg_19 <= 0;
			phy_reg_20 <= 0;
			phy_reg_21 <= 0;
			phy_reg_22 <= 0;
			phy_reg_23 <= 0;
			phy_reg_24 <= 0;
			phy_reg_25 <= 0;
			phy_reg_26 <= 0;
			phy_reg_27 <= 0;
			phy_reg_28 <= 0;
			phy_reg_29 <= 0;
			phy_reg_30 <= 0;
			phy_reg_31 <= 0;
			phy_registers_read <= 0;
			bits_to_read_phy <= {PHY_READ, PHY_ADDR, phy_registers_read[4:0]};
		    reg_LED1 <= 1'b0;
		end
		// according to Marvel 88E1111 spec, phy is ready 5ms after reset.
		// count to 'd12,500 using a 2.5MHz clock to wait 5ms
		else if (phy_wait_after_reset_count < 'd125000000) begin
			phy_wait_after_reset_count <= phy_wait_after_reset_count + 1;
		end
		// first, send the 32-bit premable mentioned on page 81, Table 38
		else if (phy_preamble_count < 32) begin
			write_enet_mdio <= 1;
			enet_mdio <= 1'b1; // the premable is all 1s
			phy_preamble_count <= phy_preamble_count + 1;
		end
		// then, issue the read command to the PHY
		else if (enet_mdio_bit_count < 14) begin
			write_enet_mdio <= 1;
			bits_to_read_phy <= {PHY_READ, PHY_ADDR, phy_registers_read[4:0]};
			enet_mdio <= bits_to_read_phy[13-enet_mdio_bit_count];
			enet_mdio_bit_count <= enet_mdio_bit_count + 1;
		// then, drive the z of the turn around
		end else if (turnaround_z_done != 1) begin
			write_enet_mdio <= 0; // drive z onto inout
			turnaround_z_done <= 1;
		// then, ignore the first 0 back from ENET_MDIO
		end else if (turnaround_0_ignored != 1) begin
			write_enet_mdio <= 0; // drive z onto inout ???
			turnaround_0_ignored <= 1;
		// then, capture the PHY's read response
		end else if (enet_mdio_read_count <= 16) begin
			//phy_reg_2 <= {phy_reg_2[14:0], ENET_MDIO}; // rewrite them all to this? DELETE THIS once working
			write_enet_mdio <= 0; // drive z onto inout
			bits_read_from_phy <= {bits_read_from_phy[14:0], ENET_MDIO};
			enet_mdio_read_count <= enet_mdio_read_count + 1;
		// finished reading a PHY register, reset the counts
		end else if (phy_registers_read < 'd32) begin
			phy_registers_read <= phy_registers_read + 1;
			case(phy_registers_read)
			    5'd0:  phy_reg_0  <= bits_read_from_phy;
			    5'd1:  phy_reg_1  <= bits_read_from_phy;
			    5'd2:  phy_reg_2  <= bits_read_from_phy;
			    5'd3:  phy_reg_3  <= bits_read_from_phy;
			    5'd4:  phy_reg_4  <= bits_read_from_phy;
			    5'd5:  phy_reg_5  <= bits_read_from_phy;
			    5'd6:  phy_reg_6  <= bits_read_from_phy;
			    5'd7:  phy_reg_7  <= bits_read_from_phy;
			    5'd8:  phy_reg_8  <= bits_read_from_phy;
			    5'd9:  phy_reg_9  <= bits_read_from_phy;
			    5'd10: phy_reg_10 <= bits_read_from_phy;
			    5'd11: phy_reg_11 <= bits_read_from_phy;
			    5'd12: phy_reg_12 <= bits_read_from_phy;
			    5'd13: phy_reg_13 <= bits_read_from_phy;
			    5'd14: phy_reg_14 <= bits_read_from_phy;
			    5'd15: phy_reg_15 <= bits_read_from_phy;
			    5'd16: phy_reg_16 <= bits_read_from_phy;
			    5'd17: phy_reg_17 <= bits_read_from_phy;
			    5'd18: phy_reg_18 <= bits_read_from_phy;
			    5'd19: phy_reg_19 <= bits_read_from_phy;
			    5'd20: phy_reg_20 <= bits_read_from_phy;
			    5'd21: phy_reg_21 <= bits_read_from_phy;
			    5'd22: phy_reg_22 <= bits_read_from_phy;
			    5'd23: phy_reg_23 <= bits_read_from_phy;
			    5'd24: phy_reg_24 <= bits_read_from_phy;
			    5'd25: phy_reg_25 <= bits_read_from_phy;
			    5'd26: phy_reg_26 <= bits_read_from_phy;
			    5'd27: phy_reg_27 <= bits_read_from_phy;
			    5'd28: phy_reg_28 <= bits_read_from_phy;
			    5'd29: phy_reg_29 <= bits_read_from_phy;
			    5'd30: phy_reg_30 <= bits_read_from_phy;
			    5'd31: phy_reg_31 <= bits_read_from_phy;
                // Reg 2 should always be 'h0141 (the OUI), so if reg2 = FFFF there was a problem
			    default: phy_reg_2 <= 32'hFFFF; 
			endcase

			enet_mdio_bit_count  <= 0;
			enet_mdio_read_count <= 0;
			phy_preamble_count   <= 0;
			turnaround_z_done    <= 0;
			turnaround_0_ignored <= 0;
			bits_read_from_phy   <= 0;
		end
		else if (phy_registers_read == 'd32) begin
		    reg_LED1 <= 1'b1;
			phy_read_done <= 1;
		end
	end

	reg [3:0] enet_mdio_bit_count;
	reg [4:0] enet_mdio_read_count;
    reg       enet_mdc_clk;
	reg	      enet_mdio;
	reg       write_enet_mdio;
	reg [3:0] div_by_4_count;
	initial begin
		div_by_4_count = 0;
		enet_mdio = 0;
		enet_mdio_bit_count = 0;
		enet_mdio_read_count = 0;
	    bits_read_from_phy = 0;
		phy_registers_read = 0;
	end
	// clock divider: 25MHz down to 2.5MHz 
    always @ (posedge CLK_25_MAX10) begin
		if (div_by_4_count == 'd4) begin
			enet_mdc_clk <= ~enet_mdc_clk;
			div_by_4_count <= 0;
		end
		else begin
			div_by_4_count <= div_by_4_count + 1;
		end
    end


    /////////////////////////////////////////////////////////
    // sanity LED signals
    /////////////////////////////////////////////////////////
    reg [31:0] clock_count1, clock_count2, clock_count3;
    initial begin
        clock_count1 = 0;
        clock_count2 = 0;
        clock_count3 = 0;
    end
    // because ENETA_TX_CLK doesn't appear to be running, the PHY may be in GMII mode (not MII mode)
    //always @ (posedge ENETA_TX_CLK) begin
    //always @ (posedge CLK_LVDS_125_p) begin
    always @ (posedge enet_mdc_clk) begin
        clock_count2 <= clock_count2 + 1;
        if (clock_count2[26] == 1) begin
            //reg_LED1 <= 1'b1;
        end else begin
            //reg_LED1 <= 1'b0;
        end
    end
    always @ (posedge ENETA_RX_CLK) begin
        clock_count3 <= clock_count3 + 1;
        if (clock_count3[27] == 1) begin
            reg_LED2 <= 1'b1;
        end else begin
            reg_LED2 <= 1'b0;
        end
    end
    always @ (posedge CLK_50_MAX10) begin
        clock_count1 <= clock_count1 + 1;
        if (clock_count1[26] == 1) begin
            reg_LED3 <= 1'b1;
        end else begin
            reg_LED3 <= 1'b0;
        end
        // CPU_RESTEn is 1 if not being pushed
        if (CPU_RESETn == 0) begin
            clock_count1 <= 0;
        end
    end
    assign  USER_LED[0] = ~reg_LED0; // write to mem complete
    assign  USER_LED[1] = ~reg_LED1;
    assign  USER_LED[2] = ~reg_LED2;
    assign  USER_LED[3] = ~reg_LED3;
    assign  USER_LED[4] = ~CPU_RESETn;
	
endmodule
