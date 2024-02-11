f_clock:
	mov	rax, [frames]	;load frames address
	shl	dword[rax], 1	;shift left by 1 so can tell if frame draw was finished in timespace
	mov	rax, 1	;write again
	mov	edi, dword[pipe+4]	;pipe to 3d main fd
	mov	rsi, msg	;random msg
	mov	rdx, 1	;1 byte, this just notifies main to process the current frame
	syscall
	mov	rax, 35	;system call for sys_nanosleep
	mov	rdi, time	;time struct
	xor	rsi, rsi	;just in case as rsi is a param
	syscall
	mov	rax, 1	;write syscall
	mov	rdi, 1	;stdout
	mov	rsi, [framebuf]	;print framebuffer
	mov	edx, dword[fps_space]	;move fps addr into edx
	mov	r8, qword[fps_counter]	;move the fps counter into r8
	mov	qword[rsi+rdx], r8	;move counter into space
	mov	edx, dword[screen_size]	;screen size in bytes
	syscall	
	mov	rax, [frames]	;load frames addr again
	mov	ebx, dword[rax]	;moves that into ebx, so shifts dont affect memory
	mov	rcx, 30	;length of backlog to read
	mov	dword[fps_counter], "0"	;bcd for fps counter
	mov	dword[fps_counter+4], "0"
.loop:
	cmp	rcx, 0	;checks if rcx is 0 (finished read)
	jz	.done	;if yes, done
	test	rbx, 1	;test lsb of rbx
	jz	.end	;if its 0, dont increase fps counter (frame dropped)
	call	f_inc_bcd	;otherwise, add to bcd string
	jmp	.end	;then continue
.end:
	dec	rcx	;decrease backlog counter
	shr	rbx, 1	;shift right rbx so can check the next bit
	jmp	.loop	;loop over
.done:
	jmp	f_clock	;loop over
