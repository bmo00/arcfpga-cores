/* Capa BG: tilemap 128x1024 en ROM (bgmap+bgatr+bggfx), scroll lineal.
   Formulas reducidas del driver MAME (ver Global Constraints):
     mx = h + bg_scrollx + 7 (mod 1024), my = vline + bg_scrolly + 16 (mod 8192)
   Mapa: fila my[12:3], columna mx[9:3]. Color/prioridad: col_map[chr + select*512 +
   priority*256] (momoko.cpp:356) => bgatr[{bg_sel[3:0],bg_pri,code}].
   Tile: t13 = {bg_sel[3:0],1'b0,code}; word izquierdo (px 0-3) en {t13,my[2:0]},
   derecho a +0x800 words. */
module jtmomoko_bg(
    input             rst,
    input             clk,
    input             hs,
    input             pxl_cen,
    input      [ 8:0] vrender,
    input      [ 8:0] vdump,
    input      [ 8:0] hdump,
    input             flip,
    input      [15:0] bg_scrollx, bg_scrolly,
    input      [ 3:0] bg_sel,
    input             bg_pri,

    output reg [16:0] bgmap_addr,   // lado fetcher del mux (no la BRAM directa)
    input             stall,        // el mux esta sirviendo a la CPU: reintentar
    input      [ 7:0] bgmap_data,
    output reg [12:0] bgatr_addr,
    input      [ 7:0] bgatr_data,
    output reg [15:0] bggfx_addr,
    input      [15:0] bggfx_data,

    output reg [ 8:0] pxl          // {pri, col[3:0], pen[3:0]}
);

// H7: calibrado por barrido pixel a pixel contra MAME (frames 200 y 259 del
// guion comun) -> mejor offset core-vs-render (dx,dy)=(+1,-1) de forma
// nitida (score 0.991 en (1,-1) vs ~0.8-0.9 en vecinos), identico al hallado
// en jtmomoko_text.v. OJO signo (no es "HOFF-=dx, VOFF-=dy" literal, verificado
// con una 1a pasada fallida + 2 puntos empiricos, ver task-7-report.md): aqui
// HOFF/VOFF se suman a mx0/my (direccion de FETCH del mapa), y "wa" (destino)
// se calcula como tile*8-fine, con fine=mx0[2:0] -- la resta de fine invierte
// el signo respecto al texto (que suma TXT_HOFF directo al destino). Formula
// resultante: HOFF += dx, VOFF += dy (para HOFF, inversa a la de
// jtmomoko_text.v; para VOFF, jtmomoko_text.v resulto tener la misma regla).
localparam [9:0]  BG_HOFF = 10'sd1;
// BG_VOFF a lo ancho de 'my' (13b): {4'd0,BG_VOFF} con BG_VOFF de 9b hacia
// negativo haria zero-extend en vez de sign-extend (bug real, detectado por
// una 1a corrida que empeoro catastroficamente en vez de solo "seguir off
// por 1px" -- ver task-7-report.md). Se declara ya a 13b y se suma directo.
localparam [12:0] BG_VOFF = -13'sd1;

// line buffer ping-pong 2x256x9: solo se escriben 248 de las 256 posiciones
// por linea (31 tiles x 8px); el hueco cae siempre en 240..255, en el
// blanking (HB_START=240), nunca visible
reg  [8:0] buf0[0:255], buf1[0:255];
reg        wrline;

reg  [3:0] st;
reg  [5:0] tcnt;        // 0..30 tiles
reg  [12:0] my;
reg  [ 9:0] mx0;        // mx del pixel h=0
reg  [ 6:0] mcol;
reg  [ 2:0] fine;
reg  [ 7:0] code;
reg  [ 3:0] bg_sel_l;   // bg_sel enclavado al leer el mapa (hallazgo M-1)
reg  [ 4:0] attr;       // {pri,col}
reg  [15:0] wL, wR;
reg  [ 7:0] wa;
reg  [ 2:0] sx;
// constante de flip provisional: verificar en H7 (el texto necesitó 223, ver jtmomoko_text)
wire [8:0] vline = flip ? 9'd215-vrender : vrender;

// pen 4bpp planos MAME {4,0,12,8}: {d0[3-i],d0[7-i],d1[3-i],d1[7-i]}
reg [3:0] pen_r;
wire [15:0] wsel = sx[2] ? wR : wL;
always @* case( sx[1:0] )
    2'd0: pen_r = { wsel[3], wsel[7], wsel[11], wsel[15] };
    2'd1: pen_r = { wsel[2], wsel[6], wsel[10], wsel[14] };
    2'd2: pen_r = { wsel[1], wsel[5], wsel[9],  wsel[13] };
    2'd3: pen_r = { wsel[0], wsel[4], wsel[8],  wsel[12] };
endcase

always @(posedge clk) begin
    if( rst ) begin
        st <= 4'd15;
    end else begin
        case( st )
            4'd15: ;
            // estados 0-2: lectura del mapa a traves del mux; si la CPU roba
            // el puerto (stall) se reintenta desde 0 (el robo dura 2-3 clk y
            // las lecturas CPU van separadas >=19 clk: sin livelock)
            4'd0: begin
                bgmap_addr <= { my[12:3], mcol };
                if( !stall ) st <= 4'd1;
            end
            4'd1: st <= stall ? 4'd0 : 4'd2;
            4'd2: if( stall ) st <= 4'd0; else begin
                code       <= bgmap_data;
                bg_sel_l   <= bg_sel; // enclavado: atributo y gfx del MISMO banco
                bgatr_addr <= { bg_sel, bg_pri, bgmap_data }; // select*512 + pri*256 + chr
                st <= 4'd3;
            end
            4'd3: begin
                bggfx_addr <= { bg_sel_l, 1'b0, code, my[2:0] };  // 4+1+8+3=16
                st <= 4'd4;
            end
            4'd4: begin
                attr       <= bgatr_data[4:0];
                bggfx_addr <= bggfx_addr | 16'h0800;            // mitad derecha
                st <= 4'd5;
            end
            4'd5: begin
                wL <= bggfx_data;
                st <= 4'd6;
            end
            4'd6: begin
                wR <= bggfx_data;
                // H5 x=0: se renderiza un tile extra a la izquierda (mcol-1, 32
                // tiles) y se desplaza wa -8 para que la fuente de la columna 0
                // (mx0-1) caiga en buf[255]; asi la lectura de x=0 (buf[255],
                // ver abajo) tiene contenido valido incluso con fine=0, sin
                // mover buf[0..238] (columnas 1..239 identicas). buf[A]=mx0+A.
                wa <= { tcnt[4:0], 3'd0 } - { 5'd0, fine } - 8'd8;
                sx <= 3'd0;
                st <= 4'd7;
            end
            4'd7: begin
                if( wrline ) buf1[ flip ? 8'd239-wa : wa ] <= { attr, pen_r };
                else         buf0[ flip ? 8'd239-wa : wa ] <= { attr, pen_r };
                wa <= wa + 8'd1;
                sx <= sx + 3'd1;
                if( sx==3'd7 ) begin
                    tcnt <= tcnt + 6'd1;
                    mcol <= mcol + 7'd1;
                    st   <= tcnt==6'd31 ? 4'd15 : 4'd0;  // H5 x=0: 32 tiles (0..31)
                end
            end
            default: st <= 4'd15;
        endcase
        if( hs ) begin
            wrline <= vrender[0];
            my     <= {4'd0, vline} + 13'd16 + bg_scrolly[12:0] + BG_VOFF;
            mx0    <= bg_scrollx[9:0] + 10'd7 + BG_HOFF;
            st     <= 4'd8;
        end
        if( st==4'd8 ) begin       // precalcula columna y fase inicial
            mcol <= mx0[9:3] - 7'd1;   // H5 x=0: empieza un tile a la izquierda
            fine <= mx0[2:0];
            tcnt <= 6'd0;
            st   <= 4'd0;
        end
    end
end

// H5 x=0: en el wrap H 383->0 la lectura registrada (pxl_r<=buf[hdump]) muestrea
// hdump=383 -> buf[383&255]=buf[127], que via el pipeline de 2 etapas (este
// registro + el latch de idx en colmix) alimenta la columna 0 (col N<-buf[N-1]).
// Se corrige leyendo buf[255] en esa unica muestra (hdump==383, siempre en
// blanking): columna 0 pasa a leer buf[255] (fuente mx0-1, escrita arriba) y
// las columnas 1..239 quedan intactas (hdump!=383 sin cambios).
wire [7:0] rd_addr = (hdump==9'd383) ? 8'd255 : hdump[7:0];
always @(posedge clk) if( pxl_cen )
    pxl <= vdump[0] ? buf1[rd_addr] : buf0[rd_addr];

endmodule
