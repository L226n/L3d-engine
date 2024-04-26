f_rodrigues_rotation:
	movups	xmm0, [r15+4]	;move in vector to xmm0
	movaps	xmm1, xmm0	;clone into xmm1
	mulps	xmm0, xmm1	;get square of all elements
	movaps	xmm1, xmm0	;clone into xmm1 again
	haddps	xmm0, xmm0	;first val in xmm0 is now v1+v2
	shufps	xmm1, xmm1, 0b00000010	;rearange xmm1 so v3 is in v0
	addss	xmm0, xmm1	;add v0 to v0 in both (get sum of 3 vals)
	sqrtss	xmm1, xmm0	;then square root of v0
	shufps	xmm1, xmm1, 0b00000000	;broadcast this to all elements
	movups	xmm0, [r15+4]	;then reload the originalvector
	divps	xmm0, xmm1	;and divide by the sqrt thing to normalise vector
	movups	[r15+4], xmm0	;store back
	mov	dword[obj_aux_2], 12	;prepare space for skew matrix
	mov	dword[obj_aux_2+4], 0	;like inserting 0s
	mov	dword[obj_aux_2+20], 0
	mov	dword[obj_aux_2+36], 0
	mov	dword[obj_aux_2+40], 234356
	fld	dword[r15+4]	;now, load different values from normalised vector
	fst	dword[obj_aux_2+32]	;and store one in one place
	fchs	;then invert the sign bit
	fst	dword[obj_aux_2+24]	;and store that in another
	fld	dword[r15+8]	;do this for all 3 normalised vector elements
	fst	dword[obj_aux_2+12]	;it does smth dont ask
	fchs
	fst	dword[obj_aux_2+28]
	fld	dword[r15+12]
	fst	dword[obj_aux_2+16]
	fchs
	fst	dword[obj_aux_2+8]
	emms	;reset this guy
	push	r14	;push the addr of the angle to use for matrix
	lea	r15, [obj_aux_2]	;now, copy skew matrix from aux_2
	lea	r14, [obj_aux_1]	;to aux_1
	call	f_copy_matrix
	lea	r13, [matrix_ndc]	;now multiply them together into ndc
	call	f_multiply_matrix	;to get symetric skew matrix
	pxor	xmm0, xmm0	;clear xmm0
	movups	[obj_aux_2+4], xmm0	;and now populate aux_2 with 0s
	movups	[obj_aux_2+16], xmm0
	movups	[obj_aux_2+28], xmm0
	mov	dword[obj_aux_2+40], 234356	;create 3x3 identity matrix
	mov	dword[obj_aux_2+4], 0x3F800000	;insert 1s atdiagnoal p much
	mov	dword[obj_aux_2+20], 0x3F800000
	mov	dword[obj_aux_2+36], 0x3F800000
	pop	r14	;get back angle addr
	fld	dword[r14]	;load it...
	fsincos	;then get cos in st0 and sin in st1
	fstp	dword[buf1+12]	;store this cos in buf2
	fst	dword[buf1+8]	;and sin in buf1
	fld	dword[buf1+12]	;then reload cos
	fld1	;and a 1
	fsub	st1	;subtract cos val from 1
	fst	dword[buf1+12]	;and store back
	emms
	lea	r15, [buf1+8]	;load sin val
	lea	r14, [obj_aux_1]	;and skew matrix
	call	f_scalar_multiply_matrix	;multiply scalar by skew matrix
	lea	r15, [obj_aux_2]	;then add result to identity matrix
	call	f_add_matrix
	lea	r15, [buf1+12]	;now multiply cos val
	lea	r14, [matrix_ndc]	;by symetric skew matrix
	call	f_scalar_multiply_matrix
	lea	r15, [obj_aux_2]	;now add that to identity matrix to form rotation matrix
	call	f_add_matrix
	ret
f_add_matrix:
	mov	rax, 4	;skip first 16 / 12 / whatever
.loop:
	cmp	dword[r14+rax], 234356	;check if at end
	jz	.end	;if yes go here
	fld	dword[r15+rax]	;load current val of destination matrix
	fld	dword[r14+rax]	;and source matrix
	fadd	st1	;add together
	fst	dword[r15+rax]	;then store in destination (just like add rax, rbx...)
	emms	;reset stack bc its important
	add	rax, 4	;go to next val
	jmp	.loop	;loop over
.end:
	ret
f_scalar_multiply_matrix:
	mov	rax, 4
.loop:
	cmp	dword[r14+rax], 234356	;literally like
	jz	.end	;exactly the same as the above
	fld	dword[r15]	;except theres a scalar here
	fld	dword[r14+rax]
	fmul	st1
	fst	dword[r14+rax]	;and its stored in the matrix instead ofc
	emms
	add	rax, 4
	jmp	.loop
.end:
	ret
f_get_id_offset:
	xor	rcx, rcx	;u dont need an explanation for this
.loop:
	cmp	word[r15+rcx+1], ax	;cmon now
	jz	.found_offset
	add	rcx, 4
	jmp	.loop
.found_offset:
	mov	rdx, rcx
	inc	rcx
	shl	rcx, 2
	ret
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
	movups	xmm7, [r14]	;vertex position into xmm0
	movups	xmm8, [r15]	;camera position into xmm1
	subps	xmm7, xmm8	;then subtract the vertex positions from the camera
	movaps	xmm8, xmm7
	mulps	xmm7, xmm8
	movaps	xmm8, xmm7
	haddps	xmm7, xmm7
	shufps	xmm8, xmm8, 0b00000010
	addss	xmm7, xmm8
	sqrtss	xmm7, xmm7
	movss	dword[vertex_dist], xmm7
	ret
f_sample_image:
	push	rbx	;push	registers (return is rax soooo no rax)
	push	rcx
	fild	word[r13]	;load image size x
	fld	dword[interpolated_uvd]	;load uv coords x
	fabs	;get absolute value, prevents some crashes
	fmul	st1	;multiply together to get cartesian coords
	fist	dword[interpolated_uvd]	;store back in uv coords bc they are interpolated anyway
	fild	word[r13+2]	;do the same but with y positions
	fld	dword[interpolated_uvd+4]
	fabs	;same here
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
	movdqu	xmm0, [triangle+8]	;calculate vectors between different points
	movdqa	xmm1, [triangle]	;move ALIGNED DATA into xmm1
	pshufd	xmm1, xmm1, 0b01000100	;then shuffle it so its now like [0, 1, 0, 1]
	psubd	xmm0, xmm1	;this is between point B and A
	movdqa	[bc_vectors], xmm0	;save result and this bit is aligned so u can save time prehaps
	movdqa	xmm0, [point]	;move point into xmm reg
	psubd	xmm0, xmm1	;then reuse xmm1 bc its okay!
	movdqa	[bc_vectors+16], xmm0	;store here
	movdqa	xmm0, [bc_vectors]	;move vectors v0 and v1 into xmm0
	pmulld	xmm0, xmm0	;multiply them
	pshufd	xmm1, xmm0, 0b00110001	;and then move the second values in each vector calc to align with first vals
	paddd	xmm0, xmm1	;add them together
	movd	[dot_products], xmm0	;store this as dot product d00
	pshufd	xmm0, xmm0, 0b00000010	;shuffle to get other dot product
	movd	[dot_products+8], xmm0	;and store this as dot product d11
	movdqa	xmm0, [bc_vectors]	;this time v0 and v1 are still used
	movdqa	xmm1, [bc_vectors+16]	;but it also uses v2
	pshufd	xmm1, xmm1, 0b01000100	;here it duplicates v2 x and y to highest qword
	pmulld	xmm0, xmm1	;multiply!
	pshufd	xmm1, xmm0, 0b00110001	;same with the value aligning thingy
	paddd	xmm0, xmm1	;add them together
	movd	[dot_products+12], xmm0	;and store as d20
	pshufd	xmm0, xmm0, 0b00000010
	movd	[dot_products+16], xmm0	;and d21
	movdqa	xmm0, [bc_vectors]	;last time! use v0
	movdqu	xmm1, [bc_vectors+8]	;and v1
	pmulld	xmm0, xmm1	;multiply them
	pshufd	xmm1, xmm0, 0b00000001	;align values
	paddd	xmm0, xmm1	;and get sum
	movd	[dot_products+4], xmm0	;store as d01
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
	movups	xmm0, [barycentric]	;cant remember how this works now
	movups	xmm1, [simd_zeros]	;but it does so whatever
	cmpnltps	xmm1, xmm0
	movmskps	ebx, xmm0
	movups	xmm0, [barycentric]
	movaps	xmm1, [simd_ones]
	cmpnltps	xmm0, xmm1
	xor	rax, rax
	movmskps	eax, xmm1
	add	eax, ebx
	and	al, 0b00000111
	cmp	eax, 0
	jz	.end
	jmp	.outside
.outside:
	inc	r8	;increase r8 to show that outside triangle
.end:
	emms	;reset stack
	pop	rbx
	pop	rax
	ret
f_cross_product:
	movaps	xmm0, [r15]	;load A struct into xmm0
	movaps	xmm2, xmm0	;and xmm2 bah
	movaps	xmm1, [r14]	;now load B struct into xmm1
	movaps	xmm3, xmm1	;duplicate into xmm3
	shufps	xmm2, xmm2, 0b00010010	;rearange stuff
	shufps	xmm0, xmm0, 0b00001001	;not very interesting
	shufps	xmm3, xmm3, 0b00001001
	shufps	xmm1, xmm1, 0b00010010
	mulps	xmm0, xmm1	;multiply stuff together
	mulps	xmm2, xmm3
	subps	xmm0, xmm2	;and do the subtraction
	movups	[r13], xmm0	;then store it
	ret	;done! wasnt that easy :3
f_edge_vector:
	mov	rbx, 16	;multiplication value
	movzx	rax, word[r14+rcx]	;get value at index
	mul	rbx	;multiply!
	movups	xmm0, [r15+rax+4]
	movzx	rax, word[r14+rcx+2]	;use second value at index
	mul	rbx	;and do p much the same thing
	movups	xmm1, [r15+rax+4]
	subps	xmm1, xmm0
	movaps	[r13], xmm1
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
	;add	r14, 4	;why is this here
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
	cmp	rdi, 2
	jnz	.above_d
	add	eax, 48
	mov	dword[r13+r14], eax
.loop:
	add	r14, 4	;the only difference is that
	add	edx, 48	;it doesnt check if the value is 0
	mov	dword[r13+r14], edx	;because in decimals leading 0s are needed
	cmp	rdi, 0	;check if rdi is 0
	jz	.end	;if yes then finish this section
	pop	rdx	;else pop back rdx
	dec	rdi	;decrease counter
	jmp	.loop	;and loop
.above_d:
	inc	rdi	;increase push counter
	push	rdx	;do the push
	xor	rdx, rdx	;and reset rdx
	jmp	.div_d	;more loop
.end:
	cmp	dword[r13+r14], "0"	;check if trailing 0
	jnz	.check_point	;if no, done
	mov	dword[r13+r14], " "	;otherwise put in a space
	sub	r14, 4	;decrease position
	jmp	.end
.check_point:
	cmp	dword[r13+r14], "."	;check if its a .
	jnz	.end_final	;if no, then completely done
	mov	dword[r13+r14], " "	;otherwise remove it
	sub	r14, 4	;decrease in this case
.end_final:
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
	push	rax	;push rax (requested memory)
	cmp	rax, qword[mem_available]	;check if needed memory is less than available (no allocation)
	jbe	.no_allocate	;if its below or equal, then no allocation is needed
	xor	rbx, rbx	;reset page counter
.loop:
	add	rbx, 4096	;always allocate at least 1 page if memory isnt available
	sub	rax, 4096	;take away one page
	cmp	rax, 0	;compare rax with 0
	jle	.allocate	;if its lower or equal, allocate memory with current page size
	jmp	.loop	;else loop over
.no_allocate:
	mov	rbx, qword[last_memory]	;move last memory place into rbx
	mov	r12, rbx	;move that into r12 (returns place to write)
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
	mov	rbx, rax
	pop	rax	;get back requested size 
	add	rax, rbx	;add the requested size to mem addr
	mov	qword[last_memory], rax	;moves that into last memory pos
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
