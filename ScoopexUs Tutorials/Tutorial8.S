	ORG $20000
	LOAD $20000
	JUMPPTR init
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
	move.w #$7fff,$dff09a	;disable all bits in INTENA

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
	move.l d4,$dff080
	or #$c000,d5
	move d5,$dff09a
	rts

gfxname:	
	dc.b "graphics.library",0


	EVEN
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
	
