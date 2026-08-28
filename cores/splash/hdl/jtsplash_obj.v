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

// Splash! sprites: up to 256, 16x16, 4bpp. Table at words 0x000-0x3ff:
//   word 4n+0 [7:0] sprite code low
//   word 4n+1 [7:0] Y -> screen y = 240 - Y
//   word 4n+2 [7:0] X low
//   word 4n+3 [7:0] attr: 3-0 code high, 6 hflip, 7 vflip
// Second table at 0x400 + 4n, high byte (splash sets 1.1-1.4):
//   11-8 palette, 15 X bit 8
// Lower sprite indexes are drawn on top: scan 0 to 255 with KEEP_OLD
// MAME offset: screen x = X - 8. Ours: xpos = X - 8 - 16 (visible window)

module jtsplash_obj #(
    parameter integer VTOTAL = 270,
    parameter integer YOFFS  = 15   // 16 ventana - 1 (confirmado con render analitico: match 100%)
)(
    input         clk,
    input         rst,
    input         pxl_cen,
    input         hs,
    input  [8:0]  hdump,
    input  [8:0]  vdump,

    output reg [11:1] oram_addr,
    input  [15:0] oram_dout,

    output        rom_cs,
    output [18:2] rom_addr,
    input  [31:0] rom_data,
    input         rom_ok,

    output [7:0]  pxl
);

// the BRAM returns data one clock after the address is presented, so each
// state sets the next address and captures the data requested two states ago
localparam [3:0] IDLE   = 4'd0,
                 AD_Y   = 4'd1,
                 AD_W0  = 4'd2,
                 AD_W2  = 4'd3,
                 AD_W3  = 4'd4,
                 AD_A2  = 4'd5,
                 CAP_A2 = 4'd7,
                 DRAW   = 4'd8,
                 NEXT   = 4'd9;

reg  [8:0] vdump_l;
wire       line_change = vdump != vdump_l;
wire [8:0] next_vpos = vdump == VTOTAL[8:0]-9'd1 ? 9'd0 : vdump + 9'd1;
wire [8:0] line = next_vpos + YOFFS[8:0];

reg  [3:0] state;
reg  [7:0] spr_n;
reg  [8:0] line_r;
reg [15:0] w0, w2, w3, a2;
reg        start;

reg  [8:0] dr_xpos;
reg  [3:0] dr_pal, dr_ysub;
reg [11:0] dr_code;
reg        dr_hflip, dr_vflip, dr_draw;
wire       dr_busy;

wire [ 7:0] sy = 8'd240 - oram_dout[7:0];
wire [ 8:0] py = (line_r - {1'b0, sy}) & 9'h1ff;
wire        online = py < 9'd16;
reg  [ 3:0] py_r;

// bit reversal inside each byte: MAME ROMs pack the leftmost pixel in the
// MSB, jtframe_draw expects it in the LSB
wire [31:0] sorted;
genvar bi;
generate
    for (bi=0; bi<32; bi=bi+1) begin : gsort
        assign sorted[bi] = rom_data[{bi[4:3], ~bi[2:0]}];
    end
endgenerate

always @(posedge clk) vdump_l <= vdump;

always @* begin
    case (state)
        AD_Y:   oram_addr = { 1'b0, spr_n, 2'd1 };
        AD_W0:  oram_addr = { 1'b0, spr_n, 2'd0 };
        AD_W2:  oram_addr = { 1'b0, spr_n, 2'd2 };
        AD_W3:  oram_addr = { 1'b0, spr_n, 2'd3 };
        AD_A2:  oram_addr = { 1'b1, spr_n, 2'd0 };
        default: oram_addr = 11'd0;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state   <= IDLE;
        spr_n   <= 8'd0;
        start   <= 1'b0;
        dr_draw <= 1'b0;
    end else begin
        dr_draw <= 1'b0;
        start   <= line_change;
        if (start) begin
            line_r <= line;
            spr_n  <= 8'd0;
            state  <= AD_Y;
        end else begin
            case (state)
                IDLE: ;
                AD_Y:  state <= AD_W0;
                AD_W0: begin             // Y data arrives now
                    py_r  <= py[3:0];
                    state <= online ? AD_W2 : NEXT;
                end
                AD_W2: begin
                    w0    <= oram_dout;  // data for word 4n+0
                    state <= AD_W3;
                end
                AD_W3: begin
                    w2    <= oram_dout;  // data for word 4n+2
                    state <= AD_A2;
                end
                AD_A2: begin
                    w3    <= oram_dout;  // data for word 4n+3
                    state <= CAP_A2;
                end
                CAP_A2: begin
                    a2       <= oram_dout; // data for word 0x400+4n
                    dr_code  <= { w3[3:0], w0[7:0] };
                    dr_hflip <= w3[6];
                    dr_vflip <= w3[7];
                    dr_ysub  <= py_r;
                    dr_xpos  <= { oram_dout[15], w2[7:0] } - 9'd25; // -8 MAME -16 ventana -1 latencia objdraw (medido)
                    dr_pal   <= oram_dout[11:8];
                    state    <= DRAW;
                end
                DRAW: if (!dr_busy) begin
                    dr_draw <= 1'b1;
                    state   <= NEXT;
                end
                NEXT: if (spr_n == 8'd255) begin
                    state <= IDLE;
                end else begin
                    spr_n <= spr_n + 8'd1;
                    state <= AD_Y;
                end
                default: state <= IDLE;
            endcase
        end
    end
end

jtframe_objdraw #(
    .AW       (  9 ),
    .CW       ( 12 ),
    .PW       (  8 ),
    .LATCH    (  1 ),
    .KEEP_OLD (  1 )
) u_draw (
    .rst      ( rst        ),
    .clk      ( clk        ),
    .pxl_cen  ( pxl_cen    ),
    .hs       ( hs         ),
    .flip     ( 1'b0       ),
    .hdump    ( hdump      ),

    .draw     ( dr_draw    ),
    .busy     ( dr_busy    ),
    .code     ( dr_code    ),
    .xpos     ( dr_xpos    ),
    .ysub     ( dr_ysub    ),
    .hzoom    ( 6'd0       ),
    .hz_keep  ( 1'b0       ),

    .hflip    ( dr_hflip   ),
    .vflip    ( dr_vflip   ),
    .pal      ( dr_pal     ),

    .rom_addr ( rom_addr   ),
    .rom_cs   ( rom_cs     ),
    .rom_ok   ( rom_ok     ),
    .rom_data ( sorted     ),

    .pxl      ( pxl        )
);

endmodule
