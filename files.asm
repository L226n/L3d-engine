f_read_obj:
	mov	rax, 2	;open the file in question
	mov	rdi, file
	xor	rsi, rsi	;thats something look it up
	syscall
	mov	r8, rax	;save fd
	xor	rax, rax	;sys_READ
	mov	rdi, r8
	mov	rsi, filesize	;store in here bc thats what first 8 bytes is
	mov	rdx, 8	;read them
	syscall
	mov	eax, dword[filesize+4]	;move unpacked size into eax
	call	f_calc_malloc	;get address for the data to go
	mov	qword[imported_addr], r12	;r12 is revieved addr
	mov	rax, 0	;sys_read
	mov	rdi, r8	;the file
	mov	rsi, r12
	mov	edx, dword[filesize]	;read the size of the file specified (until end)
	syscall
	mov	rax, [imported_addr]	;move imported address into rax
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
	mov	qword[imported_addr+8], rax	;save face data start stuff
	add	qword[imported_addr+8], rbx
	add	qword[imported_addr+8], 2	;it just moves offset sum into here
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
	mov	byte[buf1], al	;move into a buffer
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
	mov	rax, 1	;wite again wowee no way
	mov	rdi, r8
	mov	rsi, r14	;except write image dimensions
	mov	rdx, 4	;its only 2 words so 4 bytes is fine
	syscall
	add	r9, 4	;increase data counter again
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
	fld	dword[r15+8]
	fld	dword[r15+4]
	fld	dword[r15]
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
