mainloop:

waitras1:
	cmb.b #$ac,$dff006
	bne waitrasl
	move.w #$fff, $dff180
	
	btst #6, $bfe001
	bne mainloop
	rts
