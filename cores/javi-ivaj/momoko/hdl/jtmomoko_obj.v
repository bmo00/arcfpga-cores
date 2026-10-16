module jtmomoko_obj(
    input             rst,
    input             clk,
    input             pxl_cen,
    input             hs,
    input             LHBL,
    input             flip,
    input      [ 8:0] vrender,
    input      [ 8:0] hdump,

    output reg [ 7:0] oram_addr,
    input      [ 7:0] oram_data,
    output reg [15:1] objgfx_addr,
    input      [15:0] objgfx_data,

    output     [ 7:0] pxl
);

// calibrable (H5): ajustado en Step 3 contra MAME (ver task-8-report.md)
localparam [8:0] OBJ_DX = 9'd0;

reg  [3:0] st;
reg  [5:0] idx;                    // 0..38
reg  [7:0] spr_y, spr_code, spr_attr, spr_x;
reg        dr_draw;
wire       dr_busy;
// H5 (final review, hallazgo 1 BLOCKING): jtframe_draw consume pal/hflip de
// forma COMBINACIONAL durante los 8 ciclos del draw (buf_din={pal,pxl} y el
// mux de pxl dependen de hflip en jtframe_draw.v:72-75, sin registro interno
// -- ver jtframe_draw.v, solo lectura). El FSM de aqui abajo no espera a
// !dr_busy tras soltar dr_draw: sigue leyendo la SIGUIENTE entrada de la
// tabla en los mismos regs spr_attr/idx mientras jtframe_draw todavia esta
// dibujando los 8 pixeles del sprite actual -> 6 de los 8 pixeles salian con
// el color/flip/grupo de la entrada siguiente. Fix: latch de los 3 valores
// que jtframe_draw muestrea durante todo el draw, cargados en el mismo ciclo
// que dr_draw<=1'b1 (estado 4'd9), y cablear u_draw a los latches en vez de
// a los regs "en vivo". code10/dy (code/ysub) no necesitan latch: el propio
// jtframe_draw los usa via rom_addr de forma combinacional pero el wrapper
// fst de aqui abajo los muestrea una sola vez en fst==0/1, ANTES de que
// spr_code/spr_y se sobreescriban (ver comentario del "OJO" mas abajo);
// xpos si esta latched internamente por jtframe_draw (buf_addr<=xpos al
// iniciar el draw, hz_keep=0 siempre en esta instancia).
reg  [3:0] dr_pal;
reg        dr_hflip, dr_vflip;
// H5: calibrado por barrido pixel a pixel contra MAME frame 259 (score
// 0.823 en (dx,dy)=(0,-1) i.e. el sprite salia 1 fila alta) -> +1 en la
// constante vertical (223->224) desplaza el sprite hacia abajo 1 linea.
// OBJ_DX=0 ya era exacto (score maximo en dx=0), sin cambios ahi.
wire [8:0] dy    = flip ? (vrender + 9'd15 - {1'b0,spr_y})
                        : (vrender + {1'b0,spr_y} - 9'd224);
wire       match = dy[8:4]==5'd0;
wire [9:0] code10= { spr_attr[6:5], spr_code };
// PENDIENTE (H7): el branch flip=1 de xpos (y el de dy arriba, "vrender+15-
// spr_y") es codigo del brief sin verificar -- ninguna escena estatica
// alcanzable con el guion comun (coin 600-607/start 660-667, sin joystick)
// activa flip=1 (solo se usa en modo cocktail, jugador 2). Si una tarea
// futura habilita flip, calibrar este branch contra MAME antes de asumirlo
// correcto por simetria con el branch flip=0 (que si esta calibrado, ver
// mas arriba: OBJ_DX=0, constante vertical 224).
wire [8:0] xpos  = (flip ? 9'd240 - {1'b0,spr_x} : {1'b0,spr_x}) - 9'd8 + OBJ_DX;

// interfaz ROM del draw: dos lecturas BRAM por fetch
wire [16:2] dr_rom_addr;
wire        dr_rom_cs;
reg         dr_rom_ok;
reg  [15:0] wL, wR;
wire [ 9:0] rc = dr_rom_addr[16:7];       // code
wire [ 3:0] rv = dr_rom_addr[5:2];        // V
// remap de MAME (momoko.cpp:244-245): chr=((chr&0x380)<<1)|(chr&0x7f) inserta
// SIEMPRE un bit 0 fijo entre c[9:7] y c[6:0] -- es un hueco de direccionamiento
// de la ROM, no un selector de mitad de sprite. jtframe_draw sin embargo
// arranca su propio rom_lsb en `hflip` (addr[6] = dr_rom_addr[6]), pensado
// para tiles de 16px reales partidos en dos mitades fisicas; con trunc=8px
// (sprites de 8px, sin mitad real) usar dr_rom_addr[6] aqui haria que los
// sprites con hflip=1 (mayoria en el demo, ver task-8-report.md) lean del
// codigo equivocado (+128 words) en vez del insertado-0 fijo de MAME. La
// mitad L/R real de los 8px (offset +0x800) es aparte, no depende de hflip.
wire [14:0] w_left  = { rc[9:7], 1'b0, rc[6:0], rv };
reg  [ 2:0] fst;
// OJO (bug real, hallado en Task 8 tras dos sims cloud mostrando el sprite
// invisible pese a direcciones de ROM correctas): con trunc=8px y hflip
// cancelado (ver comentario de w_left), jtframe_draw calcula SIEMPRE
// rom_lsb^hflip==0 en el punto donde decide si soltar rom_cs -> nunca lo
// baja a 0 (se queda pegado en 1 tras el primer sprite dibujado con exito).
// Como dr_rom_ok solo se limpia con "!dr_rom_cs", tambien se queda pegado
// en 1 para siempre: todos los sprites siguientes reutilizan wL/wR del
// PRIMER sprite dibujado en toda la simulacion (graficos atascados/en
// blanco). Fix: forzar un fetch nuevo (fst<=0, dr_rom_ok<=0) en cada pulso
// de dr_draw, sin depender del propio rom_cs de jtframe_draw para decidir
// cuando refrescar.
always @(posedge clk) begin
    if( rst || dr_draw ) begin
        fst <= 3'd0; dr_rom_ok <= 1'b0;
    end else case( fst )
        3'd0: if( dr_rom_cs && !dr_rom_ok ) begin
            objgfx_addr <= w_left;
            fst <= 3'd1;
        end else if( !dr_rom_cs ) dr_rom_ok <= 1'b0;
        3'd1: begin objgfx_addr <= w_left | 15'h0800; fst <= 3'd2; end
        3'd2: begin wL <= objgfx_data; fst <= 3'd3; end
        3'd3: begin wR <= objgfx_data; dr_rom_ok <= 1'b1; fst <= 3'd0; end
        default: fst <= 3'd0;
    endcase
end

// planos {12,8,4,0} -> formato jtframe_draw (plano p = byte p, pixel izq en LSB)
wire [31:0] sorted = {
    wR[ 8],wR[ 9],wR[10],wR[11], wL[ 8],wL[ 9],wL[10],wL[11],   // plano 3
    wR[12],wR[13],wR[14],wR[15], wL[12],wL[13],wL[14],wL[15],   // plano 2
    wR[ 0],wR[ 1],wR[ 2],wR[ 3], wL[ 0],wL[ 1],wL[ 2],wL[ 3],   // plano 1
    wR[ 4],wR[ 5],wR[ 6],wR[ 7], wL[ 4],wL[ 5],wL[ 6],wL[ 7] }; // plano 0

// recorrido de la tabla: 0 -> 38 (el ultimo dibujado gana, como MAME)
always @(posedge clk) begin
    if( rst ) begin
        st <= 4'd15; dr_draw <= 1'b0;
    end else begin
        dr_draw <= 1'b0;
        case( st )
            4'd15: ;
            4'd0: begin oram_addr <= 8'h64 + {idx,2'd0}; st <= 4'd1; end
            4'd1: st <= 4'd2;
            4'd2: begin spr_y   <= oram_data; oram_addr <= oram_addr+8'd1; st <= 4'd3; end
            4'd3: st <= 4'd4;
            4'd4: begin spr_code<= oram_data; oram_addr <= oram_addr+8'd1; st <= 4'd5; end
            4'd5: st <= 4'd6;
            4'd6: begin spr_attr<= oram_data; oram_addr <= oram_addr+8'd1; st <= 4'd7; end
            4'd7: st <= 4'd8;
            4'd8: begin spr_x   <= oram_data; st <= 4'd9; end
            4'd9: begin
                if( match && !dr_busy ) begin
                    dr_draw  <= 1'b1;
                    dr_pal   <= { idx>=6'd9, spr_attr[2:0] };
                    dr_hflip <= ~(spr_attr[4]^flip);
                    dr_vflip <=   spr_attr[3]^flip;
                    st <= 4'd10;
                end else if( !match ) st <= 4'd10;
            end
            4'd10: begin
                idx <= idx + 6'd1;
                st  <= idx==6'd38 ? 4'd15 : 4'd0;
            end
            default: st <= 4'd15;
        endcase
        if( hs ) begin
            idx <= 6'd0;
            st  <= 4'd0;
        end
    end
end

wire [8:0] buf_addr;
wire       buf_we;
wire [7:0] buf_din;

jtframe_draw #(
    .AW(9), .CW(10), .PW(8), .KEEP_OLD(0)
) u_draw(
    .rst      ( rst          ),
    .clk      ( clk          ),
    .draw     ( dr_draw      ),
    .busy     ( dr_busy      ),
    .code     ( code10       ),
    .xpos     ( xpos         ),
    .ysub     ( dy[3:0]      ),
    .trunc    ( 2'b10        ),   // sprites de 8 px de ancho
    .hzoom    ( 6'd0         ),
    .hz_keep  ( 1'b0         ),
    .hflip    ( dr_hflip     ),
    .vflip    ( dr_vflip     ),
    .pal      ( dr_pal       ),
    .rom_addr ( dr_rom_addr  ),
    .rom_cs   ( dr_rom_cs    ),
    .rom_ok   ( dr_rom_ok    ),
    .rom_data ( sorted       ),
    .buf_addr ( buf_addr     ),
    .buf_we   ( buf_we       ),
    .buf_din  ( buf_din      )
);

jtframe_obj_buffer #(
    .DW(8), .AW(9), .ALPHA(0)
) u_buf(
    .clk      ( clk        ),
    .LHBL     ( LHBL       ),
    .flip     ( 1'b0       ),
    .wr_data  ( buf_din    ),
    .wr_addr  ( buf_addr   ),
    .we       ( buf_we     ),
    .rd_addr  ( hdump      ),
    .rd       ( pxl_cen    ),
    .rd_data  ( pxl        )
);

endmodule
