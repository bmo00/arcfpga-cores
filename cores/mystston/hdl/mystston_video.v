//============================================================================
//  mystston_video — Video subsystem for Mysterious Stones (Technos 1984)
//  Owns video timing (jtframe_vtimer), the foreground text-tile fetcher, and
//  arbitration of the gfx1 SDRAM bus shared between the foreground fetcher
//  (below) and mystston_obj (sprites) — both read from "fgtiles_sprites".
//
//  Video timing: mystston.cpp's screen.set_raw(PIXEL_CLOCK,384,0,256,272,8,248)
//  gives a WRAPAROUND vertical blanking window (blank=[248,271]+[0,7], visible
//  =[8,247]) — jtframe_vtimer supports this natively (its LVBL update is a
//  case-match on vrender1==VB_START/VB_END, not a magnitude compare), so
//  VB_START=248/VB_END=8/V_START=0 reproduce it exactly; VCNT_END must be
//  overridden to 271 explicitly since its formula default (max(VB_END,
//  VS_END)) assumes a non-wrapping topology and would compute something much
//  smaller than the real wrap point otherwise. Same reasoning for HCNT_END
//  (explicitly 383) given HB_START=256/HB_END=0.
//
//  Bus arbitration: a 2-phase-per-line sequencer prepares sprite and fg-text
//  line buffers for "the next line" one at a time — never concurrently — so
//  gfx1_addr/gfx1_cs can be a plain priority mux with no real contention.
//  License: GPLv3
//============================================================================

module mystston_video(
    input               clk,
    input               rst,
    input               pxl_cen,            // 6 MHz pixel clock enable
    input               pxl2_cen,           // 12 MHz (unused: no interlace/half-rate need here)

    input               gfx_en,             // OSD debug per-layer toggle (jtframe_common_ports.inc's
                                             // [3:0]; only bit0 connects here) — unused: this core
                                             // has no per-layer debug hide implemented
    input               flip,               // screen flip
    input       [7:0]   scroll_reg,         // background vertical scroll (0x2020)
    input               page_select,        // video_control[2] for bg tile page
    input       [1:0]   fg_color,           // video_control[1:0] swapped, see mystston_main.v

    // CPU-side write snoop for videoram/spriteram/paletteram — all single-
    // port BRAM the CPU (mystston_main.v) also accesses directly, so each
    // submodule below keeps its own shadow copy instead of sharing an
    // address bus with the CPU (see mystston_scroll.v's port comment).
    input       [11:0]  cpu_videoram_addr,
    input       [7:0]   cpu_videoram_din,
    input               cpu_videoram_we,
    input       [6:0]   cpu_spriteram_addr,
    input       [7:0]   cpu_spriteram_din,
    input               cpu_spriteram_we,
    input       [4:0]   cpu_paletteram_addr,
    input       [7:0]   cpu_paletteram_din,
    input               cpu_paletteram_we,

    // SDRAM bus: gfx1 (shared for fg tiles and sprite tiles) — word address
    output      [16:1]  gfx1_addr,
    input       [15:0]  gfx1_data,
    output              gfx1_cs,
    input               gfx1_ok,

    // SDRAM bus: gfx2 (background tiles) — owned entirely by mystston_scroll
    output      [16:1]  gfx2_addr,
    input       [15:0]  gfx2_data,
    output              gfx2_cs,
    input               gfx2_ok,

    // Color PROM — owned entirely by mystston_colmix (paletteram is a snoop
    // shadow, see above, not a real bus). This is a jtframe `prom: true`
    // BRAM bus (cfg/mem.yaml), not an SDRAM ROM bus: plain 1-cycle-latency
    // addr->data read, no cs/ok handshake.
    output      [4:0]   proms_addr,
    input       [7:0]   proms_data,

    // Video outputs to framework
    output              LHBL,
    output              LVBL,
    output              HS,
    output              VS,
    output      [3:0]   red,
    output      [3:0]   green,
    output      [3:0]   blue,

    // Scanline counter for main CPU IRQ generation — see mystston_main.v's
    // port comment: 0 = start of visible area (MAME's vpos shifted by -8)
    output      [8:0]   vcnt
);

    //========================================================================
    // Video timing — real jtframe_vtimer ports/params (verified against
    // modules/jtframe/hdl/video/jtframe_vtimer.v): vdump/vrender/vrender1/H,
    // not a plain V; VCNT_END/HCNT_END explicitly overridden (see header).
    //
    // H_PHASE: mystston.cpp's screen.set_raw(...) only gives MAME the total
    // line width and the active/blanking boundary (HB_START/HB_END below) —
    // it says nothing about WHERE inside that blanking window the HSYNC
    // pulse itself sits (MAME's renderer doesn't care), so that front-porch/
    // back-porch split had to be estimated when this timing was written and
    // was never verified against real hardware. On a real CRT that split is
    // exactly what determines horizontal centering: the delay from the end
    // of the HSYNC pulse to the start of active video (back porch) is time
    // the beam spends already sweeping before real pixels arrive, so a
    // larger back porch pushes the image right and a smaller one pulls it
    // left — confirmed empirically on real hardware (direct/CRT output, no
    // scandoubler): a first +16-clock trial (shrinking back porch 34->18)
    // made the picture move 2cm further LEFT (was ~4cm off, became ~6cm),
    // proving the baseline back porch of 34 was already too small, not too
    // large. mystston alone is off-center this way — unlike jtcores' 1942
    // (vertical) or Double Dragon 2 (horizontal) on the same monitor, both
    // centered fine — so this is this core's own front/back-porch split
    // being wrong, not a monitor calibration issue. H_PHASE now SUBTRACTS
    // from HS_START/HS_END (growing back porch, shrinking front porch by
    // the same amount) to pull the image back to the right. Scaling the
    // observed 16 clocks/2cm rate to the original ~4cm offset gives ~32
    // clocks; tune further based on on-hardware measurement.
    //========================================================================
    localparam [8:0] H_PHASE = 9'd32;

    wire [8:0] vdump, vrender, vrender1, H;
    wire       hbl, vbl, hsync, vsync;

    jtframe_vtimer #(
        .V_START  ( 9'd0   ),
        .VB_START ( 9'd248 ),
        .VB_END   ( 9'd8   ),
        .VS_START ( 9'd250 ),
        .VS_END   ( 9'd253 ),
        .VCNT_END ( 9'd271 ),
        .HB_END   ( 9'd0   ),
        .HB_START ( 9'd256 ),
        .HS_START ( 9'd320 - H_PHASE ),
        .HS_END   ( 9'd350 - H_PHASE ),
        .HCNT_END ( 9'd383 ),
        .HCNT_START(9'd0   )
    ) u_vtimer(
        .clk       ( clk      ),
        .pxl_cen   ( pxl_cen  ),
        .vdump     ( vdump    ),
        .vrender   ( vrender  ),
        .vrender1  ( vrender1 ),
        .H         ( H        ),
        .Hinit     (          ),
        .Vinit     (          ),
        .LHBL      ( hbl      ),
        .LVBL      ( vbl      ),
        .HS        ( hsync    ),
        .VS        ( vsync    )
    );

    assign LHBL  = hbl;
    assign LVBL  = vbl;
    assign HS    = hsync;
    assign VS    = vsync;
    assign vcnt  = vdump - 9'd8; // wraps naturally; >240 while in vblank

    wire [8:0] target_line_full = vrender - 9'd8;
    wire       target_valid     = target_line_full < 9'd240;

    reg [8:0] vrender_last;
    always @(posedge clk, posedge rst)
        if (rst) vrender_last <= 9'd0;
        else     vrender_last <= vrender;
    wire line_start = (vrender != vrender_last) && target_valid;

    //========================================================================
    // 2-phase-per-line gfx1 bus sequencer: phase 0 = sprites active,
    // phase 1 = fg text active. Neither module drives gfx1 outside its own
    // phase (gated by the `active` input each owns), so the mux below never
    // has two real drivers at once.
    //========================================================================
    reg       phase; // 0=sprite, 1=fg
    reg [7:0] target_line_r;
    reg       obj_start, fg_start;
    wire      obj_done, fg_done;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            phase     <= 1'b0;
            obj_start <= 1'b0;
            fg_start  <= 1'b0;
        end else begin
            obj_start <= 1'b0;
            fg_start  <= 1'b0;
            if (line_start) begin
                target_line_r <= target_line_full[7:0];
                phase         <= 1'b0;
                obj_start     <= 1'b1;
            end else if (phase == 1'b0 && obj_done) begin
                phase    <= 1'b1;
                fg_start <= 1'b1;
            end
        end
    end

    wire obj_active = ~phase;
    wire fg_active  =  phase;

    //========================================================================
    // Foreground text layer (8x8 tiles, 3bpp planar from gfx1, same region as
    // sprites). Verified against mystston.cpp's get_fg_tile_info()/
    // video_start(): TILEMAP_SCAN_COLS_FLIP_X, 32 cols x 32 rows, no scroll,
    // no per-tile Y-flip quirk (unlike bg). gfx_8x8x3_planar layout: row R
    // col C -> byte (plane*0x4000 + code*8 + R), bit(7-C) (see emu/video/
    // generic.cpp's gfx_8x8x3_planar; only one byte per plane per row, unlike
    // the 16x16 sprite/bg layout's two halves).
    //========================================================================
    reg [7:0] fg_videoram_shadow [0:4095];
    always @(posedge clk) if (cpu_videoram_we) fg_videoram_shadow[cpu_videoram_addr] <= cpu_videoram_din;

    reg [4:0] fg_col;             // 0-31
    wire [4:0] fg_eff_col = flip ? (5'd31 - fg_col) : fg_col;
    wire [8:0] fg_y_pre   = flip ? (9'd239 - { 1'b0, target_line_r }) : { 1'b0, target_line_r };
    wire [4:0] fg_row     = fg_y_pre[7:3]; // 0-29
    wire [2:0] fg_line    = fg_y_pre[2:0]; // 0-7, no flip-quirk on fg
    wire [9:0] fg_tile_index = (5'd31 - fg_eff_col) * 10'd32 + { 5'd0, fg_row }; // (31-col)*32+row

    wire [11:0] fg_code_lo_addr = { 1'b0, fg_tile_index };
    wire [11:0] fg_code_hi_addr = fg_code_lo_addr + 12'h400;

    reg  [10:0] fg_code;
    reg  [7:0]  fg_plane_byte [0:2];
    reg  [1:0]  fg_plane_idx;
    reg  [4:0]  fg_out_col;
    reg  [2:0]  fg_tile_pixel;
    reg  [8:0]  fg_dest_x_pre, fg_dest_x;
    reg  [4:0]  fg_col_idx;

    reg [4:0] fg_pxl_buf [0:255]; // {fg_color[1:0], tile_pixel[2:0]}
    wire [8:0] hcnt = H;
    wire [4:0] fg_pxl = fg_pxl_buf[hcnt[7:0]];
    wire       fg_hit = (hcnt < 9'd256) && (fg_pxl_buf[hcnt[7:0]][2:0] != 3'd0);

    wire [16:0] fg_plane_base = { 4'd0, fg_code, 3'd0 } + (fg_plane_idx * 17'd16384); // code*8 + plane*0x4000
    wire [16:0] fg_byte_addr  = fg_plane_base + { 13'd0, fg_line };

    reg [16:0] fg_gfx1_addr_r;
    reg        fg_gfx1_cs_r;

    localparam F_IDLE      = 3'd0,
               F_CODE      = 3'd1,
               F_FETCH_REQ = 3'd2,
               F_FETCH_WAIT= 3'd3,
               F_FETCH_NEXT= 3'd4,
               F_STORE     = 3'd5,
               F_NEXT_COL  = 3'd6,
               F_DONE      = 3'd7;
    reg [2:0] f_state;
    integer   j;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            f_state      <= F_IDLE;
            fg_gfx1_cs_r <= 1'b0;
            fg_col       <= 5'd0;
        end else begin
            case (f_state)
                F_IDLE: begin
                    fg_gfx1_cs_r <= 1'b0;
                    if (fg_start) begin
                        fg_col  <= 5'd0;
                        f_state <= F_CODE;
                    end
                end
                F_CODE: begin
                    fg_code <= { fg_videoram_shadow[fg_code_hi_addr][2:0], fg_videoram_shadow[fg_code_lo_addr] };
                    fg_plane_idx <= 2'd0;
                    f_state <= F_FETCH_REQ;
                end
                F_FETCH_REQ: begin
                    if (fg_active) begin
                        fg_gfx1_addr_r <= fg_byte_addr;
                        fg_gfx1_cs_r   <= 1'b1;
                        f_state        <= F_FETCH_WAIT;
                    end
                end
                F_FETCH_WAIT: begin
                    if (fg_active && gfx1_ok) begin
                        fg_plane_byte[fg_plane_idx] <= fg_byte_addr[0] ? gfx1_data[15:8] : gfx1_data[7:0];
                        fg_gfx1_cs_r <= 1'b0;
                        f_state <= F_FETCH_NEXT;
                    end
                end
                F_FETCH_NEXT: begin
                    if (fg_plane_idx == 2'd2) begin
                        f_state <= F_STORE;
                    end else begin
                        fg_plane_idx <= fg_plane_idx + 2'd1;
                        f_state <= F_FETCH_REQ;
                    end
                end
                F_STORE: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        fg_col_idx = flip ? (5'd7 - j[4:0]) : j[4:0];
                        fg_tile_pixel = { fg_plane_byte[2][7-fg_col_idx[2:0]], fg_plane_byte[1][7-fg_col_idx[2:0]], fg_plane_byte[0][7-fg_col_idx[2:0]] };
                        fg_dest_x_pre = { 4'd0, fg_col } * 9'd8 + j[8:0];
                        fg_dest_x = flip ? (9'd255 - fg_dest_x_pre) : fg_dest_x_pre;
                        if (fg_dest_x < 9'd256)
                            fg_pxl_buf[fg_dest_x[7:0]] <= { fg_color, fg_tile_pixel };
                    end
                    f_state <= F_NEXT_COL;
                end
                F_NEXT_COL: begin
                    if (fg_col == 5'd31) begin
                        f_state <= F_DONE;
                    end else begin
                        fg_col  <= fg_col + 5'd1;
                        f_state <= F_CODE;
                    end
                end
                F_DONE: f_state <= F_IDLE;
                default: f_state <= F_IDLE;
            endcase
        end
    end
    assign fg_done = (f_state == F_DONE);


    //========================================================================
    // gfx1 bus mux (sprites vs fg text — see phase sequencer above)
    //========================================================================
    wire [16:0] obj_gfx1_addr;
    wire        obj_gfx1_cs;

    wire [16:0] gfx1_addr_full = phase ? fg_gfx1_addr_r : obj_gfx1_addr;
    assign gfx1_addr = gfx1_addr_full[16:1];
    assign gfx1_cs   = phase ? fg_gfx1_cs_r : obj_gfx1_cs;

    //========================================================================
    // Sub-module instantiations
    //========================================================================
    wire [2:0] bg_pxl;
    wire       bg_hit;
    mystston_scroll u_scroll(
        .clk               ( clk               ),
        .rst               ( rst               ),
        .start             ( line_start        ),
        .target_line       ( target_line_full[7:0] ),
        .done              (                   ),
        .flip              ( flip              ),
        .scroll_reg        ( scroll_reg        ),
        .page_select       ( page_select       ),
        .cpu_videoram_addr ( cpu_videoram_addr ),
        .cpu_videoram_din  ( cpu_videoram_din  ),
        .cpu_videoram_we   ( cpu_videoram_we   ),
        .gfx2_addr         ( gfx2_addr         ),
        .gfx2_data         ( gfx2_data         ),
        .gfx2_cs           ( gfx2_cs           ),
        .gfx2_ok           ( gfx2_ok           ),
        .hcnt              ( hcnt              ),
        .bg_pxl            ( bg_pxl            ),
        .bg_hit            ( bg_hit            )
    );

    wire [3:0] sprite_pxl;
    wire       sprite_hit;
    mystston_obj u_obj(
        .clk            ( clk            ),
        .rst            ( rst            ),
        .active         ( obj_active     ),
        .start          ( obj_start      ),
        .target_line    ( target_line_r  ),
        .done           ( obj_done       ),
        .flip           ( flip           ),
        .cpu_spriteram_addr ( cpu_spriteram_addr ),
        .cpu_spriteram_din  ( cpu_spriteram_din  ),
        .cpu_spriteram_we   ( cpu_spriteram_we   ),
        .gfx1_addr      ( obj_gfx1_addr  ),
        .gfx1_data      ( gfx1_data      ),
        .gfx1_cs        ( obj_gfx1_cs    ),
        .gfx1_ok        ( gfx1_ok        ),
        .hcnt           ( hcnt           ),
        .sprite_pxl     ( sprite_pxl     ),
        .sprite_hit     ( sprite_hit     )
    );

    mystston_colmix u_colmix(
        .clk            ( clk             ),
        .rst            ( rst             ),
        .pxl_cen        ( pxl_cen         ),
        .video_on       ( LHBL & LVBL     ),
        .bg_pxl         ( bg_pxl          ),
        .bg_hit         ( bg_hit          ),
        .sprite_pxl     ( sprite_pxl      ),
        .sprite_hit     ( sprite_hit      ),
        .fg_pxl         ( fg_pxl          ),
        .fg_hit         ( fg_hit          ),
        .cpu_paletteram_addr( cpu_paletteram_addr ),
        .cpu_paletteram_din ( cpu_paletteram_din  ),
        .cpu_paletteram_we  ( cpu_paletteram_we   ),
        .proms_addr     ( proms_addr      ),
        .proms_data     ( proms_data      ),
        .red            ( red             ),
        .green          ( green           ),
        .blue           ( blue            )
    );

    // Verilator lint-off idiom: pxl2_cen and gfx_en are real framework ports (see their own port
    // comments above for why neither is used here) — referencing them keeps Verilator from
    // flagging them as unused/undriven without disabling the check core-wide.
    wire _unused0 = &{1'b0, pxl2_cen, gfx_en};

endmodule
