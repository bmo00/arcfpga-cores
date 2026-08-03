//============================================================================
//  mystston_main — Main CPU subsystem for Mysterious Stones (Technos 1984)
//  Verified against src/mame/technos/mystston.cpp (M6502(config,...,MASTER_CLOCK/8),
//  main_map(), video_control_w(), ay8910_select_w(), on_scanline_interrupt(),
//  irq_clear_w(), coin_inserted()).
//
//  cen_cpu: 6MHz, 4x the real 1.5MHz CPU rate — jt65c02's own requirement
//  (see IMPLEMENTATION.md#cpu-jt65c02: no rdy pin, mem.yaml's `gate:
//  [maincpu]` handles wait states instead of a manual ready signal).
//
//  joystick1/2, coin, cab_1p: joystick[3:0]=up/down/left/right, [5:4]=
//  button1/2 (JTFRAME_BUTTONS=2); cab_1p[0]=P1 start; coin[0]/[1]=coin1/2.
//  All are active-LOW at this interface (idle=1, pressed=0).
//
//  LVBL: DSW1 bit 7 (0x80) is not a real DIP switch — it's
//  PORT_BIT(0x80,IP_ACTIVE_LOW,IPT_CUSTOM), wired to the screen's own vblank
//  line (PORT_READ_LINE_DEVICE_MEMBER("screen",vblank)). The game busy-waits
//  on it (LDA $2030 / BMI) to sync updates to vblank; treating it as a static
//  dip bit hangs that loop forever. LVBL is already
//  active-high-during-active-display, matching MAME's IP_ACTIVE_LOW
//  inversion, so no extra inversion is needed here.
//
//  vcnt: video timing from mystston_video.v — V counter, 0 = start of
//  visible area (MAME's raw vpos shifted by -8) so JTFRAME's non-wrapping
//  vtimer model can express the driver's wrap-around blanking window; see
//  mystston_video.v's jtframe_vtimer instantiation for the actual
//  VB_START/VB_END values chosen to reproduce vbend=8/vbstart=248.
//  License: GPLv3
//============================================================================

module mystston_main(
    input               clk,
    input               rst,
    input               cen_cpu,            // 6 MHz, 4x real CPU rate — see header comment

    // SDRAM bus for main program ROM (maincpu), real content 0x4000-0xffff
    output      [15:0]  maincpu_addr,
    input       [7:0]   maincpu_data,
    output              maincpu_cs,
    input               maincpu_ok,

    // BRAM bus for work RAM (single-cycle, no cs/ok — see jtframe_ram)
    output      [11:0]  workram_addr,
    input       [7:0]   workram_dout,
    output      [7:0]   workram_din,
    output              workram_we,

    // BRAM bus for video RAM (fg_videoram 0x000-0x7ff, bg_videoram 0x800-0xfff)
    output      [11:0]  videoram_addr,
    input       [7:0]   videoram_dout,
    output      [7:0]   videoram_din,
    output              videoram_we,

    // BRAM bus for sprite RAM (real size 0x60 bytes)
    output      [6:0]   spriteram_addr,
    input       [7:0]   spriteram_dout,
    output      [7:0]   spriteram_din,
    output              spriteram_we,

    // BRAM bus for palette RAM (real size 0x20 bytes)
    output      [4:0]   paletteram_addr,
    input       [7:0]   paletteram_dout,
    output      [7:0]   paletteram_din,
    output              paletteram_we,

    // Inputs — widths/names match jtframe_common_ports.inc; see header comment
    input       [5:0]   joystick1,
    input       [5:0]   joystick2,
    input       [3:0]   coin,
    input       [3:0]   cab_1p,
    input               service,
    input       [31:0]  dipsw,
    input               dip_pause,

    input               LVBL,               // DSW1 bit7 vblank quirk — see header comment

    input       [8:0]   vcnt,               // V=0 at start of visible area — see header comment

    // Outputs to video
    output      [7:0]   video_control,      // full register — flip(7), coin ctrs(5:4), page(2), fg color(1:0)
    output      [7:0]   scroll_reg,         // 0x2020 write — background VERTICAL scroll (set_scrolly)
    output              flip,               // combined DIP + video_control[7] flip

    // Outputs to sound
    output      [7:0]   snd_latch,          // data for AY8910 (0x2030 write, mirrors DSW1 read)
    output      [7:0]   snd_sel,            // AY8910 BC1/BDIR select register (0x2040 write)
    output              snd_sel_we          // pulse: snd_sel was written this cycle
);

    // ------------------------------------------------------------------
    // CPU instantiation — jt65c02 (modules/jt680x). Ports/polarity: wr/rd
    // (not a single rw), no rdy port at all (mem.yaml's `gate:` handles wait
    // states instead — see cen_cpu's port comment), irq is level-sensitive
    // and active-HIGH, nmi is edge-sensitive and active-HIGH (both opposite
    // polarity from the real 6502 pins, which jt65c02 abstracts internally).
    // ------------------------------------------------------------------
    wire [15:0] cpu_addr;
    wire [7:0]  cpu_dout;
    reg  [7:0]  cpu_din;
    wire        cpu_wr, cpu_rd;
    wire        irq, nmi;
    wire        cpu_fetch;

    jt65c02 u_cpu(
        .rst        ( rst           ),
        .clk        ( clk           ),
        .cen        ( cen_cpu       ),
        .irq        ( irq           ),
        .nmi        ( nmi           ),
        .opdec      ( 1'b0          ),
        .wr         ( cpu_wr        ),
        .rd         ( cpu_rd        ),
        .fetch      ( cpu_fetch     ),
        .addr       ( cpu_addr      ),
        .din        ( cpu_din       ),
        .dout       ( cpu_dout      )
    );

    // ------------------------------------------------------------------
    // Address decode — matches mystston.cpp's main_map() exactly, including
    // the mirror masks on the I/O register block (mirror(0x1f8f) ignores
    // address bits [12:7] and [3:0]; paletteram's mirror(0x1f80) ignores only
    // [12:7]).
    // ------------------------------------------------------------------
    wire        rom_sel      = (cpu_addr >= 16'h4000);                 // 0x4000-0xffff
    wire        workram_lo   = (cpu_addr < 16'h0780);                  // 0x0000-0x077f
    wire        spriteram_sel= (cpu_addr >= 16'h0780 && cpu_addr < 16'h07e0); // 0x0780-0x07df
    wire        workram_hi   = (cpu_addr >= 16'h07e0 && cpu_addr < 16'h1000); // 0x07e0-0x0fff
    wire        fg_vram_sel  = (cpu_addr >= 16'h1000 && cpu_addr < 16'h1800); // 0x1000-0x17ff
    wire        bg_vram_sel  = (cpu_addr >= 16'h1800 && cpu_addr < 16'h2000); // 0x1800-0x1fff
    wire        workram_sel  = workram_lo | workram_hi;
    wire        videoram_sel = fg_vram_sel | bg_vram_sel;

    wire        io_region    = (cpu_addr[15:13] == 3'b001);            // 0x2000-0x3fff
    wire        video_ctrl_cs= io_region && (cpu_addr[6:4] == 3'b000); // 0x2000 (r: IN0)
    wire        irq_clear_cs = io_region && (cpu_addr[6:4] == 3'b001); // 0x2010 (r: IN1)
    wire        scroll_cs    = io_region && (cpu_addr[6:4] == 3'b010); // 0x2020 (r: DSW0)
    wire        snd_latch_cs = io_region && (cpu_addr[6:4] == 3'b011); // 0x2030 (r: DSW1)
    wire        snd_sel_cs   = io_region && (cpu_addr[6:4] == 3'b100); // 0x2040 (write-only)
    wire        paletteram_cs= io_region && (cpu_addr[6:5] == 2'b11); // 0x2060-0x207f

    wire        wr = cpu_wr;

    // ------------------------------------------------------------------
    // BRAM pass-throughs. addr/wr/rd stay valid for several clk cycles per
    // real bus cycle (jt65c02.v: "addr always valid") — no extra cen gate is
    // needed on these: re-asserting the same write for a few clk cycles is
    // harmless since cpu_dout hasn't changed yet either.
    // ------------------------------------------------------------------
    assign workram_addr    = cpu_addr[11:0];
    assign workram_din     = cpu_dout;
    assign workram_we      = workram_sel & wr;

    assign videoram_addr   = cpu_addr[11:0];
    assign videoram_din    = cpu_dout;
    assign videoram_we     = videoram_sel & wr;

    assign spriteram_addr  = cpu_addr[6:0];
    assign spriteram_din   = cpu_dout;
    assign spriteram_we    = spriteram_sel & wr;

    assign paletteram_addr = cpu_addr[4:0];
    assign paletteram_din  = cpu_dout;
    assign paletteram_we   = paletteram_cs & wr;

    // ------------------------------------------------------------------
    // ROM bus
    // ------------------------------------------------------------------
    assign maincpu_addr = cpu_addr;
    assign maincpu_cs   = rom_sel & cpu_rd;

    // ------------------------------------------------------------------
    // Input read mux (IN0 @ 0x2000, IN1 @ 0x2010 — mystston.cpp INPUT_PORTS_START)
    // ------------------------------------------------------------------
    // coin[]/cab_1p[]/joystick[] are ALL ACTIVE-LOW at this interface
    // (idle=1, pressed=0).
    wire [7:0] in0 = { coin[1], coin[0], joystick1[5], joystick1[4],
                       joystick1[2], joystick1[3], joystick1[1], joystick1[0] };
    // in0/in1 bit order (LSB first): right,left,up,down,button1,button2,
    // coin1/cab2,coin2/cab1 (mystston.cpp IN0/IN1: bit0=right,1=left,2=up,
    // 3=down,4=btn1,5=btn2,6/7=coin or cabinet start). joystick[3:0] is
    // up/down/left/right, so bits [2]/[3] are swapped here to match.
    wire [7:0] in1 = { cab_1p[1], cab_1p[0], joystick2[5], joystick2[4],
                       joystick2[2], joystick2[3], joystick2[1], joystick2[0] };

    reg [7:0] io_rdata;
    always @(*) begin
        case (cpu_addr[6:4])
            3'b000:  io_rdata = in0;
            3'b001:  io_rdata = in1;
            3'b010:  io_rdata = dipsw[7:0];   // DSW0
            3'b011:  io_rdata = { LVBL, dipsw[14:8] };  // DSW1, bit7 = live vblank (see LVBL port comment)
            default: io_rdata = 8'hFF;
        endcase
    end

    always @(*) begin
        if (rom_sel)
            cpu_din = maincpu_data;
        else if (workram_sel)
            cpu_din = workram_dout;
        else if (spriteram_sel)
            cpu_din = spriteram_dout;
        else if (videoram_sel)
            cpu_din = videoram_dout;
        else if (paletteram_cs)
            cpu_din = paletteram_dout;
        else if (io_region)
            cpu_din = io_rdata;
        else
            cpu_din = 8'hFF;
    end

    // ------------------------------------------------------------------
    // Registers written by the CPU
    // ------------------------------------------------------------------
    reg [7:0] video_control_r;
    reg [7:0] scroll_r;
    reg [7:0] snd_latch_r;
    reg [7:0] snd_sel_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            video_control_r <= 8'd0;
            scroll_r        <= 8'd0;
            snd_latch_r     <= 8'd0;
            snd_sel_r       <= 8'd0;
        end else if (wr) begin
            if (video_ctrl_cs) video_control_r <= cpu_dout;
            if (scroll_cs)     scroll_r        <= cpu_dout;
            if (snd_latch_cs)  snd_latch_r     <= cpu_dout;
            if (snd_sel_cs)    snd_sel_r       <= cpu_dout;
        end
    end

    assign video_control = video_control_r;
    assign scroll_reg    = scroll_r;
    assign snd_latch     = snd_latch_r;
    assign snd_sel       = snd_sel_r;
    assign snd_sel_we    = snd_sel_cs & wr;
    
    // dipsw[13] is the Flip Screen DIP (DSW1 bit5); see doc/IMPLEMENTATION.md's
    // Implementation log (Video) for why it's inverted here relative to
    // mystston.cpp's own flip formula.
    assign flip = video_control_r[7] ^ ~dipsw[13];

    // ------------------------------------------------------------------
    // Scanline interrupt — mystston.cpp: interrupt every 16 scanlines
    // starting at vpos=8 (FIRST_INT_VPOS), wrapping at VBSTART=248, 16
    // interrupts/frame. mystston_video.v's vtimer is configured so its own V
    // counter is MAME's vpos shifted by -8 (V=0 is vpos=8, the first visible
    // line) — in that numbering the interrupt scanlines are V=0,16,32,...,240
    // (240 = vpos 248, the entry into vblank), i.e. V[3:0]==0 && V<=240.
    // irq_clear_w (0x2010 write) clears the CPU's IRQ line (line 0 in MAME,
    // i.e. the CPU's single maskable IRQ input). jt65c02's irq is level-
    // sensitive and active-HIGH, so irq_pending itself IS the irq input
    // (no inversion, unlike the old CPU module's wiring).
    // ------------------------------------------------------------------
    reg [8:0] vcnt_l;
    reg       irq_pending;
    wire      irq_scanline = (vcnt[3:0] == 4'h0) && (vcnt <= 9'd240);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            vcnt_l   <= 9'd0;
            irq_pending <= 1'b0;
        end else begin
            vcnt_l <= vcnt;
            if (irq_clear_cs && wr)
                irq_pending <= 1'b0;
            else if (vcnt != vcnt_l && irq_scanline)
                irq_pending <= 1'b1;
        end
    end

    // dip_pause (test/service pause from the OSD) simply blocks the IRQ line
    // from ever asserting, freezing game logic. dip_pause is 1 during NORMAL
    // operation and 0 while paused (jtframe_dip.v's own
    // `dip_pause <= ~game_pause & ~osd_shown`) — must NOT be inverted here.
    assign irq = irq_pending & dip_pause;

    // ------------------------------------------------------------------
    // Coin NMI — mystston.cpp's coin_inserted(): NMI is ASSERTED on the
    // falling edge of the raw (active-low) coin switch signal, i.e. the
    // instant the switch is pressed, and stays asserted (a level, not a
    // latched one-shot) until the switch is released — there is no software
    // acknowledge register for it on real hardware. coin[] at this interface
    // is itself active-LOW, so building an active-high level for jt65c02's
    // nmi input (edge-sensitive, active-HIGH) needs an explicit invert.
    assign nmi = ~coin[0] | ~coin[1];

endmodule
