/*  jt539_single.v — silent placeholder for jotego's K054539 PCM module (jt539)

    jotego's jt539 is a private beta module: upstream's own cfg/files.yaml has it commented out
    (`#jt539:`) and modules/jt539 is empty in the public jtcores tree, so any core that instantiates
    it fails lint/synthesis with "undefined entity jt539_single". This stub keeps the exact port list
    (taken from the instantiations in rungun/xmen) so the core builds without the K054539:

      - PCM playback is silent: rom_cs/rom_addr idle, register reads (dout) return 0.
      - aux_l/aux_r are passed straight to left/right. The real chip mixes its aux input (e.g. xmen's
        YM2151 FM) into its output, so passing it through keeps that audio.
      - timeout (the chip's timer output) is held at 1 = inactive. prmrsocr drives the sound Z80's
        NMI from it (eff_nmin = tima in jtrungun_sound.v), so that core's sound CPU gets no timer
        NMIs.

    Delete this file (and the matching patch) once jt539 is public.
*/

module jt539_single #(parameter VOLSHIFT=0) (
    input                    rst,
    input                    clk,
    input                    cen,
    output                   timeout,
    // CPU interface
    input             [ 8:0] addr,
    input                    we,
    input                    rd,
    input                    cs,
    input             [ 7:0] din,
    output            [ 7:0] dout,
    // ROM
    output                   rom_cs,
    output            [23:0] rom_addr,
    input             [ 7:0] rom_data,
    // aux (e.g. YM) input
    input      signed [15:0] aux_l,
    input      signed [15:0] aux_r,
    // sound output
    output     signed [15:0] left,
    output     signed [15:0] right,
    // debug
    input             [ 7:0] debug_bus,
    output            [ 7:0] st_dout
);

assign timeout  = 1'b1;
assign dout     = 8'd0;
assign rom_cs   = 1'b0;
assign rom_addr = 24'd0;
assign left     = aux_l;
assign right    = aux_r;
assign st_dout  = 8'd0;

endmodule
