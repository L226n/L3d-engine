f_read_tex:
	push	r8
	mov	rax, 2
	mov	rdi, r15
	xor	rsi, rsi
	syscall
	mov	r8, rax
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, filesize
	mov	rdx, 4
	syscall
	mov	eax, dword[filesize]
	sub	rax, 4
	mov	rbx, 3
	mul	rbx
	add	rax, 4
	mov	rbx, rax
	call	f_calc_malloc
	mov	r9, qword[obj_addr]
	mov	r10, qword[obj_addr_counter]
	mov	qword[r9+r10], r12
	add	qword[obj_addr_counter], 8
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, r12
	mov	edx, dword[filesize]
	syscall
	mov	rcx, rdx
	mov	r15, [r9+r10]
.loop:
	dec	rcx
	cmp	rcx, 3
	jz	.end
	sub	rbx, 3
	xor	rdx, rdx
	movzx	rax, byte[r15+rcx]
	mov	rsi, 10
	idiv	rsi
	add	rdx, 48
	mov	byte[r15+rbx+2], dl
	xor	rdx, rdx
	idiv	rsi
	add	rdx, 48
	mov	byte[r15+rbx+1], dl
	xor	rdx, rdx
	idiv	rsi
	add	rdx, 48
	mov	byte[r15+rbx], dl
	jmp	.loop
.end:
	mov	rax, 3
	mov	rdi, r8
	syscall
	pop	r8
	ret
f_read_map:
	push	r8
	mov	rax, 2
	mov	rdi, r15
	xor	rsi, rsi
	syscall
	mov	r8, rax
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, filesize
	mov	rdx, 4
	syscall
	mov	eax, dword[filesize]
	call	f_calc_malloc
	mov	r9, qword[obj_addr]
	mov	r10, qword[obj_addr_counter]
	mov	qword[r9+r10], r12
	add	qword[obj_addr_counter], 8
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, r12
	mov	edx, dword[filesize]
	syscall
	mov	rax, 3
	mov	rdi, r8
	syscall
	pop	r8
	ret
f_read_obj:
	push	r8
	mov	rax, 2	;open the file in question
	mov	rdi, r15
	xor	rsi, rsi	;thats something look it up
	syscall
	mov	r8, rax	;save fd
	push	r8
	xor	rax, rax	;sys_READ
	mov	rdi, r8
	mov	rsi, filesize	;store in here bc thats what first 8 bytes is
	mov	rdx, 8	;read them
	syscall
	mov	eax, dword[filesize+4]	;move unpacked size into eax
	call	f_calc_malloc	;get address for the data to go
	mov	r9, qword[obj_addr]
	mov	r10, qword[obj_addr_counter]
	mov	qword[r9+r10], r12	;r12 is recieved addr
	mov	rax, 0	;sys_read
	mov	rdi, r8	;the file
	mov	rsi, r12
	mov	edx, dword[filesize]	;read the size of the file specified (until end)
	syscall
	mov	rax, r12	;move imported address into rax
	mov	ebx, dword[filesize+4]	;load unpacked data size into ebx
	sub	rbx, 4	;subtract 4
	mov	ecx, dword[filesize]	;load packed data size into rcx
	sub	rcx, 8	;subtract 8????? why oh bc it gets the end of the data so u can interate over it
	mov	dword[rax+rbx], 65535 << 16 | 65534	;this looks cool as shit
	sub	rbx, 8	;just written 8 bytes so move back that amount
.load_faces:
	mov	rdx, qword[rax+rcx]	;move data at read position into rdx
	mov	qword[rax+rbx], rdx	;then store it in write position
	cmp	word[rax+rcx], 65535	;check if its this (end of face data)
	jz	.end_faces	;if yes guess what
	mov	word[rax+rbx], 65534	;write end of face segment
	sub	rbx, 8	;move write data back 4
	sub	rcx, 6	;and read data back 3
	jmp	.load_faces	;load faces again
.end_faces:
	add	qword[obj_addr_counter], 8
	mov	r10, qword[obj_addr_counter]
	mov	qword[r9+r10], rax	;save face data start stuff
	add	qword[r9+r10], rbx
	add	qword[r9+r10], 2	;it just moves offset sum into here
	add	qword[obj_addr_counter], 8
	sub	rbx, 2	;go back to write some data
	mov	dword[rax+rbx], 234356	;write end of vertex data sequence
.load_vertices:
	sub	rbx, 16	;go back loads wow (one vertex full data)
	sub	rcx, 12	;read data goes back not that much
	mov	rdx, qword[rax+rcx]	;move data at position into rdx
	mov	r8, qword[rax+rcx+8]	;move other half into r8
	mov	qword[rax+rbx], rdx	;move them into right place
	mov	qword[rax+rbx+8], r8
	mov	dword[rax+rbx+12], 0x3F800000	;binary for 1.0 (w coord)
	cmp	rcx, 0	;check if rcx is 0 (at end)
	jz	.end	;if yes, go to end
	jmp	.load_vertices	;otherwise keep going!!!
.end:
	mov	dword[rax], 16	;write column size (always 16)
	pop	r8
	mov	rax, 3
	mov	rdi, r8
	syscall
	pop	r8
	ret
f_read_scene:
	mov	rax, 2
	mov	rdi, file
	xor	rsi, rsi
	syscall
	mov	r8, rax
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, obj_count
	mov	rdx, 2
	syscall
	movzx	rax, word[obj_count]
	mov	rbx, 32
	mul	rbx
	call	f_calc_malloc
	mov	qword[obj_addr], r12
.read_obj:
	xor	rax, rax	;sys_read
	mov	rdi, r8	;read from the file
	mov	rsi, filesize	;put it in here
	mov	rdx, 1	;only read 1 byte bc thats how big it is
	syscall
	xor	rax, rax	;sys_read
	mov	rdi, r8	;from the fileeee
	mov	rsi, files	;put it in the buffer
	movzx	rdx, byte[filesize]	;read this amount (total size)
	syscall
	dec	rdx	;now it points to the last byte of the file
	movzx	rbx, byte[files+rdx]	;move the last byte into rbx
	push	rbx	;and save it to the stack
	mov	byte[files+rdx], 0	;move a 0 into position
	lea	r15, [files]	;move the address of file data into r15
	call	f_read_obj	;and then read the object at this point
.get_uv_start:
	inc	r15	;increase r15
	cmp	byte[r15-1], 0	;if you are at a 0 byte, then u have reached the next segment
	jz	.read_uv	;read uv if yes
	jmp	.get_uv_start	;otherwise keep going
.read_uv:
	call	f_read_map
.get_tex_start:
	inc	r15	;same thing but it checks for texture bits
	cmp	byte[r15-1], 0
	jz	.read_tex
	jmp	.get_tex_start
.read_tex:
	call	f_read_tex
	pop	rbx	;pop back last byte of file sequence
	cmp	rbx, 1	;if it was 1, keep reading objects
	mov	byte[buf2], 60
	jz	.read_obj	;yep
.read_operation:
	xor	rax, rax	;sys_read
	mov	rdi, r8	;read from file
	mov	rsi, buf1	;put it in here
	mov	rdx, 1	;read 1 byte
	syscall
	cmp	byte[buf1], 0
	jz	.read_variable
	cmp	byte[buf1], 1	;check if first byte is 1
	jz	.read_translate	;if yes its a translation action
.end:
	mov	rax, 3
	mov	rdi, r8
	syscall
	ret
.read_variable:
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, buf1
	mov	rdx, 1
	syscall
	cmp	byte[buf1], 0
	jz	.var_sky_colour
.var_sky_colour:
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, sky_colour
	mov	rdx, 3
	syscall
	jmp	.read_operation
.read_translate:
	xor	rax, rax
	mov	rdi, r8
	mov	rsi, buf1
	mov	rdx, 14
	syscall
	mov	eax, dword[buf1+2]
	mov	dword[translation], eax
	mov	eax, dword[buf1+6]
	mov	dword[translation+4], eax
	mov	eax, dword[buf1+10]
	mov	dword[translation+8], eax
	call	f_translation_matrix
	movzx	rax, word[buf1]
	mov	rbx, 32
	mul	rbx
	mov	rbx, qword[obj_addr]
	mov	rcx, qword[rbx+rax]
	push	r13
	mov	r15, rcx
	lea	r14, [matrix_translate]
	lea	r13, [obj_aux_1]
	call	f_multiply_matrix
	lea	r15, [obj_aux_1]
	mov	r14, rcx
	call	f_copy_matrix
	pop	r13
	jmp	.read_operation
f_write_scene:
	mov	rax, 2
	mov	rdi, file
	mov	rsi, 0b1001000010	 
	mov	rdx, 0q777
	syscall
	mov	r8, rax
	mov	rax, 1
	mov	rdi, r8
	mov	rsi, r14
	mov	rdx, 2
	syscall
	xor	r9, r9
	xor	rax, rax
.get_length:
	cmp	byte[r15+rax], 1	;check if at end of data segment
	jz	.write_segment	;if yes, write segment
	cmp	byte[r15+rax], 10	;check if at end of string completely
	jz	.segment_end	;if so, then write segment but flag r9
	inc	rax	;otherwise increase rax
	jmp	.get_length	;and go to next bit in the string
.segment_end:
	mov	r9, 1	;mark r9 as being at end of string
.write_segment:
	inc	rax	;increase rax so that it is the length of data to write rather than offset
	push	rax	;push rax bc its used at some point
	mov	byte[filesize], al	;move rax into filesize
	mov	rax, 1	;sys_write
	mov	rdi, r8	;write to file
	mov	rsi, filesize	;filesize
	mov	rdx, 1	;which is just 1 byte
	syscall
	pop	rax	;pop back rax, which is now length to write
	mov	rdx, rax	;move it into length arg
	mov	rax, 1	;sys_write again
	mov	rdi, r8	;write to fileeee
	mov	rsi, r15	;and write stuff in r15
	syscall
	xor	rax, rax	;rax is now 0
	add	r15, rdx	;add offset to r15
	cmp	r9, 1	;check if r9 is 1 (end of string)
	jnz	.get_length	;if no, continue
.file_end:
	cmp	byte[r13], 255
	jz	.end
	cmp	byte[r13], 0
	jz	.write_variable
	cmp	byte[r13], 1
	jz	.write_translation
.write_variable:
	cmp	byte[r13+1], 0
	jz	.write_sky_colour
.write_sky_colour:
	mov	rax, 1
	mov	rdi, r8
	mov	rsi, r13
	mov	rdx, 5
	syscall
	add	r13, 5
	jmp	.file_end
.write_translation:
	mov	rax, 1
	mov	rdi, r8
	mov	rsi, r13
	mov	rdx, 15
	syscall
	add	r13, 15
	jmp	.file_end
.end:
	mov	rax, 1
	mov	rdi, r8
	mov	rsi, r13
	mov	rdx, 1
	syscall
	mov	rax, 3
	mov	rdi, r8
	syscall
	ret
f_write_tex:
	mov	rax, 2	;system call for open!!
	mov	rdi, file	;file path
	mov	rsi, 0b1001000010	;and some args jsvnkvdsndslfc
	mov	rdx, 0q777	;permissions like chmod 777 wow
	syscall
	mov	r8, rax	;SAVE fd
	mov	rax, 1	;and write irrelevant data to start
	mov	rdi, r8
	mov	rsi, filesize
	mov	rdx, 4	;what matters is that its 4 bytes
	syscall
	mov	r9, 4	;u write image dimensions first
	mov	rax, 1	;wite again wowee no way
	mov	rdi, r8
	mov	rsi, r14	;except write image dimensions
	mov	rdx, 4	;its only 2 words so 4 bytes is fine
	syscall
.write_loop:
	movzx	rcx, byte[r15+rbx+2]	;lsBYTE not bit in rcx
	sub	rcx, 48	;subtract 48 (convert to integer)
	movzx	rdx, byte[r15+rbx+1]	;now second least significant byte
	sub	rdx, 48	;convert to integer
	mov	rax, 10	;and multiply by 10
	mul	rdx
	add	rcx, rax	;and add to counter
	movzx	rdx, byte[r15+rbx]	;do the same with msBYTE
	sub	rdx, 48
	mov	rax, 100	;except 100 this time
	mul	rdx
	add	rcx, rax	;and add still (this converts an ascii 3 digit to integer)
	mov	byte[buf1], cl	;move into a buffer
	mov	rax, 1	;write again
	mov	rdi, r8
	mov	rsi, buf1	;write result of mathy thing
	mov	rdx, 1	;1 byte bc its not gonna be > 255
	syscall
	inc	r9	;increase r9 data counter
	cmp	byte[r15+rbx+3], 0	;check if at end of string
	jz	.finish	;if yes, go to end
	add	rbx, 3	;else add 3 to go to next string
	jmp	.write_loop	;loop also
.finish:
	mov	rax, 8	;lseek to beginning yk the drill
	mov	rdi, r8
	xor	rsi, rsi
	xor	rdx, rdx
	syscall
	mov	dword[filesize], r9d	;move data written into filesize
	mov	rax, 1	;then write that data in gap from beginning
	mov	rdi, r8
	mov	rsi, filesize
	mov	rdx, 4	;cmon yk by now
	syscall
	mov	rax, 3	;close the file
	mov	rdi, r8
	syscall
	ret
f_write_map:
	mov	rax, 2	;sys_open
	mov	rdi, file	;file path string
	mov	rsi, 0b1001000010	;flags for O_CREAT | O_TRUNC | O_RDWR
	mov	rdx, 0q777	;mode is 777 (everyone can read write and excecute)
	syscall
	mov	r8, rax	;store fd in r8
	mov	rax, 1	;sys_write
	mov	rdi, r8	;write to file
	mov	rsi, filesize	;reserve space, junk data
	mov	rdx, 4	;dword max file size
	syscall
	xor	rbx, rbx	;reset rbx (position counter)
.loop:
	mov	rax, 1	;write to file again!
	mov	rdi, r8
	mov	rsi, r15	;address of data start
	add	rsi, rbx	;then offset from rbx
	mov	rdx, 8	;length to write is qword (writing both uv coords)
	syscall
	add	rbx, 8	;increase position counter (doubles as data counter)
	cmp	dword[r15+rbx], 234356	;check if at end of uv mapping
	jz	.finished	;if yes, finished
	jmp	.loop	;otherwise continue
.finished:
	mov	rax, 8	;sys_lseek
	mov	rdi, r8	;fd for open file
	xor	rsi, rsi	;and offset 0
	xor	rdx, rdx	;from start of file
	syscall
	mov	dword[filesize], ebx	;move data written into filesize dword
	mov	rax, 1	;write
	mov	rdi, r8	;to
	mov	rsi, filesize	;the
	mov	rdx, 4	;file
	syscall
	mov	rax, 3	;sys_close
	mov	rdi, r8	;close this file
	syscall
	ret
f_write_obj:
	xor	rbx, rbx
	mov	r9, 10
	add	r15, 4	;add 4 to coordinate address (skip column value)
	mov	rax, 2	;sys_open
	mov	rdi, file	;file path string
	mov	rsi, 0b1001000010	;flags for O_CREAT | O_TRUNC | O_RDWR
	mov	rdx, 0q777	;mode is 777 (everyone can read write and excecute)
	syscall
	mov	r8, rax	;save fd to r8
	mov	rax, 1	;sys_write
	mov	rdi, r8	;fd of newly opened file
	mov	rsi, filesize	;filesize is at this point arbitrary, it just reserves space
	mov	rdx, 8	;8 bytes reserve (for unpacked size also)
	syscall
.write_coords:
	mov	rax, 1	;sys_write again (lots of this)
	mov	rdi, r8	;yep
	mov	rsi, r15	;address of vertex data
	mov	rdx, 12	;3 dwords (X Y Z coordinates)
	syscall
	add	rbx, 12	;increase rbx (byte counter) by 12
	add	r9, 16
	cmp	dword[r15+16], 234356 ;checks if at end of vertex data
	jz	.end_coords	;if yes, finish writing vertices
	add	r15, 16	;add 16 (next X Y Z coordinates) to address
	jmp	.write_coords	;write next set
.end_coords:
	mov	rax, 1	;yes yk its this again
	mov	rdi, r8
	mov	rsi, file_separator	;but it writes the file separator (255)
	mov	rdx, 2	;single byte
	syscall
	add	rbx, 2	;increase byte counter again
.write_faces:
	mov	rax, 1	;yes
	mov	rdi, r8
	mov	rsi, r14	;it uses face data now instead
	mov	rdx, 6	;3 words, always using triangles
	syscall
	add	rbx, 6	;increase byte counter by amount written
	add	r9, 8
	cmp	word[r14+8], 65535	;check if at end of face data
	jz	.end	;if yes, go to end
	add	r14, 8	;otherwise, go to next face indexes
	jmp	.write_faces	;and write again
.end:
	mov	dword[filesize], ebx	;move byte counter into filesize buffer
	mov	dword[filesize+4], r9d
	mov	rax, 8	;system call for sys_lseek
	mov	rdi, r8	;reset position for open file
	xor	rsi, rsi	;offset 0
	xor	rdx, rdx	;offset 0 from SEEK_SET (start)
	syscall
	mov	rax, 1	;write
	mov	rdi, r8	;to file
	mov	rsi, filesize	;the size of the data in bytes
	mov	rdx, 8	;8 bytes is the whole thing + unpacked
	syscall
	mov	rax, 3	;sys_close
	mov	rdi, r8	;close open file
	syscall
	ret
