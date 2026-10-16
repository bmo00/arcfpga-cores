/* Lee ciclicamente la BRAM vregs (escrita por CPU y por restore de escenas)
   y refresca los flops que consume el video. Fuente unica de verdad = BRAM,
   asi las escenas restauran tambien los registros. */
module jtmomoko_vregs(
    input             rst,
    input             clk,
    output reg [ 3:0] vregs_addr,
    input      [ 7:0] vregs_data,

    output reg [ 7:0] fg_scrollx, fg_scrolly,
    output reg [ 4:0] fg_sel,
    output reg [ 7:0] txt_scrolly,
    output reg        txt_mode,
    output reg [15:0] bg_scrollx, bg_scrolly,
    output reg [ 4:0] bg_sel,
    output reg        bg_pri,
    output reg        flip
);

reg [3:0] rd_addr;   // direccion cuyo dato llega este ciclo (latencia BRAM 1)

always @(posedge clk) begin
    if( rst ) begin
        vregs_addr <= 4'd0;
        rd_addr    <= 4'd15;
        { fg_scrollx, fg_scrolly, txt_scrolly } <= 24'd0;
        { fg_sel, bg_sel } <= 10'd0;
        { bg_scrollx, bg_scrolly } <= 32'd0;
        { txt_mode, bg_pri, flip } <= 3'd0;
    end else begin
        rd_addr    <= vregs_addr;
        vregs_addr <= vregs_addr==4'd12 ? 4'd0 : vregs_addr+4'd1;
        case( rd_addr )
            4'd0:  fg_scrolly        <= vregs_data;
            4'd1:  fg_scrollx        <= vregs_data;
            4'd2:  fg_sel            <= vregs_data[4:0];
            4'd3:  txt_scrolly       <= vregs_data;
            // MAME evalua text_mode con !=0 sobre el byte entero
            // (momoko.cpp:278) y la ROM real escribe 0x02 en E801:
            // reduccion-OR, no solo bit 0 (hallazgo C-1 auditoria doble)
            4'd4:  txt_mode          <= |vregs_data;
            4'd5:  bg_scrolly[ 7:0]  <= vregs_data;
            4'd6:  bg_scrolly[15:8]  <= vregs_data;
            4'd7:  bg_scrollx[ 7:0]  <= vregs_data;
            4'd8:  bg_scrollx[15:8]  <= vregs_data;
            // 4'd9 = bg_bank: solo lo usa la CPU, flop propio en _main
            4'd10: bg_sel            <= vregs_data[4:0];
            4'd11: bg_pri            <= vregs_data[0];
            4'd12: flip              <= vregs_data[0];
            default: ;
        endcase
    end
end

endmodule
