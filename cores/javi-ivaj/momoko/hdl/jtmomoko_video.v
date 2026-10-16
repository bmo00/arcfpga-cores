module jtmomoko_video(
    input             rst,
    input             clk,
    input             pxl_cen,
    input             pxl2_cen,

    // vregs BRAM (puerto principal)
    output     [ 3:0] vregs_addr,
    input      [ 7:0] vregs_data,
    // vram texto
    output     [ 9:0] vram_addr,
    input      [ 7:0] vram_data,
    output     [12:0] chgfx_addr,
    input      [ 7:0] chgfx_data,
    output     [ 8:0] tprom_addr,
    input      [ 7:0] tprom_data,
    // paleta
    output     [ 9:0] pal_addr,
    input      [ 7:0] pal_data,
    // resto de capas (tasks 6 y 8); sin uso en v1
    // bgmap va al lado fetcher de jtmomoko_bgmap_mux (en game), no directo a la BRAM
    output     [16:0] bgmap_addr,
    input             bgmap_stall,
    input      [ 7:0] bgmap_data,
    output     [12:0] bgatr_addr,
    input      [ 7:0] bgatr_data,
    // NB (mem_ports.inc): bggfx/objgfx son ROM de 16 bits, direccion de
    // palabra sin bit 0 (mismo ancho que el puerto de nivel superior).
    // addr_width en mem.yaml esta en BYTES (bggfx 17 = 128kB, objgfx 16 =
    // 64kB); con eso el puerto de palabra queda en 16/15 bits (Task 6 Step 0)
    output     [16:1] bggfx_addr,
    input      [15:0] bggfx_data,
    output     [13:0] fgmap_addr,
    input      [ 7:0] fgmap_data,
    output     [12:0] fggfx_addr,
    input      [ 7:0] fggfx_data,
    output     [ 7:0] oram_addr,
    input      [ 7:0] oram_data,
    output     [15:1] objgfx_addr,
    input      [15:0] objgfx_data,

    output            LHBL,
    output            LVBL,
    output            HS,
    output            VS,
    output     [ 3:0] red, green, blue,
    input      [ 3:0] gfx_en
);

wire [8:0] vdump, vrender, hdump;
wire [7:0] fg_scrollx, fg_scrolly, txt_scrolly;
wire [4:0] fg_sel, bg_sel;
wire [15:0] bg_scrollx, bg_scrolly;
wire       txt_mode, bg_pri, flip;
wire [6:0] txt_pxl;

jtframe_vtimer #(
    .HCNT_END ( 9'd383 ),
    .HB_START ( 9'd240 ),
    .HB_END   ( 9'd0   ),
    .HS_START ( 9'd284 ),
    .HS_END   ( 9'd316 ),
    .VCNT_END ( 9'd259 ),
    .VB_START ( 9'd216 ),
    .VB_END   ( 9'd0   ),
    .VS_START ( 9'd226 ),
    .VS_END   ( 9'd229 )
) u_vtimer(
    .clk      ( clk     ),
    .pxl_cen  ( pxl_cen ),
    .vdump    ( vdump   ),
    .vrender  ( vrender ),
    .vrender1 (         ),
    .H        ( hdump   ),
    .Hinit    (         ),
    .Vinit    (         ),
    .LHBL     ( LHBL    ),
    .LVBL     ( LVBL    ),
    .HS       ( HS      ),
    .VS       ( VS      )
);

jtmomoko_vregs u_vregs(
    .rst        ( rst        ),
    .clk        ( clk        ),
    .vregs_addr ( vregs_addr ),
    .vregs_data ( vregs_data ),
    .fg_scrollx ( fg_scrollx ),
    .fg_scrolly ( fg_scrolly ),
    .fg_sel     ( fg_sel     ),
    .txt_scrolly( txt_scrolly),
    .txt_mode   ( txt_mode   ),
    .bg_scrollx ( bg_scrollx ),
    .bg_scrolly ( bg_scrolly ),
    .bg_sel     ( bg_sel     ),
    .bg_pri     ( bg_pri     ),
    .flip       ( flip       )
);

jtmomoko_text u_text(
    .rst        ( rst        ),
    .clk        ( clk        ),
    .hs         ( HS         ),
    .pxl_cen    ( pxl_cen    ),
    .vrender    ( vrender    ),
    .vdump      ( vdump      ),
    .hdump      ( hdump      ),
    .flip       ( flip       ),
    .txt_scrolly( txt_scrolly),
    .txt_mode   ( txt_mode   ),
    .vram_addr  ( vram_addr  ),
    .vram_data  ( vram_data  ),
    .chgfx_addr ( chgfx_addr ),
    .chgfx_data ( chgfx_data ),
    .tprom_addr ( tprom_addr ),
    .tprom_data ( tprom_data ),
    .pxl        ( txt_pxl    )
);

wire [8:0] bg_pxl;
wire [1:0] fg_pxl;
wire [7:0] obj_pxl;

jtmomoko_obj u_obj(
    .rst        ( rst        ),
    .clk        ( clk        ),
    .pxl_cen    ( pxl_cen    ),
    .hs         ( HS         ),
    .LHBL       ( LHBL       ),
    .flip       ( flip       ),
    .vrender    ( vrender    ),
    .hdump      ( hdump      ),
    .oram_addr  ( oram_addr  ),
    .oram_data  ( oram_data  ),
    .objgfx_addr( objgfx_addr),
    .objgfx_data( objgfx_data),
    .pxl        ( obj_pxl    )
);

jtmomoko_bg u_bg(
    .rst(rst), .clk(clk), .hs(HS), .pxl_cen(pxl_cen),
    .vrender(vrender), .vdump(vdump), .hdump(hdump), .flip(flip),
    .bg_scrollx(bg_scrollx), .bg_scrolly(bg_scrolly),
    .bg_sel(bg_sel[3:0]), .bg_pri(bg_pri),
    .bgmap_addr(bgmap_addr), .stall(bgmap_stall), .bgmap_data(bgmap_data),
    .bgatr_addr(bgatr_addr), .bgatr_data(bgatr_data),
    .bggfx_addr(bggfx_addr), .bggfx_data(bggfx_data),
    .pxl(bg_pxl)
);
// En game: video.bgmap_addr -> mux.fet_addr, mux.fet_stall -> video.bgmap_stall,
// mux.fet_data -> video.bgmap_data; main.bgwin_* -> mux.bgwin_*; el mux conduce
// el puerto real bgmap_addr/bgmap_data generado por mem.yaml.

jtmomoko_fg u_fg(
    .rst(rst), .clk(clk), .hs(HS), .pxl_cen(pxl_cen),
    .vrender(vrender), .vdump(vdump), .hdump(hdump), .flip(flip),
    .fg_scrollx(fg_scrollx), .fg_scrolly(fg_scrolly), .fg_sel(fg_sel[1:0]),
    .fgmap_addr(fgmap_addr), .fgmap_data(fgmap_data),
    .fggfx_addr(fggfx_addr), .fggfx_data(fggfx_data),
    .pxl(fg_pxl)
);

jtmomoko_colmix u_colmix(
    .rst      ( rst      ),
    .clk      ( clk      ),
    .pxl_cen  ( pxl_cen  ),
    .LHBL     ( LHBL     ),
    .LVBL     ( LVBL     ),
    .txt_pxl  ( gfx_en[0] ? txt_pxl : 7'd0 ),
    .fg_pxl   ( gfx_en[2] ? fg_pxl : 2'd0 ),
    .bg_pxl   ( gfx_en[1] ? bg_pxl : 9'd0 ),
    .obj_pxl  ( gfx_en[3] ? obj_pxl : 8'd0 ),
    .fg_mask  ( fg_sel[4] ),
    .bg_mask  ( bg_sel[4] | ~gfx_en[1] ),
    .pal_addr ( pal_addr ),
    .pal_data ( pal_data ),
    .red      ( red      ),
    .green    ( green    ),
    .blue     ( blue     )
);

endmodule
