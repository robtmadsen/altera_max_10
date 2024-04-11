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

	`ifndef COCOTB_SIM // no need to include the nios II/e core
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
	`endif

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

    localparam RAM_DELIMITER = 32'hAAAAAAAA;
    
    reg[17:0] dummy_wait;
    reg       add_delimiter;
    initial begin
        dummy_wait = 0;
        //add_delimiter = 1;
    end
    initial begin
        onchip_memory2_0_s1_writedata = 0;
        onchip_memory2_0_s1_write = 0;
    end
    always @ (posedge ENETA_RX_CLK) begin
        if (CPU_RESETn == 0) begin
            //onchip_memory2_0_s1_address <= 0;
            onchip_memory2_0_s1_address <= 'h400; // for some reason the bottom 'd700 odd addresses aren't being written
            onchip_memory2_0_s1_write <= 0;
            onchip_memory2_0_s1_chipselect <= 0;
            reg_LED0 <= 1'b0;
            onchip_memory2_0_s1_writedata <= {32'hBEEFBEEF};
            ram_writes_per_phy_addr <= 0;
            phy_regs_written_to_ram <= 0;
            phy_reg_write_done <= 1'b0;
            add_delimiter <= 1'b1;
        end else begin
            // doesn't start writing until address 'h4B1C (or thereabouts)
            if (onchip_memory2_0_s1_address < 13'h1000) begin
                dummy_wait <= dummy_wait + 1;

                // this bit is driven by the FSM that's reading/writing the PHY
                if (write_phy_reg_space_to_ram == 0) begin
                // do nothing until the entire PHY register space has been read
                    
                    phy_reg_write_done <= 1'b0;
                    phy_regs_written_to_ram <= 0;
                end else if (phy_regs_written_to_ram < 'd32) begin
                    // the update cycle
                    if (dummy_wait == 0) begin
                        onchip_memory2_0_s1_address <= onchip_memory2_0_s1_address + 1;
                        // delimiters don't increase these counters
                        //if (add_delimiter == 1'b0) begin
                            ram_writes_per_phy_addr <= ram_writes_per_phy_addr + 1;
                            if (ram_writes_per_phy_addr == 'd7) begin
                                phy_regs_written_to_ram <= phy_regs_written_to_ram + 1;
                                ram_writes_per_phy_addr <= 0;
                                add_delimiter <= 1; // reprint the delimiter next time we're at reg 0
                            end
                        //end
                        case(phy_regs_written_to_ram)
                        5'd0:  begin
                            if (add_delimiter) begin
                                onchip_memory2_0_s1_writedata <= RAM_DELIMITER;
                                add_delimiter <= 0; // print the actual data next time
                            end else begin
                                onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_0};
                            end
                        end
                        5'd1:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_1};
                        5'd2:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_2};
                        5'd3:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_3};
                        5'd4:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_4};
                        5'd5:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_5};
                        5'd6:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_6};
                        5'd7:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_7};
                        5'd8:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_8};
                        5'd9:  onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_9};
                        5'd10: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_10};
                        5'd11: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_11};
                        5'd12: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_12};
                        5'd13: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_13};
                        5'd14: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_14};
                        5'd15: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_15};
                        5'd16: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_16};
                        5'd17: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_17};
                        5'd18: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_18};
                        5'd19: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_19};
                        5'd20: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_20};
                        5'd21: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_21};
                        5'd22: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_22};
                        5'd23: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_23};
                        5'd24: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_24};
                        5'd25: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_25};
                        5'd26: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_26};
                        5'd27: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_27};
                        5'd28: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_28};
                        5'd29: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_29};
                        5'd30: onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_30};
                        5'd31: begin
                            if (ram_writes_per_phy_addr == 'd7) begin
                                onchip_memory2_0_s1_writedata <= RAM_DELIMITER;
                                //add_delimiter <= 0; // print the actual data next time
                            end else begin
                                onchip_memory2_0_s1_writedata <= {4'hB, 3'b000, phy_regs_written_to_ram[4:0], 4'h0, phy_reg_31};
                            end
                        end
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
                    //phy_regs_written_to_ram <= 0;
                    phy_reg_write_done <= 1'b1;
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
    
    // See Marvell 88E1111 Datasheet page 81
    parameter [3:0] PHY_READ  = 4'b0110;
    parameter [3:0] PHY_WRITE = 4'b0101;
    parameter [4:0] PHY_ADDR =  5'b0;
    parameter [1:0] PHY_WR_TURNAROUND = 2'b10;
    //parameter [15:0] REG0_LOOPBACK = 16'h5140; //Default is 'h1140 -> flip 14th bit. 0101_0001_0100_0000


    parameter [15:0] REG0_LOOPBACK = 16'hA280; //DELETE THIS, just for testing

/*
    'h5140 -> 'h2880
    'h5141 -> 'h2880 in sim, same as with 'h5140 ...
    'h5143 -> also leads to 'h2880 in sim
    'h5147 -> also leads to 'h2880 in sim ... 
    'hD147 -> leads to 'h6880

    'h5140: 0101_0001_0100_0000 --> 0010_1000_1000_0000
    'hD147: 1101_0001_0100_0111 --> 0110_1000_1000_0000
    (new 15th bit mapped to 14th bit. )

    hack: use this (and every bit will be one pos lower?)  1010_00010_1000_0000 = 'hA280


*/

    
    reg [31:0] phy_wait_after_reset_count;
    reg [13:0] serial_rd_cmd_to_phy; //0110 -> READ, phy addr 00000, reg addr 00000 
    reg [15:0] serial_wr_cmd_to_phy; //0101 -> WRITE, phy addr 00000, reg addr 00000, turnaround 10 
    reg [15:0] serial_wr_data_to_phy;
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
    reg        write_phy_reg_space_to_ram;
    reg        set_reg0_to_loopback;
    reg        reg0_in_loopback;
    reg        phy_reg_write_done;
    reg        turnaround_z_done;
    reg        turnaround_0_ignored;

    localparam  RESET_s           = 4'h0,
                POST_RST_WAIT_s   = 4'h1,
                PHY_PREAMBLE_s    = 4'h2,
                SEND_READ_CMD_s   = 4'h3,
                TURNAROUND_z_s    = 4'h4,
                TURNAROUND_0_s    = 4'h5,
                READ_s            = 4'h6,
                STORE_READ_DATA_s = 4'h7,
                WAIT_FOR_RAM_WRITE_s   = 4'h8,
                ENABLE_LOOPBACK_s = 4'h9,
                SEND_WRITE_CMD_s = 4'hA,
                SEND_WRITE_DATA_s = 4'hB;
                // TODO add placeholder states for the rest of the bits
    reg [3:0]   current_state, next_state;

    always @ (posedge enet_mdc_clk) begin
        if (CPU_RESETn == 0) begin
            current_state <= RESET_s;
        end else begin
            current_state <= next_state;
        end
    end

    always @ (*) begin
        next_state = current_state; // default value
        if (CPU_RESETn == 0) begin
            next_state = RESET_s;
        end 
        else begin
            case (current_state)
                RESET_s : begin
                    if (CPU_RESETn == 1) next_state = POST_RST_WAIT_s;
                end
                POST_RST_WAIT_s : begin
                    if (phy_wait_after_reset_count == 'd125000000) next_state = PHY_PREAMBLE_s;
                end
                PHY_PREAMBLE_s : begin
                    if (phy_preamble_count == 'd32) begin
                        if (set_reg0_to_loopback) next_state = SEND_WRITE_CMD_s;
                        else                      next_state = SEND_READ_CMD_s;
                    end
                end
                SEND_READ_CMD_s : begin
                    if (enet_mdio_bit_count == 'd14) next_state = TURNAROUND_z_s;
                end
                SEND_WRITE_CMD_s : begin
                    // 2 more bits because contains 2-bit turnaround
                    if (enet_mdio_wr_cmd_count == 'd16 /*4/6/24 registers unwritable unless 'd16*/) next_state = SEND_WRITE_DATA_s;
                end
                SEND_WRITE_DATA_s : begin
                    if (enet_mdio_write_count == 'd15) next_state = PHY_PREAMBLE_s; // but with set_reg0_to_loopback deasserted
                end
                TURNAROUND_z_s : begin
                    next_state = TURNAROUND_0_s;
                end
                TURNAROUND_0_s : begin
                    next_state = READ_s;
                end
                READ_s : begin
                    if (enet_mdio_read_count == 'd15 /*?*/) next_state = STORE_READ_DATA_s;
                end
                STORE_READ_DATA_s : begin
                    if (phy_registers_read == 'd31 /*?*/) next_state = WAIT_FOR_RAM_WRITE_s;
                    else next_state = PHY_PREAMBLE_s; 
                end
                WAIT_FOR_RAM_WRITE_s : begin
                    if ((phy_reg_write_done == 1'd1) && (reg0_in_loopback == 1'b0)) next_state = ENABLE_LOOPBACK_s;
                end
                ENABLE_LOOPBACK_s : begin
                    next_state = PHY_PREAMBLE_s; // with set_reg0_to_loopback asserted
                end
                // TODO add placeholder states
            endcase
        end
    end

    always @ (posedge enet_mdc_clk) begin
        case (current_state)
        RESET_s : begin
            write_enet_mdio <= 0; // drive z onto inout
            enet_mdio_bit_count <= 0;
            enet_mdio_read_count <= 0;
            enet_mdio_write_count <= 0;
            enet_mdio_wr_cmd_count <= 0;
            phy_wait_after_reset_count <= 0;
            write_phy_reg_space_to_ram <= 0;
            set_reg0_to_loopback <= 0;
            reg0_in_loopback <= 0;
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
            serial_rd_cmd_to_phy <= {PHY_READ, PHY_ADDR, phy_registers_read[4:0]};
            serial_wr_cmd_to_phy <= {PHY_WRITE, PHY_ADDR, 5'b0_0000, PHY_WR_TURNAROUND};
            serial_wr_data_to_phy <= {REG0_LOOPBACK};
            reg_LED1 <= 1'b0;
        end
        POST_RST_WAIT_s: begin
            phy_wait_after_reset_count <= phy_wait_after_reset_count + 1;
        end
        PHY_PREAMBLE_s : begin
            write_enet_mdio <= 1;
            enet_mdio <= 1'b1; // the premable is all 1s
            phy_preamble_count <= phy_preamble_count + 1;
            enet_mdio_write_count <= 0;
            enet_mdio_wr_cmd_count <= 0; // probably redundant
        end
        SEND_READ_CMD_s : begin
            write_enet_mdio <= 1;
            serial_rd_cmd_to_phy <= {PHY_READ, PHY_ADDR, phy_registers_read[4:0]};
            enet_mdio <= serial_rd_cmd_to_phy[13-enet_mdio_bit_count];
            enet_mdio_bit_count <= enet_mdio_bit_count + 1;
        end
        SEND_WRITE_CMD_s : begin
            write_enet_mdio <= 1;
            serial_wr_cmd_to_phy <= {PHY_WRITE, PHY_ADDR, 5'b0_0000, PHY_WR_TURNAROUND}; // temporarily (?) hardcoded to Register 0
            enet_mdio <= serial_wr_cmd_to_phy[15-enet_mdio_wr_cmd_count];
            enet_mdio_wr_cmd_count <= enet_mdio_wr_cmd_count + 1;
        end
        SEND_WRITE_DATA_s : begin
            serial_wr_data_to_phy <= {REG0_LOOPBACK}; // redundant?
            set_reg0_to_loopback <= 0; // deassert this so that when done writing to the PHY, the READ flow starts again
            reg0_in_loopback <= 1; // it will be (ideally) once out of this state. A flag preventing the FSM from continually writing Reg0
            write_enet_mdio <= 1;
            enet_mdio <= serial_wr_data_to_phy[15-enet_mdio_write_count];
            enet_mdio_write_count <= enet_mdio_write_count + 1;
        end
        TURNAROUND_z_s : begin
            write_enet_mdio <= 0; // drive z onto inout
        end
        TURNAROUND_0_s : begin
            write_enet_mdio <= 0; // drive z onto inout
        end
        READ_s : begin
            write_enet_mdio <= 0; // drive z onto inout
            bits_read_from_phy <= {bits_read_from_phy[14:0], ENET_MDIO};
            enet_mdio_read_count <= enet_mdio_read_count + 1;
        end
        STORE_READ_DATA_s : begin
            phy_registers_read <= phy_registers_read + 1;
            case(phy_registers_read)
                // 'h1140 by default: 0001_0001_0100_0000
                // For loopback, set 0.14 = 1
                // -> 0101_0001_0100_0000 = 'h5140
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
        WAIT_FOR_RAM_WRITE_s : begin
            reg_LED1 <= 1'b1;
            write_phy_reg_space_to_ram <= 1;
            phy_registers_read <= 0;
        end
        ENABLE_LOOPBACK_s : begin
            reg_LED1 <= 1'b0;
            write_phy_reg_space_to_ram <= 0; // stop writing to RAM
            set_reg0_to_loopback <= 1;
            enet_mdio_bit_count  <= 0; // probably redundant
        end
        // TODO add placeholder states
        endcase
    end

    reg [4:0] enet_mdio_bit_count;
    reg [4:0] enet_mdio_read_count;
    reg [4:0] enet_mdio_write_count;
    reg [4:0] enet_mdio_wr_cmd_count;
    reg       enet_mdc_clk;
    reg	      enet_mdio;
    reg       write_enet_mdio;
    reg [3:0] div_by_4_count;
    initial begin
        div_by_4_count = 0;
        enet_mdio = 0;
        enet_mdio_bit_count = 0;
        enet_mdio_read_count = 0;
        enet_mdio_write_count = 0;
        enet_mdio_wr_cmd_count = 0;
        bits_read_from_phy = 0;
        phy_registers_read = 0;
    end
    // clock divider: 25MHz down to 2.5MHz 
    always @ (posedge CLK_25_MAX10) begin
        if (div_by_4_count == 'd4) begin
            enet_mdc_clk <= ~enet_mdc_clk;
            div_by_4_count <= 0;
        end else begin
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
