f_cross_product:
	fld	dword[r15+4]	;the cross product is weird and uses an odd formula
	fld	dword[r14+8]	;but its easy to program so thats ok
	fmul	st1	;its p much just multiply 2 values an sub from each other
	fld	dword[r15+8]	;yep
	fld	dword[r14+4]
	fmul	st1
	fsubr st2
	fst	dword[r13]
	fld	dword[r15+8]
	fld	dword[r14]
	fmul	st1
	fld	dword[r15]
	fld	dword[r14+8]
	fmul	st1
	fsubr st2
	fst	dword[r13+4]
	emms
	fld	dword[r15]
	fld	dword[r14+4]
	fmul	st1
	fld	dword[r15+4]
	fld	dword[r14]
	fmul	st1
	fsubr st2
	fst	dword[r13+8]
	emms
	ret
f_edge_vector:
	mov	rbx, 16	;multiplication value
	movzx	rax, word[r14+rcx]	;get value at index
	mul	rbx	;multiply!
	fld	dword[r15+rax+4]	;get value at index again + 4
	fld	dword[r15+rax+8]	;+8
	fld	dword[r15+rax+12]	;guess
	movzx	rax, word[r14+rcx+2]	;use second value at index
	mul	rbx	;and do p much the same thing
	fld	dword[r15+rax+4]
	fld	dword[r15+rax+8]
	fld	dword[r15+rax+12]
	fsub	st3	;subtract Ax from Bx
	fxch	st1	;Ay from By
	fsub	st4	;Az from Bz
	fxch	st2
	fsub	st5
	fst	dword[r13]	;aaand then ur done
	fxch	st2	;just put the thingies in the right place
	fst	dword[r13+4]
	fxch	st1
	fst	dword[r13+8]
	emms
	ret
f_float_ascii:
	fstcw	word[cw]	;stores current control word in cw
	and	word[cw], 0xFCFF	;uses bitmasks to change
	or	word[cw], 0x0C00	;to truncating on fist/p
	fldcw	word[cw]	;load the new control word
	fld	dword[r15]	;load the value to convert to ascii
	fist	dword[buf1]	;store the truncated value in buf1
	fild	dword[buf1]	;load truncated value
	fsubp	st1	;subtract st0 from st1 and pop stack
	fld	dword[float_multiplier]	;load multiplier (100 so 2 dp)
	fmul	TO	st1	;multiplies st0 by st1 and store in st1
	fxch	st1	;swap st0 and st1
	fabs	;absolute value of the decimal
	fist	dword[buf2]	;store in buf2
	emms	;reset fpu stack
	mov	eax, dword[buf1]	;moves buf1 (int) into eax
	mov	dword[r13+r14], "+"	;moves a + byte in so its positive
	mov	ebx, dword[r15]
	test	ebx, ebx	;test if its signed or not
	jns	.not_negative	;if not signed, its not negative
	add	dword[r13+r14], 2	;adds 2 if its negative (-)
	not	eax	;invert eax
	inc	eax	;then inc to convert to positive
	mov	dword[buf1], eax	;moves that into buf1
	;add	r14, 4
.not_negative:
	xor	rdx, rdx	;reset rdx
	xor	rdi, rdi	;and rdi
	mov	rcx, 10	;divisor
.div:
	div	rcx	;divide rax by rcx
	cmp	rax, 10	;checks if larger than 10 or equal to
	jae	.above	;go to above intermediate if so
	cmp	rax, 0	;otherwise check if rax is 0
	jz	.skip	;if yes, dont display
	add	eax, 48	;add ascii value of 0 to rax otherwise
	add	r14, 4	;then add 4 to the position counter
	mov	dword[r13+r14], eax	;and move that value in
.skip:
	add	r14, 4	;increase counter again
	add	edx, 48	;add 48 to the divisor (ascii 0)
	mov	dword[r13+r14], edx	;move the ascii val into the dword
	cmp	rdi, 0	;check if interation counter is 0
	jz	.decimal	;if yes, display decimal side
	pop	rdx	;if not then pop rdx (previous value)
	dec	rdi	;dec rdi (iteration counter)
	jmp	.skip	;then loop over
.above:
	inc	rdi	;increase iteration counter
	push	rdx	;push value to display later
	xor	rdx, rdx	;reset rdx
	jmp	.div	;go divide value again
.decimal:
	mov	eax, dword[buf2]	;move buffer 2 into eax
	add	r14, 8	;add 8 to iteration counter (skips next line)
	mov	dword[r13+r14-4], "."	;moves ascii . into position
	xor	rdx, rdx	;reset rdx and rdi again
	xor	rdi, rdi
.div_d:
	div	rcx	;this is just the same code as before
	cmp	rax, 10
	jae	.above_d
	add	eax, 48
	mov	dword[r13+r14], eax
.loop:
	add	r14, 4	;the only difference is that
	add	edx, 48	;it doesnt check if the value is 0
	mov	dword[r13+r14], edx	;because in decimals leading 0s are needed
	cmp	rdi, 0
	jz	.end
	pop	rdx
	dec	rdi
	jmp	.loop
.above_d:
	inc	rdi
	push	rdx
	xor	rdx, rdx
	jmp	.div_d
.end:
	ret
f_pos_string:
	lea	r15, [camera_position]	;float to generate string for
	xor	r14, r14	;reset position counter
	lea	r13, [location_string]	;destination addr
	call	f_float_ascii	;generate string for that r15 in r13
	lea	r15, [camera_position+4]	;then it does the same thing
	mov	r14, 32	;for Y and Z positions
	call	f_float_ascii
	lea	r15, [camera_position+8]
	mov	r14, 64
	call	f_float_ascii
	ret
f_insert_location:
	mov	rsi, [framebuf]	;moves framebuf addr into rsi
	mov	edx, dword[location_space]	;moves location space offset into edx
	mov	r8, qword[location_string]	;moves the location string 1st qword into r8
	mov	qword[rsi+rdx], r8	;then move that into the first qword in location space
	mov	r8, qword[location_string+8]	;now it uses an offset for the location string and space
	mov	qword[rsi+rdx+8], r8
	mov	r8, qword[location_string+16]
	mov	qword[rsi+rdx+16], r8
	mov	r8, qword[location_string+24]
	mov	qword[rsi+rdx+24], r8
	mov	r8, qword[location_string+32]
	mov	qword[rsi+rdx+44], r8	;now this is different because there is the space between this value
	mov	r8, qword[location_string+40]	;and the last value
	mov	qword[rsi+rdx+52], r8
	mov	r8, qword[location_string+48]
	mov	qword[rsi+rdx+60], r8
	mov	r8, qword[location_string+56]
	mov	qword[rsi+rdx+68], r8
	mov	r8, qword[location_string+64]
	mov	qword[rsi+rdx+88], r8	;again same here
	mov	r8, qword[location_string+72]	;theres gap between the location spaces
	mov	qword[rsi+rdx+96], r8
	mov	r8, qword[location_string+80]
	mov	qword[rsi+rdx+104], r8
	mov	r8, qword[location_string+88]
	mov	qword[rsi+rdx+112], r8
	ret
f_inc_bcd:
	inc	dword[fps_counter+4]	;increases lsb of fps counter
	cmp	byte[fps_counter+4], 58	;checks if it has overflowed
	jnz	.end	;if no, do nothing
	sub	byte[fps_counter+4], 10	;otherwise, decrease lsb to 0
	inc	byte[fps_counter]	;and increase the next sb
.end:
	ret

