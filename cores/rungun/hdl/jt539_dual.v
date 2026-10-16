/*  jt539_dual.v — silent placeholder for jotego's dual K054539 PCM module (jt539)

    Same reason and behaviour as jt539_single.v (private beta module, not in the public jtcores
    tree): two silent K054539s with the port list taken from rungun's jtrungun_sound.v. aux inputs
    are passed through to the outputs, register reads return 0, ROM ports idle, timeouts held
    inactive (1). In rungun, chip B's output feeds chip A's aux input and B's own aux is tied to 0,
    so the whole PCM path is silent.

    Delete this file (and the matching patch) once jt539 is public.
*/

module jt539_dual #(parameter VOLSHIFT_A=0, VOLSHIFT_B=0) (
    input                    rst,
    input                    clk,
    input                    cen,
    output                   timeout_a,
    output                   timeout_b,
    // CPU interface
    input             [ 8:0] addr_a,
    input             [ 8:0] addr_b,
    input                    we_a,
    input                    we_b,
    input                    rd_a,
    input                    rd_b,
    input                    cs_a,
    input                    cs_b,
    input             [ 7:0] din_a,
    input             [ 7:0] din_b,
    output            [ 7:0] dout_a,
    output            [ 7:0] dout_b,
    // ROM
    output                   rom_cs_a,
    output                   rom_cs_b,
    output            [23:0] rom_addr_a,
    output            [23:0] rom_addr_b,
    input             [ 7:0] rom_data_a,
    input             [ 7:0] rom_data_b,
    // aux inputs
    input      signed [15:0] aux_l_a,
    input      signed [15:0] aux_r_a,
    input      signed [15:0] aux_l_b,
    input      signed [15:0] aux_r_b,
    // sound output
    output     signed [15:0] left_a,
    output     signed [15:0] right_a,
    output     signed [15:0] left_b,
    output     signed [15:0] right_b,
    // debug
    input             [ 7:0] debug_bus,
    output            [ 7:0] st_dout_a,
    output            [ 7:0] st_dout_b
);

assign { timeout_a, timeout_b } = 2'b11;
assign { dout_a, dout_b }       = 16'd0;
assign { rom_cs_a, rom_cs_b }   = 2'b00;
assign rom_addr_a = 24'd0;
assign rom_addr_b = 24'd0;
assign left_a     = aux_l_a;
assign right_a    = aux_r_a;
assign left_b     = aux_l_b;
assign right_b    = aux_r_b;
assign { st_dout_a, st_dout_b } = 16'd0;

endmodule
