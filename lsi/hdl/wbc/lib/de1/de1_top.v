//
// Copyright (c) 2014-2019 by 1801BM1@gmail.com
//
// Top module for DE1 board based system
//______________________________________________________________________________
//
// synopsys translate_off
`include "../../lib/de1/config.v"
// synopsys translate_on
//
`define  DE1_DCLO_WIDTH_CLK         15
`define  DE1_ACLO_DELAY_CLK         7

//______________________________________________________________________________
//
// Initialized RAM block - 8K x 16
//
module wbc_mem
(
   input          wb_clk_i,
   input  [15:0]  wb_adr_i,
   input  [15:0]  wb_dat_i,
   output [15:0]  wb_dat_o,
   input          wb_cyc_i,
   input          wb_we_i,
   input  [1:0]   wb_sel_i,
   input          wb_stb_i,
   output         wb_ack_o
);
wire [1:0] ena;
reg [1:0]ack;

de1_ram16k ram(
   .address(wb_adr_i[13:1]),
   .byteena(ena),
   .clock(wb_clk_i),
   .data(wb_dat_i),
   .wren( wb_we_i & wb_cyc_i & wb_stb_i),
   .q(wb_dat_o));

assign ena = wb_we_i ? wb_sel_i : 2'b11;
assign wb_ack_o = wb_cyc_i & wb_stb_i & (ack[1] | wb_we_i);
always @ (posedge wb_clk_i)
begin
   ack[0] <= wb_cyc_i & wb_stb_i;
   ack[1] <= wb_cyc_i & ack[0];
end
endmodule

//______________________________________________________________________________
//
// Top project module - instantiates the DE1 board itself
//
module de1
(
   input    [1:0] de1_clock_24,        // clock input 24 MHz
   input    [1:0] de1_clock_27,        // clock input 27 MHz
   input          de1_clock_50,        // clock input 50 MHz
   input          de1_clock_ext,       // external clock input
                                       //
   input    [3:0] de1_button,          // push button[3:0]
                                       //
   input    [9:0] de1_sw,              // DPDT toggle switch[9:0]
   output   [6:0] de1_hex0,            // seven segment digit 0
   output   [6:0] de1_hex1,            // seven segment digit 1
   output   [6:0] de1_hex2,            // seven segment digit 2
   output   [6:0] de1_hex3,            // seven segment digit 3
   output   [7:0] de1_ledg,            // LED green[7:0]
   output   [9:0] de1_ledr,            // LED red[9:0]
                                       //
   output         de1_uart_txd,        // UART transmitter
   input          de1_uart_rxd,        // UART receiver
                                       //
   inout   [15:0] de1_dram_dq,         // SDRAM data bus 16 bits
   output  [11:0] de1_dram_addr,       // SDRAM address bus 12 bits
   output         de1_dram_ldqm,       // SDRAM low-byte data mask
   output         de1_dram_udqm,       // SDRAM high-byte data mask
   output         de1_dram_we_n,       // SDRAM write enable
   output         de1_dram_cas_n,      // SDRAM column address strobe
   output         de1_dram_ras_n,      // SDRAM row address strobe
   output         de1_dram_cs_n,       // SDRAM chip select
   output   [1:0] de1_dram_ba,         // SDRAM bank address
   output         de1_dram_clk,        // SDRAM clock
   output         de1_dram_cke,        // SDRAM clock enable
                                       //
   inout    [7:0] de1_fl_dq,           // FLASH data bus 8 Bits
   output  [21:0] de1_fl_addr,         // FLASH address bus 22 Bits
   output         de1_fl_we_n,         // FLASH write enable
   output         de1_fl_rst_n,        // FLASH reset
   output         de1_fl_oe_n,         // FLASH output enable
   output         de1_fl_ce_n,         // FLASH chip enable
                                       //
   inout   [15:0] de1_sram_dq,         // SRAM Data bus 16 Bits
   output  [17:0] de1_sram_addr,       // SRAM Address bus 18 Bits
   output         de1_sram_ub_n,       // SRAM High-byte Data Mask
   output         de1_sram_lb_n,       // SRAM Low-byte Data Mask
   output         de1_sram_we_n,       // SRAM Write Enable
   output         de1_sram_ce_n,       // SRAM Chip Enable
   output         de1_sram_oe_n,       // SRAM Output Enable
                                       //
   inout          de1_sd_mosi,         // SD Card Data Output
   inout          de1_sd_miso,         // SD Card Data Input
   inout          de1_sd_cmd,          // SD Card Command Signal
   output         de1_sd_clk,          // SD Card Clock
                                       //
   input          de1_tdi,             // CPLD -> FPGA (data in)
   input          de1_tck,             // CPLD -> FPGA (clk)
   input          de1_tms,             // CPLD -> FPGA (mode select)
   output         de1_tdo,             // FPGA -> CPLD (data out)
                                       //
   inout          de1_i2c_dat,         // I2C Data
   output         de1_i2c_clk,         // I2C Clock
   inout          de1_ps2_dat,         // PS2 Data
   inout          de1_ps2_clk,         // PS2 Clock
                                       //
   output         de1_vga_hs,          // VGA H_SYNC
   output         de1_vga_vs,          // VGA V_SYNC
   output   [3:0] de1_vga_r,           // VGA Red[3:0]
   output   [3:0] de1_vga_g,           // VGA Green[3:0]
   output   [3:0] de1_vga_b,           // VGA Blue[3:0]
                                       //
   output         de1_aud_adclrck,     // Audio CODEC ADC LR Clock
   input          de1_aud_adcdat,      // Audio CODEC ADC Data
   output         de1_aud_daclrck,     // Audio CODEC DAC LR Clock
   output         de1_aud_dacdat,      // Audio CODEC DAC Data
   inout          de1_aud_bclk,        // Audio CODEC Bit-Stream Clock
   output         de1_aud_xck,         // Audio CODEC Chip Clock
                                       //
   inout [35:0]   de1_gpio0,           // GPIO Connection 0
   inout [35:0]   de1_gpio1            // GPIO Connection 1
);

//______________________________________________________________________________
//
wire        clk50;                     // 50 MHz clock source entry
wire        sys_clk_p;                 // system positive clock (all buses)
wire        sys_clk_n;                 // system negative clock (180 phase shift)
wire        sys_init;                  // peripheral reset
wire        sys_plock;                 //
wire        ena_us, ena_ms, i50Hz;     //
wire        pwr_rst, sys_rst;          //
wire [1:0]  bsel;                      //
                                       //
wire        wb_clk;                    //
wire [15:0] wb_adr;                    // master address out bus
wire [15:0] wb_out;                    // master data out bus
wire [15:0] wb_mux;                    // master data in bus
wire        wb_cyc;                    // master wishbone cycle
wire        wb_we;                     // master wishbone direction
wire [1:0]  wb_sel;                    // master wishbone byte election
wire        wb_stb;                    // master wishbone strobe
wire        wb_ack;                    // master wishbone acknowledgement
                                       //
wire        vm_istb;                   //
wire        vm_iack;                   //
wire [15:0] vm_ivec;                   //
wire [2:0]  mx_stb;                    //
wire [2:0]  mx_ack;                    // system wishbone data mux
wire [15:0] mx_dat[2:0];               //
                                       //
wire [15:0] vm_in14;                   //
reg  [15:0] vm_reg0, vm_reg1;          //
                                       //
wire        vm_init_out;               //
wire        vm_dclo_in;                //
wire        vm_aclo_in;                //
wire        vm_virq;                   //
wire        vm_halt;                   //
wire        vm_evnt;                   //
                                       //
wire        tx_irq, tx_ack;            //
wire        rx_irq, rx_ack;            //
wire [31:0] baud;                      //
                                       //
//______________________________________________________________________________
//
assign      sys_init = vm_init_out;
assign      baud = 921600/115200-1;

assign      vm_halt  = 1'b0;
assign      vm_evnt  = i50Hz & de1_sw[0];

//______________________________________________________________________________
//
// System Reset and Clock controller
//
assign wb_clk  = sys_clk_p;
assign clk50   = de1_clock_50;
assign bsel    = `SIM_CONFIG_BOOT_MODE;

de1_pll60 corepll
(
   .inclk0(clk50),
   .c0(sys_clk_p),
   .c1(sys_clk_n),
   .locked(sys_plock)
);

defparam reset.OSCCLK      = `CONFIG_OSC_CLOCK;
defparam reset.REFCLK      = `CONFIG_SYS_CLOCK;
defparam reset.PWR_WIDTH   = `CONFIG_RESET_PULSE_WIDTH_CLK;
defparam reset.DEBOUNCE    = `CONFIG_RESET_BUTTON_DEBOUNCE_MS;
defparam reset.DCLO_WIDTH  = `DE1_DCLO_WIDTH_CLK;
defparam reset.ACLO_DELAY  = `DE1_ACLO_DELAY_CLK;
defparam reset.SYSTICK     = 20000;

wbc_rst reset
(
   .osc_clk(clk50),
   .sys_clk(wb_clk),
   .pll_lock(sys_plock),
   .button(de1_button[0]),
   .sys_ready(1'b1),

   .pwr_rst(pwr_rst),
   .sys_rst(sys_rst),
   .sys_dclo(vm_dclo_in),
   .sys_aclo(vm_aclo_in),
   .sys_us(ena_us),
   .sys_ms(ena_ms),
   .sys_irq(i50Hz)
);

//______________________________________________________________________________
//
// CPU instantiation
//
lsi_wb cpu
(
   .vm_clk_p(sys_clk_p),               // positive processor clock
   .vm_clk_n(sys_clk_n),               // negative processor clock
   .vm_clk_slow(1'b0),                 // slow clock sim mode
   .vm_clk_ena(1'b1),                  // slow clock strobe
                                       //
   .vm_init(vm_init_out),              // peripheral reset
   .vm_dclo(vm_dclo_in),               // processor reset
   .vm_aclo(vm_aclo_in),               // power fail notoficaton
   .vm_halt(vm_halt),                  // halt mode interrupt request
   .vm_evnt(vm_evnt),                  // timer interrupt request
   .vm_virq(vm_virq),                  // vectored interrupt request
   .vm_bsel(bsel),                     //
                                       //
   .wbm_gnt_i(1'b1),                   // master wishbone granted
   .wbm_adr_o(wb_adr),                 // master wishbone address
   .wbm_dat_o(wb_out),                 // master wishbone data output
   .wbm_dat_i(wb_mux),                 // master wishbone data input
   .wbm_cyc_o(wb_cyc),                 // master wishbone cycle
   .wbm_we_o(wb_we),                   // master wishbone direction
   .wbm_sel_o(wb_sel),                 // master wishbone byte election
   .wbm_stb_o(wb_stb),                 // master wishbone strobe
   .wbm_ack_i(wb_ack),                 // master wishbone acknowledgement
                                       //
   .wbi_dat_i(vm_ivec),                // interrupt vector input
   .wbi_stb_o(vm_istb),                // interrupt vector strobe
   .wbi_ack_i(vm_iack)                 // interrupt vector acknowledgement
);

wire de1_lcd_rs;
wire de1_lcd_en;
wire [7:0] de1_lcd_data;

wire de1_uart_rts;
wire de1_uart_cts;

assign de1_uart_rts = 1'b0;
//______________________________________________________________________________
//
wbc_mem mem(
   .wb_clk_i(wb_clk),
   .wb_adr_i(wb_adr),
   .wb_dat_i(wb_out),
   .wb_dat_o(mx_dat[1]),
   .wb_cyc_i(wb_cyc),
   .wb_we_i(wb_we),
   .wb_sel_i(wb_sel),
   .wb_stb_i(mx_stb[1]),
   .wb_ack_o(mx_ack[1])
);

//______________________________________________________________________________
//
`ifdef CONFIG_SYS_CLOCK
defparam uart.REFCLK = `CONFIG_SYS_CLOCK;
`endif

wbc_uart uart
(
   .wb_clk_i(wb_clk),
   .wb_rst_i(sys_init),
   .wb_adr_i(wb_adr[2:0]),
   .wb_dat_i(wb_out),
   .wb_dat_o(mx_dat[2]),
   .wb_cyc_i(wb_cyc),
   .wb_we_i(wb_we),
   .wb_stb_i(mx_stb[2]),
   .wb_ack_o(mx_ack[2]),

   .tx_dat_o(de1_uart_txd),
   .tx_cts_i(de1_uart_rts),
   .rx_dat_i(de1_uart_rxd),
   .rx_dtr_o(de1_uart_cts),

   .tx_irq_o(tx_irq),
   .tx_ack_i(tx_ack),
   .rx_irq_o(rx_irq),
   .rx_ack_i(rx_ack),

   .cfg_bdiv(baud[15:0]),
   .cfg_nbit(2'b11),
   .cfg_nstp(1'b1),
   .cfg_pena(1'b0),
   .cfg_podd(1'b0)
);

wbc_vic #(.N(2)) vic
(
   .wb_clk_i(wb_clk),
   .wb_rst_i(vm_dclo_in),
   .wb_irq_o(vm_virq),
   .wb_dat_o(vm_ivec),
   .wb_stb_i(vm_istb),
   .wb_ack_o(vm_iack),
   .wb_una_i(1'b0),
   .rsel(16'h0000),
   .ivec({16'o000064, 16'o000060}),
   .ireq({tx_irq, rx_irq}),
   .iack({tx_ack, rx_ack})
);

//______________________________________________________________________________
//
assign mx_stb[0]  = wb_stb & wb_cyc & (wb_adr[15:4] == (16'o177700 >> 4));
assign mx_stb[1]  = wb_stb & wb_cyc & (wb_adr[15:14] == 2'o0);
assign mx_stb[2]  = wb_stb & wb_cyc & (wb_adr[15:3] == (16'o177560 >> 3));

assign wb_ack     = mx_ack[0] | mx_ack[1] | mx_ack[2];
assign wb_mux     = (mx_stb[0] ? mx_dat[0] : 16'o000000)
                  | (mx_stb[1] ? mx_dat[1] : 16'o000000)
                  | (mx_stb[2] ? mx_dat[2] : 16'o000000);
//______________________________________________________________________________
//
//
// Simulation stop flag and console
//
assign de1_lcd_rs    = wb_stb & wb_cyc & (wb_adr[15:0] == 16'o000172);
assign de1_lcd_data  = wb_out[7:0];
assign de1_lcd_en    = (wb_adr[15:0] == 16'o177566) & wb_stb & wb_we & wb_ack;

//______________________________________________________________________________
//
// 7-segment display registers and switches
//
assign de1_hex0      = ~vm_reg0[6:0];
assign de1_hex1      = ~vm_reg0[14:8];
assign de1_hex2      = ~vm_reg1[6:0];
assign de1_hex3      = ~vm_reg1[14:8];

always @(posedge wb_clk)
begin
   if (sys_init)
   begin
      vm_reg0 <= 16'o000000;
      vm_reg1 <= 16'o000000;
   end
   else
   begin
      if (mx_stb[0] & wb_we & ~wb_adr[0]) vm_reg0 <= wb_out;
      if (mx_stb[0] & wb_we &  wb_adr[0]) vm_reg1 <= wb_out;
   end
end

assign vm_in14[3:0]     = de1_button;
assign vm_in14[13:4]    = de1_sw;
assign vm_in14[15:14]   = 2'b00;
assign mx_dat[0]        = vm_in14;
assign mx_ack[0]        = mx_stb[0];

assign de1_ledr[0]      = de1_sw[0];
assign de1_ledr[1]      = vm_dclo_in;
assign de1_ledr[2]      = vm_aclo_in;
assign de1_ledr[3]      = sys_rst;
assign de1_ledr[4]      = pwr_rst;
assign de1_gpio1[7:0]   = de1_lcd_data;
assign de1_gpio1[8]     = de1_lcd_rs;
assign de1_gpio1[9]     = de1_lcd_en;


//______________________________________________________________________________
//
// Temporary and debug assignments
//
assign   de1_dram_dq    = 16'hzzzz;
assign   de1_dram_addr  = 12'h000;
assign   de1_dram_ldqm  = 1'b0;
assign   de1_dram_udqm  = 1'b0;
assign   de1_dram_we_n  = 1'b1;
assign   de1_dram_cas_n = 1'b1;
assign   de1_dram_ras_n = 1'b1;
assign   de1_dram_cs_n  = 1'b1;
assign   de1_dram_ba[0] = 1'b0;
assign   de1_dram_ba[1] = 1'b0;
assign   de1_dram_clk   = 1'b0;
assign   de1_dram_cke   = 1'b0;

assign   de1_fl_dq      = 7'hzz;
assign   de1_fl_addr    = 22'hzzzzzz;
assign   de1_fl_we_n    = 1'b1;
assign   de1_fl_rst_n   = 1'b0;
assign   de1_fl_oe_n    = 1'b1;
assign   de1_fl_ce_n    = 1'b1;

assign   de1_sram_dq    = 16'hzzzz;
assign   de1_sram_addr  = 18'h00000;
assign   de1_sram_we_n  = 1'b1;
assign   de1_sram_ce_n  = 1'b1;
assign   de1_sram_oe_n  = 1'b1;
assign   de1_sram_lb_n  = 1'b1;
assign   de1_sram_ub_n  = 1'b1;

assign   de1_sd_clk     = 1'b0;
assign   de1_sd_mosi    = 1'hz;
assign   de1_sd_miso    = 1'hz;
assign   de1_sd_cmd     = 1'hz;

assign   de1_ps2_dat    = 1'hz;
assign   de1_ps2_clk    = 1'hz;
assign   de1_i2c_dat    = 1'hz;
assign   de1_i2c_clk    = 1'hz;

assign   de1_vga_hs     = 1'b0;
assign   de1_vga_vs     = 1'b0;
assign   de1_vga_r      = 4'h0;
assign   de1_vga_g      = 4'h0;
assign   de1_vga_b      = 4'h0;

assign   de1_gpio0         = 36'hzzzzzzzzz;
assign   de1_gpio1[35:10]  = 26'hzzzzzzz;
assign   de1_ledg          = 8'hzz;
assign   de1_ledr[9:5]     = 5'hzz;

assign   de1_aud_adclrck = 1'b0;
assign   de1_aud_daclrck = 1'b0;
assign   de1_aud_dacdat  = 1'b0;
assign   de1_aud_xck     = 1'b0;

//______________________________________________________________________________
//
endmodule
