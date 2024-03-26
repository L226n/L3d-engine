f_alert:
	xor	rcx, rcx	;used for msg offset
	movzx	rax, word[alert_y_offset]	;y pos
	movzx	rbx, word[alert_x_offset]	;x pos also
	cmp	qword[alert_tick], 0	;check if ticker is 0
	jnz	.loop	;if its not procede as normal
	not	byte[alert_end]	;otherwise set end byte
	not	byte[alerted]	;and clear alerted byte
.loop:
	mov	r8w, word[message+rcx]	;move current 2 letters into r8
	call	f_draw_ui	;draw this
	add	rcx, 2	;increase letter counter
	inc	rbx	;and x pos counter
	cmp	byte[message+rcx], 0	;check if at end
	jnz	.loop	;if no, loop over
.end:
	dec	qword[alert_tick]	;decrease the ticks to show for
	ret
f_clear_alert:
	xor	rcx, rcx	;used for msg offset
	movzx	rax, word[alert_y_offset]	;y pos
	movzx	rbx, word[alert_x_offset]	;and x pos
.loop:
	mov	r8w, word[message_clear]	;move double space "  " into r8 to be drawn
	call	f_draw_ui	;same as above
	add	rcx, 2	;increase this so you know where the end of the string is
	inc	rbx	;increase rbx (x position, draw next space)
	cmp	byte[message+rcx], 0	;check if at end
	jnz	.loop	;if no loop over
.end:
	not	byte[alert_end]	;clear end byte to show that alert is gone
	ret

