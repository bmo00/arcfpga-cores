module jtmomoko_text(
    input             rst,
    input             clk,
    input             hs,           // pulso de inicio de linea
    input             pxl_cen,
    input      [ 8:0] vrender,      // linea a renderizar (0..215 visibles)
    input      [ 8:0] vdump,
    input      [ 8:0] hdump,
    input             flip,
    input      [ 7:0] txt_scrolly,
    input             txt_mode,
    // VRAM texto (puerto principal)
    output reg [ 9:0] vram_addr,
    input      [ 7:0] vram_data,
    // chars 2bpp
    output reg [12:0] chgfx_addr,
    input      [ 7:0] chgfx_data,
    // PROMs de color
    output reg [ 8:0] tprom_addr,
    input      [ 7:0] tprom_data,

    output     [ 6:0] pxl           // {col[4:0], pen[1:0]}
);

// H7: calibrado por barrido pixel a pixel contra MAME (frames 200 y 259 del
// guion comun, dos escenas independientes) -> mejor offset core-vs-render
// (dx,dy)=(+1,-1) de forma nitida (score 1.000 en (1,-1) vs ~0.3-0.5 en
// vecinos), identico al hallado en BG. OJO signo: TXT_HOFF se suma directo
// al DESTINO ('wa'), asi que "HOFF-=dx" fue correcto a la primera (confirmado:
// dx 1->0). TXT_VOFF en cambio se suma al FETCH de origen ('ymame'->'sy'),
// igual que BG_HOFF/BG_VOFF -- una 1a pasada con "VOFF=+1" (regla ingenua
// "-=dy") empeoro dy de -1 a -2; la regla correcta, verificada con 2 puntos
// empiricos + relectura del RTL, es VOFF += dy (ver jtmomoko_bg.v y
// task-7-report.md). El texto no traia VOFF; se anade aqui porque el barrido
// exige el mismo ajuste vertical que BG.
localparam [8:0] TXT_HOFF = -9'sd1;
localparam [8:0] TXT_VOFF = -9'sd1;

// line buffer ping-pong 2x256x7
reg  [6:0] buf0[0:255], buf1[0:255];
reg  [6:0] pxl_r;
reg        wrline;                  // paridad de la linea en render

// render FSM
reg  [3:0] st;
reg  [5:0] xcol;      // 0..31 columnas + fin
reg  [8:0] ymame;     // vrender+16
reg  [8:0] sy;        // linea fuente tras scroll parcial
reg  [4:0] col;
reg  [7:0] code, gL, gR;
reg  [7:0] wa;
reg        line_on;   // sy valida (ramoffset<0x400)
reg  [2:0] sx;
// flip: MAME dibuja el texto en py=255-y con y=16..239 (8 filas de holgura
// asimetrica): ymame = 239-L => vline = 223-vrender (NO 215)
wire [8:0] vline = flip ? 9'd223-vrender : vrender;

always @(posedge clk) begin
    if( rst ) begin
        st <= 4'd15; wrline <= 1'b0;
    end else begin
        case( st )
            4'd15: ;   // reposo, espera hs
            // fase 1: color de la linea
            4'd0: begin
                tprom_addr <= { 1'b0, ymame[7:0] };            // promC[y]
                st <= 4'd1;
            end
            4'd1: st <= 4'd2;
            4'd2: begin
                if( txt_mode ) begin
                    sy  <= tprom_data<8'h08 ? ymame + {1'b0,txt_scrolly} : ymame;
                    col <= { 2'b10, tprom_data[2:0] };          // (c&7)+0x10
                    st  <= 4'd4;
                end else begin
                    sy  <= ymame;
                    st  <= 4'd3;
                end
            end
            4'd3: begin                                          // modo 0: promB
                tprom_addr <= { 4'b1000, ymame[7:3] };           // 0x100 + y>>3
                st <= 4'd12;
            end
            4'd12: st <= 4'd13;
            4'd13: begin
                col <= { 1'b0, tprom_data[3:0] };
                st  <= 4'd4;
            end
            // fase 2: bucle de columnas
            4'd4: begin
                line_on <= sy[8:3] < 6'd32;                      // ramoffset<0x400
                xcol    <= 6'd0;
                st      <= 4'd5;
            end
            4'd5: begin
                vram_addr <= { sy[7:3], xcol[4:0] };
                st <= 4'd6;
            end
            4'd6: st <= 4'd7;
            4'd7: begin
                code       <= vram_data;
                chgfx_addr <= { 2'b00, vram_data, sy[2:0] };     // e = code*8+dy
                st <= 4'd8;
            end
            4'd8: begin
                chgfx_addr <= chgfx_addr + 13'h800;              // mitad derecha
                st <= 4'd9;
            end
            4'd9: begin
                gL <= chgfx_data;
                st <= 4'd10;
            end
            4'd10: begin
                gR <= chgfx_data;
                wa <= { xcol[4:0], 3'd0 } - 8'd8 + TXT_HOFF[7:0];
                sx <= 3'd0;
                st <= 4'd11;
            end
            4'd11: begin
                // se escriben SIEMPRE las 256 posiciones de la linea (32x8,
                // wa envuelve modulo 256), con pen 0 si la fila no es valida:
                // no hace falta borrado previo y la BRAM se infiere limpia
                sx <= sx + 3'd1;
                if( wrline ) buf1[ flip ? 8'd239-wa : wa ] <= line_on ? { col, txpen_r } : 7'd0;
                else         buf0[ flip ? 8'd239-wa : wa ] <= line_on ? { col, txpen_r } : 7'd0;
                wa <= wa + 8'd1;
                if( sx==3'd7 ) begin
                    xcol <= xcol + 6'd1;
                    st   <= xcol==6'd31 ? 4'd15 : 4'd5;
                end
            end
            default: st <= 4'd15;
        endcase
        if( hs ) begin
            wrline <= vrender[0];
            ymame  <= vline + 9'd16 + TXT_VOFF;
            xcol   <= 6'd0;
            st     <= 4'd0;
        end
    end
end

// pixel: sx<4 de gL, si no de gR; planos MAME {4,0}: pen={b[3-i],b[7-i]}
// (case explicito = traduccion literal, sin indexados variables)
reg [1:0] txpen_r;
always @* case( {sx[2], sx[1:0]} )
    3'b000: txpen_r = { gL[3], gL[7] };
    3'b001: txpen_r = { gL[2], gL[6] };
    3'b010: txpen_r = { gL[1], gL[5] };
    3'b011: txpen_r = { gL[0], gL[4] };
    3'b100: txpen_r = { gR[3], gR[7] };
    3'b101: txpen_r = { gR[2], gR[6] };
    3'b110: txpen_r = { gR[1], gR[5] };
    3'b111: txpen_r = { gR[0], gR[4] };
endcase

// lectura sincronizada con el barrido. H5 x=0: en el wrap H 383->0 la muestra
// hdump=383 leia buf[383&255]=buf[127] y (via pipeline de 2 etapas) alimentaba
// la columna 0. Se lee buf[255] en esa muestra: el texto YA escribe la fuente
// de x=0 en buf[255] (char col 1 pixel 0, wa=1*8-8+TXT_HOFF=-1=255, 32 tiles),
// asi que aqui basta la correccion de lectura (sin cambio de escritura, a
// diferencia de BG/FG). Columnas 1..239 intactas (hdump!=383 sin cambios).
wire [7:0] rd_addr = (hdump==9'd383) ? 8'd255 : hdump[7:0];
always @(posedge clk) if( pxl_cen )
    pxl_r <= vdump[0] ? buf1[rd_addr] : buf0[rd_addr];
assign pxl = (hdump<9'd240) ? pxl_r : 7'd0;

endmodule
