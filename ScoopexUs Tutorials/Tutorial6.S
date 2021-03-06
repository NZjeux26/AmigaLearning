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
wframe:
	btst #0, $dff005
	bne wframe
	cmp.b #$2c,$dff006
	bne wframe
	move.w #$000,$dff180
	
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
		
waitras1:
	cmp.b $dff006,d7
	bne waitras1
	move.w #$fff, $dff180
	
waitras2:
	cmp.b $dff006,d7
	beq waitras2
	move.w #$000, $dff180	;sets the colour below the line set to black
	
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
	dc.w $100,$0200		;bitplane enable register
	dc.w $ffff,$fffe	;mask the last bit, end
	
