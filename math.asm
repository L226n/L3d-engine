f_resize_bounding:	
	cmp	dword[bounding_box], 0	;this resizes the bounding box to fit screen
	jge	.skip_xl	;this part checks if the x is left off screen
	mov	dword[bounding_box], 0	;if it is, set it to 0 to skip offscreen processing
.skip_xl:
	movzx	rax, word[window_size+2]	;if x is greater than screen space
	dec	rax	;this thing
	cmp	dword[bounding_box+8], eax	;its just this for everything
	jle	.skip_xg
	mov	dword[bounding_box+8], eax
.skip_xg:
	cmp	dword[bounding_box+4], 0
	jge	.skip_yl
	mov	dword[bounding_box+4], 0
.skip_yl:
	movzx	rax, word[available_window]
	dec	rax
	cmp	dword[bounding_box+12], eax
	jle	.skip_yg
	mov	dword[bounding_box+12], eax
.skip_yg:
	ret
f_check_minmax:
	fld	dword[r15+rdi]	;this function checks values against the min and max values
	fld	dword[bounding_box]	;compare onscreen x with bounding box xmin
	fcom	st1	;compare
	fstsw	ax
	sahf
	jna	.not_lower_x	;if bounding box is lower skip
	mov	ebx, dword[r15+rdi]	;otherwise move value into bounding box
	mov	dword[bounding_box], ebx
	jmp	.not_greater_x
.not_lower_x:
	fld	dword[bounding_box+8]	;now with xmax coord
	fcom	st2	;and its the same thing
	fstsw	ax	;lots of repetition with texture mapping
	sahf
	jnb	.not_greater_x
	mov	ebx, dword[r15+rdi]
	mov	dword[bounding_box+8], ebx
.not_greater_x:
	fld	dword[r15+rdi+4]	;y values instead so exciting
	fld	dword[bounding_box+4]	;ymin again
	fcom	st1
	fstsw	ax
	sahf
	jna	.not_lower_y
	mov	ebx, dword[r15+rdi+4]
	mov	dword[bounding_box+4], ebx
	jmp	.not_greater_y
.not_lower_y:
	fld	dword[bounding_box+12]	;ymax
	fcom	st2
	fstsw	ax
	sahf
	jnb	.not_greater_y
	mov	ebx, dword[r15+rdi+4]
	mov	dword[bounding_box+12], ebx
.not_greater_y:
	emms	;done thank god it was so boring
	ret
f_get_bounding:
	push	rcx	;push rcx (reference position)
	movzx	rax, word[r14+rcx]	;standard code to get screen space coords
	mov	rbx, 16
	mul	rbx
	add	rax, 4
	mov	rbx, qword[r15+rax]	;load screen space coords into rbx
	mov	qword[bounding_box], rbx	;move that to initialise bounding box
	mov	qword[bounding_box+8], rbx	;for x and y
	sub	rcx, 2	;decrease rcx
	movzx	rax, word[r14+rcx]	;get position again
	mov	rbx, 16	;bc face indexes arent always equally spaced
	mul	rbx
	add	rax, 4
	mov	rdi, rax	;use rdi for this
	call	f_check_minmax	;and check if its min or max
	sub	rcx, 2	;same thing again
	movzx	rax, word[r14+rcx]
	mov	rbx, 16
	mul	rbx
	add	rax, 4
	mov	rdi, rax
	call	f_check_minmax
	fld	dword[bounding_box+12]	;load all coords and convert them to integers
	fist	dword[bounding_box+12]
	fld	dword[bounding_box+8]
	fist	dword[bounding_box+8]
	fld	dword[bounding_box+4]
	fist	dword[bounding_box+4]
	fld	dword[bounding_box]
	fist	dword[bounding_box]
	emms
	pop	rcx
	ret
f_euclidean_distance:
	fld	dword[r13+rax]	;load object space coords
	fld	dword[r8]	;and load point to compare with
	fsub	st1	;subtract object space coords from point
	fld	st0	;duplicate value
	fmul	st1	;and multiply by itself (squared)
	fst	dword[buf1]	;store in buffer 1
	emms	;stack cant hold all values so reset it
	fld	dword[r13+rax+4]	;load same values
	fld	dword[r8+4]	;but y coords not x
	fsub	st1
	fld	st0
	fmul	st1	;u dont have to store after this
	fld	dword[r13+rax+8]	;same thing but with z coords
	fld	dword[r8+8]
	fsub	st1
	fld	st0
	fmul	st1
	fld	dword[buf1]	;load the x value
	fadd	st1	;add them all together
	fadd	st4	;yeah
	fsqrt	;and square root it
	fst	dword[vertex_depth]	;store in vertex depth
	emms
	ret
f_sample_image:
	push	rbx	;push	registers (return is rax soooo no rax)
	push	rcx
	fild	word[r13]	;load image size x
	fld	dword[interpolated_uvd]	;load uv coords x
	fmul	st1	;multiply together to get cartesian coords
	fist	dword[interpolated_uvd]	;store back in uv coords bc they are interpolated anyway
	fild	word[r13+2]	;do the same but with y positions
	fld	dword[interpolated_uvd+4]
	fmul	st1
	fist	dword[interpolated_uvd+4]
	emms	;reset stack
	mov	eax, dword[interpolated_uvd]	;move in cartesian x
	mov	rcx, 3	;3
	mul	rcx	;multiply by 3 (pixel width ??? lol thats not making sense)
	mov	rbx, rax	;store in rbx
	mov	eax, dword[interpolated_uvd+4]	;do same but with y coords
	mov	rcx, 3	;3
	mul	rcx	;go again
	mul	word[r13]	;multiply it by image width also to move to next row
	add	rax, rbx	;add together to get offset
	add	rax, r15	;add address of image buffer
	pop	rcx	;pop back registers
	pop	rbx
	ret
f_barycentric_coords:
	push	rax
	push	rbx
	mov	eax, dword[triangle+8]	;this bit calculates vectors between different points
	sub	eax, dword[triangle]	;in this case its between point B and point A
	mov	dword[bc_vectors], eax	;store this as vector 0
	mov	eax, dword[triangle+12]	;the above was for X, now this is for Y
	sub	eax, dword[triangle+4]	;still point B and A
	mov	dword[bc_vectors+4], eax
	mov	eax, dword[triangle+16]	;this is now X position for point C and A
	sub	eax, dword[triangle]
	mov	dword[bc_vectors+8], eax
	mov	eax, dword[triangle+20]	;and Y position for point C and A
	sub	eax, dword[triangle+4]
	mov	dword[bc_vectors+12], eax
	mov	eax, dword[point]	;now its different, its between point P and A
	sub	eax, dword[triangle]	;(X position)
	mov	dword[bc_vectors+16], eax
	mov	eax, dword[point+4]	;Y position for P to A
	sub	eax, dword[triangle+4]
	mov	dword[bc_vectors+20], eax
	mov	eax, dword[bc_vectors]	;now calculate dot product of V0 and V0
	mul	eax	;multiply it by itself
	mov	dword[dot_products], eax	;and store as d00
	mov	eax, dword[bc_vectors+4]	;load Y positions instead
	mul	eax	;multiply by itself again
	add	dword[dot_products], eax	;add to other thing
	mov	eax, dword[bc_vectors]	;same thing for dot product of V0 and V1
	mov	ebx, dword[bc_vectors+8]	;except this multiplies by different (V1) values
	mul	ebx
	mov	dword[dot_products+4], eax	;store as d01
	mov	eax, dword[bc_vectors+4]	;now Y pos
	mov	ebx, dword[bc_vectors+12]
	mul	ebx
	add	dword[dot_products+4], eax
	mov	eax, dword[bc_vectors+8]	;this is now d11
	mul	eax
	mov	dword[dot_products+8], eax	;d11 position
	mov	eax, dword[bc_vectors+12]
	mul	eax
	add	dword[dot_products+8], eax
	mov	eax, dword[bc_vectors+16]	;this is now d02
	mov	ebx, dword[bc_vectors]
	mul	ebx
	mov	dword[dot_products+12], eax	;d02 position
	mov	eax, dword[bc_vectors+20]
	mov	ebx, dword[bc_vectors+4]
	mul	ebx
	add	dword[dot_products+12], eax
	mov	eax, dword[bc_vectors+16]	;and finally this is now d12
	mov	ebx, dword[bc_vectors+8]
	mul	ebx
	mov	dword[dot_products+16], eax	;d12 position
	mov	eax, dword[bc_vectors+20]
	mov	ebx, dword[bc_vectors+12]
	mul	ebx
	add	dword[dot_products+16], eax
	mov	eax, dword[dot_products]	;rax is now d00
	mov	ebx, dword[dot_products+8]	;and rbx d11
	mul	ebx	;multiply them by each other
	mov	qword[denom], rax	;and store this in denominator quad
	mov	eax, dword[dot_products+4]	;d01 is in rax
	mul	eax	;and multiplied by itself
	sub	qword[denom], rax	;subtract this from the denominator
	;denom = d00 * d11 - d01 * d01
	fild	qword[denom]	;load denominator to divide value by
	fild	dword[dot_products+8]	;load d11
	fild	dword[dot_products+12]	;and d02
	fmul	st1	;multiply them
	fild	dword[dot_products+4]	;load d01
	fild	dword[dot_products+16]	;and d12
	fmul	st1	;multiply them also
	fsubr	st2	;u = d11 * d02 - d01 * d12
	fdiv	st4	;divide by denominator
	fst	dword[barycentric+4]	;and store as v
	emms	;reset
	fild	qword[denom]	;same thing again different values
	fild	dword[dot_products]	;d00
	fild	dword[dot_products+16]	;d12
	fmul	st1
	fild	dword[dot_products+4]	;d01
	fild	dword[dot_products+12]	;d02
	fmul	st1
	fsubr	st2	;v = d00 * d12 - d01 * d02
	fdiv	st4	;divided by denom again
	fst	dword[barycentric+8]	;store as w
	fld	dword[barycentric+4]	;load v
	fld1	;and 1
	fsub	st1	;subtract both values from 1
	fsub	st2
	fst	dword[barycentric]	;and the result is u
	emms
	xor	r8, r8	;reset r8 (triangle bounds calculator)
	fldz	;load 0 and 1
	fld1
	fld	dword[barycentric]	;and u coord
	fcom	st1	;check against 1
	fstsw	ax
	sahf
	ja	.outside	;if its higher, its outside triangle
	fcom	st2	;compare with 0
	fstsw	ax
	sahf
	jb	.outside	;if its lower, its also outside
	fld	dword[barycentric+4]	;do the same for v coords
	fcom	st2
	fstsw	ax
	sahf
	ja	.outside
	fcom	st3
	fstsw	ax
	sahf
	jb	.outside
	fld	dword[barycentric+8]	;and w coords
	fcom	st3
	fstsw	ax
	sahf
	ja	.outside
	fcom	st4
	fstsw	ax
	sahf
	jb	.outside
	jmp	.end	;skip r8 setting
.outside:
	inc	r8	;increase r8 to show that outside triangle
.end:
	emms	;reset stack
	pop	rbx
	pop	rax
	ret
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
f_calc_malloc:
	push	rbx	;push all registers
	push	rcx	;lots of them
	push	rdx
	push	rdi
	push	rsi
	push	r10
	push	r9
	push	r8
	cmp	rax, qword[mem_available]	;check if needed memory is less than available (no allocation)
	jbe	.no_allocate	;if its below or equal, then no allocation is needed
	push	rax	;push rax (requested memory)
	xor	rbx, rbx	;reset page counter
.loop:
	add	rbx, 4096	;always allocate at least 1 page if memory isnt available
	sub	rax, 4096	;take away one page
	cmp	rax, 0	;compare rax with 0
	jle	.allocate	;if its lower or equal, allocate memory with current page size
	jmp	.loop	;else loop over
.no_allocate:
	mov	rbx, qword[last_memory]	;move last memory place into rbx
	mov	r12, rbx	;move that into r11 (returns place to write)
	add	qword[last_memory], rax	;add rax into last memory position (requested size)
	sub	qword[mem_available], rax	;subtract requested size from available memory
	pop	rax
	jmp	.end	;go to end
.allocate:
	mov	rax, 9	;system call for sys_mmap
	mov	rdi, 0	;automatic start
	mov	rsi, rbx	;size in pages in rbx
	mov	rdx, 3	;PROT_READ and PROT_WRITE
	mov	r10, 2 | 32	;use anonymous private mapping
	mov	r8, -1	;ignored bc its anonymous
	mov	r9, 0	;also anonymous thing
	syscall
	mov	r12, rax	;move the start into r11 for return
	movzx	rcx, word[reserved_pos]	;move reserved space index into rcx
	mov	qword[reserved_memory+rcx], rax	;move address into deallocation table
	mov	qword[reserved_memory+rcx+8], rbx	;and size
	add	word[reserved_pos], 16	;add 16 to the counter (2 qwords)
	add	rax, rbx	;add the requested size to mem addr
	mov	qword[last_memory], rax	;moves that into last memory pos
	pop	rax	;get back requested size 
	mov	qword[mem_available], rbx	;move allocated size into memory counter
	sub	qword[mem_available], rax	;then subtract size used
.end:
	pop	r8	;pop back everything
	pop	r9
	pop	r10
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	ret
f_inc_bcd:
	inc	dword[fps_counter+4]	;increases lsb of fps counter
	cmp	byte[fps_counter+4], 58	;checks if it has overflowed
	jnz	.end	;if no, do nothing
	sub	byte[fps_counter+4], 10	;otherwise, decrease lsb to 0
	inc	byte[fps_counter]	;and increase the next sb
.end:
	ret

