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

// Splash! sound: Z80 @ 3.75 MHz + YM3812 @ 3.75 MHz + MSM5205 @ 384 kHz
// Memory map (MAME splash.cpp, splash_sound_map):
//   0000-d7ff ROM
//   d800      ADPCM byte (write). MSM5205 plays the high nibble first
//   e000      ADPCM control (write). Bit 0 = !reset
//   e800      sound latch (read). Clears the Z80 INT
//   f000-f001 YM3812
//   f800-ffff RAM
// A periodic NMI at 3840 Hz (60*64) paces the sample stream

module jtsplash_snd(
    input                rst,
    input                clk,
    input                cen_fm,   // 3.75 MHz
    input                cen_pcm,  // 384 kHz

    input                snd_irq,
    input        [ 7:0]  snd_latch,

    output       [15:0]  rom_addr,
    output               rom_cs,
    input        [ 7:0]  rom_data,
    input                rom_ok,

    output signed [15:0] fm,
    output signed [11:0] pcm
);
`ifndef NOSOUND
wire [15:0] A;
wire [ 7:0] dout, fm_dout, ram_dout;
reg  [ 7:0] din;
reg  [ 7:0] adpcm_data;
reg  [ 3:0] pcm_din;
reg         msm_rstn, vclk_l, nmi_n;
reg  [ 6:0] nmi_cnt;
wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, int_n;
wire        mem_acc, mem_wr, mem_rd;
reg         rom_sel, adpcm_cs, ctl_cs, latch_cs, fm_cs, ram_cs;
wire        vclk;
wire        latch_rd;

assign mem_acc  = ~mreq_n & rfsh_n;
assign mem_wr   = mem_acc & ~wr_n;
assign mem_rd   = mem_acc & ~rd_n;
assign rom_addr = A;
assign rom_cs   = mem_acc & rom_sel;
assign latch_rd = latch_cs & mem_rd;

always @* begin
    rom_sel  = A < 16'hd800;
    adpcm_cs = A[15:11] == 5'b11011; // d800
    ctl_cs   = A[15:11] == 5'b11100; // e000
    latch_cs = A[15:11] == 5'b11101; // e800
    fm_cs    = A[15:11] == 5'b11110; // f000
    ram_cs   = A[15:11] == 5'b11111; // f800
end

always @(posedge clk) begin
    din <= rom_sel  ? rom_data  :
           ram_cs   ? ram_dout  :
           latch_cs ? snd_latch :
           fm_cs    ? fm_dout   : 8'hff;
end

// ADPCM byte latch and nibble feed, high nibble first
always @(posedge clk or posedge rst) begin
    if (rst) begin
        adpcm_data <= 8'd0;
        pcm_din    <= 4'd0;
        msm_rstn   <= 1'b0;
        vclk_l     <= 1'b0;
    end else begin
        vclk_l <= vclk;
        if (mem_wr && adpcm_cs) adpcm_data <= dout;
        if (mem_wr && ctl_cs  ) msm_rstn   <= dout[0];
        if (vclk && !vclk_l) begin
            pcm_din    <= adpcm_data[7:4];
            adpcm_data <= { adpcm_data[3:0], 4'h0 };
        end
    end
end

// Periodic NMI at 384 kHz / 100 = 3840 Hz
always @(posedge clk or posedge rst) begin
    if (rst) begin
        nmi_cnt <= 7'd0;
        nmi_n   <= 1'b1;
    end else if (cen_pcm) begin
        nmi_cnt <= nmi_cnt == 7'd99 ? 7'd0 : nmi_cnt + 7'd1;
        nmi_n   <= ~(nmi_cnt < 7'd4);
    end
end

// INT follows the latch pending flag, like MAME's generic_latch_8
jtframe_ff u_int(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    .sigedge( snd_irq   ),
    .din    ( 1'b1      ),
    .clr    ( latch_rd  ),
    .set    ( 1'b0      ),
    .q      (           ),
    .qn     ( int_n     )
);

jtframe_sysz80 #(.RAM_AW(11)) u_z80(
    .rst_n    ( ~rst        ),
    .clk      ( clk         ),
    .cen      ( cen_fm      ),
    .cpu_cen  (             ),
    .int_n    ( int_n       ),
    .nmi_n    ( nmi_n       ),
    .busrq_n  ( 1'b1        ),
    .m1_n     ( m1_n        ),
    .mreq_n   ( mreq_n      ),
    .iorq_n   ( iorq_n      ),
    .rd_n     ( rd_n        ),
    .wr_n     ( wr_n        ),
    .rfsh_n   ( rfsh_n      ),
    .halt_n   (             ),
    .busak_n  (             ),
    .A        ( A           ),
    .cpu_din  ( din         ),
    .cpu_dout ( dout        ),
    .ram_dout ( ram_dout    ),
    .ram_cs   ( ram_cs      ),
    .rom_cs   ( rom_cs      ),
    .rom_ok   ( rom_ok      )
);

jtopl2 u_opl2(
    .rst    ( rst            ),
    .clk    ( clk            ),
    .cen    ( cen_fm         ),
    .din    ( dout           ),
    .addr   ( A[0]           ),
    .cs_n   ( ~fm_cs         ),
    .wr_n   ( ~(mem_wr & fm_cs) ),
    .dout   ( fm_dout        ),
    .irq_n  (                ),
    .snd    ( fm             ),
    .sample (                )
);

jt5205 u_5205( // 384 kHz / 48 = 8 kHz, 4 bits per sample
    .rst    ( ~msm_rstn  ),
    .clk    ( clk        ),
    .cen    ( cen_pcm    ),
    .sel    ( 2'b10      ),
    .din    ( pcm_din    ),
    .sound  ( pcm        ),
    .sample (            ),
    .irq    (            ),
    .vclk_o ( vclk       )
);
`else
assign rom_addr = 16'd0;
assign rom_cs   = 1'b0;
assign fm       = 16'sd0;
assign pcm      = 12'sd0;
`endif
endmodule
