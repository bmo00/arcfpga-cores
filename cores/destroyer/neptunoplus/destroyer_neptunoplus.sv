// destroyer_neptunoplus.sv — NeptUNO+ bridge for Cidelsa "Destroyer" (1980)
//
// Like mariobros, the upstream repo (jlrh/cidelsa-fpga) is MiSTer-only: its own top
// (hdl/mister/Destroyer.sv, module `emu`) uses hps_io.sv and the Template_MiSTer `sys/`
// framework, both HPS/ARM-side concepts NeptUNO+ has no equivalent of. ../hdl/rtl/cidelsa_machine.v
// itself is fully protocol-agnostic (plain in0/in1/ef_ext switches, plain
// ioctl_rom_we/ioctl_rom_addr/ioctl_rom_data download bus, no SPI/HPS ports at all), so this file
// plays the role of a *new* MiST-style board wrapper — the same user_io/data_io/arcade_inputs/
// mist_dual_video/dac instantiation every other bridge in this repo uses, wired to
// cidelsa_machine's ports the same way Destroyer.sv's own `emu` wires them to hps_io. See
// neptunoplus/NOTES.md for the signal-by-signal mapping this was derived from (the real upstream
// Destroyer.sv, read at the pinned commit) and for the two NeptUNO+-specific pieces added on top of
// that reference:
//
// 1. microSD SPI pass-through: SD_SCK/SD_MISO shared with SPI_SCK/SPI_DO, muxed by SPI_SS4.
// 2. DB9 joystick shift-register relay between JOY_* and XJOY_*.
//
// Destroyer has no SDRAM at all — the 8KB program ROM and 256B NVRAM in ../hdl/ are both on-chip
// block RAM, loaded directly over cidelsa_machine's own ioctl_rom_we/ioctl_rom_addr/ioctl_rom_data
// — so unlike every SDRAM-backed core in this repo, this bridge has no SDRAM group and no
// SDRAM-clock concern (doc/porting-a-native-core.md §2.2 is about never *duplicating* a core-owned
// PLL; there is no core-owned PLL here to duplicate). The one PLL this bridge owns (cidelsa_machine
// has none of its own — only clk/ce_cpu/ce_pix inputs) is a device-family reimplementation of
// ../hdl/mister/pll.v's own 50MHz-in/30MHz-out ratio (Cyclone V's altera_pll has no Cyclone IV GX
// equivalent) — see pll.v's own header comment. NeptUNO+'s CLOCK_27[0] is already a real 50MHz
// reference (same as MiSTer's CLK_50M), so the ratio itself needed no retuning, only the megafunction
// swap.
//
// Destroyer is a vertical-cabinet game. The upstream MiSTer wrapper rotates the actual game video via
// screen_rotate + a DDRAM framebuffer (MISTER_FB=1) — a real per-pixel rotation this repo's
// SDRAM-less bridge convention has no equivalent of (mist_dual_video's own `rotate_screen` mode
// "needs SDRAM connection" per its own port comment). Like every other bridge in this repo, video is
// passed through raw (rotate_screen=2'b00); "Orientation" below only rotates the OSD menu box itself,
// for a physically-rotated monitor — the standard MiST-class convention for vertical cabinets.
//
// The game logic under ../hdl/ is never modified.

`include "build_id.v"

module destroyer_neptunoplus(
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
// cidelsa_machine has no internal PLL of its own (it only takes clk/ce_cpu/ce_pix as plain inputs)
// — like mariobros, this bridge owns the single system PLL directly, reimplementing
// ../hdl/mister/pll.v's own 50MHz-in/30MHz-out ratio for Cyclone IV GX (see pll.v's own header
// comment).
wire clk_sys, pll_locked;
pll pll(
    .refclk   (CLOCK_27[0]),
    .rst      (1'b0),
    .outclk_0 (clk_sys),
    .locked   (pll_locked)
);

// ce_pix=5.626 MHz (dot clock), ce_cpu=447.375 kHz (CDP1802 machine-cycle rate = 3.579MHz/8) — the
// exact same phase-accumulator-derived enables ../hdl/mister/Destroyer.sv itself uses (real Destroyer
// service-manual clocks; validated CPU-OUT-stream-identical-to-MAME upstream, see hdl/README.md).
// Reused verbatim rather than re-derived, since clk_sys is the same 30MHz either way.
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
// DIP switches (Difficulty/Bonus/Lives/Coinage) come from CONF_STR's "DIP;" tag below, not a
// hand-rolled O-line — see doc/porting-a-native-core.md §2.5. Confirmed against
// ../mra/Destroyer (FF, Cidelsa, 1980).mra: <switches default="0xd6" base="16">, so the DIP byte
// lands in status[23:16], not status[7:0] (base=0 was an earlier, wrong assumption made before this
// .mra existed — see neptunoplus/NOTES.md). Reset placed at status[12] — clear of both the OSD
// options above (bits 8-11, 13) and the DIP switches' real status[23:16] range.
// LAYOUT (2026-09-03, real-hardware-directed): "DIP;" moved to just before "Reset" (every other
// option first), matching a known-working reference bridge's own layout — see neptunoplus/NOTES.md
// for the full account of the still-unresolved menu-duplication investigation this responds to.
localparam CONF_STR = {
    "Destroyer;;",
    "O8,Aspect Ratio,Original,Wide;",
    "O9,Orientation,Horz,Vert;",
    "OAB,Scanlines,None,25%,50%,75%;",
    "-;",
    "OD,Swap Joysticks,Off,On;",
    "-;",
    "DIP;",
    "-;",
    "J1,Fire,Start 1P,Start 2P,Coin;",
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
// Fire/Left/Right/Start1/Start2 go through arcade_inputs (adds keyboard fallback on top of the
// joystick bits, same J1-tag bit convention — bit4=Fire, bit5=Start1P, bit6=Start2P — the upstream
// hps_io wrapper's own joystick_0 layout already used, see NOTES.md). Coin1/Coin2 are wired straight
// from joystick_0[7]/joystick_1[7] instead — cidelsa_machine's own ef_ext exposes them as two
// independent per-player EF lines (see cidelsa_machine.v's own header comment), not a single merged
// "coin" signal arcade_inputs' own controls[] would produce for both players alike.
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
    .joyswap     ( status[13]    ),
    .oneplayer   ( 1'b0          ),
    .controls    ( controls      ),
    .player1     ( player1       ),
    .player2     ( player2       ),
    .player3     (               ),
    .player4     (               )
);

// IN0 (activo-BAJO, ver cidelsa_machine.v): b7=PCB (lo pone el core), b6=unused, b5=Fire, b4=Left,
// b3=Right, b2=Start2, b1=Start1, b0=cartucho (inactivo).
wire [7:0] in0 = ~{ 1'b0,          // b7 (PCB, lo sobreescribe el core)
                    1'b0,          // b6 unused
                    player1[4],    // b5 Fire
                    player1[1],    // b4 Left
                    player1[0],    // b3 Right
                    controls[1],   // b2 Start2
                    controls[0],   // b1 Start1
                    1'b0 };        // b0 cartucho (inactivo)

// IN1 = DIP switches, read directly by the CPU (INP2) — see CONF_STR's "DIP;" comment above.
// ../mra/Destroyer (FF, Cidelsa, 1980).mra's <switches base="16"> puts the DIP byte at status[23:16].
wire [7:0] in1 = status[23:16];

// EF2..4 (activo-ALTO, ver cidelsa_machine.v): ef_ext[1]=Service (no wired, matches upstream),
// ef_ext[2]=Coin2, ef_ext[3]=Coin1. Swapped by status[13] ("Swap Joysticks") the same way
// arcade_inputs' own .joyswap swaps player1/player2 above, so a swapped controller's own Coin
// button still credits the coin slot that now matches its logical player.
wire [3:0] ef_ext = status[13] ? { joystick_1[7], joystick_0[7], 1'b0, 1'b0 }
                                : { joystick_0[7], joystick_1[7], 1'b0, 1'b0 };

// ========== Game core ==========
wire [8:0] hcount, vcount;
wire       hsync, vsync, de;
wire [7:0] r, g, b;
wire signed [15:0] audio;

cidelsa_machine u_core (
    .clk(clk_sys), .ce_cpu(ce_cpu), .ce_pix(ce_pix), .reset(reset),
    .in0(in0), .in1(in1), .ef_ext(ef_ext),
    .ioctl_rom_we(ioctl_wr && ioctl_download && !ioctl_index), .ioctl_rom_addr(ioctl_addr[12:0]), .ioctl_rom_data(ioctl_dout),
    .q_out(),
    .hcount(hcount), .vcount(vcount), .hsync(hsync), .vsync(vsync), .de(de),
    .r(r), .g(g), .b(b),
    .audio(audio),
    .io_active(), .io_is_out(), .io_port(), .io_data(), .io_addr(),
    .dbg_pc(), .dbg_fetch(), .dbg_rb(), .dbg_cfg(), .dbg_hma(),
    .dbg_state(), .dbg_op(), .dbg_r1(), .dbg_p(), .dbg_x(), .dbg_d_out()
);

assign LED = ~ioctl_download;

// Blanking derivado de hcount/vcount — cidelsa_machine sólo expone `de`, no hblank/vblank por
// separado; estos umbrales son los mismos con los que vis_video_timing.v calcula `de` internamente
// (HBLANK_END/START=30/324, VBLANK_END/START=10/304 — ver vis_video_timing.v), replicados aquí tal
// cual (no inventados) porque mist_dual_video sí necesita HBlank/VBlank como señales separadas.
wire hblank = ~((hcount >= 9'd30) && (hcount < 9'd324));
wire vblank = ~((vcount >= 9'd10) && (vcount < 9'd304));

// ========== Video ==========
// r/g/b son 888 reales (vis_palette.v), no un empaquetado 3-3-2 — COLOR_DEPTH/OUT_COLOR_DEPTH=8, sin
// replicar bits (a diferencia de mariobros).
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
// dac.vhd's sigma-delta accumulator expects dac_i as offset binary (MSB=1 == high level), not
// two's complement — vis_sound.v's `audio` is signed PCM (see its own header comment: mix<<<9), so
// the sign bit must be inverted before it reaches the DAC (dac.vhd's own header comment: "not
// dac_i(C_bits-1) effectively adds 0x8..0 to dac_i") — same fix mariobros needed after its own
// real-hardware audio testing, applied here up front rather than rediscovered.
wire [15:0] audio_offset = {~audio[15], audio[14:0]};

dac #(.C_bits(16)) dac_l(
    .clk_i   ( clk_sys ),
    .res_n_i ( ~reset  ),
    .dac_i   ( audio_offset ),
    .dac_o   ( AUDIO_L )
);

assign AUDIO_R = AUDIO_L;

endmodule
