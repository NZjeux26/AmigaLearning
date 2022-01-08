
	SECTION TutDemo,CODE		;Will try F mem failing C mem
	JUMPPTR start

;;     ------- screen buffer ----------

w	=320
h	=256
bplsize =w*h/8				;bitplane buffer not interleaved yet

;;     ------- logo dimensions --------

logow 		=192			;based on words in mem hence need to be bigger
logoh		=67
logomar		=(320-logow)/2		;margin
logobpl 	=logow/8		;One byte = 8 pixals
logobwid	=logobpl*3		;logo bit width


start:

OSoff:
	movem.l d1-a6,-(sp)
	move.l 4.w,a6		;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr -408(a6)		;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1),d4	;org copper pointer

	jsr -414(a6)		;closelibrary()
	
	move.w #$4c-6,d7	;Start y pos
	moveq #1,d6		;y add
	move.w $dff01c,d5		
	move.w $dff002,d3

	move.w #$138,d0		;wait for end of frame
	bsr.w WaitRaster	;jumps to waitraster and then returns here
	move.w #$7fff,$dff09a	;disable all bits in INTENA
	move.w #$7fff,$dff09c	;disable all bits in INTREQ
	move.w #$7fff,$dff09c	;disable all bits in INTREQ
	move.w #$7fff,$dff096	;disable all bits in DMACON
	move.w #$87e0,$dff096

	bsr init
	
	move.l #copper,$dff080	; moves copper list	
	bsr main
	
OSon:	
	move.w #$7fff,$dff096	;clear
	or.w #$8200,d3
	move.w d3,$dff096
	move.l d4,$dff080
	or #$c000,d5		;or'd for bit 14
	move d5,$dff09a
	movem.l (sp)+,d1-a6	;pop regs from stack
	moveq #0,d0		;somethign about d0 being non-zero
	rts			;return to AmigaOS
	
*********** ROUTINES **********
main:
	movem.l d0-a6,-(sp)	;pushes regs d0-a6 onto stack
	
***************************
	
mainloop:
	move.w #$02a,d0		;wait for end of frame
	bsr.w WaitRaster	;jumps to waitraster and then returns here	

;----------frame Loop Start---------

	add.b #1,Spr+1		;adds one to Spr position making it move
	add  d6,d7		;add "1" to y position
	
	cmp #$4c+logoh+1,d7	;bottom check based on heigh of logo
	blo.b ok1
	neg d6			;change direction
ok1:
	cmp #$4c-6,d7		;top check
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
	
*****************************

	movem.l (sp)+,d0-a6	;pop stack
	rts

hwinit:
	lea Screen,a1
	move.w #bplsize-1,d0
.l:	move.b $0,(a1)+
	dbf d0,.l

	lea Logo,a0		;ptr to first bitplane
	lea CopBplP,a1		;where ot poke the bitplane pointer words
	move #3-1,d0
.bpll:				;bitplane something loop
	move.l a0,d1		;put source ptr into d0
	swap d1			
	move.w d1,2(a1)		;highword poke
	swap d1
	move.w d1,6(a1)		;low wordpoke

	addq #8,a1		;point to next bitplane to poke in copper
	lea LogoBpl(a0),a0		
	dbf d0,.bpll

	lea ScrBplP,a1		;bitplane poker pointer		
	lea Screen,a0
	move.l a0,d1
	swap d1
	move.w d1,2(a1)
	swap d1
	move.w d1,6(a1)

	lea SprP,a1		;bitplane poker pointer		
	lea Spr,a0		;load effective address of sprite to a0
	move.l a0,d1		;moves sprite address into d1
	swap d1			;swaps out high word of address
	move.w d1,2(a1)		;moves that word at offset two
	swap d1			;swaps again
	move.w d1,6(a1)		;poke the low address at offset six
	lea NullSpr,a0		;load effective address of sprite to a0
	move.l a0,d1		;moves sprite address into d1
	moveq #7-1,d0
.sprpl:				;poke loop
	addq.l #8,a1
	swap d1			;swaps out high word of address
	move.w d1,2(a1)		;moves that word at offset two
	swap d1			;swaps again
	move.w d1,6(a1)		;poke the low address at offset six
	DBF d0,.sprpl	 
init:
	movem.l d0-a6,-(sp)	;pushes reg d0-a6 to the stack

	moveq #0,d1		;clears d1 reg
	lea Screen,a1
	move.w #bplsize/2-1,d0
.l:	move.w d1,(a1)+
	addq.w #1,d1		;add one into d1
	dbf d0,.l

;; 	---  clr part of screen  ---

bltx	=48			;=(320-224)/2
blty	=30			;random
bltoffs	=30*(w/8)+bltx/8	;offset

blth	=50			;blitter height
bltw	=224/16			;blitter width
bltskip =(320-224)/8		;how many bytes in mem to skip

	move.w #$8040,$dff096	;enable blitter DMA

	tst $dff002		;for combat
.waitblit:
	btst #14-8,$dff002
	bne.s .waitblit	
	
	move.l #$01ff0000,$dff040		;blitter control word
	move.l #Screen+bltoffs,$dff054
	move.w #bltskip,$dff066			;modulo set
	move.w #blth*64+bltw,$dff058

	lea Logo,a0		;ptr to first bitplane
	lea CopBplP,a1		;where ot poke the bitplane pointer words
	move #3-1,d0
.bpll:				;bitplane something loop
	move.l a0,d1		;put source ptr into d0
	swap d1			
	move.w d1,2(a1)		;highword poke
	swap d1
	move.w d1,6(a1)		;low wordpoke

	addq #8,a1		;point to next bitplane to poke in copper
	lea LogoBpl(a0),a0		
	dbf d0,.bpll

	lea ScrBplP,a1		;bitplane poker pointer		
	lea Screen,a0
	move.l a0,d1
	swap d1
	move.w d1,2(a1)
	swap d1
	move.w d1,6(a1)

	lea SprP,a1		;bitplane poker pointer		
	lea Spr,a0		;load effective address of sprite to a0
	move.l a0,d1		;moves sprite address into d1
	swap d1			;swaps out high word of address
	move.w d1,2(a1)		;moves that word at offset two
	swap d1			;swaps again
	move.w d1,6(a1)		;poke the low address at offset six
	lea NullSpr,a0		;load effective address of sprite to a0
	move.l a0,d1		;moves sprite address into d1
	moveq #7-1,d0
.sprpl:				;poke loop
	addq.l #8,a1
	swap d1			;swaps out high word of address
	move.w d1,2(a1)		;moves that word at offset two
	swap d1			;swaps again
	move.w d1,6(a1)		;poke the low address at offset six
	DBF d0,.sprpl	 
	movem.l (sp)+,d0-a6	;pop stack
	rts
	
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

	SECTION TutData,DATA_C

Spr:	
	dc.w $ec40,$fc00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000100000000,%0000000000000000
	dc.w %0000001110000000,%0000000000000000
	dc.w %0000011011000000,%0000000000000000
	dc.w %0000101101100000,%0000000000000000
	dc.w %0001011110110000,%0000000000000000
	dc.w %0010111111011000,%0000000000000000
	dc.w %0101111111101100,%0000000000000000
	dc.w %1101111111110110,%0000000000000000
	dc.w %0110111111101100,%0000000000000000
	dc.w %0011011111001000,%0000000000000000
	dc.w %0001101110110000,%0000000000000000
	dc.w %0000110001100000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0000001110000000,%0000000000000000
	dc.w %0000000100000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000	
	dc.w 0,0

NullSpr:			;one pixal high sprite displayed outside screen
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0
		
Copper:
	dc.w $1fc,0		;slow fetch mode,for AGA combatibility MUST
	dc.w $100,$0200		;bitplane enable register
	dc.b 0,$8e,$4c,$81		
	dc.b 0,$90,$2c,$c1
	dc.w $92,$38+logomar/2	;DMA fetch start word	
	dc.w $94,$d0-logomar/2	;DMA fetch stop word

	dc.w $108,logobwid-logobpl
	dc.w $10a,logobwid-logobpl

	dc.w $102,0
	
	dc.w $1a2,$e22		;fill colour for sprites so jsut leave
	dc.w $1a4,$ff0		
	dc.w $1a6,$a32
SprP:				;Eight Sprite pointers custom chip addresses
	dc.w $120,0		;Customer Chip address and high word
	dc.w $122,0		;Cus Chip address and low word
	dc.w $124,0		;bitmap filler
	dc.w $126,0
	dc.w $128,0
	dc.w $12a,0
	dc.w $12c,0
	dc.w $12e,0
	dc.w $130,0
	dc.w $132,0
	dc.w $134,0
	dc.w $136,0
	dc.w $138,0
	dc.w $13a,0
	dc.w $13c,0
	dc.w $13e,0
	
CopBplP:
	dc.w $e0,0		;pointers to logo bitplane
	dc.w $e2,0
	dc.w $e4,0		;pointers to logo bitplane
	dc.w $e6,0
	dc.w $e8,0		;pointers to logo bitplane
	dc.w $ea,0
	
	dc.w $180,$349		;sets colour above bar to grey/blueish
	dc.w $2b07,$fffe	;vertial start and hor start pos wait command
	dc.w $180,$56c		
	dc.w $2c07,$fffe

LogoPal:
	dc.w $0180,$0667,$0182,$0ddd,$0184,$0833,$0186,$0334
	dc.w $0188,$0a88,$018a,$099a,$018c,$0556,$018e,$0633

	dc.w $100,$3200

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
	dc.w $180,$667

	dc.w $9507,$fffe
ScrBplP:
	dc.w $e0,0		;pointers to logo bitplane
	dc.w $e2,0
	dc.w $108,0
	dc.w $10a,0
	dc.w $92,$38
	dc.w $94,$d0
	dc.w $100,$1200		;should be displaying random data but isn't
	
	dc.w $ffdf,$fffe	;Bottom
	dc.w $2c07,$fffe
	dc.w $180,$56c
	dc.w $2d07,$fffe
	dc.w $180,$349

	dc.w $ffff,$fffe	;mask the last bit, end

Logo:
	INCBIN "DH0:sky.178x67x3.raw"
LogoE:
	dcb.b logobwid*6,0	;reserves 6* logo byte width as a buffer

	SECTION TutBSS,BSS_C
Screen:
	ds.b bplsize		;res screen buffer mem which is bplsize	

