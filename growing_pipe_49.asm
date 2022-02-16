;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; SMW Growing Pipe (sprite 49), by imamelia
;;
;; This is a disassembly of sprite 49 in SMW, the growing pipe.
;;
;; Uses first extra bit: YES
;;
;; If the first extra bit is clear, the pipe will start out going up.  If the first extra
;; bit is set, the pipe will start out going down.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YSpeed:
db $00,$F0,$00,$10

FrameCount:
db $20,$40,$20,$40

TilesToGen1:
db $00,$14,$00,$02

TilesToGen2:
db $00,$15,$00,$02

!PipeTile1 = $A4
!PipeTile2 = $A6

!ExtraBit = $04

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc

LDA #$40
STA !1534,x

LDA !7FAB10,x		;
AND #!ExtraBit		; if the extra bit is set...
BEQ NotUpsideDown	;

INC !C2,x		; make the sprite start out in state 02
INC !C2,x		; so that it goes down instead

NotUpsideDown:		;

RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR GrowingPipeMain
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowingPipeMain:

LDA !1534,x	;
BMI Continue	; if the timer is positive...

LDA !D8,x	;
PHA		;
SEC		;
SBC !1534,x	;
STA !D8,x	; offset the sprite's Y position
LDA !14D4,x	;
PHA		;
SBC #$00		;
STA !14D4,x	;

LDY #$03		;
JSR GenerateTiles	;
PLA		;
STA !14D4,x	;
PLA		;
STA !D8,x	;

LDA !1534,x	;
SEC		;
SBC #$10		;
STA !1534,x	;

RTS

Continue:		;

JSR GrowingPipeGFX

LDA #$00
%SubOffScreen()

LDA $9D			; if sprites or locked...
ORA !15A0,x		; or the sprite is offscreen horizontally...
BNE SkipPositionUpdate	; don't update its position

%SubHorzPos()		;

LDA $0F			;
CLC			;
ADC #$50		; if the sprite is more than 5 tiles away from the player...
CMP #$A0		;
BCS SkipPositionUpdate	; don't update the sprite's position

LDA !C2,x		;
AND #$03		;
TAY			;
INC !1570,x		;
LDA !1570,x		; after a certain number of frames...
CMP FrameCount,y		;
BNE NoChangeState		;
STZ !1570,x		;
INC !C2,x		; change the sprite state
BRA SkipPositionUpdate	;

NoChangeState:		;

LDA YSpeed,y		;
STA !AA,x		; if the sprite Y speed is nonzero...
BEQ SkipTileGen		;

LDA !D8,x		;
AND #$0F		; and the sprite is centered over a tile...
BNE SkipTileGen		;

JSR GenerateTiles		; generate pipe tiles

SkipTileGen:		;

JSL $01801A|!bank		; update sprite Y position

SkipPositionUpdate:		;

LDA $94
PHA
JSL $01B44F|!bank		; make the sprite solid

LDA !7FAB10,x		;
AND #!ExtraBit		;
BEQ .no_hurt

LDA $94
SEC
SBC $01,s ; did mario position change (by 01B530)
BEQ .no_hurt

BPL ++
EOR #$FF
INC
++
CMP #$05 ; did mario position change by more than 4 px
BCC .no_hurt

PLA
STA $94
JSL $00F606|!bank				; > Kill the player.
RTS


.no_hurt
PLA

RTS			;

GenerateTiles:		;

LDA !7FAB10,x		;
AND #!ExtraBit		;
BEQ NotUpsideDown2	;

TYA			;
INC			;
INC			;
AND #$03		;
TAY			;

NotUpsideDown2:		;

LDA TilesToGen1,y		;
STA $185E|!Base2		; first tile
LDA TilesToGen2,y		;
STA $18B6|!Base2		; second tile

LDA $185E|!Base2		;
STA $9C			;
LDA !E4,x		;
STA $9A			; set the position
LDA !14E0,x		;
STA $9B			; of the tile
LDA !D8,x		;
STA $98			; that will be generated
LDA !14D4,x		;
STA $99			;

JSL $00BEB0|!bank		; generate Map16 tile routine

LDA $18B6|!Base2		;
STA $9C			;
LDA !E4,x		;
CLC			;
ADC #$10		; generate the second tile 1 tile to the right
STA $9A			;
LDA !14E0,x		;
ADC #$00		;
STA $9B			;
LDA !D8,x		;
STA $98			;
LDA !14D4,x		;
STA $99			;

JSL $00BEB0|!bank		;

RTS			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowingPipeGFX:

%GetDrawInfo()

LDA $00		;
STA $0300|!Base2,y	;
CLC		;
ADC #$10	;
STA $0304|!Base2,y	;

LDA $01		;
DEC		;
STA $0301|!Base2,y	;
STA $0305|!Base2,y	;

LDA #!PipeTile1	;
STA $0302|!Base2,y	;
LDA #!PipeTile2	;
STA $0306|!Base2,y	;

LDA !15F6,x	;
ORA $64		;
STA $0303|!Base2,y	;
STA $0307|!Base2,y	;

LDA #$01		;
LDY #$02		;
JSL $01B7B3|!bank	;
RTS
