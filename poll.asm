f_poll:
	mov	rax, 0	;sys_read
	mov	rdi, 0	;stdin
	mov	rsi, input_buf	;put it in input buffer
	mov	rdx, 8	;read 8 bytes (qword)
	syscall
	mov	rax, [poll]	;move polling buffer into rax
	mov	rsi, qword[input_buf]	;move current input into rsi
	mov	qword[rax], rsi	;move that into shared memory
	jmp	f_poll	;loop over
	
