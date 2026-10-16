// altair_neptunoplus.sv — NeptUNO+ bridge for Cidelsa "Altair" (1981) / "Altair II"
//
// Same structure as cores/destroyer/neptunoplus/destroyer_neptunoplus.sv (same upstream repo,
// jlrh/cidelsa-fpga, same VIS-based hardware family): the upstream top (hdl/mister/Altair.sv,
// module `emu`) is MiSTer-only (hps_io + Template_MiSTer sys/), while ../hdl/rtl/altair_machine.v is
// protocol-agnostic (plain in0/in1/in2/ef_ext, plain ioctl_rom_* download bus). This file is a
// MiST-style board wrapper (user_io/data_io/arcade_inputs/mist_dual_video/dac) wired to
// altair_machine the way Altair.sv wires it to hps_io. See neptunoplus/NOTES.md.
//
// NeptUNO+-specific pieces, same as destroyer: microSD SPI pass-through and DB9 joystick relay.
//
// No SDRAM: program ROM and NVRAM are on-chip BRAM loaded over ioctl_rom_*. The one PLL is
// bridge-owned (altair_machine has none) — same pll.v as destroyer (50MHz -> 30MHz). Upstream's
// own MiSTer pll runs at 28.13MHz; ce_pix/ce_cpu are phase-accumulator enables computed from
// CLK_KHZ, so only CLK_KHZ changes (30000 instead of 28130), the enable rates stay identical.
//
// Vertical game: like every bridge in this repo video is passed through raw (rotate_screen=0,
// needs SDRAM); "Orientation" only rotates the OSD for a physically-rotated monitor.
//
// The game logic under ../hdl/ is never modified in place (see neptunoplus/patches/).

`include "build_id.v"

module altair_neptunoplus(
    input        [1:0] CLOCK_27,   // [0]=50MHz reference, [1] unused

    output              LED,
    output        [7:0] VGA_R,
    output        [7:0] VGA_G,
    output        [7:0] VGA_B,
    output              VGA_HS,
    output              VGA_VS,

    output              AUDIO_L,
    output              AUDIO_R,

    input               SPI_SCK,
    inout               SPI_DO,
    input               SPI_DI,
    input               SPI_SS2,
    input               SPI_SS3,
    input               SPI_SS4,
    input               CONF_DATA0,

    input               SD_SCK,
    input               SD_MISO,

    output              JOY_CLK,
    output              JOY_LOAD,
    input               JOY_DATA,
    output              JOY_SELECT,
    input               XJOY_CLK,
    input               XJOY_LOAD,
    output              XJOY_DATA
);

// ========== microSD pass-through ==========
wire spi_do_int;
assign spi_do_int = SPI_SS4 ? 1'bz : SD_MISO;
assign SPI_DO = spi_do_int;

// ========== DB9 joystick relay ==========
reg joy_select = 1'b1;
always @(posedge XJOY_LOAD) begin
    joy_select <= ~joy_select | ~XJOY_CLK;
end

assign JOY_CLK    = XJOY_CLK;
assign JOY_LOAD   = XJOY_LOAD;
assign XJOY_DATA  = JOY_DATA;
assign JOY_SELECT = joy_select;

// ========== Clock ==========
wire clk_sys, pll_locked;
pll pll(
    .refclk   (CLOCK_27[0]),
    .rst      (1'b0),
    .outclk_0 (clk_sys),
    .locked   (pll_locked)
);

// ce_pix=5.626 MHz, ce_cpu=447 kHz — same enable rates as ../hdl/mister/Altair.sv.
localparam [15:0] CLK_KHZ = 16'd30000;
reg [16:0] acc_pix = 0, acc_cpu = 0;
reg        ce_pix = 0, ce_cpu = 0;
always @(posedge clk_sys) begin
    if (acc_pix + 17'd5626 >= {1'b0,CLK_KHZ}) begin acc_pix <= acc_pix + 17'd5626 - {1'b0,CLK_KHZ}; ce_pix <= 1; end
    else begin acc_pix <= acc_pix + 17'd5626; ce_pix <= 0; end
    if (acc_cpu + 17'd447 >= {1'b0,CLK_KHZ}) begin acc_cpu <= acc_cpu + 17'd447 - {1'b0,CLK_KHZ}; ce_cpu <= 1; end
    else begin acc_cpu <= acc_cpu + 17'd447; ce_cpu <= 0; end
end

// ========== OSD / IO controller ==========
// DIP switches: ../mra/Altair*.mra <switches default="0xff" base="16"> -> status[23:16]
// (matches ../arc/Altair*.arc DEFAULT=0xFF0000). OSD options use bits 8-14, Reset bit 12.
localparam CONF_STR = {
    "Altair;;",
    "O8,Aspect Ratio,Original,Wide;",
    "O9,Orientation,Horz,Vert;",
    "OAB,Scanlines,None,25%,50%,75%;",
    "OE,Flip 180,Off,On;",
    "-;",
    "OD,Swap Joysticks,Off,On;",
    "-;",
    "DIP;",
    "-;",
    "J1,Fire,Fire 2,Start 1P,Start 2P,Coin;",
    "TC,Reset v",`BUILD_DATE,";",
    "V,v",`BUILD_DATE
};

wire [63:0] status;
wire  [1:0] buttons;
wire        scandoublerD, ypbpr, no_csync;
wire  [6:0] core_mod;
wire        key_strobe, key_pressed;
wire  [7:0] key_code;
wire [31:0] joystick_0, joystick_1;

user_io #(
    .STRLEN($size(CONF_STR)>>3),
    .FEATURES(32'h0)
) user_io (
    .clk_sys              ( clk_sys      ),
    .conf_str             ( CONF_STR     ),
    .SPI_CLK              ( SPI_SCK      ),
    .SPI_SS_IO            ( CONF_DATA0   ),
    .SPI_MISO             ( spi_do_int   ),
    .SPI_MOSI             ( SPI_DI       ),
    .buttons              ( buttons      ),
    .switches             (              ),
    .scandoubler_disable  ( scandoublerD ),
    .ypbpr                ( ypbpr        ),
    .no_csync             ( no_csync     ),
    .core_mod             ( core_mod     ),
    .key_strobe           ( key_strobe   ),
    .key_pressed          ( key_pressed  ),
    .key_code             ( key_code     ),
    .joystick_0           ( joystick_0   ),
    .joystick_1           ( joystick_1   ),
    .status               ( status       )
);

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_index;
wire  [7:0] ioctl_dout;

data_io data_io(
    .clk_sys        ( clk_sys        ),
    .SPI_SCK        ( SPI_SCK        ),
    .SPI_SS2        ( SPI_SS2        ),
    .SPI_DI         ( SPI_DI         ),
    .ioctl_download ( ioctl_download ),
    .ioctl_index    ( ioctl_index    ),
    .ioctl_wr       ( ioctl_wr       ),
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_dout     ( ioctl_dout     )
);

// ========== Reset ==========
reg rom_loaded = 0;
always @(posedge clk_sys) begin
    reg ioctl_downlD;
    ioctl_downlD <= ioctl_download;
    if (ioctl_downlD & ~ioctl_download & !ioctl_index) rom_loaded <= 1;
end

reg reset;
always @(posedge clk_sys) reset <= status[12] | buttons[1] | ~pll_locked | ~rom_loaded | (ioctl_download & !ioctl_index);

// ========== Inputs ==========
// J1 bits (same as Altair.sv's own CONF_STR): 4=Fire, 5=Fire 2, 6=Start 1P, 7=Start 2P, 8=Coin.
// Upstream drives all player controls from joystick_0 (alternating 2P game); arcade_inputs adds the
// keyboard fallback on top. Coins stay per-joystick (two independent EF lines), debounced exactly
// like upstream (coin_debounce.v), with its cycle counts rescaled from 28.13MHz to 30MHz
// (same 1ms deglitch / 50ms pulse).
wire [19:0] player1, player2;
wire  [8:0] controls;

arcade_inputs #(.START1(6), .START2(7), .COIN1(0)) inputs (
    .clk         ( clk_sys       ),
    .key_strobe  ( key_strobe    ),
    .key_pressed ( key_pressed   ),
    .key_code    ( key_code      ),
    .joystick_0  ( joystick_0[19:0] ),
    .joystick_1  ( joystick_1[19:0] ),
    .joystick_2  ( 20'd0         ),
    .joystick_3  ( 20'd0         ),
    .rotate      ( 1'b0          ),
    .orientation ( 2'b00         ),
    .joyswap     ( status[13]    ),
    .oneplayer   ( 1'b0          ),
    .controls    ( controls      ),
    .player1     ( player1       ),
    .player2     ( player2       ),
    .player3     (               ),
    .player4     (               )
);

// IN0 (active-low): b5=Fire, b4=Left, b3=Right, b2=Start2, b1=Start1 — as Altair.sv.
wire [7:0] in0 = ~{ 1'b0,
                    1'b0,
                    player1[4],    // Fire
                    player1[1],    // Left
                    player1[0],    // Right
                    controls[1],   // Start2
                    controls[0],   // Start1
                    1'b0 };

// IN2 (active-low): b2=Fire 2, b1=Down, b0=Up — as Altair.sv.
wire [7:0] in2 = ~{ 5'b0,
                    player1[5],    // Fire 2
                    player1[2],    // Down
                    player1[3] };  // Up

// IN1 = DIP switches.
wire [7:0] in1 = status[23:16];

// EF lines: ef_ext[3]=Coin1, ef_ext[2]=Coin2 (as Altair.sv). Keyboard coin (controls[4]/[5]) is
// OR-ed in; swapped together with the joysticks.
wire coin_j0 = joystick_0[8], coin_j1 = joystick_1[8];
wire coin1_raw = (status[13] ? coin_j1 : coin_j0) | controls[4];
wire coin2_raw = (status[13] ? coin_j0 : coin_j1) | controls[5];
wire coin1_clean, coin2_clean;
coin_debounce #(.DEGLITCH_CYCLES(16'd30000), .PULSE_CYCLES(22'd1500000)) u_coin1 (.clk(clk_sys), .raw(coin1_raw), .clean(coin1_clean));
coin_debounce #(.DEGLITCH_CYCLES(16'd30000), .PULSE_CYCLES(22'd1500000)) u_coin2 (.clk(clk_sys), .raw(coin2_raw), .clean(coin2_clean));
wire [3:0] ef_ext = { coin1_clean, coin2_clean, 1'b0, 1'b0 };

// ========== Game core ==========
wire [8:0] hcount, vcount;
wire       hsync, vsync, de;
wire [7:0] r, g, b;
wire signed [15:0] audio;

altair_machine u_core (
    .clk(clk_sys), .ce_cpu(ce_cpu), .ce_pix(ce_pix), .reset(reset), .flip(status[14]),
    .in0(in0), .in1(in1), .in2(in2), .ef_ext(ef_ext),
    .ioctl_rom_we(ioctl_wr && ioctl_download && !ioctl_index), .ioctl_rom_addr(ioctl_addr[13:0]), .ioctl_rom_data(ioctl_dout),
    .q_out(),
    .hcount(hcount), .vcount(vcount), .hsync(hsync), .vsync(vsync), .de(de),
    .r(r), .g(g), .b(b),
    .audio(audio),
    .io_active(), .io_is_out(), .io_port(), .io_data(), .io_addr(),
    .dbg_pc(), .dbg_fetch(), .dbg_rb(), .dbg_cfg(), .dbg_hma(),
    .dbg_state(), .dbg_op(), .dbg_r1(), .dbg_p(), .dbg_x(), .dbg_d_out()
);

assign LED = ~ioctl_download;

// Same blanking thresholds as Altair.sv / vis_video_timing.v.
wire hblank = ~((hcount >= 9'd30) && (hcount < 9'd324));
wire vblank = ~((vcount >= 9'd10) && (vcount < 9'd304));

// ========== Video ==========
mist_dual_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(8), .USE_BLANKS(1'b1), .BIG_OSD(1'b1)) mist_video(
    .clk_sys        ( clk_sys          ),
    .SPI_SCK        ( SPI_SCK          ),
    .SPI_SS3        ( SPI_SS3          ),
    .SPI_DI         ( SPI_DI           ),
    .R              ( r                ),
    .G              ( g                ),
    .B              ( b                ),
    .HBlank         ( hblank           ),
    .VBlank         ( vblank           ),
    .HSync          ( hsync            ),
    .VSync          ( vsync            ),
    .VGA_R          ( VGA_R            ),
    .VGA_G          ( VGA_G            ),
    .VGA_B          ( VGA_B            ),
    .VGA_VS         ( VGA_VS           ),
    .VGA_HS         ( VGA_HS           ),
    .ce_divider     ( 4'd4             ),
    .rotate         ( {1'b0, status[9]} ),
    .rotate_screen  ( 2'b00            ),
    .rotate_hfilter ( 1'b0             ),
    .rotate_vfilter ( 1'b0             ),
    .blend          ( 1'b0             ),
    .scandoubler_disable( scandoublerD ),
    .scanlines      ( status[11:10]    ),
    .ypbpr          ( ypbpr            ),
    .no_csync       ( no_csync         )
);

// ========== Audio ==========
// signed PCM -> offset binary for dac.vhd (same as destroyer).
wire [15:0] audio_offset = {~audio[15], audio[14:0]};

dac #(.C_bits(16)) dac_l(
    .clk_i   ( clk_sys ),
    .res_n_i ( ~reset  ),
    .dac_i   ( audio_offset ),
    .dac_o   ( AUDIO_L )
);

assign AUDIO_R = AUDIO_L;

endmodule
