/*  jt49_exp.v — konamigt-local replacement for modules/jt49/hdl/jt49_exp.v

    Upstream (jlrh/konami-fpga) sets JT49_EXP=nemesis_jt49_exp in cfg/macros.def, expecting a jt49
    whose jt49.v instantiates `JT49_EXP instead of the stock jt49_exp. This repo's modules/jt49
    (jotego/jt49) always instantiates jt49_exp and ignores that macro, so this file provides a
    module with that exact name that forwards to nemesis_jt49_exp — keeping the Nemesis-specific
    volume LUT upstream intended. modules/jt49/hdl/jt49_exp.v must therefore NOT be listed in
    cfg/files.yaml (it would define jt49_exp twice).

    nemesis_jt49_exp only has a 2-bit compression input (4 x 32-entry LUT); jt49 drives a 3-bit
    one. nemesis_sound.v instantiates jt49_bus with COMP=2'b01, so bit 2 is always 0.
*/

module jt49_exp(
    input            clk,
    input      [2:0] comp,
    input      [4:0] din,
    output     [7:0] dout
);

nemesis_jt49_exp u_nemesis(
    .clk    ( clk       ),
    .comp   ( comp[1:0] ),
    .din    ( din       ),
    .dout   ( dout      )
);

endmodule
