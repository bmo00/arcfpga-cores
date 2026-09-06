// systemc2_neptunoplus.sv — NeptUNO+ bridge for Sega System C / System C-2
// (Mezzow/Arcade-SystemC2_MiSTer)
//
// Unlike every MiST-sourced core bridged so far in this repo, there is no existing MiST board
// wrapper to clone almost verbatim: the upstream repo is MiSTer-only (its own top,
// Arcade-SystemC2.sv, uses hps_io.sv — a fundamentally different protocol from MiST's
// user_io/data_io). ../hdl/rtl/c2_system.sv, ../hdl/rtl/c2_romload.sv and ../hdl/rtl/sdram.sv are
// themselves protocol-agnostic (a plain ioctl_wr/ioctl_addr/ioctl_dout download bus feeding a real
// SDRAM controller, plain P1/P2/SERVICE/DSW1/DSW2 inputs, no SPI/HPS ports at all), so this file
// plays the role of a *new* MiST-style board wrapper — the same user_io/data_io/mist_dual_video/dac
// instantiation every other bridge in this repo uses, wired the same way Arcade-SystemC2.sv's own
// emu module wires hps_io to these same ports. See neptunoplus/NOTES.md for the full signal-by-
// signal account this was derived from and for the two NeptUNO+-specific pieces added on top:
//
// 1. microSD SPI pass-through: SD_SCK/SD_MISO shared with SPI_SCK/SPI_DO, muxed by SPI_SS4.
// 2. DB9 joystick shift-register relay between JOY_* and XJOY_*.
//
// **Real SDRAM, upstream-owned PLL** — this is the first core bridged in this repo that combines
// both: ../hdl/rtl/sdram.sv is a real 3-port SDRAM chip controller (68000 program ROM, uPD7759
// samples, plus the ROM-loader write port) and ../hdl/rtl/pll.v (a Cyclone-V-only `altera_pll`) is
// retuned in place for NeptUNO+'s real 50MHz reference via a same-named, same-ratio bridge-local
// `pll.v` (classic `altpll`, see that file's own header for the ratio math) — the bridge itself
// contributes zero PLLs of its own, per doc/porting-a-native-core.md §2.2. SDRAM_CLK/SDRAM_CKE are
// wired straight from ../hdl/rtl/sdram.sv's own output ports.
//
// The game logic under ../hdl/ is never modified. One genuine vendored-HDL bug — sdram.sv's
// SDRAM_CLK-generating `altddio_out` hardcodes `intended_device_family("Cyclone V")`, the upstream
// board's own family, not NeptUNO+'s Cyclone IV GX — is fixed via neptunoplus/patches/, not in
// place (see patches/README.md).

`include "build_id.v"

module systemc2_neptunoplus(
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
    output              XJOY_DATA,

    output       [12:0] SDRAM_A,
    inout        [15:0] SDRAM_DQ,
    output              SDRAM_DQML,
    output              SDRAM_DQMH,
    output              SDRAM_nWE,
    output              SDRAM_nCAS,
    output              SDRAM_nRAS,
    output              SDRAM_nCS,
    output        [1:0] SDRAM_BA,
    output              SDRAM_CLK,
    output              SDRAM_CKE
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
// c2_system's own PLL is retuned in place for NeptUNO+'s real 50MHz reference — see pll.v's own
// header comment for the ratio math. clk_ram (c1) drives both the SDRAM controller's `clk` input
// and, through it, SDRAM_CLK/SDRAM_CKE (sdram.sv's own outputs, wired straight to the pins below —
// the bridge owns no SDRAM-clock logic of its own, doc/porting-a-native-core.md §2.2).
wire clk_sys, clk_ram, pll_locked;
pll pll(
    .inclk0 (CLOCK_27[0]),
    .areset (1'b0),
    .c0     (clk_sys),
    .c1     (clk_ram),
    .locked (pll_locked)
);

// ========== OSD / IO controller ==========
// DIP switches: exposed via CONF_STR's "DIP;" magic tag, not individual "O<letters>,..." lines —
// doc/porting-a-native-core.md §2.5. Every systemc2 .mra carries <switches base="0">, so the OSD
// firmware writes the two DIP bytes into status[15:0] directly (DSW1=status[7:0],
// DSW2=status[15:8], see the DSW wiring below) — no extra offset needed.
//
// Layout follows §2.6's template: DIP first (no "-;" immediately before it, one right after),
// then video, then the momentary Service-Mode trigger (a real button on this hardware, not one of
// the DIP switches above — segac2.cpp's TEST line is PORT_SERVICE_NO_TOGGLE), then Reset+version.
localparam CONF_STR = {
    "SYSTEMC2;;",
    "DIP;",
    "-;",
    "O[17:16],Aspect Ratio,Original,Full Screen;",
    "O[19:18],Scanlines,None,25%,50%,75%;",
    "-;",
    "R[24],Enter Service Mode;",
    "-;",
    "J1,Button 1,Button 2,Button 3,Start,Coin,Service,Test;",
    "T[27],Reset v",`BUILD_DATE,";",
    "V,v",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire        scandoublerD, ypbpr, no_csync;
wire [31:0] joystick_0, joystick_1;
wire        key_strobe, key_pressed;
wire  [7:0] key_code;

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
    .SPI_DO         ( spi_do_int     ),
    .ioctl_download ( ioctl_download ),
    .ioctl_index    ( ioctl_index    ),
    .ioctl_wr       ( ioctl_wr       ),
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_dout     ( ioctl_dout     )
);

// The single MRA-unified byte stream data_io hands us is c2_romload's own index-0 stream (its own
// header comment documents the [region][size][data] shape it parses). No equivalent of upstream's
// ioctl_index==254 DIP-switch block exists (or is needed) here: DIP bytes come from status[]
// instead, per the "DIP;" tag above.
wire rom_download = ioctl_download && !ioctl_index;

// ========== Reset ==========
// No framework-driven RESET input on this platform (unlike hps_io's own RESET port) — held in
// reset until the first ROM load completes, same idiom every SDRAM/BRAM-backed bridge in this repo
// uses (see mariobros_neptunoplus.sv), since a MiST-class core has nothing else forcing a
// power-up load before the game logic starts running against undefined SDRAM contents.
reg rom_loaded = 0;
always @(posedge clk_sys) begin
    reg ioctl_downlD;
    ioctl_downlD <= ioctl_download;
    if (ioctl_downlD & ~ioctl_download & !ioctl_index) rom_loaded <= 1;
end

reg reset;
always @(posedge clk_sys) reset <= status[27] | buttons[1] | ~rom_loaded | rom_download;

// ========== ROM stream -> SDRAM loader + protection table ==========
wire [24:1] ldr_addr;
wire [15:0] ldr_data;
wire        ldr_req;
wire        ldr_ack;

wire        prot_wr;
wire  [7:0] prot_a;
wire  [3:0] prot_d;
wire  [7:0] board_cfg;
wire  [1:0] pcm_bank_mask;
wire        has_pcm;
wire        loading;
wire        ldr_wait;   // c2_romload's own backpressure signal — see note below

c2_romload romload
(
    .CLK(clk_sys),
    .RESET((~rom_loaded | buttons[1]) & ~rom_download),

    .IOCTL_DOWNLOAD(rom_download),
    .IOCTL_WR(ioctl_wr && !ioctl_index),
    .IOCTL_DOUT(ioctl_dout),
    .IOCTL_WAIT(ldr_wait),

    .SDR_ADDR(ldr_addr),
    .SDR_DATA(ldr_data),
    .SDR_REQ(ldr_req),
    .SDR_ACK(ldr_ack),

    .PROT_WR(prot_wr),
    .PROT_A(prot_a),
    .PROT_D(prot_d),

    .BOARD_CFG(board_cfg),
    .PCM_BANK_MASK(pcm_bank_mask),
    .HAS_PCM(has_pcm),
    .LOADING(loading)
);
// ldr_wait (c2_romload's IOCTL_WAIT) has no consumer: MiST's data_io.v (modules/mist-modules/) has
// no wait/backpressure input at all, unlike hps_io on MiSTer. Left unconnected-but-observed rather
// than tied off silently, so a future testbench/ILA probe can still see it. This is safe as long as
// the SDRAM controller's write-acknowledge latency (a handful of clk_ram cycles, ~100ns) stays well
// under one SPI byte period (SPI_SCK is orders of magnitude slower) — true for every core on this
// platform so far, but genuinely unverified on real hardware for this specific 3-port controller
// under worst-case refresh/PCM-read contention. c2_romload's own OVERFLOW output (also unconnected)
// is the upstream author's own safety-net flag for exactly this failure mode; wire it to a debug LED
// if a real-hardware ROM-corruption report ever needs to confirm/rule this out.

// ========== SDRAM ==========
// Same 3-port shape as the vendored top (Arcade-SystemC2.sv): loader writes, 68000 program-ROM
// reads, uPD7759 sample reads. Ported here verbatim (protocol-independent glue).
wire [23:1] rom_addr;
wire [15:0] rom_data;
wire        rom_req;
wire        rom_ack;

wire [18:0] pcm_addr;
wire [15:0] pcm_word;
wire        pcm_req;
wire        pcm_ack;

reg  pcm_addr0;
always @(posedge clk_sys) if (pcm_req && !pcm_ack) pcm_addr0 <= pcm_addr[0];
wire [7:0] pcm_data = pcm_addr0 ? pcm_word[15:8] : pcm_word[7:0];

reg  pcm_sdr_req;
wire pcm_sdr_ack;
always @(posedge clk_sys) begin
    reg old_req;
    old_req <= pcm_req;
    if (pcm_req && !old_req) pcm_sdr_req <= ~pcm_sdr_ack;
end
assign pcm_ack = (pcm_sdr_req == pcm_sdr_ack) & pcm_req;

sdram sdram
(
    .SDRAM_DQ(SDRAM_DQ),
    .SDRAM_A(SDRAM_A),
    .SDRAM_DQML(SDRAM_DQML),
    .SDRAM_DQMH(SDRAM_DQMH),
    .SDRAM_BA(SDRAM_BA),
    .SDRAM_nCS(SDRAM_nCS),
    .SDRAM_nWE(SDRAM_nWE),
    .SDRAM_nRAS(SDRAM_nRAS),
    .SDRAM_nCAS(SDRAM_nCAS),
    .SDRAM_CLK(SDRAM_CLK),
    .SDRAM_CKE(SDRAM_CKE),

    .init(~pll_locked),
    .clk(clk_ram),

    .addr0(ldr_addr),
    .din0(ldr_data),
    .dout0(),
    .wrl0(1),
    .wrh0(1),
    .req0(ldr_req),
    .ack0(ldr_ack),

    .addr1({1'b0, rom_addr}),
    .din1(0),
    .dout1(rom_data),
    .wrl1(0),
    .wrh1(0),
    .req1(rom_req),
    .ack1(rom_ack),

    .addr2({1'b0, 4'h1, pcm_addr[18:1]}),   // samples at byte 0x200000
    .din2(0),
    .dout2(pcm_word),
    .wrl2(0),
    .wrh2(0),
    .req2(pcm_sdr_req),
    .ack2(pcm_sdr_ack)
);

// ========== Inputs ==========
// Direct joystick-bit reads, not arcade_inputs: the upstream emu module already assembles
// P1/P2/SERVICE straight from fixed joystick_N bit positions matching
// INPUT_PORTS_START(systemc_generic) in MAME's segac2.cpp (see comments below), and that bit
// convention (0=right,1=left,2=down,3=up,4..=named J1 buttons in CONF_STR order) is the same one
// user_io.v fills here — arcade_inputs would only add keyboard-to-joystick translation, which this
// bridge doesn't wire up (documented limitation, see NOTES.md).
//
// Everything the 315-5296 reads is active low.
//   P1/P2   0 B1, 1 B2, 2 B3, 3 unused, 4 down, 5 up, 6 right, 7 left
//   SERVICE 0 coin1, 1 coin2, 2 test, 3 service1, 4 start1, 5 start2
wire [7:0] p1_in = ~{ joystick_0[1],    // left
                      joystick_0[0],    // right
                      joystick_0[3],    // up
                      joystick_0[2],    // down
                      1'b0,
                      joystick_0[6],    // button 3
                      joystick_0[5],    // button 2
                      joystick_0[4] };  // button 1

wire [7:0] p2_in = ~{ joystick_1[1],
                      joystick_1[0],
                      joystick_1[3],
                      joystick_1[2],
                      1'b0,
                      joystick_1[6],
                      joystick_1[5],
                      joystick_1[4] };

// The TEST switch is momentary (segac2.cpp:824, PORT_SERVICE_NO_TOGGLE) and a press *latches* the
// game into the service menu — ten frames is enough. The OSD item is a trigger, not a toggle: fire
// on either edge of status[24] and use a lockout longer than the pulse to swallow the second edge
// of a rise/fall pair (MiST's own R-line delivery convention isn't visible from the FPGA side
// either, same reasoning as the upstream hps_io version this is ported from).
localparam [24:0] TEST_PULSE_W = 25'd13_423_294;   // 0.25 s @ 53.693175 MHz
localparam [24:0] TEST_LOCKOUT = 25'd26_846_588;   // 0.50 s

reg  [24:0] test_cnt  = 0;
reg  [24:0] test_lock = 0;
reg         test_osd_d = 0;
always @(posedge clk_sys) begin
    test_osd_d <= status[24];
    if ((status[24] ^ test_osd_d) && !(|test_lock)) begin
        test_cnt  <= TEST_PULSE_W;
        test_lock <= TEST_LOCKOUT;
    end else begin
        if (|test_cnt)  test_cnt  <= test_cnt  - 1'd1;
        if (|test_lock) test_lock <= test_lock - 1'd1;
    end
end

wire test_btn = (|test_cnt) | joystick_0[10] | joystick_1[10];

wire [7:0] service_in = ~{ 2'b00,
                           joystick_1[7],                   // start 2
                           joystick_0[7],                   // start 1
                           joystick_0[9] | joystick_1[9],   // service
                           test_btn,                        // test (momentary)
                           joystick_1[8],                   // coin 2
                           joystick_0[8] };                 // coin 1

// ========== Game core ==========
wire  [7:0] red, green, blue;
wire        hs, vs, hblank, vblank, ce_pix;
wire  [1:0] resolution;
wire signed [15:0] audio_l, audio_r;

c2_system c2
(
    .RESET_N(~reset),
    .MCLK(clk_sys),

    .LOADING(loading),
    .PAUSE_EN(1'b0),

    .IO_DIR_OVERRIDE(8'hFF),
    .PCM_BANK_MASK(pcm_bank_mask),
    .HAS_PCM(has_pcm),

    .ROM_ADDR(rom_addr),
    .ROM_DATA(rom_data),
    .ROM_REQ(rom_req),
    .ROM_ACK(rom_ack),

    .PCM_ADDR(pcm_addr),
    .PCM_DATA(pcm_data),
    .PCM_REQ(pcm_req),
    .PCM_ACK(pcm_ack),

    .PROT_WR(prot_wr),
    .PROT_A(prot_a),
    .PROT_D(prot_d),

    .RED(red),
    .GREEN(green),
    .BLUE(blue),
    .HS(hs),
    .VS(vs),
    .HBL(hblank),
    .VBL(vblank),
    .CE_PIX(ce_pix),
    .RESOLUTION(resolution),
    .INTERLACE(),
    .FIELD(),

    .AUDIO_L(audio_l),
    .AUDIO_R(audio_r),

    .P1(p1_in),
    .P2(p2_in),
    .SERVICE(service_in),
    .DSW1(status[7:0]),
    .DSW2(status[15:8]),

    // Save support is not implemented in this bridge — work RAM keeps its 0xFF fill at load, same
    // as the vendored top's own behaviour ("Save support is deferred").
    .BRAM_A(16'd0),
    .BRAM_DI(8'd0),
    .BRAM_DO(),
    .BRAM_WE(1'b0),
    .BRAM_CHANGE(),

    .DBG_M68K_A(),
    .DBG_MBUS_DO(),
    .DBG_UNMAPPED(),
    .DBG_BUS_CYCLE(),
    .DBG_WRAM_WR(),
    .DBG_VDP_WR(),
    .DBG_PAL_WR(),
    .DBG_PROT_WR(),
    .DBG_IO_WR(),
    .DBG_FM_WR(),
    .DBG_PCM_WR(),
    .DBG_IRQ6(),
    .DBG_IRQ4(),
    .DBG_IRQ2(),
    .DBG_DISPLAY_EN(),
    .DBG_COL_IDX(),
    .DBG_COL_SPR(),
    .DBG_COL_MODE(),
    .DBG_COL_BORDER(),
    .DBG_PAL_WDATA(),
    .DBG_INTACK(),
    .DBG_IACK_LEVEL(),
    .DBG_IPL_N()
);

// LED lit during an active ROM download, same active-low convention as every other bridge on this
// platform (mariobros_neptunoplus.sv: `assign LED = ~ioctl_download;`) — matches the vendored
// top's own `assign LED_USER = ioctl_download;`.
assign LED = ~ioctl_download;

// ========== Video ==========
// c2_system's own RESOLUTION output (0/1/2/3 = 256x224/320x224/256x240/320x240) is latched for the
// whole frame the same way the vendored top does, and used here only to pick mist_dual_video's own
// pixel-clock divider at runtime: bit0 selects the VDP's actual H32 (MCLK/10) vs H40 (MCLK/8) dot
// clock — this bitstream serves every game in the systemc2 family from one build, and different
// games use different widths, so the divider can't be a fixed compile-time constant the way most
// single-resolution native cores on this platform use it. See NOTES.md.
reg [1:0] res;
always @(posedge clk_sys) begin
    reg old_vbl;
    old_vbl <= vblank;
    if (old_vbl & ~vblank) res <= resolution;
end

wire [3:0] ce_divider = res[0] ? 4'd7 : 4'd9;   // H40 (320w): /8.  H32 (256w): /10.

// "Aspect Ratio" (status[17:16]) is carried in CONF_STR for parity with every other bridge on this
// platform, same as mariobros/breakthru's own copy of this option — mist_dual_video has no
// ARX/ARY-style aspect control (that's a MiSTer/HDMI-scaler concept, video_freak, not present on
// this platform's analog-only video pipeline), so, like those two cores, it isn't wired to anything
// here either.

// Real-hardware finding (2026-09-04): c2/vdp.vhd's HS/VS outputs are active-low (`FF_HS<='1'` at
// reset/idle, `<='0'` during the actual sync pulse — same Genesis/MiSTer-VDP convention the
// vendored top's own MiSTer video_mixer instantiation expects and consumes directly, uninverted).
// `mist_dual_video`'s own scandoubler (`scandoubler_framing.v`) expects ACTIVE-HIGH sync inputs —
// same reason mariobros_neptunoplus.sv inverts its own core's active-low `hsync_n`/`vsync_n`
// (`.HSync(~hsync_n)`) rather than passing them through directly. Feeding `hs`/`vs` here
// uninverted, as the vendored top's own MiSTer wiring pattern suggested, fed the scandoubler's own
// edge-detection logic (which looks for the falling edge of an assumed active-high pulse) the wrong
// edge — every derived line/frame timing calculation downstream was consequently wrong, producing
// recognizable graphics on a rolling/unstable picture on real hardware, exactly matching a vertical-
// hold-style CRT symptom, despite clean Quartus timing closure (a synthesis-time check that has no
// way to catch a synchronous but semantically-inverted signal).
mist_dual_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(8), .USE_BLANKS(1'b1), .BIG_OSD(1'b1)) mist_video(
    .clk_sys        ( clk_sys          ),
    .SPI_SCK        ( SPI_SCK          ),
    .SPI_SS3        ( SPI_SS3          ),
    .SPI_DI         ( SPI_DI           ),
    .R              ( red              ),
    .G              ( green            ),
    .B              ( blue             ),
    .HBlank         ( hblank           ),
    .VBlank         ( vblank           ),
    .HSync          ( ~hs              ),
    .VSync          ( ~vs              ),
    .VGA_R          ( VGA_R            ),
    .VGA_G          ( VGA_G            ),
    .VGA_B          ( VGA_B            ),
    .VGA_VS         ( VGA_VS           ),
    .VGA_HS         ( VGA_HS           ),
    .ce_divider     ( ce_divider       ),
    .rotate         ( 2'b00            ),
    .rotate_screen  ( 2'b00            ),
    .rotate_hfilter ( 1'b0             ),
    .rotate_vfilter ( 1'b0             ),
    .blend          ( 1'b0             ),
    .scandoubler_disable( scandoublerD ),
    .scanlines      ( status[19:18]    ),
    .ypbpr          ( ypbpr            ),
    .no_csync       ( no_csync         )
);

// ========== Audio ==========
// dac.vhd's sigma-delta accumulator expects dac_i as offset binary (MSB=1 == high level), not
// two's complement — c2_system's AUDIO_L/AUDIO_R are declared `signed`, so the sign bit must be
// inverted before either reaches the DAC (dac.vhd's own header comment: "not dac_i(C_bits-1)
// effectively adds 0x8..0 to dac_i"), same fix mariobros_neptunoplus.sv applies for its own signed
// audio output.
wire [15:0] audio_l_offset = {~audio_l[15], audio_l[14:0]};
wire [15:0] audio_r_offset = {~audio_r[15], audio_r[14:0]};

dac #(.C_bits(16)) dac_l(
    .clk_i   ( clk_sys ),
    .res_n_i ( ~reset  ),
    .dac_i   ( audio_l_offset ),
    .dac_o   ( AUDIO_L )
);

dac #(.C_bits(16)) dac_r(
    .clk_i   ( clk_sys ),
    .res_n_i ( ~reset  ),
    .dac_i   ( audio_r_offset ),
    .dac_o   ( AUDIO_R )
);

endmodule
