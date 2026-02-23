; Tabla de consulta precomputada para el seno.
; Ocupa 2B por entrada * 256 posibles ángulos = 512B ROM

; TODO: Posibles optimizaciones (interpolación lineal o cosas por el estilo)

; Calculado con https://www.online-python.com/
;import math
;
;for i in range(256):
;    value = round(math.sin(2* math.pi * i / 256) * 256)
;    print(f"DW {value}")

DEF ANGLE_0DEG      EQU 0
DEF ANGLE_45DEG     EQU 32
DEF ANGLE_90DEG     EQU 64
DEF ANGLE_135DEG    EQU 96
DEF ANGLE_180DEG    EQU 128
DEF ANGLE_225DEG    EQU 160
DEF ANGLE_270DEG    EQU 192
DEF ANGLE_315DEG    EQU 224

SECTION "Sin Lookup Table", ROM0

; Obtiene el seno de un ángulo
;
; IN:
; A = ángulo
; OUT:
; Entero con signo en DE [-255, 255].
;
; Destruye hl, de
sinOfAinDE::
    ld l, a
    ld h, 0
    add hl, hl ; como multiplicar x2, ya que trabajmos con 2 Bytes
    ld de, sin_lookup_table
    add hl, de ; añadimos offset -> hl con dir a sin(ángulo)
    ld e, (hl)
    inc hl
    ld d, (hl)
    ret

; Se indexa por seno_lookup[angulo] -> addr = seno_lookup + ángulo
; Cambio de escala: ángulo [0º, 360º] -> 1B [0, 255]
; Equivalencia: angle_byte = grados * 256 / 360
sin_lookup_table::
DW 0
DW 6
DW 13
DW 19
DW 25
DW 31
DW 38
DW 44
DW 50
DW 56
DW 62
DW 68
DW 74
DW 80
DW 86
DW 92
DW 98
DW 104
DW 109
DW 115
DW 121
DW 126
DW 132
DW 137
DW 142
DW 147
DW 152
DW 157
DW 162
DW 167
DW 172
DW 177
DW 181
DW 185
DW 190
DW 194
DW 198
DW 202
DW 206
DW 209
DW 213
DW 216
DW 220
DW 223
DW 226
DW 229
DW 231
DW 234
DW 237
DW 239
DW 241
DW 243
DW 245
DW 247
DW 248
DW 250
DW 251
DW 252
DW 253
DW 254
DW 255
DW 255
DW 256
DW 256
DW 256
DW 256
DW 256
DW 255
DW 255
DW 254
DW 253
DW 252
DW 251
DW 250
DW 248
DW 247
DW 245
DW 243
DW 241
DW 239
DW 237
DW 234
DW 231
DW 229
DW 226
DW 223
DW 220
DW 216
DW 213
DW 209
DW 206
DW 202
DW 198
DW 194
DW 190
DW 185
DW 181
DW 177
DW 172
DW 167
DW 162
DW 157
DW 152
DW 147
DW 142
DW 137
DW 132
DW 126
DW 121
DW 115
DW 109
DW 104
DW 98
DW 92
DW 86
DW 80
DW 74
DW 68
DW 62
DW 56
DW 50
DW 44
DW 38
DW 31
DW 25
DW 19
DW 13
DW 6
DW 0
DW -6
DW -13
DW -19
DW -25
DW -31
DW -38
DW -44
DW -50
DW -56
DW -62
DW -68
DW -74
DW -80
DW -86
DW -92
DW -98
DW -104
DW -109
DW -115
DW -121
DW -126
DW -132
DW -137
DW -142
DW -147
DW -152
DW -157
DW -162
DW -167
DW -172
DW -177
DW -181
DW -185
DW -190
DW -194
DW -198
DW -202
DW -206
DW -209
DW -213
DW -216
DW -220
DW -223
DW -226
DW -229
DW -231
DW -234
DW -237
DW -239
DW -241
DW -243
DW -245
DW -247
DW -248
DW -250
DW -251
DW -252
DW -253
DW -254
DW -255
DW -255
DW -256
DW -256
DW -256
DW -256
DW -256
DW -255
DW -255
DW -254
DW -253
DW -252
DW -251
DW -250
DW -248
DW -247
DW -245
DW -243
DW -241
DW -239
DW -237
DW -234
DW -231
DW -229
DW -226
DW -223
DW -220
DW -216
DW -213
DW -209
DW -206
DW -202
DW -198
DW -194
DW -190
DW -185
DW -181
DW -177
DW -172
DW -167
DW -162
DW -157
DW -152
DW -147
DW -142
DW -137
DW -132
DW -126
DW -121
DW -115
DW -109
DW -104
DW -98
DW -92
DW -86
DW -80
DW -74
DW -68
DW -62
DW -56
DW -50
DW -44
DW -38
DW -31
DW -25
DW -19
DW -13
DW -6