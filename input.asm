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
	ret
.escape:
	cmp	word[rax+1], "[D"	;arrow keys are weird and sent odd escapes
	jz	.case_left	;this one is left
	cmp	word[rax+1], "[C"
	jz	.case_right
	cmp	word[rax+1], "[A"
	jz	.case_up
	cmp	word[rax+1], "[B"
	jz	.case_down
	ret	;return if it was smth like escape key
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
	fxch	st2
	fst	dword[camera_position+4]
	fxch	st1
	fst	dword[camera_position]
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
