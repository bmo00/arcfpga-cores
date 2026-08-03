//============================================================================
//  mystston_colmix — Color mixer for Mysterious Stones (Technos 1984)
//  Verified against mystston.cpp's set_palette()/screen_update() and the
//  GFXDECODE_START palette bases:
//    sprites: GFXDECODE_ENTRY("fgtiles_sprites",0,spritelayout,0*8,2) -> base
//             0, 2 groups of 8 -> palette 0-15 (paletteram, dynamic)
//    background: GFXDECODE_ENTRY("bgtiles",0,spritelayout,2*8,1) -> base 16,
//             1 group of 8 -> palette 16-23 (paletteram, dynamic)
//    foreground: GFXDECODE_ENTRY("fgtiles_sprites",0,gfx_8x8x3_planar,4*8,4)
//             -> base 32, 4 groups of 8 -> palette 32-63 (from color PROM)
//  set_palette(): entries 0-31 come from paletteram, entries 32-63 from the
//  color PROM (i&0x1f) — read once per frame during vblank here, matching
//  MAME's own once-per-frame set_palette() call (not a "goes stale mid-frame"
//  issue: real hardware/MAME only ever refreshes the palette this often too).
//  Byte format (both paletteram and PROM): bits[2:0]=R, bits[5:3]=G,
//  bits[7:6]=B (3-3-2, verified bit-for-bit against set_palette()'s bit
//  shifts). RGB is expanded from 3/3/2 bits to JTFRAME_COLORW=4 by MSB/LSB
//  replication rather than the exact resistor-weighted DAC network
//  (compute_resistor_weights) — a standard, visually-close approximation
//  used throughout jtframe cores; not bit-exact to the real DAC.
//
//  cpu_paletteram_*: Palette RAM is single-port BRAM the CPU
//  (mystston_main.v) also accesses directly — same reasoning as
//  mystston_scroll.v's videoram shadow: a local copy snooped from the CPU's
//  write side, always current (simpler than mystston_scroll's shadow even,
//  since a write mirrors instantly instead of needing a periodic re-read).
//
//  proms_addr/proms_data: Color PROM, a jtframe `prom: true` BRAM bus
//  (cfg/mem.yaml), not an SDRAM ROM bus: plain synchronous read, 1 cycle of
//  latency from proms_addr to proms_data, no cs/ok handshake. Read once
//  after reset into prom_shadow; the PROM never changes, unlike paletteram.
//  License: GPLv3
//============================================================================

module mystston_colmix(
    input               clk,
    input               rst,
    input               pxl_cen,

    input               video_on,           // LHBL & LVBL (both active-high)

    input       [2:0]   bg_pxl,             // palette base 16
    input               bg_hit,
    input       [3:0]   sprite_pxl,         // {color,tile_pixel}, palette base 0
    input               sprite_hit,
    input       [4:0]   fg_pxl,             // {fg_color[1:0],tile_pixel[2:0]}, palette base 32
    input               fg_hit,

    // Palette RAM CPU write snoop — see header comment
    input       [4:0]   cpu_paletteram_addr,
    input       [7:0]   cpu_paletteram_din,
    input               cpu_paletteram_we,

    // Color PROM bus — see header comment
    output reg  [4:0]   proms_addr,
    input       [7:0]   proms_data,

    output reg  [3:0]   red,
    output reg  [3:0]   green,
    output reg  [3:0]   blue
);

    reg [7:0] pal_shadow  [0:31]; // entries 0-31 (dynamic)
    reg [7:0] prom_shadow [0:31]; // entries 32-63 (fixed)

    always @(posedge clk) if (cpu_paletteram_we) pal_shadow[cpu_paletteram_addr] <= cpu_paletteram_din;

    // Ramp-and-capture sweep: jtframe_prom (cfg/mem.yaml's `prom: true`) is a
    // plain synchronous ROM, but the actual latency from presenting proms_addr
    // to seeing the matching proms_data is 2 cycles here, not 1 — proms_addr
    // is itself a register (this block's own output), so a newly-set address
    // only becomes stable for jtframe_prom's own `q<=mem[rd_addr]` to sample
    // on the next edge, and that q only becomes visible on our side as
    // proms_data the edge after that. idx ramps addresses 0..31 while idx<32,
    // and the shadow write (idx-2) runs two cycles behind; finishes after 34
    // cycles (idx 0..33) so the final two in-flight responses (for addresses
    // 30/31) get captured too.
    reg  [5:0] idx;
    reg        proms_done;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            idx        <= 6'd0;
            proms_addr <= 5'd0;
            proms_done <= 1'b0;
        end else if (!proms_done) begin
            if (idx >= 6'd2)
                prom_shadow[idx[4:0] - 5'd2] <= proms_data;
            if (idx == 6'd33) begin
                proms_done <= 1'b1;
            end else begin
                if (idx < 6'd32)
                    proms_addr <= idx[4:0];
                idx <= idx + 6'd1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Priority: FG > sprites > BG (screen_update()'s draw order: bg first,
    // sprites second, fg last/topmost).
    // ------------------------------------------------------------------
    reg [5:0] pal_index;
    reg [7:0] pal_data;

    always @(*) begin
        if (fg_hit)
            pal_index = 6'd32 + { 1'b0, fg_pxl };
        else if (sprite_hit)
            pal_index = { 2'b00, sprite_pxl };
        else
            pal_index = 6'd16 + { 3'b000, bg_pxl }; // bg is always "hit" (opaque)

        pal_data = (pal_index < 6'd32) ? pal_shadow[pal_index[4:0]] : prom_shadow[pal_index[4:0]];
    end

    wire [2:0] pal_r = pal_data[2:0];
    wire [2:0] pal_g = pal_data[5:3];
    wire [1:0] pal_b = pal_data[7:6];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            red   <= 4'd0;
            green <= 4'd0;
            blue  <= 4'd0;
        end else if (pxl_cen) begin
            if (video_on) begin
                red   <= { pal_r, pal_r[2]   };
                green <= { pal_g, pal_g[2]   };
                blue  <= { pal_b, pal_b      };
            end else begin
                red   <= 4'd0;
                green <= 4'd0;
                blue  <= 4'd0;
            end
        end
    end

endmodule
