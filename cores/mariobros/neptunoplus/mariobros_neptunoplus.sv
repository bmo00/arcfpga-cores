// mariobros_neptunoplus.sv — NeptUNO+ bridge for Mario Bros
//
// Unlike every other native core bridged so far in this repo, there is no existing MiST board
// wrapper to clone almost verbatim here: the upstream repo (MiSTer-devel/Arcade-MarioBros_MiSTer)
// is MiSTer-only (its own top, Arcade-MarioBros.sv, uses hps_io.sv — a fundamentally different
// protocol from MiST's user_io/data_io). ../hdl/rtl/mario_top.v itself is fully protocol-agnostic
// (plain dn_addr/dn_data/dn_wr download bus, plain switches, no SPI/HPS ports at all), so this file
// plays the role of a *new* MiST-style board wrapper — the same user_io/data_io/arcade_inputs/
// mist_dual_video/dac instantiation every other bridge in this repo already uses, wired to
// mario_top's ports the same way Arcade-MarioBros.sv's own emu module wires them to hps_io. See
// neptunoplus/NOTES.md for the signal-by-signal mapping this was derived from (the real upstream
// Arcade-MarioBros.sv, read at the pinned commit) and for the two NeptUNO+-specific pieces added on
// top of that reference:
//
// 1. microSD SPI pass-through: SD_SCK/SD_MISO shared with SPI_SCK/SPI_DO, muxed by SPI_SS4.
// 2. DB9 joystick shift-register relay between JOY_* and XJOY_*.
//
// Mario Bros has no SDRAM at all — every ROM/RAM in ../hdl/ is on-chip block RAM, loaded
// directly over dn_addr/dn_data/dn_wr — so unlike every SDRAM-backed core in this repo, this bridge
// has no SDRAM group and no SDRAM-clock concern. The one PLL it does own (mario_top has none of its
// own) is retuned only in the sense of targeting Cyclone IV's altpll instead of Cyclone V's
// altera_pll — see pll.v's own header comment; the 50MHz-in/48MHz-out ratio itself is unchanged
// from upstream, since NeptUNO+'s real reference is already 50 MHz (same as MiSTer's CLK_50M).
//
// The game logic under ../hdl/ is never modified (one genuine vendored-HDL bug, a duplicate
// `.I_ANLG_VOL()` pin connection in mario_top.v, is fixed via neptunoplus/patches/, not in place).

`include "build_id.v"

module mariobros_neptunoplus(
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

    // microSD pass-through, shared with SPI_SCK/SPI_DO above (driven by the RP2040 middle board)
    input               SD_SCK,
    input               SD_MISO,

    // DB9 joystick shift-register reflection to/from the RP2040 (the FPGA does not decode this
    // itself)
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
// mario_top has no internal PLL of its own (unlike every SDRAM-backed core bridged so far) — this
// bridge owns the single system PLL directly, same 50MHz-in/48MHz-out ratio the pinned
// ../hdl/rtl/pll.v already used (see pll.v's own header comment for why no retune math is
// needed here, only a Cyclone IV altpll re-implementation).
wire clk_sys;
pll pll(
    .refclk   (CLOCK_27[0]),
    .rst      (1'b0),
    .outclk_0 (clk_sys),
    .locked   ()
);

// ========== OSD / IO controller ==========
localparam CONF_STR = {
    "MARIO;;",
    "-;",
    "O1,Aspect Ratio,Original,Wide;",
    "O2,Orientation,Horz,Vert;",
    "O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
    "ODG,Analogue Sound Vol,100%,Off,10%,20%,30%,40%,50%,60%,70%,80%,90%,;",
    "-;",
    "OQ,Dim video after 10s,On,Off;",
    "-;",
    "T0,Reset;",
    "J1,Jump,Start 1P,Start 2P,Pause;",
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
// mario_top's own DIP-switch-configuration path (I_DIPSW via a MiSTer ioctl_index==254 OSD upload)
// is not wired: the real upstream Arcade-MarioBros.sv ships with every "O89/OAB/OCD/OEF" dip option
// line commented out, and this core's own .mra has no <dip> entries — sw[0] simply never gets
// written in the real, shipped upstream core, staying at its power-up default of 0. I_DIPSW is
// hardwired to that same real default (8'h00) rather than inventing an OSD path nothing upstream
// actually exercises. See neptunoplus/NOTES.md.
reg rom_loaded = 0;
always @(posedge clk_sys) begin
    reg ioctl_downlD;
    ioctl_downlD <= ioctl_download;
    if (ioctl_downlD & ~ioctl_download & !ioctl_index) rom_loaded <= 1;
end

reg reset;
always @(posedge clk_sys) reset <= status[0] | buttons[1] | ~rom_loaded | (ioctl_download & !ioctl_index);

// ========== Inputs ==========
wire [19:0] player1, player2;
wire  [8:0] controls;

arcade_inputs #(.START1(5), .START2(6), .COIN1(0)) inputs (
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
    .joyswap     ( 1'b0          ),
    .oneplayer   ( 1'b0          ),
    .controls    ( controls      ),
    .player1     ( player1       ),
    .player2     ( player2       ),
    .player3     (               ),
    .player4     (               )
);

wire m_left1  = player1[1];
wire m_right1 = player1[0];
wire m_fire1  = player1[4];
wire m_left2  = player2[1];
wire m_right2 = player2[0];
wire m_fire2  = player2[4];
wire m_start1 = controls[0];
wire m_start2 = controls[1];
wire m_coin   = controls[4];
wire m_pause  = joystick_0[8] | joystick_1[8];

wire [7:0] I_SW1 = {1'b1, ~m_start2, ~m_start1, ~m_fire1, 1'b1, 1'b1, ~m_left1, ~m_right1};
wire [7:0] I_SW2 = {1'b1, 1'b1,      ~m_coin,   ~m_fire2, 1'b1, 1'b1, ~m_left2, ~m_right2};

// ========== Pause (dim-after-10s only — no OSD-open/hiscore trigger, see neptunoplus/NOTES.md) ==========
wire        pause_cpu;
wire  [7:0] rgb_out;
wire  [2:0] vid_r, vid_g;
wire  [1:0] vid_b;

pause #(3, 3, 2, 48) pause (
    .clk_sys      ( clk_sys    ),
    .reset        ( reset      ),
    .user_button  ( m_pause    ),
    .pause_request( 1'b0       ),
    .options      ( {~status[26], 1'b0} ),
    .OSD_STATUS   ( 1'b0       ),
    .r            ( vid_r      ),
    .g            ( vid_g      ),
    .b            ( vid_b      ),
    .pause_cpu    ( pause_cpu  ),
    .rgb_out      ( rgb_out    )
);

// ========== Game core ==========
wire hblank, vblank;
wire hsync_n, vsync_n;
wire signed [15:0] audio;

mario_top mariobros(
    .I_CLK_48M   ( clk_sys        ),
    .I_RESETn    ( ~reset         ),

    .I_ANLG_VOL  ( status[16:13]  ),
    .I_SW1       ( I_SW1          ),
    .I_SW2       ( I_SW2          ),
    .I_DIPSW     ( 8'h00          ),

    .dn_addr     ( ioctl_addr[16:0] ),
    .dn_data     ( ioctl_dout     ),
    .dn_wr       ( ioctl_wr && ioctl_download && !ioctl_index ),

    .O_VGA_R     ( vid_r          ),
    .O_VGA_G     ( vid_g          ),
    .O_VGA_B     ( vid_b          ),
    .O_HBLANK    ( hblank         ),
    .O_VBLANK    ( vblank         ),
    .O_VGA_HSYNCn( hsync_n        ),
    .O_VGA_VSYNCn( vsync_n        ),
    .O_PIX       (                ),

    .O_SOUND_DAT ( audio          ),

    .pause       ( pause_cpu      ),

    .hs_address  ( 16'd0          ),
    .hs_data_in  ( 8'h00          ),
    .hs_data_out (                ),
    .hs_write    ( 1'b0           ),
    .hs_access   ( 1'b0           )
);

assign LED = ~ioctl_download;

// ========== Video ==========
mist_dual_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(8), .USE_BLANKS(1'b1)) mist_video(
    .clk_sys        ( clk_sys          ),
    .SPI_SCK        ( SPI_SCK          ),
    .SPI_SS3        ( SPI_SS3          ),
    .SPI_DI         ( SPI_DI           ),
    .R              ( rgb_out[7:5]     ),
    .G              ( rgb_out[4:2]     ),
    .B              ( {rgb_out[1:0], rgb_out[1]} ),
    .HBlank         ( hblank           ),
    .VBlank         ( vblank           ),
    .HSync          ( ~hsync_n         ),
    .VSync          ( ~vsync_n         ),
    .VGA_R          ( VGA_R            ),
    .VGA_G          ( VGA_G            ),
    .VGA_B          ( VGA_B            ),
    .VGA_VS         ( VGA_VS           ),
    .VGA_HS         ( VGA_HS           ),
    .ce_divider     ( 4'd7             ),
    .rotate         ( {1'b0, status[2]} ),
    .rotate_screen  ( 2'b00            ),
    .rotate_hfilter ( 1'b0             ),
    .rotate_vfilter ( 1'b0             ),
    .blend          ( 1'b0             ),
    .scandoubler_disable( scandoublerD ),
    .scanlines      ( status[5:3]      ),
    .ypbpr          ( ypbpr            ),
    .no_csync       ( no_csync         )
);

// ========== Audio ==========
dac #(.C_bits(16)) dac_l(
    .clk_i   ( clk_sys ),
    .res_n_i ( 1'b1    ),
    .dac_i   ( audio   ),
    .dac_o   ( AUDIO_L )
);

assign AUDIO_R = AUDIO_L;

endmodule
