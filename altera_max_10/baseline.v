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
 
module  baseline (
        //Reset and Clocks
//        input           clk_ddr3_100_p,
        input           CLK_50_MAX10,    //2.5v
        input           CLK_25_MAX10,    //2.5v 
        input           CLK_LVDS_125_p,  //2.5v 
        input           CLK_10_ADC,      //2.5v
        input           CPU_RESETn,      //3.3-v LVCMOS        
        
    `ifdef USER_PINS
        output [4:0]    USER_LED,        //1.5v
        input  [3:0]    USER_PB,         //1.5v
        input  [4:0]    USER_DIPSW,     //1.5v
    `endif
    	    
    `ifdef USB 
        input           USB_RESETn,     //3.3-v LVCMOS
        input           USB_WRn,   	//3.3-v LVCMOS  
        input           USB_RDn,   	//3.3-v LVCMOS    
        input           USB_OEn,   	//3.3-v LVCMOS    
        inout  [1:0]    USB_ADDR,  	//3.3-v LVCMOS    
        inout  [7:0]    USB_DATA,  	//3.3-v LVCMOS    
        output          USB_FULL,  	//3.3-v LVCMOS    
        output          USB_EMPTY, 	//3.3-v LVCMOS    
        input           USB_SCL,   	//3.3-v LVCMOS    
        inout           USB_SDA,   	//3.3-v LVCMOS    
        input           USB_CLK,   	//3.3-v LVCMOS    
    `endif
    `ifdef DDR3    
	output	[9:0]	DDR3_A,         //SSTL-15 CLASS I
	output	[2:0]	DDR3_BA,        //SSTL-15 CLASS I
	output		DDR3_CASn,      //SSTL-15 CLASS I
	output		DDR3_CKE,       //SSTL-15 CLASS I
	output		DDR3_CLK_p,     //DIFFERENTIAL 1.5-V SSTL-15 CLASS I
	output		DDR3_CSn,       //SSTL-15 CLASS I 
	output	[2:0]	DDR3_DM,        //SSTL-15 CLASS I
	inout	[23:0]	DDR3_DQ,        //SSTL-15 CLASS I
	inout	[2:0]	DDR3_DQS_p,     //DIFFERENTIAL 1.5-V SSTL-15 CLASS I
	output		DDR3_ODT,       //SSTL-15 CLASS I
	output 		DDR3_RASn,      //1.5v
	output		DDR3_RESEtn,    //SSTL-15 CLASS I
	output		DDR3_WEn,       //SSTL-15 CLASS I
    `endif 


    `ifdef QSPI
	output		QSPI_CSn,    //3.3-v LVCMOS 
	output		QSPI_CLK,    //3.3-v LVCMOS  
	output	[3:0]	QSPI_IO,     //3.3-v LVCMOS  
    `endif

     `ifdef ETHERNET_A
	output		ENETA_GTX_CLK,     //2.5v
	input		ENETA_TX_CLK,      //3.3-v LVCMOS
	output	[3:0]	ENETA_TX_D,     //2.5v
	output		ENETA_TX_EN,     //2.5v
	output		ENETA_TX_ER,     //2.5v
	input		ENETA_RX_CLK,     //2.5v
	input	[3:0]	ENETA_RX_D,     //2.5v
	input		ENETA_RX_DV,     //2.5v
	input		ENETA_RX_ER,     //2.5v
	input		ENETA_RESETn,     //2.5v
	input		ENETA_RX_CRS,     //2.5v
	input		ENETA_RX_COL,     //2.5v
	output		ENETA_LED_LINK100,     //2.5v
	input		ENETA_INTn,     //2.5v
	output 		ENET_MDC,     //2.5v
	inout		ENET_MDIO,     //2.5v
     `endif
	
    `ifdef ETHERNET_B	
        output		ENETB_GTX_CLK,     //2.5v
        input		ENETB_TX_CLK,      //3.3v
        output	[3:0]	ENETB_TX_D,     //2.5v
        output		ENETB_TX_EN,     //2.5v
        output		ENETB_TX_ER,     //2.5v
        input		ENETB_RX_CLK,     //2.5v
        input	[3:0]	ENETB_RX_D,     //2.5v
        input		ENETB_RX_DV,     //2.5v
        input		ENETB_RX_ER,     //2.5v
        input		ENETB_RESETn,     //2.5v
        input		ENETB_RX_CRS,     //2.5v
        input		ENETB_RX_COL,     //2.5v
        output		ENETB_LED_LINK100,     //2.5v
	input		ENETB_INTn,     //2.5v
     `endif

     `ifdef UART
	output		UART_TX,     //2.5v
	input		UART_RX,     //2.5v
     `endif

     `ifdef HSMC
        input 	[2:1]	HSMC_CLK_IN_p,     //2.5v
        input       	HSMC_CLK_IN0,     //2.5v
        output	[2:1] 	HSMC_CLK_OUT_p,     //2.5v
	output	        HSMC_CLK_OUT0,	     //2.5v
        input 	[16:0]	HSMC_RX_D_p,     //2.5v
        output	[16:0]	HSMC_TX_D_p,     //2.5v
	inout	[3:0]	HSMC_D,     //2.5v
	inout		HSMC_SDA,     //2.5v
	output		HSMC_SCL,     //2.5v
	input		HSMC_PRSNTn,     //2.5v
     `endif
  	
     `ifdef HDMI
	output	[23:0]	HDMI_TX_D,     //3.3-v LVCMOS  
	output		HDMI_TX_CLK,   //3.3-v LVCMOS   
	output		HDMI_TX_DE,    //3.3-v LVCMOS   
	output		HDMI_TX_HS,    //3.3-v LVCMOS   
	output		HDMI_TX_VS,    //3.3-v LVCMOS   
	input		HDMI_TX_INT,   //3.3-v LVCMOS   
	inout		HDMI_SCL,      //3.3-v LVCMOS 
	inout		HDMI_SDA,      //3.3-v LVCMOS 
     `endif
	
     `ifdef PMOD
        inout 	[7:0] 	PMODA_IO,       //3.3-v LVCMOS
        inout 	[7:0] 	PMODB_IO,       //3.3-v LVCMOS
     `endif
   
     `ifdef DAC
        output        	DAC_SYNC,       //3.3-v LVCMOS
        output        	DAC_SCLK,       //3.3-v LVCMOS
        output        	DAC_DIN,        //3.3-v LVCMOS
     `endif
   
     `ifdef GPIO
        input	[8:1] 	ADC1IN,       //2.5v
        input 	[8:1] 	ADC2IN,       //2.5v
     `endif
   
     `ifdef JTAG
        inout        	IP_SECURITY,    //3.3-v LVCMOS 
        output        	JTAG_SAFE       //3.3-v LVCMOS
     `endif

        ); 

endmodule
