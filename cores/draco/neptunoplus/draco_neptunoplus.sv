// draco_neptunoplus.sv — NeptUNO+ bridge for Cidelsa "Draco" (1981)
//
// Same structure as cores/destroyer/neptunoplus/destroyer_neptunoplus.sv (same upstream repo,
// jlrh/cidelsa-fpga): the upstream top (hdl/mister/Draco.sv, module `emu`) is MiSTer-only, while
// ../hdl/rtl/draco_machine.v is protocol-agnostic (plain in0/in1/in2/ef_ext, plain ioctl_rom_* and
// ioctl_snd_* download buses). This file is a MiST-style board wrapper wired to draco_machine the
// way Draco.sv wires it to hps_io. See neptunoplus/NOTES.md.
//
// No SDRAM (program ROM, COP402 sound ROM and RAM are on-chip BRAM). One bridge-owned PLL, same
// pll.v as destroyer (50MHz -> 30MHz); upstream runs at 28.13MHz, so only CLK_KHZ changes and the
// phase-accumulator enables keep the exact upstream rates.
//
// ROM download — the one real difference from Draco.sv:
//   upstream's .mra sends the 16KB program ROM as ioctl_index 0 and the 2KB COP402 sound ROM
//   ("dra s 1.ic4") as ioctl_index 1. NeptUNO+ loads a single .rom built by mra-tools-c, which only
//   contains <rom index="0"> (index 1 is reserved for the .arc MOD byte). So this bridge accepts the
//   sound ROM both ways:
//     - ioctl_index 1, address 0x000-0x7FF (upstream MiSTer layout), or
//     - ioctl_index 0, address 0x4000-0x47FF, i.e. appended right after the program ROM.
//   A neptUNO+ .rom without the sound ROM appended still boots, just without sound.
//
// The game logic under ../hdl/ is never modified in place (see neptunoplus/patches/).

`include "build_id.v"

module draco_neptunoplus(
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

// ce_pix=5.626MHz, ce_cpu=554kHz (CDP1802), ce_cop=126kHz (COP402), ce_ay=2.012MHz (AY-3-8910) —
// same enable rates as ../hdl/mister/Draco.sv.
localparam [15:0] CLK_KHZ = 16'd30000;
reg [16:0] acc_pix = 0, acc_cpu = 0;
reg [16:0] acc_cop = 0, acc_ay  = 0;
reg        ce_pix  = 0, ce_cpu  = 0;
reg        ce_cop  = 0, ce_ay   = 0;
always @(posedge clk_sys) begin
    if (acc_pix + 17'd5626 >= {1'b0,CLK_KHZ}) begin acc_pix <= acc_pix + 17'd5626 - {1'b0,CLK_KHZ}; ce_pix <= 1; end
    else begin acc_pix <= acc_pix + 17'd5626; ce_pix <= 0; end
    if (acc_cpu + 17'd554 >= {1'b0,CLK_KHZ}) begin acc_cpu <= acc_cpu + 17'd554 - {1'b0,CLK_KHZ}; ce_cpu <= 1; end
    else begin acc_cpu <= acc_cpu + 17'd554; ce_cpu <= 0; end
    if (acc_cop + 17'd126 >= {1'b0,CLK_KHZ}) begin acc_cop <= acc_cop + 17'd126 - {1'b0,CLK_KHZ}; ce_cop <= 1; end
    else begin acc_cop <= acc_cop + 17'd126; ce_cop <= 0; end
    if (acc_ay + 17'd2012 >= {1'b0,CLK_KHZ}) begin acc_ay <= acc_ay + 17'd2012 - {1'b0,CLK_KHZ}; ce_ay <= 1; end
    else begin acc_ay <= acc_ay + 17'd2012; ce_ay <= 0; end
end

// ========== OSD / IO controller ==========
// DIP switches: ../mra/Draco*.mra <switches default="0xff" base="16"> -> status[23:16]
// (matches ../arc/Draco*.arc DEFAULT=0xFF0000). OSD options use bits 8-14, Reset bit 12.
localparam CONF_STR = {
    "Draco;;",
    "O8,Aspect Ratio,Original,Wide;",
    "O9,Orientation,Horz,Vert;",
    "OAB,Scanlines,None,25%,50%,75%;",
    "OE,Flip 180,Off,On;",
    "-;",
    "OD,Swap Joysticks,Off,On;",
    "-;",
    "DIP;",
    "-;",
    "J1,Start 1P,Start 2P,Coin;",
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

// ========== ROM download routing ==========
wire dl_main  = ioctl_download && (ioctl_index == 8'd0);
wire dl_snd   = ioctl_download && (ioctl_index == 8'd1);
wire rom_we   = dl_main && ioctl_wr && (ioctl_addr[24:14] == 11'd0);                 // 0x0000-0x3FFF
wire snd_we   = ioctl_wr && ((dl_main && (ioctl_addr[24:11] == 14'h0008)) ||          // 0x4000-0x47FF
                             (dl_snd  && (ioctl_addr[24:11] == 14'h0000)));           // index 1
wire [13:0] rom_addr = ioctl_addr[13:0];
wire [10:0] snd_addr = ioctl_addr[10:0];

// ========== Reset ==========
reg rom_loaded = 0;
always @(posedge clk_sys) begin
    reg ioctl_downlD;
    ioctl_downlD <= ioctl_download;
    if (ioctl_downlD & ~ioctl_download & !ioctl_index) rom_loaded <= 1;
end

reg reset;
always @(posedge clk_sys) reset <= status[12] | buttons[1] | ~pll_locked | ~rom_loaded | ioctl_download;

// ========== Inputs ==========
// J1 bits (same as Draco.sv's own CONF_STR): 4=Start 1P, 5=Start 2P, 6=Coin. Two simultaneous
// 4-way sticks (player1 = joystick_0, player2 = joystick_1), with keyboard fallback via arcade_inputs.
wire [19:0] player1, player2;
wire  [8:0] controls;

arcade_inputs #(.START1(4), .START2(5), .COIN1(0)) inputs (
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

// IN0 (active-low): b1=Start2, b0=Start1 — as Draco.sv.
wire [7:0] in0 = ~{ 6'b0, controls[1], controls[0] };

// IN2 (active-low): {P2 L,R,D,U, P1 L,R,D,U} — as Draco.sv.
wire [7:0] in2 = ~{ player2[1], player2[0], player2[2], player2[3],
                    player1[1], player1[0], player1[2], player1[3] };

// IN1 = DIP switches.
wire [7:0] in1 = status[23:16];

// EF lines: ef_ext[3]=Coin1, ef_ext[2]=Coin2 (as Draco.sv), debounced like upstream with the cycle
// counts rescaled from 28.13MHz to 30MHz (same 1ms deglitch / 50ms pulse). Keyboard coin OR-ed in.
wire coin_j0 = joystick_0[6], coin_j1 = joystick_1[6];
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

draco_machine u_core (
    .clk(clk_sys), .ce_cpu(ce_cpu), .ce_pix(ce_pix), .ce_cop(ce_cop), .ce_ay(ce_ay),
    .reset(reset), .flip(status[14]),
    .in0(in0), .in1(in1), .in2(in2), .ef_ext(ef_ext),
    .ioctl_rom_we(rom_we), .ioctl_rom_addr(rom_addr), .ioctl_rom_data(ioctl_dout),
    .ioctl_snd_we(snd_we), .ioctl_snd_addr(snd_addr), .ioctl_snd_data(ioctl_dout),
    .q_out(),
    .hcount(hcount), .vcount(vcount), .hsync(hsync), .vsync(vsync), .de(de),
    .r(r), .g(g), .b(b),
    .audio(audio),
    .io_active(), .io_is_out(), .io_port(), .io_data(), .io_addr(),
    .dbg_pc(), .dbg_fetch(), .dbg_rb(), .dbg_sndcmd()
);

assign LED = ~ioctl_download;

// Same blanking thresholds as Draco.sv / vis_video_timing.v.
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
// draco_sound.v's `audio` is signed PCM -> offset binary for dac.vhd (same as destroyer).
wire [15:0] audio_offset = {~audio[15], audio[14:0]};

dac #(.C_bits(16)) dac_l(
    .clk_i   ( clk_sys ),
    .res_n_i ( ~reset  ),
    .dac_i   ( audio_offset ),
    .dac_o   ( AUDIO_L )
);

assign AUDIO_R = AUDIO_L;

endmodule
