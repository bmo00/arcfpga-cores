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

// Splash! 68000 @ 12 MHz (24 MHz/2 on the PCB, 48 MHz/4 here)
// Memory map (see MAME splash.cpp, splash_map):
//   000000-3fffff ROM (program + bitmap data copied by the CPU)
//   800000-83ffff pixel layer RAM
//   840000-840007 DSW1/DSW2/P1/P2
//   84000a        LS259 coin counters/lockout (not implemented)
//   84000f        sound latch (low byte)
//   880000-881fff VRAM (both tilemaps + scroll regs + spare RAM)
//   8c0000-8c0fff palette
//   900000-900fff sprite RAM
//   ffc000-ffffff work RAM
// IRQ 6 autovectored on vblank

module jtsplash_main (
    input              clk,
    input              rst,
    input              lvbl,

    output     [21:1]  main_addr,
    output reg         main_cs,
    input      [15:0]  main_data,
    input              main_ok,

    output     [15:0]  cpu_dout,
    output     [13:1]  bus_addr,
    output     [17:1]  pxl_addr,
    output             bus_uds, bus_lds,
    output             bus_wr,
    output reg         vram_cs,
    output reg         pal_cs,
    output reg         oram_cs,
    output reg         pxl_cs,
    output reg         wram_cs,
    input      [15:0]  vram_rdata,
    input      [15:0]  pal_rdata,
    input      [15:0]  oram_rdata,
    input      [15:0]  pxl_rdata,
    input      [15:0]  wram_rdata,

    input      [15:0]  dipsw,
    input      [ 5:0]  joystick1,
    input      [ 5:0]  joystick2,
    input      [ 1:0]  coin,
    input      [ 1:0]  cab_1p,
    input              service,
    input              dip_test,
    input              dip_pause,

    output reg [ 7:0]  snd_latch,
    output reg         snd_irq
);

wire [23:0] addr;
wire        RnW;

`ifndef NOMAIN
wire [23:1] A;
wire [ 2:0] FC, IPLn;
wire [15:0] in_dsw1, in_dsw2, in_p1, in_p2;
wire [ 1:0] cpu_dsn;
wire        cpu_cen, cpu_cenb;
wire        UDSn, LDSn, ASn, BUSn, VPAn, DTACKn;
wire        bus_cs, bus_busy;
wire        IPL_n, lvbl_fall, inta;

reg  [15:0] cpu_din;
reg         dsw1_cs, dsw2_cs, p1_cs, p2_cs, snd_latch_cs;

assign addr      = { A, 1'b0 };
assign main_addr = A[21:1];
assign bus_addr  = A[13:1];
assign pxl_addr  = A[17:1];
assign cpu_dsn   = { UDSn, LDSn };
assign bus_uds   = ~UDSn;
assign bus_lds   = ~LDSn;
assign bus_wr    = ~RnW;
assign BUSn      = ASn | &cpu_dsn;
assign inta      = !ASn && FC == 3'd7;
assign VPAn      = ~inta;         // autovector the vblank interrupt
assign bus_cs    = main_cs;
assign bus_busy  = main_cs & ~main_ok;
assign IPLn      = { IPL_n, IPL_n, 1'b1 }; // IRQ level 6
assign lvbl_fall = ~lvbl;

// All inputs are active low. Note BTN2 sits below BTN1 (bits 4 and 5)
assign in_dsw1   = { 8'hff, dipsw[ 7:0] };
assign in_dsw2   = { 8'hff, dipsw[15] & service, dipsw[14:8] };
assign in_p1     = { 8'hff, coin[1],   coin[0],   joystick1[4], joystick1[5], joystick1[3:0] };
assign in_p2     = { 8'hff, cab_1p[1], cab_1p[0], joystick2[4], joystick2[5], joystick2[3:0] };

always @* begin
    main_cs      = !BUSn && addr[23:22] == 2'd0 && RnW;
    pxl_cs       = !BUSn && addr[23:18] == 6'b1000_00;
    vram_cs      = !BUSn && addr[23:16] == 8'h88 && addr[15:13] == 3'd0;
    pal_cs       = !BUSn && addr[23:16] == 8'h8c && addr[15:12] == 4'd0;
    oram_cs      = !BUSn && addr[23:16] == 8'h90 && addr[15:12] == 4'd0;
    wram_cs      = !BUSn && addr[23:14] == 10'h3ff;

    dsw1_cs      = 1'b0;
    dsw2_cs      = 1'b0;
    p1_cs        = 1'b0;
    p2_cs        = 1'b0;
    snd_latch_cs = 1'b0;
    if (!BUSn && addr[23:16] == 8'h84) begin
        if (RnW) begin
            dsw1_cs = addr[3:1] == 3'd0;
            dsw2_cs = addr[3:1] == 3'd1;
            p1_cs   = addr[3:1] == 3'd2;
            p2_cs   = addr[3:1] == 3'd3;
        end else begin
            // 84000a (LS259, coin counters) falls on addr[3:1]==5, ignored
            snd_latch_cs = addr[3:1] == 3'd7 && !LDSn;
        end
    end
end

always @(posedge clk) begin
    cpu_din <= main_cs ? main_data  :
               wram_cs ? wram_rdata :
               pxl_cs  ? pxl_rdata  :
               vram_cs ? vram_rdata :
               pal_cs  ? pal_rdata  :
               oram_cs ? oram_rdata :
               dsw1_cs ? in_dsw1    :
               dsw2_cs ? in_dsw2    :
               p1_cs   ? in_p1      :
               p2_cs   ? in_p2      : 16'hffff;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        snd_latch <= 8'd0;
        snd_irq   <= 1'b0;
    end else begin
        snd_irq <= 1'b0;
        if (snd_latch_cs && !RnW) begin
            snd_latch <= cpu_dout[7:0];
            snd_irq   <= 1'b1;
        end
    end
end

`ifdef SIMULATION
// debug de arranque: muestrea el bus periodicamente y las primeras escrituras
reg [31:0] dbg_cnt = 0;
reg        busn_l  = 1'b1;
reg [ 7:0] dbg_wr  = 0;
reg [ 7:0] dbg_rd  = 0;
always @(posedge clk) begin
    dbg_cnt <= dbg_cnt + 1;
    busn_l  <= BUSn;
    if (dbg_cnt[20:0] == 0)
        $display("DBG68K t=%0t A=%h ASn=%b RnW=%b FC=%b din=%h IPLn=%b",
                 $time, {A,1'b0}, ASn, RnW, FC, cpu_din, IPLn);
    if (busn_l && !BUSn && !RnW && dbg_wr < 8'd40) begin
        dbg_wr <= dbg_wr + 8'd1;
        $display("DBG68K WR t=%0t A=%h dout=%h uds=%b lds=%b (wram=%b pxl=%b vram=%b pal=%b oram=%b)",
                 $time, {A,1'b0}, cpu_dout, ~UDSn, ~LDSn, wram_cs, pxl_cs, vram_cs, pal_cs, oram_cs);
    end
    // primeros 60 ciclos de bus completos, con el dato devuelto al cerrarse
    if (!busn_l && BUSn && dbg_rd < 8'd60) begin
        dbg_rd <= dbg_rd + 8'd1;
        $display("DBG68K CYC %0d A=%h RnW=%b FC=%b din=%h", dbg_rd, {A,1'b0}, RnW, FC, cpu_din);
    end
end
`endif

jtframe_edge #(.QSET(0)) u_irq(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .edgeof ( lvbl_fall ),
    .clr    ( inta      ),
    .q      ( IPL_n     )
);

jtframe_68kdtack_cen #(.W(6),.RECOVERY(1)) u_dtack(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .bus_legit  ( 1'b0      ),
    .bus_ack    ( 1'b0      ),
    .ASn        ( ASn       ),
    .DSn        ( cpu_dsn   ),
    .num        ( 5'd1      ),  // 48 MHz * 1/4 = 12 MHz
    .den        ( 6'd4      ),
    .DTACKn     ( DTACKn    ),
    .wait2      ( 1'b0      ),
    .wait3      ( 1'b0      ),
    .fave       (           ),
    .fworst     (           )
);

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( rst         ),
    .RESETn     (             ),
    .cpu_cen    ( cpu_cen     ),
    .cpu_cenb   ( cpu_cenb    ),

    .eab        ( A           ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout    ),

    .eRWn       ( RnW         ),
    .LDSn       ( LDSn        ),
    .UDSn       ( UDSn        ),
    .ASn        ( ASn         ),
    .VPAn       ( VPAn        ),
    .FC         ( FC          ),

    .BERRn      ( 1'b1        ),
    .HALTn      ( dip_pause   ),
    .BRn        ( 1'b1        ),
    .BGACKn     ( 1'b1        ),
    .BGn        (             ),

    .DTACKn     ( DTACKn      ),
    .IPLn       ( IPLn        )
);

`else
assign main_addr = 21'd0;
assign cpu_dout  = 16'd0;
assign bus_addr  = 13'd0;
assign pxl_addr  = 17'd0;
assign bus_uds   = 1'b0;
assign bus_lds   = 1'b0;
assign bus_wr    = 1'b0;
assign addr      = 24'd0;
assign RnW       = 1'b1;

initial begin
    main_cs   = 1'b0;
    vram_cs   = 1'b0;
    pal_cs    = 1'b0;
    oram_cs   = 1'b0;
    pxl_cs    = 1'b0;
    wram_cs   = 1'b0;
    snd_latch = 8'd0;
    snd_irq   = 1'b0;
end
`endif

endmodule
