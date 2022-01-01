	ORG $20000
	LOAD $20000
	JUMPPTR init

w	=320
h	=256
bplsize =w*h/8

screen  =$60000

init:

	move.l 4.w,a6		;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr -408(a6)		;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1), d4	;org copper pointer

	jsr -414(a6)		;closelibrary()
	
	move.w #$ac,d7		;Start y pos
	moveq #1,d6		;y add
	move.w $dff01c,d5		
	move.w $dff002,d3

	move.w #$138,d0		;wait for end of frame
	bsr.w WaitRaster
	move.w #$7fff,$dff09a	;disable all bits in INTENA
	move.w #$7fff,$dff09c	;disable all bits in INTREQ
	move.w #$7fff,$dff09c	;disable all bits in INTREQ
	move.w #$7fff,$dff096	;disable all bits in DMACON
	move.w #$87e0,$dff096

hwinit:
	lea Screen,a1
	move.w #bplsize-1,d0
.l:	move.b $dff007,(a1)+
	dbf d0,.l
		 
	move.l #copper,$dff080	; moves copper list
	
***************************
mainloop:	
wframe:				;CPU busywait instruction
	btst #0, $dff005
	bne.b wframe
	cmp.b #$2a,$dff006	;screen start at 2c
	bne.b wframe
wframe2:
	cmp.b #$2a,$dff006	;screen start at 2c
	beq.b wframe2
	
;----------frame Loop Start---------

	add.b #1,Spr+1		;adds one to Spr position making it move
	add  d6,d7		;add "1" to y position
	
	cmp #$f0,d7		;bottom check
	blo.b ok1
	neg d6			;change direction
ok1:
	cmp #$40,d7
	bhi.b ok2
	neg d6			;chnage direction

ok2:	
	move.l #waitras1,a0
	move.b d7,d0		;copy d7 into temp reg
	moveq #6-1,d1
.l:
	move.b d0,(a0)
	add.w #1,d0
	add.w #8,a0
	DBF d1,.l		;decrease while false
		
;----------frame loop end----------
	
	btst #6, $bfe001
	bne.b mainloop
***************************
exit:	
	move.w #$7fff,$dff096	;clear
	
	or.w #$8200,d3
	move.w d3,$dff096
	move.l d4,$dff080
	or #$c000,d5		;or'd for bit 14
	move d5,$dff09a
	rts
	
*********** ROUTINES **********

WaitRaster:		;wait for rasterline d0.w modifies d0-d2/a0
	move.l #$1ff00,d2
	lsl.l #8,d0
	and.l d2,d0
	lea $dff004,a0
.wr:	move.l (a0),d1
	and.l	d2,d1
	cmp.l	d1,d0
	bne.s	.wr
	rts
	
** ********* DATA **************

gfxname:	
	dc.b "graphics.library",0

	EVEN

Spr:	
	dc.w $2c40,$3c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000100000000,%0000000000000000
	dc.w %0000001110000000,%0000000000000000
	dc.w %0000011011000000,%0000000000000000
	dc.w %0000101101100000,%0000000000000000
	dc.w %0001011110110000,%0000000000000000
	dc.w %0010111111011000,%0000000000000000
	dc.w %0101111111101100,%0000000000000000
	dc.w %1101111111110110,%0000000000000000
	dc.w %0110111111110100,%0000000000000000
	dc.w %0011011111001000,%0000000000000000
	dc.w %0001101110110000,%0000000000000000
	dc.w %0000110001100000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0000001110000000,%0000000000000000
	dc.w %0000000100000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000	
	dc.w 0,0

NullSpr:		;one pixal high sprite displayed outside screen
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0
		
Copper:
	dc.w $1fc,0		;slow fetch mode,for AGA combatibility MUST
	dc.w $100,$0200		;bitplane enable register
	dc.w $8e,$2c81		
	dc.w $90,$2cc1
	dc.w $92,$38		;start word	
	dc.w $94,$d0		;stop word
	dc.w $108,0
	dc.w $10a,0
	dc.w $102,0

	dc.w $1a2,$f00		;fill colour
	dc.w $1a4,$0f0		
	dc.w $1a6,$00f
SprP:
	dc.w $120,(Spr>>16)&$ffff
	dc.w $122,(Spr)&$ffff
	
	dc.w $124,(NullSpr>>16)&$ffff
	dc.w $126,(NullSpr)&$ffff
	dc.w $128,(NullSpr>>16)&$ffff
	dc.w $12a,(NullSpr)&$ffff
	dc.w $12c,(NullSpr>>16)&$ffff
	dc.w $12e,(NullSpr)&$ffff
	dc.w $130,(NullSpr>>16)&$ffff
	dc.w $132,(NullSpr)&$ffff
	dc.w $134,(NullSpr>>16)&$ffff
	dc.w $136,(NullSpr)&$ffff
	dc.w $138,(NullSpr>>16)&$ffff
	dc.w $13a,(NullSpr)&$ffff
	dc.w $13c,(NullSpr>>16)&$ffff
	dc.w $13e,(NullSpr)&$ffff
	
CopBplP:
	dc.w $e0,(Screen>>16)&$ffff
	dc.w $e2,(Screen)&$ffff
	
	dc.w $180,$349		;sets colour above bar to grey/blueish
	dc.w $2b07,$fffe	;vertial start and hor start pos wait command
	dc.w $180,$56c		
	dc.w $2c07,$fffe
	dc.w $180,$113
	dc.w $100,$1200

waitras1:
	dc.w $8007,$fffe	
	dc.w $180,$055
waitras2:		
	dc.w $8107,$fffe
	dc.w $180,$0aa
waitras3:		
	dc.w $8207,$fffe
	dc.w $180,$0ff
waitras4:		
	dc.w $8307,$fffe
	dc.w $180,$0aa
waitras5:		
	dc.w $8407,$fffe
	dc.w $180,$055
waitras6:		
	dc.w $8507,$fffe
	dc.w $180,$113

	dc.w $ffdf,$fffe	;Bottom
	dc.w $2c07,$fffe
	dc.w $180,$56c
	dc.w $2d07,$fffe
	dc.w $180,$349


	dc.w $ffff,$fffe	;mask the last bit, end
