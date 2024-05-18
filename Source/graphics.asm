%macro	interpolate_uvd	1
	fld	dword[barycentric]	;load barycentric u coord
	fld	dword[vertex_attr+%1]	;load v0 u coord
	fmul	st1	;multiply
	fld	dword[barycentric+4]	;load barycentric v coord
	fld	dword[vertex_attr+16+%1]	;and v1 u coord
	fmul	st1	;guess what comes next
	fld	dword[barycentric+8]	;its just this but over again
	fld	dword[vertex_attr+32+%1]
	fmul	st1
	fadd	st2	;takes the sum of all of these
	fadd	st4
	fst	dword[interpolated_uvd+%1]	;then this is interpolated value
	emms	;its just a dot product btw
%endmacro
%macro	calc_attr	1
	xor	rdx, rdx	;for mul operation
	movzx	rax, word[r14+rcx]	;move face index into rax
	mov	rbx, 16	;and 16 (length of vertex) into rbx
	mul	rbx	;get start of vertex info for r14+rcx
	add	rax, 4	;add 4 because of the 16 offset
	fld	dword[r15+rax]	;load screenspace coord x
	fist	dword[triangle+%1*8]	;store as int in tri struct
	fld	dword[r15+rax+4]	;do same with y pos
	fist	dword[triangle+%1*8+4]
	fld	dword[matrix_ndc+rax+8]	;load depth
	fst	dword[vertex_attr+%1*16+12]	;and store here
	fld1	;and load 1
	fdiv	st1	;recpirocal of vertex_depth
	fst	dword[vertex_attr+%1*16+8]	;store in third position
	sub	rax, 4	;remove 16 offset
	shr	rax, 1	;and half to get uv position
	fld	dword[r12+rax]	;load u coord
	fdiv	st2	;divide by depth
	fst	dword[vertex_attr+%1*16]	;store in position 1
	fld	dword[r12+rax+4]	;do the same with v coord
	fdiv	st3
	fst	dword[vertex_attr+%1*16+4]
	emms
%endmacro
%macro	get_rgb	2
	imul	rbx, 100	;multiplies ascii chr by 100 
	mov	byte[%1], bl	;now move here
	movzx	rbx, byte[%2+1]	;multiply second ascii chr by 10
	sub	bl, 48	;subtract ascii 0
	imul	rbx, 10
	add	byte[%1], bl	;and add it here
	movzx	rbx, byte[%2+2]
	sub	bl, 48	;this last chr doesnt require conversion
	add	byte[%1], bl	;now u have an int
	movzx	rax, byte[%1]	;get number 
	sub	rax, 16	;subtract black colour
	xor	rdx, rdx
	mov	rbx, 36	;now divide by this to get red val
	idiv	rbx
	mov	dword[%1], eax	;store r component
	mov	rax, rdx	;now divide result
	xor	rdx, rdx
	mov	rbx, 6	;by 6 to get green and blue!
	idiv	rbx	;do that
	mov	dword[%1+4], eax	;store g component
	mov	dword[%1+8], edx	;and b
%endmacro
%macro	cmp_ansi_new	1
	mov	rsi, r11	;mostly similar to below macro
	cmp	si, bx	;but it uses bx, (new texel word)
	jnz	%%not_eq
	mov	rsi, r12
	xchg	ch, cl
	cmp	sil, cl	;then do comparison with sil and cl
	xchg	ch, cl
	jz	%1	;if comparison was true go here
%%not_eq:
%endmacro
%macro	cmp_ansi_old	1	;macro for comparing old ansi vals to current texel
	mov	rsi, r11	;move r11 (get texel word) into rsi for comparison
	cmp	si, ax	;compare with ax (old texel word)
	jnz	%%not_eq	;if its not equal then not equal
	mov	rsi, r12	;now use get texel byte in rsi
	cmp	sil, cl	;and compare with old texel byte
	jz	%1	;if its equal go to specified addr
%%not_eq:
%endmacro
%macro	fill_rows	2
	mov	r10, r13	;save x val here
%%loop_tr:
	cmp	r10w, word[buf1+2]	;and check if at rightmost texel
	jz	%%end_tr	;if yes finish checking for new rows
	lea	rdx, [r14%1]	;otherwise load y value +1/-1 into rdx
	cmp	dx, %2	;and check if y val is at screen edge
	jz	%%skip_tr	;if yes skip new row
	mov	rdi, rdx	;now get the current texel
	mov	rsi, r10
	call	f_get_texel
	cmp_ansi_old	%%skip_x	;if its the same as the old val then fill
	jmp	%%skip_tr	;otherwise skip again
%%skip_x:
	push	r14	;for this, push all the registers that change
	push	r13
	push	rdx
	push	r10
	push	qword[buf1]	;and also right/leftmost texels
	mov	r14, rdx	;move value to start row at to coords
	mov	r13, r10
	call	f_span_fill	;and recursive span fill
	pop	qword[buf1]	;then pop back all this stuff when its done
	pop	r10
	pop	rdx
	pop	r13
	pop	r14
%%skip_tr:
	inc	r10	;and increase r10 bc this goes right
	jmp	%%loop_tr	;and go again loop over
%%end_tr:
	lea	r10, [r13-1]	;now load x-1 into r10
%%loop_tl:
	cmp	r10w, word[buf1]	;check if r10 is at leftmost
	jz	%%end_tl	;if yes then done
	lea	rdx, [r14%1]	;load y+1/-1
	cmp	dx, %2	;check if at edge again
	jz	%%skip_tl	;if yes then skip checking the left
	mov	rdi, rdx	;now get coords again
	mov	rsi, r10
	call	f_get_texel
	cmp_ansi_old	%%skip_y	;and if its the old colour then fill
	jmp	%%skip_tl	;otherwise done
%%skip_y:
	push	r14	;push everything again
	push	r13
	push	rdx
	push	r10
	push	qword[buf1]
	mov	r14, rdx	;and move cooords
	mov	r13, r10
	call	f_span_fill	;then call this
	pop	qword[buf1]
	pop	r10	;and pop everything back
	pop	rdx
	pop	r13
	pop	r14
%%skip_tl:
	dec	r10	;go left now
	jmp	%%loop_tl	;and still loop over
%%end_tl:
%endmacro
f_get_translation_index:
	mov	rdx, qword[mainloop]	;this code is just f_process_translations
	mov	rax, qword[translation_index]	;p much
	movzx	rbx, byte[obj_counter]
.loop:
	cmp	word[rdx+rax], bx	;the difference is,
	jnz	.end	;is that it just corrects the offset in translation_index
	cmp	byte[rdx+rax+2], 0	;its used when reordering draw order
	jz	.transform	;bc the engine doesnt like that too much @~@
.transform:
	cmp	byte[rdx+rax+3], 0
	jz	.set_position
	cmp	byte[rdx+rax+3], 1
	jz	.rotate
	cmp	byte[rdx+rax+3], 2
	jz	.translate_func
.set_position:
	add	rax, 16	;as u can see it does nothing here
	jmp	.loop	;and it just adds the offset for different things
.rotate:
	add	rax, 13	;more verbose descriptions below,,,,
	jmp	.loop
.translate_func:
	add	rax, 25
	jmp	.loop
.end:
	mov	qword[translation_index], rax
	ret
f_process_translations:
	mov	byte[aux_counter], 0	;reset auxiliary counter
	mov	rdx, qword[mainloop]	;move mainloop addr into rdx
	mov	rax, qword[translation_index]	;move translation index into rax
	movzx	rbx, byte[obj_counter]	;and obj counter
.sock:
	nop
.loop:
	cmp	word[rdx+rax], bx	;if obj counter is not equal to translation counter end
	jnz	.end
	cmp	byte[rdx+rax+2], 0	;if its 0 then condition is always, jump regardless
	jz	.transform
.transform:
	mov	r13, obj_aux_0	;store addr here
	cmp	byte[aux_counter], 0	;if aux counter is 0 then
	jz	.skip	;DONT set this
	mov	r13, obj_aux_1	;use this if its not 0
.skip:
	not	byte[aux_counter]	;byte complement this guy
	cmp	byte[rdx+rax+3], 0	;check this guy (so many guys not much gender diversity)
	jz	.set_position	;if its 0 then set position
	cmp	byte[rdx+rax+3], 1	;if its 1
	jz	.rotate	;then itsrotation
	cmp	byte[rdx+rax+3], 2
	jz	.translate_func
.set_position:
	movups	xmm0, [rdx+rax+4]	;move coords into here
	movaps	[translation], xmm0	;and store here
	push	rax	;push rax
	call	f_translation_matrix	;make a translation matrix
	pop	rax	;pop rax
	mov	r15, qword[imported_addr]	;thennnn vertex data
	lea	r14, [matrix_translate]	;mul by translation
	call	f_multiply_matrix	;multiply!!!!!!
	mov	qword[imported_addr], r13	;store result
	add	rax, 16	;add data length
	jmp	.loop	;and keep checking
.rotate:
	fld	dword[rdx+rax+5]	;load increment val for rotation
	fild	qword[frame_delta]
	fild	qword[usec]
	fdivr	st1
	fmul	st2
	fld	dword[rdx+rax+9]	;and current val
	fadd	st1	;add the increment to current
	fst	dword[rdx+rax+9]	;and store here
	emms
	lea	r15, [rdx+rax+9]	;load this addr into r15
	cmp	byte[rdx+rax+4], 0	;check the axis (0 is x, y=1 and z=2)
	jz	.rotate_x
	cmp	byte[rdx+rax+4], 1
	jz	.rotate_y
.rotate_z:
	call	f_rotate_matrix_z	;rotate around z using r15 as angle
	mov	r15, qword[imported_addr]	;then do the normal
	lea	r14, [matrix_rotation_z]
	call	f_multiply_matrix
	mov	qword[imported_addr], r13	;and store
	jmp	.rotate_step_end	;goto end
.rotate_y:
	call	f_rotate_matrix_y	;same but with y rotation
	mov	r15, qword[imported_addr]
	lea	r14, [matrix_rotation_y]
	call	f_multiply_matrix
	mov	qword[imported_addr], r13
	jmp	.rotate_step_end
.rotate_x:
	call	f_rotate_matrix_x	;and x rotation
	mov	r15, qword[imported_addr]
	lea	r14, [matrix_rotation_x]
	call	f_multiply_matrix
	mov	qword[imported_addr], r13
.rotate_step_end:
	add	rax, 13	;add offset
	jmp	.loop	;loop over!
.translate_func:
	fld	dword[rdx+rax+17]	;load increment
	fild	qword[frame_delta]
	fild	qword[usec]
	fdivr	st1
	fmul	st2
	fld	dword[rdx+rax+21]	;and current val
	fadd	st1	;add so it increases
	fst	dword[rdx+rax+21]	;and store back!
	cmp	byte[rdx+rax+4], 0	;check operation values to use
	jz	.translate_sin	;and go to appropriate case
	cmp	byte[rdx+rax+4], 1
	jz	.translate_cos
.return:
	fst	dword[buf1]	;store computed value in buf1
	emms	;reset stack
	movaps	xmm0, [buf1]	;load computed val into xmm0
	shufps	xmm0, xmm0, 0b00000000	;then shuffle so every value is dword[buf1]
	movups	xmm1, [rdx+rax+5]	;move the translation into xmm1
	mulps	xmm0, xmm1	;and multiply them together
	movaps	[translation], xmm0	;move this into translation thingy
	push	rax	;push rax
	call	f_translation_matrix	;make a translation matrix
	pop	rax	;pop rax
	mov	r15, qword[imported_addr]	;thennnn vertex data
	lea	r14, [matrix_translate]	;mul by translation
	call	f_multiply_matrix	;multiply!!!!!!
	mov	qword[imported_addr], r13	;store result
	add	rax, 25	;add data length
	jmp	.loop	;and keep checking
.translate_sin:
	fsin	;if only switch cases existed in nasm
	jmp	.return
.translate_cos:
	fcos
	jmp	.return
.end:
	mov	qword[translation_index], rax ;and store index of translation
	ret
f_map_texture:
	push	r13
	push	r12
	push	rcx	;push rcx bc its important to stay the same
	sub	rcx, 2	;decrease so it points to value before delimiter
	call	f_get_bounding	;get the bounding box of coords
	cmp	qword[bounding_box+16], 0	;check if xmax is 0 (completely offscreen)
	jl	.end	;if yes, dont process this
	cmp	qword[bounding_box+24], 0	;same but with ymax
	jl	.end
	mov	rax, qword[bounding_box]	;now you load in rax
	inc	rax	;and increase it fsr cant remember why
	movzx	rbx, word[window_size+2]
	cmp	rax, rbx	;then check if xmin is larger than screen width
	jge	.end	;then its still not visible
	mov	rax, qword[bounding_box+8]	;same but with ymin
	inc	rax
	movzx	rbx, word[available_window]
	cmp	rax, rbx	;this is 3 less than window height
	jge	.end
	call	f_resize_bounding	;resize bounding box to match window
	calc_attr	2	;calculate attributes for vertex 2
	sub	rcx, 2	;decrease pointer to vertex indexes
	calc_attr	1	;attributes for v1
	sub	rcx, 2
	calc_attr	0	;and v0
	shr	rcx, 3
	imul	rcx, 24
	%assign	COUNTER	0
	%rep	3
		fld	dword[vertex_attr+COUNTER+12]
		fld	dword[r12+rcx]
		fdiv	st1
		fst	dword[vertex_attr+COUNTER]
		fld	dword[r12+rcx+4]
		fdiv	st2
		fst	dword[vertex_attr+COUNTER+4]
		emms
		add	rcx, 8
		%assign	COUNTER	COUNTER+16
	%endrep
	xor	rax, rax	;clear upper bytes of rax and rbx
	xor	rbx, rbx
	mov	rbx, qword[bounding_box+16]	;get bounding box
	mov	rax, qword[bounding_box+24]
	imul	rbx, 13	;multiply max width by 13
	imul	rax, qword[main_width]	;and max height by width to get the thing yk
	mov	qword[bounding_box+16], rbx	;annd save these vals
	mov	qword[bounding_box+24], rax
	mov	rbx, qword[bounding_box]	;move in start pos
	mov	rax, qword[bounding_box+8]	;(xmin, ymin)
	mov	qword[buf3], rbx	;save start pos here cuz its important
	mov	r11, rax	;start positions as relative vals
	mov	r12, rbx
	imul	rbx, 13	;but now change bounding box vals to raw vals
	imul	rax, qword[main_width]
	mov	qword[bounding_box], rbx	;and store them back
	mov	r10, qword[framebuf]	;framebuf here,
	mov	r13, [imported_addr+24]	;use dimensions of image here
.loop:
	mov	dword[point], r12d	;set the point coords to rbx and rax
	mov	dword[point+4], r11d
	call	f_barycentric_coords	;calc barycentric coords for this point
	cmp	r8, 1	;check if outside of triangle
	jz	.no_draw	;if yes, dont draw this point
	interpolate_uvd	0	;interpolate u
	interpolate_uvd	4	;interpolate v
	interpolate_uvd	8	;interpolate d
	interpolate_uvd	12	;interpolate dist
	mov	r8d, dword[interpolated_uvd+12]
	mov	dword[point_depth], r8d
	fld	dword[interpolated_uvd+8]	;load depth reciprocal
	fld1	;load 1
	fdiv	st1	;reciprocal of reciprocal is non reciprocal interpolated depth
	fld	dword[interpolated_uvd+4]	;load v coord
	fmul	st1	;multiply by depth (perspective correction factor)
	fst	dword[interpolated_uvd+4]	;store back
	fld	dword[interpolated_uvd]	;same but with u coord
	fmul	st2
	fst	dword[interpolated_uvd]
	emms	;reset stack
	push	rax	;push values used in image sampling
	push	r15
	mov	r15, [imported_addr+24]	;textures here
	add	r15, 4	;4 offset
	call	f_sample_image	;sample uv
	mov	rdi, rax	;move position of sampled data into rdi
	pop	r15
	pop	rax
	push	rax
.call_addr:
	mov	r8, f_draw_point_raw
	call	r8	;draw point in correct colour
	pop	rax
.no_draw:
	cmp	rbx, qword[bounding_box+16]	;check if x counter is at end of row
	jz	.inc_y	;if yes, increase y
	add	rbx, UNIT_SIZE	;otherwise just increase x
	inc	r12
	jmp	.loop	;and keep going
.inc_y:
	cmp	rax, qword[bounding_box+24]	;check if y is at end
	jz	.end	;if yes, done
	add	rax, qword[main_width]	;otherwise increase y
	inc	r11
	mov	rbx, qword[bounding_box]	;and reset x
	mov	r12, qword[buf3]
	jmp	.loop	;loop over
.end:
	pop	rcx
	pop	r12
	pop	r13
	ret
f_cull_backfaces:
	push	rax	;yk
	push	rcx
	push	rsi
	push	rdi
	push	r13
	push	r14
	push	r15
	push	rdx
	push	r9
	mov	rdi, r15	;saves these bc r15 and r14 are used as source and destination holders
	mov	rsi, r14	;yep
	mov	rcx, rdx	;saves rdx to rcx for some reason that cannot remember probably a good idea
	lea	r13, [edge_vector_a]	;destination (aligned)
	call	f_edge_vector	;get edge vector (uses rcx as offset)
	add	rcx, 2	;next line in poly
	lea	r13, [edge_vector_b]	;same same (aligned)
	call	f_edge_vector
	sub	rcx, 2	;restore value of c
	lea	r15, [edge_vector_a]	;cross product this matrix
	lea	r14, [edge_vector_b]	;with this one
	lea	r13, [cross_product]	;and store here!
	call	f_cross_product	;all args must be aligned to 16 bytes
	movzx	r9, word[rsi+rcx]	;moves index of line into r9
	mov	rax, 16	;multiply val
	mul	r9	;multiply together, get offset of first index and result in rax
	movaps	xmm1, [camera_position_cull]	;move culled camera position into xmm1
	movups	xmm0, [rdi+rax+4]	;and move in value for camera position
	subps	xmm0, xmm1	;calculate vector
	movaps	xmm1, [cross_product]	;move in cross product to xmm1
	mulps	xmm0, xmm1	;then start dot product of cross product and camera vertex vector
	movaps	xmm1, xmm0	;clone xmm0 to xmm1
	shufps	xmm1, xmm0, 0b00000001 ;and rerange xmm1
	addss	xmm0, xmm1	;add scalars together
	movaps	xmm1, xmm0	;same again
	shufps	xmm1, xmm0, 0b00000010	;but use third value
	addss	xmm0, xmm1	;add scalars
	movss	[edge_vector_b], xmm0	;and store here
	fldz	;load zero
	fld	dword[edge_vector_b]	;load dot product
	xor	r8, r8	;reset r8 bc its used to see if line is negative or not
	fcom	st1	;compare dot product with 0
	fstsw	ax	;move status words into rax
	sahf	;and this guy
	ja	.end	;if its above 0, go to end
	inc	r8	;otherwise r8 = 1
.end:
	pop	r9	;pop back everything
	pop	rdx
	pop	r15
	pop	r14
	pop	r13
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax
	emms	;clear stack
	ret
f_clear_screen:
	xor	rcx, rcx	;xor register used for screen resetting offset
	xor	rbx, rbx	;reset rbx
	mov	rdx, [framebuf]	;load frame buffer
	lea	r15, [sky_colour]
	cmp	byte[wireframe], 0
	jz	.loop_reset
	lea	r15, [black_ansi]
.loop_reset:
	cmp	byte[rdx+rcx+TOP_SIZE+13], 27	;checks if current char is escape
	jnz	.end_reset	;if no, dont reset bc its part of ui
	mov	dword[depth_buffer+rbx], 1287568416	;float for very large negative value
	mov	ax, word[r15]	;otherwise move sky color into rax
	mov	word[rdx+rcx+7+TOP_SIZE], ax	;and move it into current escape
	mov	al, byte[r15+2]	;same but with last byte
	mov	byte[rdx+rcx+9+TOP_SIZE], al	;yep
	add	rcx, 13	;increase rcx by 13 (unit size)
	add	rbx, 4	;increase depth buf counter
	jmp	.loop_reset	;loop over
.end_reset:
	mov	word[rdx+rcx+7+TOP_SIZE], "23"	;move in black escape into text box thingy
	mov	byte[rdx+rcx+9+TOP_SIZE], "2"
	ret
f_node_screen:
	push	rax	;push registers
	push	rbx	;...
	push	rcx	;..
	push	rdx	;.
	xor	rcx, rcx
.loop:
	cmp	dword[r15+rcx+4], 234356	;check if at end
	jz	.draw_lines	;if yes, go to end part
	fld	dword[r15+rcx+4]	;otherwise load X pos onto FPU stack
	frndint	;rounds X pos value
	fst	dword[r15+rcx+4]	;store it back in the matrix
	fld	dword[r15+rcx+8]	;loads Y pos
	frndint	;rounds Y pos up
	fst	dword[r15+rcx+8]	;store it back in the matrix
	emms	;reset grahhhh
	add	rcx, 16	;increase rcx by matrix column value
	jmp	.loop	;loop over
.draw_lines:
	xor	rcx, rcx	;its important that both rcx and rdx are 0!
	xor	rdx, rdx	;.
	mov	qword[buf4], rsp
.line_loop:
	cmp	word[r14+rcx], 65535	;checks if at end of string
	jz	.end	;if yes, done!
	cmp	word[r14+rcx], 65534	;checks if at side separator
	jz	.draw_poly	;if yes, draw the poly here
	add	rcx, 2	;otherwise increase rcx (counter) by 2
	jmp	.line_loop	;and check again
.draw_poly:
	cmp	byte[culling], 0	;why do u feel like this
	jz	.dont_cull	;heeelpppppp
	call	f_cull_backfaces	;cull backfaces
	cmp	r8, 0	;if val is 0, then the face isnt valid
	jz	.dont_draw	;if val is 1, then draw the face
.dont_cull:
	cmp	byte[wireframe], 0	;for no reason maybe vignette is dying or smth
	jnz	.cont_draw	;either way it feels like amalgamation of ideas masquerading as some1
.no_wireframe:
	call	f_map_texture
.dont_draw:
	add	rcx, 2	;add 2 to rcx for next value
	mov	rdx, rcx	;move rcx to rdx so backface culling doesnt get sad
	jmp	.line_loop	;go to line loop
.cont_draw:
	push	rcx	;rcx should be stored here so u have the location of the EOS
	sub	rcx, 2	;decrease rcx so that it now points to the value before the EOS
.poly_loop:
	push	rdx	;push rdx, as its modified by mul operations
	mov	rbx, 16	;moves 16 into rbx
	movzx	rax, word[r14+rcx]	;moves the first line value into rax
	mul	rbx	;multiply it by 16 (matrix column length in bytes)
	mov	rbx, qword[r15+rax+4]	;reference the face index coordinates
	mov	qword[line_start], rbx	;then move that into the line start place
	mov	rbx, 16	;moves 16 back into rbx
	movzx	rax, word[r14+rcx-2]	;does the same thing, but with the memory location 2 bytes down
	mul	rbx	;same same
	mov	rbx, qword[r15+rax+4]
	mov	qword[line_end], rbx	;but line end now
	;call	f_check_visible	;check if face is visible
	;cmp	r8, 2	;if it isnt,
	;jz	.dont_draw_1	;go to loop over
	mov	qword[jump_point], f_draw_point
	call	f_draw_line	;draw the line
.dont_draw_1:
	sub	rcx, 2	;decrease rcx by 2, so that it draws lines between the previous 2 points
	pop	rdx	;pop back rdx for a compare with the start
	cmp	rcx, rdx	;if rcx is the same as rdx, it should close the poly
	jz	.close_poly	;so do that
	jmp	.poly_loop	;and if its not the same keep going
.close_poly:
	mov	rbx, 16	;same as it was b4
	movzx	rax, word[r14+rdx]	;rdx was poped back earlier and no mul since then soooo
	mul	rbx	;now theres a mul
	mov	rbx, qword[r15+rax+4]	;reference index blah blah
	mov	qword[line_start], rbx
	mov	rbx, 16
	pop	rcx	;pops back rcx from start (separator position)
	movzx	rax, word[r14+rcx-2]	;use the -2 bc otherwise it gets 65543 as the index to use
	mul	rbx	;multiply by 16
	mov	rbx, qword[r15+rax+4]
	mov	qword[line_end], rbx	;line end thingy
	;call	f_check_visible	;check if face is visible lol this function doesnt exist any more
	;no idea what it even did
	;cmp	r8, 2
	;jz	.dont_draw_2	;if not then yeah
	;these are commented bc they are stupid
	call	f_draw_line	;draws the line
.dont_draw_2:
	add	rcx, 2	;adds 2 to rcx, so it now points to the first value of next poly
	mov	rdx, rcx	;and store that in rdx bc its important
	jmp	.line_loop	;loop over
.end:
	pop	rdx	;pop back registers
	pop	rcx	;...
	pop	rbx	;..
	pop	rax	;.
	ret
f_draw_ui:
	push	rax	;push position registers
	push	rbx
	push	rcx	;push some registers
	push	rdx	;..
	push	rax	;.
	mov	eax, ebx	;move ebx (width) into eax	
	mul	dword[unit_size]	;and multiply by unit size
	mov	ecx, eax	;and move that into ecx
	pop	rax	;pop back height
	mul	word[window_size+2]	;multiply by half screen width
	mul	dword[unit_size]	;and unit size
	add	eax, ecx	;add the two together
	mov	rcx, [framebuf]	;move the shared memory framebuffer into rcx
	mov	word[rcx+rax+7+TOP_SIZE], "19"	;and move escapes for color
	mov	byte[rcx+rax+9+TOP_SIZE], "6"	;move colour
	mov	word[rcx+rax+11+TOP_SIZE], r8w
	pop	rdx	;....
	pop	rcx	;...
	pop	rbx	;..
	pop	rax	;.
	ret
f_draw_point:
	push	rax	;push position registers
	push	rbx
	push	rcx	;push some registers
	push	rdx	;..
	push	rax	;.
	push	rax	;push these AGAIN??
	push	rbx
	movzx	rcx, word[window_size]
	cmp	rax, rcx
	jae	.not_draw
	movzx	rcx, word[window_size+2]
	cmp	rbx, rcx
	jae	.not_draw
	mul	word[window_size+2]	;get position but in depth buf
	shl	rax, 2	;multiply by 4 ouh
	shl	rbx, 2	;shifts beloved
	add	rbx, rax
	fld	dword[depth_buffer+rbx]	;load depth buffer position
	fld	dword[point_depth]	;load depth of current point
	fcom	st1	;compare!!!!
	fstsw	ax	;blahhh
	sahf
	ja	.not_draw	;if point depth is above, its further away so dont draw
	fst	dword[depth_buffer+rbx]	;otherwise overwrite it
	emms
	pop	rbx
	pop	rax
	mov	eax, ebx	;move ebx (width) into eax	
	mul	dword[unit_size]	;and multiply by unit size
	mov	ecx, eax	;and move that into ecx
	pop	rax	;pop back height
	mul	word[window_size+2]	;multiply by half screen width
	mul	dword[unit_size]	;and unit size
	add	eax, ecx	;add the two together
	mov	rcx, [framebuf]	;move the shared memory framebuffer into rcx
	movzx	rdx, word[rdi]
	mov	word[rcx+rax+7+TOP_SIZE], dx	;and move escapes for color
	movzx	rdx, byte[rdi+2]
	mov	byte[rcx+rax+9+TOP_SIZE], dl	;move colour
	pop	rdx	;....
	pop	rcx	;...
	pop	rbx	;..
	pop	rax	;.
	ret
.not_draw:
	pop	rbx	;bubble wrap
	pop	rax
	pop	rax
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	ret
	times 10	nop
f_draw_point_offset_raw:
	;call	f_kill
	add	rax, qword[offset_graphics_window]
	sub	rax, TOP_SIZE
	push	rax
	jmp	f_draw_point_raw.offset_cont
f_draw_point_raw:
	push	rax	;this draws points with raw coords
.offset_cont:
	mov	r8, r11	;save the int arg to r8
	movzx	r9, word[window_size+2]	;and move multiplier for height into r9
	imul	r8, r9	;get height of pixel
	mov	r9, r12	;now calculate x offset
	shl	r8, 2	;double x offset
	shl	r9, 2	;and double y offset
	add	r9, r8	;then add together
	fld	dword[depth_buffer+r9]	;load depth buffer pos
	fld	dword[point_depth]	;and current point depth
	fcom	st1	;compare them!
	fstsw	ax	;store sw yk
	sahf
	ja	.no_draw	;if the point depth is higher dont draw it
	test	byte[rdi], 0b10000000	;OTHERWISE test for blending
	jnz	.test_blend
	fst	dword[depth_buffer+r9]	;if no blending store position in depth buiffer
	pop	rax	;and get back rac
	lea	r9, [rax+rbx]	;now load raw pixel pos
	mov	r8w, word[rdi]	;and also pixel colour
	mov	word[r10+r9+TOP_SIZE+7], r8w	;now move the colour into place
	mov	r8b, byte[rdi+2]
	mov	byte[r10+r9+TOP_SIZE+9], r8b
	ret
.no_draw:
	pop	rax	;just pop rax ant ret lol
	ret
.test_blend:
	test	byte[rdi], 0b01110000	;test if completely transparent
	jz	.no_draw	;if yes dont draw anything
	pop	rax	;otherwise get back rax as usual
	push	r15	;and push these registers (so many,,)
	push	r14
	push	rbx
	push	rcx
	push	rdx
	push	rax
	lea	r9, [rax+rbx]	;load addr here now
	lea	r14, [r10+r9+TOP_SIZE+7]	;and load place to put blend here
	mov	r15, rdi	;and pen colour
	call	f_blend_colours	;blend the colours
	pop	rax	;now done
	pop	rdx
	pop	rcx
	pop	rbx
	pop	r14
	pop	r15
	ret
f_display_transparent:
	test	byte[rdi], 0b01110000	;test complete transparency,,,, again
	jnz	.not_invis	;if its not then do other stuff
	cmp	si, "[]"	;otherwise check if selected
	jz	.keep_select	;if yes skip overwrite
	mov	si, " 0"	;otherwise load this 0
.keep_select:
	lea	rdi, [editor_invis_ansi]	;and this invisible ansi seq
	ret	;then return!
.not_invis:
	mov	bl, byte[rdi]	;get pen
	and	bl, 0b01110000	;now get opacity
	shr	bl, 4	;convert to int
	add	bl, 48	;and convert to ascii!
	mov	eax, dword[rdi]	;now move the pen to eax
	mov	dword[converted_ansi], eax	;and write here
	and	byte[converted_ansi], 0b00001111	;get first byte colour
	add	byte[converted_ansi], 48	;and conv to ascii
	cmp	si, "[]"	;check if selected
	jz	.keep_select_b	;if yes skip this
	mov	word[buf1], "  "	;otherwise move in blank
	mov	byte[buf1+1], bl	;and insert the number
	mov	si, word[buf1]	;and load this to rsi
.keep_select_b:
	lea	rdi, [converted_ansi]	;now put the resulting ascii in rdi
	ret	;return!
f_draw_point_offset:
	push	rcx
	movzx	rcx, word[preview_width]
	cmp	rbx, rcx	;clever code well done vignette
	jae	.retpoint	;bc its unsigned negative values are treated as higher
	movzx	rcx, word[preview_height]
	cmp	rax, rcx
	jae	.retpoint
	push	r15
	push	rdx	;rdx in particular fucks up line drawing alg
	push	rbx
	push	rax
	mov	rcx, qword[offset_graphics_window]	;offset for drawing
	imul	rax, qword[row_width_editor]	;multiply row number by width of row
	imul	rbx, UNIT_SIZE	;multiply column number by unit size
	add	rcx, rbx	;add to offset
	add	rcx, rax	;again
	test	byte[rdi], 0b10000000	;test if should mix or not,,,,
	jz	.skip_mix
	cmp	byte[buf4], -1
	jz	.blend_texel
	call	f_display_transparent
.skip_mix:
	movzx	rdx, word[rdi]	;move colour into here
	mov	r15, qword[framebuf]	;bc r15 is smth else in point display
	mov	word[r15+rcx+7], dx	;save here
	movzx	rdx, byte[rdi+2]	;and last byte of colour
	mov	byte[r15+rcx+9], dl	;save heere
	mov	word[r15+rcx+11], si	;move in point id
	pop	rax
	pop	rbx
	pop	rdx
	pop	r15
.retpoint:
	pop	rcx
	ret
.blend_texel:
	test	byte[rdi], 0b01110000	;test for complete transparency again
	jnz	.blend
	call	f_display_transparent	;if yes then display this
	jmp	.skip_mix	;and finish
.blend:
	push	r14	;otherwise you blend the pixels
	mov	r15, qword[framebuf]	;yk the setup for this now
	lea	r14, [r15+rcx+7]	;r14 is destination, r15 is source
	mov	r15, rdi
	push	qword[r15]	;put also preserve the pen colour
	call	f_blend_colours
	pop	qword[r15]
	pop	r14
	pop	rax
	pop	rbx
	pop	rdx
	pop	r15
	pop	rcx
	ret
f_draw_line:
	push	r15	;god damn
	push	r14	;......
	push	rbx	;.....
	push	rax	;....
	push	rcx	;...
	push	rdx	;..
	push	rdi	;.
	fld	dword[line_start+4]	;load start and end Y pos values
	fld	dword[line_end+4]
	fsub	st1	;sub start value from end value
	fst	dword[line_buf+4]	;store that in buffer for later
	fld	dword[line_start]	;do the same but for X pos values
	fld	dword[line_end]
	fsub	st1
	fst	dword[line_buf]	;and store in buffer for later again
	fabs	;calculate the absolute value of the X pos
	fxch	st2	;swap X pos val with Y pos val
	fabs	;absolute value again
	lea	r15, [line_start]	;load line_start into r15
	lea	r14, [line_end]	;and then end into r14
	xor	r13, r13	;reset r13
	mov	rbx, 4	;moves 4 (1 dword in bytes) to rbx
	xor	rcx, rcx	;resets rcx (rbx/rcx are used for indexes)
	xor	rdx, rdx	;and rdx (used for i value, which is 1 by default)
	fcom	st2	;compare st0 (abs(Y) with abs(X))
	fstsw	ax	;store status word in rax
	sahf	;and then move those into the status words
	emms	;all stack registers available
	jb	.horizontal	;if its below, draw a horizontal line
.vertical:
	xchg	rbx, rcx	;otherwise, swap indexes so that it works for vert lines
.horizontal:
	fldz	;loads zero val
	fld	dword[line_buf+rcx]	;loads X val (written for horizontal line)
	fcom	st1	;compares it with 0
	fstsw	ax	;stores result status words in rax
	sahf	;and then move that to status words
	jnb	.h_continue	;if not below, continue going
	xchg	r15, r14	;otherwise, swap end and start coordinates
.h_continue:
	fld	dword[r15]	;load start X coord
	fld	dword[r14]	;and end X coord
	fsub	st1	;take away end from start
	fst	dword[line_buf]	;store it in X pos buf
	fld	dword[r15+4]	;same thing but for Y pos
	fld	dword[r14+4]
	fsub	st1
	fst	dword[line_buf+4]
	fld	dword[line_buf+rbx]	;load Y pos
	xor	rdx, rdx	;reset rdx
	fcom	st6	;compare Y pos with 0
	fstsw	ax	;and yk by now
	sahf
	jnb	.no_switch	;if its not below, dont do this stuff
	fchs	;otherwise, negate Y pos
	fst	dword[line_buf+rbx]	;and store it back
	mov	rdx, 4	;moves 4 into rdx (-1 is now used instead of 1 for line increments)
.no_switch:
	emms	;reset stack
	fld	dword[line_buf+rcx]	;load X value
	fld	dword[line_buf+rbx]	;and Y value
	fld	st0	;duplicates Y value
	fadd	st1	;adds it to itself (multiply by 2)
	fsub	st2	;subtract X value from this
	fst	dword[line_val]	;store this in line value dword
	fld	dword[r15+rcx]	;load line start X pos
	fist	dword[line_int]	;store as an int in line int
	fld	dword[r14+rcx]	;load line end X pos
	fist	dword[line_int+4]	;and do the same
	emms	;reset stack
	mov	edi, dword[line_int]	;move X pos int into rdi to iterate over
.loop:
	push	rax	;push rax and rbx
	push	rbx	;.
	fld	dword[r15+rbx]	;load start Y pos
	fist	dword[buf3]	;store it in buffer 3 as an int
	mov	eax, dword[buf3]	;move the int into eax
	mov	ebx, edi	;moves X pos int into rbx
	cmp	rcx, 4	;checks if rcx is 4
	jnz	.draw	;if no, (horizontal) draw
	xchg	rax, rbx	;else, swap draw co-ords
.draw:
	push	rdi	;this is a mess
	lea	rdi, [white_ansi]	;go figure not commenting all this	
	mov	r8, qword[jump_point]	;boring code
	cmp	r8, f_draw_point
	jnz	.skip_test_editor
	cmp	rax, 0
	jl	.skip_draw
	cmp	rbx, 0
	jl	.skip_draw
	cmp	ax, word[available_window]
	jae	.skip_draw
	cmp	bx, word[window_size+2]
	jae	.skip_draw
	jmp	.draw_normal
.skip_test_editor:
	mov	rdi, qword[line_colour]
	mov	si, word[unit_template+11]
.draw_normal:
	call	r8	;draw the point
.skip_draw:
	pop	rdi
	pop	rbx	;get back rbx and rax
	pop	rax	;.
	fldz	;load 0 val
	fld	dword[line_val]	;load calculated val
	fcom	st1	;compare with 0
	fstsw	ax	;yeah
	sahf
	jna	.loop_end	;if its not larger, continue as normal
	emms	;if yes, reset stack
	fld	dword[line_i+rdx]	;load 1 (or -1) value
	fld	dword[r15+rbx]	;load line start Y value
	fadd	st1	;add 1
	fst	dword[r15+rbx]	;store back where it was before
	fld	dword[line_buf+rcx]	;load X buffer value
	fld	st0	;duplicate it
	fadd	st1	;then add them together
	fld	dword[line_val]	;load calculated val
	fsub	st1	;subtract it from duped value
	fst	dword[line_val]	;store it back
	emms	;reset stack
.loop_end:
	fld	dword[line_buf+rbx]	;loads line buffer for X pos
	fld	st0	;duplicate
	fadd	st1	;multiply by 2
	fld	dword[line_val]	;load line val
	fadd	st1	;add it to other val
	fst	dword[line_val]	;and store back
	emms	;reset stack
	cmp	edi, dword[line_int+4]	;check if iteration value is same as line end val
	jz	.end	;if yes, done
	inc	edi	;else, increase rdi
	jmp	.loop	;and loop over
.end:
	pop	rdi	;pop back
	pop	rdx
	pop	rcx
	pop	rax
	pop	rbx
	pop	r14
	pop	r15
	ret
f_initialise_screen:
	xor	rax, rax	;forgor
	mov	r15, [framebuf]	;loads frame buffer into r15
	mov	byte[r15], 27	;moves a 10 for the first byte
	mov	word[r15+1], "[H"
	add	rax, TOP_SIZE	;then increase rax to skip past 10 for future
.loop:
	cmp	rax, 499200 + TOP_SIZE	;checks if at end of buffer
	jz	.end	;if yes, go to end
	xor	rbx, rbx	;otherwise, reset rbx
.loop_segment:
	cmp	rbx, 13	;checks if rbx (escape counter) is 13
	jz	.loop	;if yes, go out of this loop and reset rbx
	movzx	rcx, byte[unit_template+rbx]	;moves current byte in escape unit template into rcx
	mov	byte[r15+rax], cl	;moves that into current screen buffer position
	inc	rax	;increase rax
	inc	rbx	;and rbx
	jmp	.loop_segment	;loop over
.end:
	mov	byte[r15+rax], 27
	mov	dword[r15+rax+1], "[48;"
	mov	dword[r15+rax+5], "5;00"
	mov	word[r15+rax+9], "0m"
	movzx	rcx, word[window_size+2]	;move window width into rcx (in half val)
	mov	eax, dword[unit_size]	;move in the unit size (13)
	mul	rcx	;multiply together so eax is value of row in bytes
	shl	rcx, 1	;double rcx to non half value (printable chars count)
	mov	edx, eax	;store eax for later (row width)
	mov	ebx, dword[screen_size]	;move the screen size in bytes into ebx
	add	ebx, 11
	sub	ebx, eax	;subtract eax from that, so last line start in ebx
	add	ebx, 4 + TOP_SIZE	;add 5 (offset for first middle char)
	mov	eax, dword[screen_size]	;moves screen size in bytes into eax
	add	eax, 11
	add	eax, TOP_SIZE - 1
	mov	r14, "╰"	;start
	mov	r13, "─"	;middle
	mov	r12, "╯"	;end
	call	f_generate_row	;generate this row!
	push	rbx	;push rbx so its not screwed
	add	rbx, 88	;keys section length
	mov	dword[r15+rbx], "┴"	;separator
	add	rbx, 176	;then lengths for other sections
	mov	dword[r15+rbx], "┴"
	add	rbx, 104
	mov	dword[r15+rbx], "┴"
	pop	rbx	;pop back rbx
	sub	ebx, edx	;go back a row
	sub	eax, edx	;go back a row
	mov	r14, "│"	;same thing really
	mov	r13, " "
	mov	r12, "│"
	call	f_generate_row
	mov	qword[r15+rbx], "KE"	;now u put in the section labels
	mov	qword[r15+rbx+8], "YS"
	mov	dword[r15+rbx+16], ":"
	mov	dword[keys_space], ebx	;store start of keys thingy
	add	dword[keys_space], 24	;and add 24
	push	rbx	;and push rbx bc its changed
	add	rbx, 88
	mov	dword[r15+rbx], "│"
	mov	qword[r15+rbx+4], "LO"
	mov	qword[r15+rbx+12], "CA"
	mov	qword[r15+rbx+20], "TI"
	mov	qword[r15+rbx+28], "ON"
	mov	dword[r15+rbx+36], ":"
	mov	dword[r15+rbx+44], "X"
	mov	dword[r15+rbx+88], "Y"
	mov	dword[r15+rbx+132], "Z"
	mov	dword[location_space], ebx
	add	dword[location_space], 52
	add	rbx, 176 
	mov	dword[r15+rbx], "│"
	mov	qword[r15+rbx+4], "FA"
	mov	qword[r15+rbx+12], "CI"
	mov	qword[r15+rbx+20], "NG"
	mov	dword[r15+rbx+28], ":"
	add	rbx, 104
	mov	dword[r15+rbx], "│"
	mov	qword[r15+rbx+4], "FP"
	mov	qword[r15+rbx+12], "S:"
	mov	qword[r15+rbx+24], "00"
	add	ebx, 24
	mov	dword[fps_space], ebx	;store the space of where to put fps value
	pop	rbx
	sub	ebx, edx	;same again
	sub	eax, edx
	mov	r14, "╭"
	mov	r13, "─"
	mov	r12, "╮"
	call	f_generate_row
	add	rbx, 88
	mov	dword[r15+rbx], "┬"
	add	rbx, 176
	mov	dword[r15+rbx], "┬"
	add	rbx, 104
	mov	dword[r15+rbx], "┬"
	ret	;easy
f_clear_lbar:
	mov	rax, qword[lbar_offset]	;addr offset
	movzx	rbx, word[window_size]	;use window height
	sub	rbx, EDITOR_BBAR+2	;and sub bars from it so it matches
.loop:
	cmp	rbx, 0	;check if this is 0
	jz	.end	;if yes finished
	%assign	COUNTER	0
	%rep	EDITOR_LBAR-2
		mov	dword[r15+rax+COUNTER], " "	;otherwise clear the lbar
		%assign	COUNTER	COUNTER+4
	%endrep
	add	rax, qword[row_width_editor]	;and go to next row
	dec	rbx
	jmp	.loop
.end:
	ret
f_clear_preview:
	xor	r8, r8
	mov	bx, word[preview_height]	;preview height in here
	mov	rdx, qword[offset_graphics_window]	;and new row offset here
.loop_height:
	mov	rcx, rdx	;move in the offset to here
	mov	ax, word[preview_width]	;reset preview width thing
	cmp	bx, 0	;if row counter is 0 then finished
	jz	.end
.loop_row:
	cmp	ax, 0	;if column counter is 0 then finished
	jz	.end_row
	mov	word[r15+rcx+7], "23"	;otherwise move in black ansi
	mov	byte[r15+rcx+9], "2"
	mov	word[r15+rcx+11], "  "	;clear the text also
	mov	dword[depth_buffer+r8], 1287568416	;float for very large negative value
	mov	dword[depth_buffer+r8+4], 1287568416	;float for very large negative value
	add	rcx, UNIT_SIZE	;go to next unit
	dec	ax	;decrease column counter
	add	r8, 8
	jmp	.loop_row	;loop over
.end_row:
	dec	bx	;after row end, decrease row counter
	add	rdx, qword[row_width_editor]	;and go to next row (rdx is row start)
	jmp	.loop_height	;loop over!
.end:
	ret
f_generate_escapes:
	push	rax	;give birth to rax
	push	rbx
	mov	ax, word[preview_width]	;preview window width in pixels
.loop:
	cmp	ax, 0	;check if iteration counter is 0
	jz	.end	;if it is finished row
	%assign	COUNTER	 0	;i = 0
	%rep	UNIT_SIZE	;13 times repeat
		mov	dl, byte[unit_template+COUNTER]	;transfer the bytes from escape template
		mov	byte[r15+rbx+COUNTER], dl	;to here
		%assign COUNTER	COUNTER+1 ;i += 1
	%endrep
	dec	ax	;decrease thisguy
	add	rbx, UNIT_SIZE	;increase rbx by 13 for next escape
	jmp	.loop		;loop over
.end:
	mov	byte[r15+rbx], 27	;and reset dword at end of row
	mov	word[r15+rbx+1], "[0"
	mov	byte[r15+rbx+3], "m"
	pop	rbx
	pop	rax
	ret
f_generate_row:
	push	rax	;help this was so hard to debuggg
	push	rbx
	push	rcx
	mov	dword[r15+rbx-4], r14d	;move the byte to write into first space
	;was there ever a reason to have the start address as +4???
.generate_middle:
	cmp	rcx, 2	;checks if rcx (column counter) is 2 (finished middle)
	jz	.end	;if yes, go to end
	mov	dword[r15+rbx], r13d	;else, move in middle counter
	add	rbx, 4	;next space
	dec	rcx	;decrease column counter
	jmp	.generate_middle	;loop over
.end:
	mov	dword[r15+rbx], r12d	;move in end char
	cmp	r8, 255
	jz	.end_clear
	add	rbx, 4	;increase rbx to next char
	mov	byte[r15+rbx], 0	;and then move in 0 byte
	;reason: if u dont u get unfinished escapes that dont match screen width
.loop_clear:
	cmp	eax, ebx	;checks if counter is at end
	jl	.end_clear	;if yes, (clear last byte) go to end
	mov	byte[r15+rbx], 0	;move byte into current pos otherwise
	inc	rbx	;increase rbx counter
	jmp	.loop_clear	;loop over
.end_clear:
	pop	rcx	;aaand ur done
	pop	rbx
	pop	rax
	ret
f_extrude_point:
	push	r15	;push r15 for use in future operations
	add	r15, 4	;adds 4 to skip the 16 at start
	mov	rbx, 16	;move 16 into rbx (column width)
	mul	rbx	;multiply it by vertex index
	add	r15, rax	;add this to r15 so you have the write coords
	fld	dword[center_coords+8]	;load the center coords
	fld	dword[center_coords+4]
	fld	dword[center_coords]
	fld	dword[r15+8]	;load z coord
	fsub	st3	;subtract center z coords from it
	fld	dword[r15+4]	;do the same but with y and x coords 
	fsub	st3
	fld	dword[r15]
	fsub	st3
	fld	dword[operation_multiplier]	;load the multiplier for extrusion
	fmul	TO	st1	;and multiply all of the subtracted points by it
	fmul	TO	st2
	fmulp	st3
	fadd	st3	;then add back the center coords to all coords
	fstp	dword[r15]
	fadd	st3
	fstp	dword[r15+4]
	fadd	st3
	fstp	dword[r15+8]
	emms	;and ur done wasnt that easy
	pop	r15	;pop back for future
	ret
f_apply_transformation:
	lea	r14, [matrix_camera]	;multiply by new camera matrix
	lea	r13, [obj_aux_2]	;result in copy memory
	call	f_multiply_matrix	;multiply them
	lea	r15, [obj_aux_2]	;nodes from last multiplication in obj_aux_1
	lea	r14, [matrix_projection]	;multiply by projection matrix
	lea	r13, [obj_aux_1]	;and result in first cube matrix
	call	f_multiply_matrix	;go
	lea	r15, [obj_aux_1]	;use r15 to hold matrix to normalise
	call	f_normalise_matrix	;normalise matrix
	cmp	dword[r15], 0
	jz	.retpoint
	lea	r15, [obj_aux_1]	;matrix A is result of normalisation
	lea	r14, [matrix_screen]	;matrix B is screen matrix
	lea	r13, [obj_aux_2]	;result matrix
	call	f_multiply_matrix	;bdsaojoicxzoiwadpszx
.retpoint:
	ret
f_init_matrices:
	fild	word[r14]	;load window width
	fild	word[r15]	;load window height
	fdiv	st1	;divide window height by width
	fld	dword[camera_h_fov]	;load h_fov
	fmul	st1	;multiply it by window height / width
	fst	dword[camera_v_fov]	;and thats camera_vfov
	emms	;clearrr
	call	f_projection_matrix	;generate projection matrix
	movzx	r15, word[r15]
	movzx	r14, word[r14]
	call	f_screen_matrix	;and screen matrix
	call	f_update_camera_axis	;update camera axis
	call	f_camera_rotation_matrix	;and then regenerate the rotation matrix
	call	f_camera_translation_matrix	;and translation matrix
	lea	r15, [matrix_camera_translate]
	lea	r14, [matrix_camera_rotate]
	lea	r13, [matrix_camera]
	call	f_multiply_matrix
	ret
f_display_points:
	xor	rcx, rcx	;start at 0 for the faces string
	xor	rdx, rdx
	add	rcx, qword[points_dat]
.loop_clear_points:
	cmp	edx, dword[point_dat_offset]
	jz	.finish_point_clear
	mov	byte[rcx+rdx+3], 0b00000001
	add	rdx, 4
	jmp	.loop_clear_points
.finish_point_clear:
	xor	rcx, rcx
	mov	r14, qword[edited_faces]	;addr in r14
	lea	r15, [obj_aux_2]	;and points addr in here
	mov	qword[jump_point], f_draw_point_offset	;use this point drawing function in line draw
.loop_lines:
	cmp	word[r14+rcx], 65535	;check if at end
	jz	.finished_lines	;if yes STOPPPPP
	cmp	byte[culling], 0	;check various variable things
	jz	.skip_cull
	cmp	word[r14+rcx+6], 65533
	jz	.draw_normal
	cmp	word[r14+rcx+6], 65531
	jz	.draw_normal
	mov	rdx, rcx	;set up for backface culling
	call	f_cull_backfaces
	cmp	r8, 0	;if return is 0 then do some stuff
	jnz	.draw_normal	;otherwise draw face normally
	mov	r13, qword[points_dat]
	%assign	COUNTER	0
	%rep	3
		movzx	rax, word[r14+rcx+COUNTER]	;move in point index
		shl	rax, 2	;convert to use in points_dat
		and	byte[r13+rax+3], 0b11111110	;now clear all bits but lsb of this thing
		%assign	COUNTER	COUNTER+2	;next face
	%endrep
	jmp	.skip_draw
.draw_normal:
	mov	r13, qword[points_dat]	;genuinely cant remember how this bit works sry
	%assign	COUNTER	0
	%rep	3
		movzx	rax, word[r14+rcx+COUNTER]
		shl	rax, 2
		or	byte[r13+rax+3], 0b00000010
		%assign	COUNTER	COUNTER+2
	%endrep
.skip_cull:
	mov	qword[line_colour], white_ansi	;default colour is white
	cmp	word[r14+rcx+6], 65531
	jb	.skip_preview_line
	cmp	word[r14+rcx+6], 65533	;check if current face is terminated with this
	ja	.skip_preview_line	;if no do nothing
	mov	qword[line_colour], yellow_ansi	;if yes use yellow for preview face
.skip_preview_line:
	cmp	word[r14+rcx+6], 65532
	ja	.skip_tex
	cmp	word[r14+rcx+6], 65531
	jb	.skip_tex
	mov	r12, qword[edited_uv]
	mov	rax, qword[edited_texture]
	sub	rax, 4
	mov	qword[imported_addr+24], rax
	add	rcx, 6
	mov	rax, qword[row_width_editor]
	mov	qword[main_width], rax
	push	word[window_size+2]
	push	word[available_window]
	mov	ax, word[preview_width]
	mov	word[window_size+2], ax
	mov	ax, word[preview_height]
	mov	word[available_window], ax
	call	f_map_texture
	pop	word[available_window]
	pop	word[window_size+2]
	sub	rcx, 6
	cmp	word[r14+rcx+6], 65531
	jz	.skip_tex
	jmp	.skip_draw
.skip_tex:
	push	rcx	;rcx is important to keep the same
	%rep	2
		movzx	rax, word[r14+rcx]	;move in index
		shl	rax, 4	;multiply by 16
		add	rax, 4	;and add 4 to get point offset
		mov	rbx, qword[r15+rax]	;put the qword (X and Y pos) in here
		mov	qword[line_start], rbx	;and move it into line start
		movzx	rax, word[r14+rcx+2]	;do same thing but with next point index
		shl	rax, 4
		add	rax, 4
		mov	rbx, qword[r15+rax]
		mov	qword[line_end], rbx	;line end now
		call	f_draw_line	;and draw a line!
		add	rcx, 2	;go to next pair
	%endrep
	movzx	rax, word[r14+rcx]	;do same thing again.... why isnt it %rep 3...
	shl	rax, 4
	add	rax, 4
	mov	rbx, qword[r15+rax]
	mov	qword[line_start], rbx
	movzx	rax, word[r14+rcx-4]	;bcnow it uses the first point! join back to the start
	shl	rax, 4
	add	rax, 4
	mov	rbx, qword[r15+rax]
	mov	qword[line_end], rbx
	call	f_draw_line	;so clever 
	pop	rcx
.skip_draw:
	add	rcx, 8	;go to next face
	jmp	.loop_lines	;loop over
.finished_lines:
	mov	rcx, 4	;skip 16 now
	mov	r14, qword[points_dat]	;and use different r14 addr
.loop_draw:
	cmp	dword[r15+rcx], 234356	;check if at end of matrix
	jz	.finished_points	;if yes go here
	fld	dword[r15+rcx]	;otherwise load x into fpu
	fist	dword[buf1]	;store as int here
	fld	dword[r15+rcx+4]	;same with y pos
	fist	dword[buf1+4]
	emms	;clear
	mov	ebx, dword[buf1]	;store new vals for drawing point
	mov	eax, dword[buf1+4]	;same
	push	rcx	;push rcx bc its modified here
	sub	rcx, 4	;subtract 4 to remove offset
	shr	rcx, 2	;divide by 4 to format it for point data struct
	cmp	byte[culling], 0
	jz	.not_hidden
	cmp	byte[r14+rcx+3], 0
	jnz	.not_hidden
	pop	rcx
	add	rcx, 16
	jmp	.loop_draw
.not_hidden:
	mov	si, word[r14+rcx+1]	;move the id into rsi	
	lea	rdi, [blue_ansi]
	test	byte[r14+rcx], 0b00001000
	jnz	.c_editing
	test	byte[r14+rcx], 0b00000100
	jnz	.c_selected
	test	byte[r14+rcx], 0b00000010
	jnz	.c_preview
	test	byte[r14+rcx], 0b00000001
	jnz	.c_origin
	jmp	.not_modify
.c_editing:
	lea	rdi, [purple_ansi]
	jmp	.not_modify
.c_selected:
	lea	rdi, [green_ansi]
	jmp	.not_modify
.c_preview:
	lea	rdi, [yellow_ansi]
	jmp	.not_modify
.c_origin:
	lea	rdi, [red_ansi]
.not_modify:
	pop	rcx	;pop back rcx
	call	f_draw_point_offset	;and draw the point
	add	rcx, 16	;go to next point
	jmp	.loop_draw	;loop over
.finished_points:
	ret
f_rgb_to_ansi:
	xor	rdx, rdx	;reset this for divs
	mov	rcx, 16	;and move base col into rcx
	movzx	rax, word[r13]	;move in b value
	mov	rbx, 43	;and 43, divisor for colour vals
	idiv	rbx	;divide by rbx
	add	rcx, rax	;add to base!
	xor	rdx, rdx	;same again
	movzx	rax, word[r14]	;but use G value
	idiv	rbx
	imul	rax, 6	;and now u mul by 6 instead to go next row
	add	rcx, rax
	xor	rdx, rdx
	movzx	rax, word[r15]	;same but with R val,
	idiv	rbx
	imul	rax, 36	;and now go to next 'page'
	add	rcx, rax
	mov	rax, rcx
	mov	rbx, 10	;divisor for ascii conversion
	%rep	2
		xor	rdx, rdx
		idiv	rbx
		push	rdx
	%endrep
	pop	rdx
	add	rdx, 48	;add back ascii 0
	add	rax, 48	;to both
	mov	byte[r11], al
	mov	byte[r11+1], dl
	mov	byte[r12+7], al	;this includes "0" regardless so its ok
	mov	byte[r12+8], dl
	pop	rdx	;get other val for rdx
	add	rdx, 48
	mov	byte[r11+2], dl
	mov	byte[r12+9], dl	;and insert that
	mov	byte[r12+12], " "
	mov	al, byte[r10]
	cmp	al, 8
	jz	.retpoint
	cmp	al, 0
	jnz	.skip_col_clear
	mov	word[r12+7], "01"
	mov	byte[r12+9], "6"
.skip_col_clear:
	sub	byte[r11], 48
	and	byte[r11], 0b00001111
	mov	bl, byte[r10]
	shl	bl, 4
	or	bl, 0b10000000
	or	byte[r11], bl
	add	al, 48
	mov	byte[r12+12], al
.retpoint:
	ret
f_resize_texture:
	mov	r8w, word[r14]	;move resiz x into r8
	sub	r8w, word[dimensions]	;subtract original size
	movsx	r8, r8w	;and signed extend to the entire register
	jc	.decrease_rows	;if the difference was negative then u remove rows
	jz	.row_end	;if the difference was 0 do nothing with rows
	movzx	rsi, word[dimensions]	;if u need to add rows then move og x val into rsi
	mov	r11, rsi	;and save it to r11 also
	imul	r11, 3	;multiply r11 by 3 to get row length
	lea	rsi, [r11-3]	;rsi is now r11 - 3, rsi is last pixel of first row
	movzx	rbx, word[dimensions+2]	;load y val into rbx
	dec	rbx	;decrease it bc height 1 shouldnt have any offset from this
	imul	rbx, r11	;multiply height by row length to get row offset
	add	rsi, rbx	;add rbx to rsi, rsi is now last pixel of last row
	movzx	rdi, word[r14]	;rdi is new x position
	mov	r12, rdi	;and same as above, save vals to r12
	imul	r12, 3	;then get row length for new x
	lea	rdi, [r12-3]	;and row end for new x
	movzx	rbx, word[dimensions+2]	;same with y pos now
	dec	rbx
	imul	rbx, r12	;and get row offset
	add	rdi, rbx	;add this to rdi
	times 3	sub	rdi, r8	;it also subtracts the size of the new rows to append
	movzx	r10, word[dimensions+2]	;and save old height to r10
.loop_row:
	dec	r10	;decrease it
	jl	.row_end	;if its < 0, finished adding new columns
	push	rdi	;otherwise, push the destination and source indexes
	push	rsi
	push	rdi	;and push this again for use in filling space after rows
	movzx	rcx, word[dimensions]	;rcx is now row length
.loop_fwd:
	dec	rcx	;decrease it
	jl	.end_fwd	;if its < 0 then finished moving row forward
	mov	eax, dword[r15+rsi]	;move texels forward from right to left
	mov	dword[r15+rdi], eax
	sub	rsi, 3	;and then go left to go to the previous texel
	sub	rdi, 3	;this avoids overwriting texels with duplicate values
	jmp	.loop_fwd	;keep looping over this
.end_fwd:
	pop	rdi	;get back rdi, middle between moved row and space to fill
	add	rdi, 3	;add 3 to go to the first space to fill
	mov	rcx, r8	;rcx is now the delta between old and new vals
.loop_fill:
	dec	rcx	;decrease rcx
	jl	.end_fill	;if its < 0 then it should finish
	mov	byte[r15+rdi], 0b10000000	;otherwise fill with black "016" colour
	mov	word[r15+rdi+1], "16"
	add	rdi, 3	;go to next texel
	jmp	.loop_fill	;and loop over
.end_fill:
	pop	rsi	;get back offsets from before modifications
	pop	rdi
	sub	rsi, r11	;now go to previous row in source index
	sub	rdi, r12	;and destination index, using precalculated row lengths
	jmp	.loop_row	;and loop over!
.decrease_rows:
	movzx	rdi, word[r14]	;for decreasing row length, u start from start to end
	imul	rdi, 3	;rather than end to start in increasing row length, so first get new row length
	movzx	rsi, word[dimensions]	;and old row length
	imul	rsi, 3
	movzx	r10, word[dimensions+2]	;and also save old height
	dec	r10	;decrease this preemptively so it runs 1 less time than it should
.loop_decrease:
	dec	r10	;decrease r10
	jl	.row_end	;if its < 0 then finished moving back things
	movzx	rcx, word[r14]	;new row length
.loop_move_back:
	dec	rcx	;decrease rcx
	jl	.end_move_back	;if its < 0 (yawn) then go to end of moving back
	mov	eax, dword[r15+rsi]	;otherwise move values backwards to decrease row lenght
	mov	dword[r15+rdi], eax
	add	rsi, 3	;this time move forward from left to right to preserve old values
	add	rdi, 3
	jmp	.loop_move_back	;and loop over
.end_move_back:
	times 3	sub	rsi, r8	;r8 is negative, so it essentially adds 3 if r8 is -1, goes to next row
	jmp	.loop_decrease	;and loop over to continue moving values backwards
.row_end:
	movzx	r8, word[r13]	;now calculate the y delta
	sub	r8w, word[dimensions+2]
	movsx	r8, r8w	;and save here as above
	jc	.end	;if its negative then do nothing bc it handles itself
	jz	.end	;if its nothing also do nothing
	movzx	rcx, word[dimensions]	;if its *something* then get row length
	imul	rcx, 3	;row length now in rcx
	mov	rax, rcx	;and rax
	imul	rcx, r8	;multiply rcx by delta to get amount of new vals to add
	movzx	rbx, word[dimensions+2]	;move y old into rbx
	mul	rbx	;and multiply rax (row length) by old height to get offset to add
.loop_add_y:
	dec	rcx	;decrease rcx
	jz	.end	;if its 0 then finished adding blank space
	mov	byte[r15+rax], 0b10000000	;otherwise add blank space
	mov	word[r15+rax+1], "16"
	add	rax, 3	;and go to next ansi colour
	jmp	.loop_add_y	;and loop!
.end:
	mov	ax, word[r14]	;once done, move the new val into ax
	cmp	ax, word[texture_pos]	;compare it against cursor pos
	ja	.x_ok	;if its above then dont change that val
	mov	word[texture_pos], ax	;otherwise move it to resized val
	dec	word[texture_pos]	;and subtract 1
.x_ok:
	mov	word[r15-4], ax
	mov	word[dimensions], ax	;save new val to dimensions
	mov	ax, word[r13]	;now do same as above but with y position
	cmp	ax, word[texture_pos+2]	;compare against cursor y
	ja	.y_ok
	mov	word[texture_pos+2], ax	;and save in cursor y
	dec	word[texture_pos+2]
.y_ok:
	mov	word[r15-2], ax
	mov	word[dimensions+2], ax
	ret
f_get_texel:
	movzx	r8, word[dimensions]	;move in dimensions to r8 for row length
	imul	r8, 3	;mul by 3 to get row length
	mov	r9, rdi	;move y pos into r9
	imul	r8, r9	;multiply r8 by r9 to get row offset
	mov	r9, rsi	;move x pos into r9
	imul	r9, 3	;multiply by 3
	add	r8, r9	;add together to get total offset
	mov	r11w, word[r15+r8]	;now move texel colour to r11w and r12b
	mov	r12b, byte[r15+r8+2]
	ret
f_set_texel:
	movzx	r8, word[dimensions]	;same offset calcs as above
	imul	r8, 3	;like down to the letter lol
	mov	r9, rdi
	imul	r8, r9
	mov	r9, rsi
	imul	r9, 3
	add	r8, r9
	lea	rsi, [r15+r8]	;except now it loads this into rsi to get around rex limitations
	mov	word[rsi], bx	;and it moves in the new colour word
	mov	byte[rsi+2], ch	;and new colour byte
	ret
f_span_fill:
	mov	rdi, r14	;rdi and rsi are used for coords
	mov	rsi, r13	;in get texel and set texel
	call	f_get_texel	;get the texel colour
	cmp_ansi_old	.skip_ret	;macro for comparing colour
	ret	;if current texel is not the old colour then return
.skip_ret:
	mov	r10, r13	;otherwise store the x pos in this aux
.loop_fill_r:
	cmp	r10w, word[dimensions]	;check if at right edge
	jae	.end_fill_r	;if yes then done filling right edge
	mov	rdi, r14	;otherwise put coords into here
	mov	rsi, r10
	call	f_get_texel	;and get texel colour
	cmp_ansi_old	.fill_r	;check if its the old colour
	jmp	.end_fill_r	;if no then done filling right edge
.fill_r:
	mov	rdi, r14	;otherwise move in coords here again
	mov	rsi, r10
	call	f_set_texel	;and set the texel colour to new colour
	inc	r10	;increase x pos
	jmp	.loop_fill_r	;and loop over
.end_fill_r:
	mov	word[buf1+2], r10w	;store this rightmost filled texel
	lea	r10, [r13-1]	;and now go the other way (left)
.loop_fill_l:
	cmp	r10w, 0	;check if r10 is at left edge
	jl	.end_fill_l	;if yes then go to end
	mov	rdi, r14	;otherwise load coords here again
	mov	rsi, r10
	call	f_get_texel	;and get texel
	cmp_ansi_old	.fill_l	;if its the same as old then fill
	jmp	.end_fill_l	;otherwise done
.fill_l:
	mov	rdi, r14	;coords again,,,,
	mov	rsi, r10
	call	f_set_texel	;set texel to specified colour
	dec	r10	;go left this time
	jmp	.loop_fill_l	;and loop
.end_fill_l:
	mov	word[buf1], r10w	;save leftmost texel!
	fill_rows	-1, -1	;and this gets rows above
	fill_rows	+1, word[dimensions+2]	;and below
	ret	;easy
f_blend_colours:
	test	byte[r14], 0b10000000	;test if set colour is a translucent colour
	jz	.cont_blend	;if no just blend
	mov	dx, word[r15]	;otherwise, just overwrite the place instead of blending
	mov	word[r14], dx	;blending 2 translucents gets funky
	mov	dl, byte[r15+2]	;a bit too funky
	mov	byte[r14+2], dl
	ret
.cont_blend:
	movzx	bx, byte[r15]	;otherwise move in pen
	and	bl, 0b01110000	;extract transparency
	shr	bl, 4	;and convert to int
	mov	word[buf1], bx	;save it here!
	fld	dword[eight]	;load 8 (max transparency)
	fild	word[buf1]	;load current transparency
	fdiv	st1	;divide by 8 to convert to range 0.0 - 1.0
	fst	dword[buf1]	;store here
	emms	;reset!
	mov	dword[buf1+4], 0x3F800000	;1.0....
	movzx	rbx, byte[r15]	;move first pen byte here
	and	bl, 0b00001111	;extract colour
	get_rgb	edge_vector_a, r15	;now get rgb vals in edgevectora
	movzx	rbx, byte[r14]	;and do same with bg
	sub	bl, 48	;except conv to int ofc
	get_rgb	edge_vector_b, r14
	movaps	xmm0, [edge_vector_a]	;now load the rgb sequences to xmm0
	movaps	xmm2, [edge_vector_b]	;and xmm2
	cvtdq2ps	xmm0, xmm0	;convert them to floats
	cvtdq2ps	xmm2, xmm2
	movss	xmm1, dword[buf1]	;and move the transparency value for pen into xmm1
	shufps	xmm1, xmm1, 0b00000000	;and broadcast value
	movss	xmm3, dword[buf1+4]	;same with xmm3
	shufps	xmm3, xmm3, 0b00000000
	mulps	xmm0, xmm1	;multiply pen rgb vals by pen opacity
	mulps	xmm2, xmm3	;multiply bg rgb vals by 1 p much
	movss	xmm1, dword[one]	;now using simd subtract pen opacity from 1
	movss	xmm3, dword[buf1]
	subss	xmm1, xmm3
	shufps	xmm1, xmm1, 0b00000000	;and broadcast it
	mulps	xmm2, xmm1	;multiply bg vals by this
	addps	xmm0, xmm2	;and then add that to xmm0
	cvtps2dq	xmm0, xmm0	;then convert back to int
	movaps	[edge_vector_a], xmm0	;save to edge vector A!
	mov	eax, dword[edge_vector_a]	;load r component
	imul	eax, 36	;multiply by 36
	add	eax, 16	;add black offset
	mov	byte[buf2], al	;and store result here!
	mov	eax, dword[edge_vector_a+4]	;now g component
	imul	eax, 6	;mul by 6
	add	byte[buf2], al	;and add to this result
	mov	eax, dword[edge_vector_a+8]	;now blue doesnt require multiplication
	add	byte[buf2], al
	movzx	rax, byte[buf2]	;now convert to ascii
	xor	rdx, rdx
	mov	rbx, 10	;div by 10 to get first vals
	idiv	rbx
	push	rdx	;push the result
	xor	rdx, rdx
	idiv	rbx	;now div again
	add	al, 48	;these are ascii vals now
	add	dl, 48
	mov	byte[r14], al	;store them here
	mov	byte[r14+1], dl
	pop	rdx	;get back first remainder
	add	dl, 48
	mov	byte[r14+2], dl	;and store that
	ret	;done!!!
