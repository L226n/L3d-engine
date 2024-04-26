f_input_cases:
	xor	rcx, rcx	;xor register thats used for storing keys ui memory
	mov	rax, [poll]	;move addr of polling space into rax
	cmp	byte[rax], 0	;check if the first character is 0 (no input)
	jnz	.input	;if not, check input
	ret	;otherwise, do nothing
.input:
	mov	rbx, [framebuf]	;move the frame buffer space into rbx for later
	cmp	byte[rax], 27	;checks if byte of polling space is 27
	jz	.escape	;if yes, escape sequence (arrows)
	cmp	byte[paused], 0	;if paused dont process movement
	jnz	.ret
	cmp	byte[rax], "w"	;check if byte is w
	jz	case_w	;if yes, go to the w case
	cmp	byte[rax], "s"	;do this for every key there is to grab
	jz	case_s
	cmp	byte[rax], "a"
	jz	case_a
	cmp	byte[rax], "d"
	jz	case_d
	cmp	byte[rax], "q"
	jz	case_q
	cmp	byte[rax], "e"
	jz	case_e
.ret:
	ret
.escape:
	cmp	byte[paused], 0	;only check for f keys so you can actually unpause
	jnz	.check_fkeys
	cmp	word[rax+1], "[D"	;arrow keys are weird and sent odd escapes
	jz	.case_left	;this one is left
	cmp	word[rax+1], "[C"
	jz	.case_right
	cmp	word[rax+1], "[A"
	jz	.case_up
	cmp	word[rax+1], "[B"
	jz	.case_down
.check_fkeys:
	cmp	word[rax+1], "OP"	;wow like the alphabet P Q R S
	jz	.case_f1
	cmp	word[rax+1], "OQ"
	jz	.case_f2
	cmp	word[rax+1], "OR"
	jz	.case_f3
	;cmp	word[rax+1], "OS"
	;jz	.case_f4
	ret	;return if it was smth like escape key
.case_f3:
	not	byte[alert_end]	;set alert end byte
	call	f_clear_alert	;clear previous alert thing
	not	byte[culling]	;toggle culling
	cmp	byte[culling], 0	;check if culling is to be enabled
	jnz	.enable_culling	;if it is do that
	mov	dword[message], "[Cul"	;boring
	mov	dword[message+4], "ling"
	mov	dword[message+8], " dis"
	mov	dword[message+12], "able"
	mov	word[message+16], "d]"
	mov	byte[message+18], 0	;end of string
	mov	ax, word[screen_x_center]	;move in screen center
	sub	ax, 5	;decrease by 5 (half of msg length)
	mov	word[alert_x_offset], ax	;stoooooooooooooooore here
	mov	qword[alert_tick], 120	;ticks for the message to stay for
	mov	byte[alerted], 255	;set the alerted byte
	ret
.enable_culling:
	mov	dword[message], "[Cul"	;same thing but other things yyyyyyk so bored
	mov	dword[message+4], "ling"
	mov	dword[message+8], " ena"
	mov	dword[message+12], "bled"
	mov	word[message+16], " ]"
	mov	byte[message+18], 0
	mov	ax, word[screen_x_center]
	sub	ax, 5
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.case_f2:
	not	byte[alert_end]
	call	f_clear_alert
	not	byte[wireframe]
	cmp	byte[wireframe], 0
	jz	.no_wireframe
	mov	dword[message], "[Wir"
	mov	dword[message+4], "efra"
	mov	dword[message+8], "me e"
	mov	dword[message+12], "nabl"
	mov	dword[message+16], "ed ]"
	mov	byte[message+20], 0
	mov	ax, word[screen_x_center]
	sub	ax, 5
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.no_wireframe:
	mov	dword[message], "[Wir"
	mov	dword[message+4], "efra"
	mov	dword[message+8], "me d"
	mov	dword[message+12], "isab"
	mov	dword[message+16], "led]"
	mov	byte[message+20], 0
	mov	ax, word[screen_x_center]
	sub	ax, 5
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.case_f1:
	not	byte[alert_end]
	call	f_clear_alert
	not	byte[paused]
	cmp	byte[paused], 0
	jz	.unpause
	mov	dword[message], "[Pau"
	mov	dword[message+4], "sed]"
	mov	byte[message+8], 0
	mov	ax, word[screen_x_center]
	sub	ax, 2
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], -1
	mov	byte[alerted], 255
	ret
.unpause:
	mov	dword[message], "[Unp"
	mov	dword[message+4], "ause"
	mov	word[message+8], "d]"
	mov	byte[message+10], 0
	mov	ax, word[screen_x_center]
	sub	ax, 3
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.case_left:
	mov	ecx, dword[keys_space]	;move the keys space offset into ecx
	call	f_shift_keys	;shift the keys over 1 space
	mov	dword[rbx+rcx], "⮜"	;insert left char
	lea	r15, [angle]	;load rotation angle
	lea	r14, [camera_yaw]	;then load camera yaw to change yaw
	jmp	.multiply	;go
.case_right:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "⮞"
	lea	r15, [angle_neg]	;this one uses a negative angle
	lea	r14, [camera_yaw]
	jmp	.multiply
.case_up:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "⮝"
	lea	r15, [angle]
	lea	r14, [camera_pitch]	;and this uses pitch instead
	jmp	.multiply
.case_down:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "⮟"
	lea	r15, [angle_neg]
	lea	r14, [camera_pitch]
.multiply:
	fld	dword[r15]
	fld	dword[r14]
	fsub	st1
	fst	dword[r14]
	emms
	ret	;return
case_w:
	mov	ecx, dword[keys_space]	;move in key space
	call	f_shift_keys	;shift keys over
	mov	dword[rbx+rcx], "W"	;and insert a W
	mov	r14, 1	;move 1 into r14 (important for camera translation)
	lea	r15, [matrix_fwd]	;use fwd
	call	f_translate_camera	;translate camera matrix
	ret	;return
case_s:
	mov	ecx, dword[keys_space]	;same thing
	call	f_shift_keys
	mov	dword[rbx+rcx], "S"
	xor	r14, r14
	lea	r15, [matrix_fwd]
	call	f_translate_camera
	ret
case_a:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "A"
	xor	r14, r14
	lea	r15, [matrix_right]
	call	f_translate_camera
	ret
case_d:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "D"	
	mov	r14, 1
	lea	r15, [matrix_right]
	call	f_translate_camera
	ret
case_q:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "Q"
	xor	r14, r14
	lea	r15, [matrix_up]
	call	f_translate_camera
	ret
case_e:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "E"
	mov	r14, 1
	lea	r15, [matrix_up]
	call	f_translate_camera
	ret
f_shift_keys:
	mov	edx, dword[rbx+rcx+48]	;move second to last char into edx
	mov	dword[rbx+rcx+56], edx	;and moves it to last char
	mov	edx, dword[rbx+rcx+40]	;uses third to last now
	mov	dword[rbx+rcx+48], edx	;and moves it into second to last
	mov	edx, dword[rbx+rcx+32]	;u can kinda guess where this is going
	mov	dword[rbx+rcx+40], edx
	mov	edx, dword[rbx+rcx+24]
	mov	dword[rbx+rcx+32], edx
	mov	edx, dword[rbx+rcx+16]
	mov	dword[rbx+rcx+24], edx
	mov	edx, dword[rbx+rcx+8]
	mov	dword[rbx+rcx+16], edx
	mov	edx, dword[rbx+rcx]
	mov	dword[rbx+rcx+8], edx
	ret
f_translate_camera:
	fld	dword[r15+12]	;load the values in the directional matrix
	fld	dword[r15+8]	;all of them
	fld	dword[r15+4]
	fld	dword[movement_speed]	;then load the movement speed
	fmul	TO	st1	;multiply all of them by this val
	fmul	TO	st2
	fmul	TO	st3
	fld	dword[camera_position+8]	;then load camera positions
	fld	dword[camera_position+4]
	fld	dword[camera_position]
	cmp	r14, 0	;check if r14 (forwards or backwards thing) is 0
	jz	.sub	;if yes, subtract instead of add
	fadd	st4	;add all of the values to the camera position
	fxch	st1	;swapping when necasarry
	fadd	st5
	fxch	st2
	fadd	st6
	jmp	.end	;skip sub operation
.sub:
	fsub	st4	;same thing but with subtraction
	fxch	st1
	fsub	st5
	fxch	st2
	fsub	st6
.end:
	fst	dword[camera_position+8]	;store new values in camera matrix
	fabs
	fchs
	fst	dword[camera_position_cull+8]	;store negative value here (culling use)
	fxch	st2
	fst	dword[camera_position+4]
	fst	dword[camera_position_cull+4]
	fxch	st1
	fst	dword[camera_position]
	fst	dword[camera_position_cull]
	emms
	call	f_pos_string	;generate new location string
	call	f_insert_location	;move into framebuf
	ret
f_test:
	push	rax
	push	rdi
	push	rsi
	push	rdx
	push	rcx
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, msg
	mov	rdx, 4
	syscall
	pop	rcx
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret
