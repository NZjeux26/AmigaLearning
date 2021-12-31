init:
	move.l 4.w,a6		;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr -408(a6)		;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1), d4	;org copper pointer

	jsr -414(a6)		;closelibrary()
	
	move #$ac,d7		;Start y pos
	move #1,d6		;y add
	move $dff01c,d5		
	move #$7fff,$dff09a	;disable all bits in INTENA

	move.l #copper,$dff080	; moves copper list 
	
***************************
mainloop:	
wframe:				;CPU busywait instruction
	btst #0, $dff005
	bne wframe
	cmp.b #$2a,$dff006	;screen start at 2c
	bne wframe
wframe2:
	cmp.b #$2a,$dff006	;screen start at 2c
	beq wframe2
	
;----------frame Loop Start---------
	
	add  d6,d7		;add "1" to y position
	
	cmp #$f0,d7		;bottom check
	blo ok1
	neg d6			;change direction
ok1:
	cmp #$40,d7
	bhi ok2
	neg d6			;chnage direction

ok2:	
	move.b d7,waitras1
	move.b d7,d0		;copy d7 inteo temp reg
	add #1,d0		;can use numer to change thickness
	move.b d0,waitras2
	
;----------frame loop end----------
	
	btst #6, $bfe001
	bne mainloop
***************************
exit:	
	move.l d4,$dff080
	or #$c000,d5
	move d5,$dff09a
	rts

gfxname:	
	dc.b "graphics.library",0


	SECTION tutorial,DATA_C	;puts below data in CHIP mem
copper:
	dc.w $1fc,0		;slow fetch mode,for AGA combatibility MUST
	dc.w $100,$0200		;bitplane enable register
	dc.w $180,$349		;sets colour above bar to grey/blueish
	dc.w $2b07,$fffe	;vertial start and hor start pos wait command
	dc.w $180,$56c		
	dc.w $2c07,$fffe
	dc.w $180,$113

waitras1:
	dc.w $8007,$fffe	
	dc.w $180,$fff
waitras2:		
	dc.w $8107,$fffe
	dc.w $180,$113

	dc.w $ffdf,$fffe	;Bottom
	dc.w $2c07,$fffe
	dc.w $180,$56c
	dc.w $2d07,$fffe
	dc.w $180,$349


	dc.w $ffff,$fffe	;mask the last bit, end
	
