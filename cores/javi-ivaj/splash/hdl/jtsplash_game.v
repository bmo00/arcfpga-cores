/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 10-7-2026 */

module jtsplash_game(
    `include "jtframe_game_ports.inc"
);

wire        hblank, vblank;
wire [17:1] cpu_pxl_addr;
wire [13:1] cpu_bus_addr;
wire        cpu_uds, cpu_lds, cpu_wr;
wire        cpu_vram_cs, cpu_pal_cs, cpu_oram_cs, cpu_pxl_cs, cpu_wram_cs;
wire [ 7:0] snd_latch;
wire        snd_irq;

// CPU access to BRAM blocks. we[1] = D15-D8 (UDSn), we[0] = D7-D0 (LDSn)
assign vram_cpu_addr = cpu_bus_addr[12:1];
assign vram_we       = {2{cpu_wr & cpu_vram_cs}} & { cpu_uds, cpu_lds };

assign pal_cpu_addr  = cpu_bus_addr[11:1];
assign pal_we        = {2{cpu_wr & cpu_pal_cs}} & { cpu_uds, cpu_lds };

assign oram_cpu_addr = cpu_bus_addr[11:1];
assign oram_we       = {2{cpu_wr & cpu_oram_cs}} & { cpu_uds, cpu_lds };

assign pxl_cpu_addr  = cpu_pxl_addr;
assign pxl_we        = {2{cpu_wr & cpu_pxl_cs}} & { cpu_uds, cpu_lds };

assign wram_addr     = cpu_bus_addr;
assign wram_we       = {2{cpu_wr & cpu_wram_cs}} & { cpu_uds, cpu_lds };

assign LHBL      = ~hblank;
assign LVBL      = ~vblank;
assign dip_flip  = 1'b0;   // Splash! has no screen flip
assign ioctl_din = 8'd0;
assign debug_view = 8'd0;

jtsplash_main u_main (
    .clk           ( clk            ),
    .rst           ( rst            ),
    .lvbl          ( LVBL           ),

    .main_addr     ( main_addr      ),
    .main_cs       ( main_cs        ),
    .main_data     ( main_data      ),
    .main_ok       ( main_ok        ),

    .cpu_dout      ( cpu_dout       ),
    .bus_addr      ( cpu_bus_addr   ),
    .pxl_addr      ( cpu_pxl_addr   ),
    .bus_uds       ( cpu_uds        ),
    .bus_lds       ( cpu_lds        ),
    .bus_wr        ( cpu_wr         ),
    .vram_cs       ( cpu_vram_cs    ),
    .pal_cs        ( cpu_pal_cs     ),
    .oram_cs       ( cpu_oram_cs    ),
    .pxl_cs        ( cpu_pxl_cs     ),
    .wram_cs       ( cpu_wram_cs    ),
    .vram_rdata    ( vram0_cpu_dout ),
    .pal_rdata     ( pal_cpu_dout   ),
    .oram_rdata    ( oram_cpu_dout  ),
    .pxl_rdata     ( pxl_cpu_dout   ),
    .wram_rdata    ( wram_dout      ),

    .dipsw         ( dipsw[15:0]    ),
    .joystick1     ( joystick1[5:0] ),
    .joystick2     ( joystick2[5:0] ),
    .coin          ( coin[1:0]      ),
    .cab_1p        ( cab_1p[1:0]    ),
    .service       ( service        ),
    .dip_test      ( dip_test       ),
    .dip_pause     ( dip_pause      ),

    .snd_latch     ( snd_latch      ),
    .snd_irq       ( snd_irq        )
);

jtsplash_snd u_snd (
    .clk           ( clk            ),
    .rst           ( rst            ),
    .cen_fm        ( cen_fm         ),
    .cen_pcm       ( cen_pcm        ),

    .snd_irq       ( snd_irq        ),
    .snd_latch     ( snd_latch      ),

    .rom_addr      ( snd_addr       ),
    .rom_cs        ( snd_cs         ),
    .rom_data      ( snd_data       ),
    .rom_ok        ( snd_ok         ),

    .fm            ( fm             ),
    .pcm           ( pcm            )
);

jtsplash_video u_video (
    .clk           ( clk            ),
    .rst           ( rst            ),
    .pxl_cen       ( pxl_cen        ),
    .gfx_en        ( gfx_en         ),

    // tilemap 8x8 (front layer)
    .vram0_addr    ( vram0_addr     ),
    .vram0_dout    ( vram0_dout     ),
    .char_addr     ( char_addr      ),
    .char_data     ( char_data      ),
    .char_cs       ( char_cs        ),
    .char_ok       ( char_ok        ),

    // tilemap 16x16 + scroll registers
    .vram1_addr    ( vram1_addr     ),
    .vram1_dout    ( vram1_dout     ),
    .scr_addr      ( scr_addr       ),
    .scr_data      ( scr_data       ),
    .scr_cs        ( scr_cs         ),
    .scr_ok        ( scr_ok         ),

    // sprites
    .oram_addr     ( oram_addr      ),
    .oram_dout     ( oram_dout      ),
    .obj_addr      ( obj_addr       ),
    .obj_data      ( obj_data       ),
    .obj_cs        ( obj_cs         ),
    .obj_ok        ( obj_ok         ),

    // pixel bitmap layer
    .pxlram_addr   ( pxl_addr       ),
    .pxlram_data   ( pxl_dout       ),

    // palette
    .pal_addr      ( pal_addr       ),
    .pal_data      ( pal_dout       ),

    .red           ( red            ),
    .green         ( green          ),
    .blue          ( blue           ),
    .HS            ( HS             ),
    .VS            ( VS             ),
    .hblank        ( hblank         ),
    .vblank        ( vblank         )
);

endmodule
