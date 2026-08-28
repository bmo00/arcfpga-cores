/* Momoko 120% core - top level (esqueleto H1) */
module jtmomoko_game(
    `include "jtframe_game_ports.inc"
);

// bgmap_addr (BRAM ROM de puerto unico) esta arbitrado por u_bgmap_mux:
// lado CPU (bgwin_*, ventana F000) vs lado fetcher BG (fet_*, aqui video)

wire [7:0] snd_latch;
wire [16:0] bgwin_addr;
wire        bgwin_rd;
wire [ 7:0] bgwin_data;
wire [16:0] vid_bgmap_addr;
wire        vid_bgmap_stall;
wire [ 7:0] vid_bgmap_data;

jtmomoko_main u_main(
    .rst            ( rst            ),
    .clk            ( clk            ),
    .cen_main       ( cen_main       ),
    .LVBL           ( LVBL           ),
    .main_addr      ( main_addr      ),
    .main_cs        ( main_cs        ),
    .main_data      ( main_data      ),
    .main_ok        ( main_ok        ),
    .cpu_dout       ( cpu_dout       ),
    .wram_addr      ( wram_addr      ),
    .wram_we        ( wram_we        ),
    .wram_data      ( wram_dout      ),
    .vram_cpu_addr  ( vram_cpu_addr  ),
    .vram_cpu_we    ( vram_cpu_we    ),
    .vram_cpu_data  ( vram_cpu_data  ),
    .pal_cpu_addr   ( pal_cpu_addr   ),
    .pal_cpu_we     ( pal_cpu_we     ),
    .pal_cpu_data   ( pal_cpu_data   ),
    .oram_cpu_addr  ( oram_cpu_addr  ),
    .oram_cpu_we    ( oram_cpu_we    ),
    .oram_cpu_data  ( oram_cpu_data  ),
    .vregs_cpu_addr ( vregs_cpu_addr ),
    .vregs_cpu_we   ( vregs_cpu_we   ),
    .bgwin_addr     ( bgwin_addr     ),
    .bgwin_rd       ( bgwin_rd       ),
    .bgwin_data     ( bgwin_data     ),
    .dipsw          ( dipsw[15:0]    ),
    .joystick1      ( joystick1[5:0] ),
    .joystick2      ( joystick2[5:0] ),
    .cab_1p         ( cab_1p[1:0]    ),
    .coin           ( coin[1:0]      ),
    .dip_pause      ( dip_pause      ),
    .snd_latch      ( snd_latch      )
);

// bgmap: single-port BRAM ROM, arbitrated between the BG fetcher (video,
// task 6) and the CPU's F000 window banked read
jtmomoko_bgmap_mux u_bgmap_mux(
    .rst        ( rst        ),
    .clk        ( clk        ),
    // puerto unico de la BRAM bgmap
    .bgmap_addr ( bgmap_addr ),
    .bgmap_data ( bgmap_data ),
    // lado fetcher BG (video)
    .fet_addr   ( vid_bgmap_addr  ),
    .fet_stall  ( vid_bgmap_stall ),
    .fet_data   ( vid_bgmap_data  ),
    // lado CPU (ventana F000)
    .bgwin_addr ( bgwin_addr ),
    .bgwin_rd   ( bgwin_rd   ),
    .bgwin_data ( bgwin_data )
);

// Audio: Z80 de sonido, 2x YM2203 (jt03), latch de main por IOA de u_fm1
jtmomoko_snd u_snd(
    .rst        ( rst        ),
    .clk        ( clk        ),
    .cen_snd    ( cen_snd    ),
    .cen_fm     ( cen_fm     ),
    .snd_addr   ( snd_addr   ),
    .snd_cs     ( snd_cs     ),
    .snd_data   ( snd_data   ),
    .snd_ok     ( snd_ok     ),
    .snd_latch  ( snd_latch  ),
    .fm0        ( fm0        ),
    .fm1        ( fm1        ),
    .psg0       ( psg0       ),
    .psg1       ( psg1       )
);

jtmomoko_video u_video(
    .rst          ( rst          ),
    .clk          ( clk          ),
    .pxl_cen      ( pxl_cen      ),
    .pxl2_cen     ( pxl2_cen     ),
    // vregs BRAM (puerto principal)
    // NB: mem.yaml/generador nombran el puerto0 (lectura, "principal") de
    // las BRAM dual_port como `<name>_dout` (bug del generador que ignora
    // un `dout:` distinto ahi, ver comentario en cfg/mem.yaml); por eso
    // aqui se lee vregs_dout/vram_dout/pal_dout/oram_dout, no _data.
    .vregs_addr   ( vregs_addr   ),
    .vregs_data   ( vregs_dout   ),
    // vram texto
    .vram_addr    ( vram_addr    ),
    .vram_data    ( vram_dout    ),
    .chgfx_addr   ( chgfx_addr   ),
    .chgfx_data   ( chgfx_data   ),
    .tprom_addr   ( tprom_addr   ),
    .tprom_data   ( tprom_data   ),
    // paleta
    .pal_addr     ( pal_addr     ),
    .pal_data     ( pal_dout     ),
    // bgmap: lado fetcher del mux (no directo a la BRAM)
    .bgmap_addr   ( vid_bgmap_addr  ),
    .bgmap_stall  ( vid_bgmap_stall ),
    .bgmap_data   ( vid_bgmap_data  ),
    .bgatr_addr   ( bgatr_addr   ),
    .bgatr_data   ( bgatr_data   ),
    .bggfx_addr   ( bggfx_addr   ),
    .bggfx_data   ( bggfx_data   ),
    .fgmap_addr   ( fgmap_addr   ),
    .fgmap_data   ( fgmap_data   ),
    .fggfx_addr   ( fggfx_addr   ),
    .fggfx_data   ( fggfx_data   ),
    .oram_addr    ( oram_addr    ),
    .oram_data    ( oram_dout    ),
    .objgfx_addr  ( objgfx_addr  ),
    .objgfx_data  ( objgfx_data  ),

    .LHBL         ( LHBL         ),
    .LVBL         ( LVBL         ),
    .HS           ( HS           ),
    .VS           ( VS           ),
    .red          ( red          ),
    .green        ( green        ),
    .blue         ( blue         ),
    .gfx_en       ( gfx_en       )
);

assign dip_flip   = 1'b0;
assign ioctl_din  = 8'd0;
assign debug_view = 8'd0;

endmodule
