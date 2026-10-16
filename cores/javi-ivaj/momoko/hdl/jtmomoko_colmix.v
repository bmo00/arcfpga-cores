module jtmomoko_colmix(
    input             rst,
    input             clk,
    input             pxl_cen,
    input             LHBL,
    input             LVBL,
    input      [ 6:0] txt_pxl,    // {col[4:0],pen[1:0]}
    input      [ 1:0] fg_pxl,
    input      [ 8:0] bg_pxl,     // {pri,col[3:0],pen[3:0]}
    input      [ 7:0] obj_pxl,    // {grp,pal[2:0],pen[3:0]}
    input             fg_mask,
    input             bg_mask,
    // paleta (puerto principal, 8 bits: par=0R impar=GB, big endian)
    output reg [ 9:0] pal_addr,
    input      [ 7:0] pal_data,
    output reg [ 3:0] red, green, blue
);

reg [8:0] idx;        // indice de paleta 0..511
reg [2:0] ph;         // fase dentro del pixel (8 clk por pixel a 6 MHz)
reg [3:0] r_nx;

wire txt_op = txt_pxl[1:0] != 2'd0;
wire fg_op  = fg_pxl       != 2'd0  && !fg_mask;
wire obj_op = obj_pxl[3:0] != 4'd0;
wire bg_hi  = bg_pxl[8] && bg_pxl[3]==1'b1 && !bg_mask; // pen>=8: bit3 del pen
wire obj_hi = obj_pxl[7];

always @(posedge clk) begin
    if( pxl_cen ) begin
        ph    <= 3'd0;
        // seleccion de capa
        if( fg_op )
            idx <= { 7'd0, fg_pxl };                       // 0..3
        else if( txt_op )
            idx <= { 2'd0, txt_pxl[6:2], txt_pxl[1:0] };   // col*4+pen (0..95)
        else if( obj_op && ( obj_hi || !bg_hi ) )
            idx <= { 2'b01, obj_pxl[6:0] };                // 128 + pal*16 + pen
        else if( bg_mask )
            idx <= 9'd256;
        else
            idx <= { 1'b1, bg_pxl[7:0] };                  // 256 + col*16 + pen
    end else
        ph <= ph + 3'd1;
    case( ph )
        3'd0: pal_addr <= { idx, 1'b0 };
        3'd2: begin r_nx <= pal_data[3:0]; pal_addr <= { idx, 1'b1 }; end
        3'd4: begin
            // blank muestreado en la misma fase en que se emite el RGB
            // (no en fase 0, donde LHBL acaba de subir para el pixel 0 y
            // el valor quedaba un ciclo detras -> columna x=0 negra fija,
            // hallazgo H4/Task 7). Ver task-8-brief Step 0.
            red   <= ~(LHBL&LVBL) ? 4'd0 : r_nx;
            green <= ~(LHBL&LVBL) ? 4'd0 : pal_data[7:4];
            blue  <= ~(LHBL&LVBL) ? 4'd0 : pal_data[3:0];
        end
        default: ;
    endcase
end

endmodule
