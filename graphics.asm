%macro	interpolate_uvd	1
	fld	dword[barycentric]	;load barycentric u coord
	fld	dword[vertex_attr+%1]	;load v0 u coord
	fmul	st1	;multiply
	fld	dword[barycentric+4]	;load barycentric v coord
	fld	dword[vertex_attr+12+%1]	;and v1 u coord
	fmul	st1	;guess what comes next
	fld	dword[barycentric+8]	;its just this but over again
	fld	dword[vertex_attr+24+%1]
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
	lea	r8, [camera_position]	;distance from camera position
	call	f_euclidean_distance	;get depth
	fld	dword[vertex_depth]	;load depth
	fld1	;and load 1
	fdiv	st1	;recpirocal of vertex_depth
	fst	dword[vertex_attr+%1*12+8]	;store in third position
	sub	rax, 4	;remove 16 offset
	shr	rax, 1	;and half to get uv position
	fld	dword[r12+rax]	;load u coord
	fdiv	st2	;divide by depth
	fst	dword[vertex_attr+%1*12]	;store in position 1
	fld	dword[r12+rax+4]	;do the same with v coord
	fdiv	st3
	fst	dword[vertex_attr+%1*12+4]
	emms
%endmacro
f_map_texture:
	push	rcx	;push rcx bc its important to stay the same
	sub	rcx, 2	;decrease so it points to value before delimiter
	call	f_get_bounding	;get the bounding box of coords
	cmp	dword[bounding_box+8], 0	;check if xmax is 0 (completely offscreen)
	jl	.end	;if yes, dont process this
	cmp	dword[bounding_box+12], 0	;same but with ymax
	jl	.end
	mov	eax, dword[bounding_box]	;now you load in rax
	inc	rax	;and increase it fsr cant remember why
	cmp	ax, word[window_size+2]	;then check if xmin is larger than screen width
	jge	.end	;then its still not visible
	mov	eax, dword[bounding_box+4]	;same but with ymin
	inc	rax
	cmp	ax, word[available_window]	;this is 3 less than window height
	jge	.end
	call	f_resize_bounding	;resize bounding box to match window
	calc_attr	2	;calculate attributes for vertex 2
	sub	rcx, 2	;decrease pointer to vertex indexes
	calc_attr	1	;attributes for v1
	sub	rcx, 2
	calc_attr	0	;and v0
	xor	rax, rax	;clear upper bytes of rax and rbx
	xor	rbx, rbx
	mov	ebx, dword[bounding_box]	;move in start pos
	mov	eax, dword[bounding_box+4]	;(xmin, ymin)
.loop:
	mov	dword[point], ebx	;set the point coords to rbx and rax
	mov	dword[point+4], eax
	call	f_barycentric_coords	;calc barycentric coords for this point
	cmp	r8, 1	;check if outside of triangle
	jz	.no_draw	;if yes, dont draw this point
	interpolate_uvd	0	;interpolate u
	interpolate_uvd	4	;interpolate v
	interpolate_uvd	8	;interpolate d
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
	push	r13
	lea	r13, [dimensions]	;use dimensions of image here
	lea	r15, [cube_texture]
	call	f_sample_image	;sample uv
	mov	rdi, rax	;move position of sampled data into rdi
	pop	r13
	pop	r15
	pop	rax
	call	f_draw_point	;draw point in correct colour
.no_draw:
	cmp	ebx, dword[bounding_box+8]	;check if x counter is at end of row
	jz	.inc_y	;if yes, increase y
	inc	ebx	;otherwise just increase x
	jmp	.loop	;and keep going
.inc_y:
	cmp	eax, dword[bounding_box+12]	;check if y is at end
	jz	.end	;if yes, done
	inc	eax	;otherwise increase y
	mov	ebx, dword[bounding_box]	;and reset x
	jmp	.loop	;loop over
.end:
	pop	rcx
	ret
f_check_visible:
	push	rax	;push registers used
	push	rbx
	xor	r8, r8	;xor result register
	fldz	;load zero value
	fild	word[window_size+2]	;and the window width
	fld	dword[line_start]	;load start line position X
	fcom	st1	;compare line position X with the window width (if off right)
	fstsw	ax	;store FPU status words
	sahf	;and that
	jae	.offscreen_x	;if its above, its offscreen
	fcom	st2	;then compare with 0
	fstsw	ax	;store status word
	sahf	;load status word
	jb	.offscreen_x	;if its below, its offscreen
	fld	dword[line_end]	;load line end X position
	fcom	st2	;then perform the same checks that u did with start
	fstsw	ax	;except its offset by 1 fpu stack register ofc
	sahf	;now its the same
	jae	.offscreen_x
	fcom	st3
	fstsw	ax
	sahf
	jae	.cont_x
.offscreen_x:
	inc	r8	;increase r8
.cont_x:
	emms
	fldz
	fild	word[available_window]	;now u load window height
	fld	dword[line_start+4]	;and line start Y value
	fcom	st1	;then its again the same comparisons
	fstsw	ax
	sahf
	jae	.offscreen_y
	fcom	st2
	fstsw	ax
	sahf
	jb	.offscreen_y
	fld	dword[line_end+4]	;load line end Y pos instead
	fcom	st2	;same again
	fstsw	ax
	sahf
	jae	.offscreen_y
	fcom	st3
	fstsw	ax
	sahf
	jae	.end
.offscreen_y:
	inc	r8	;increase r8
.end:
	emms	;clear fpu
	pop	rbx	;pop back registers
	pop	rax
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
	lea	r13, [edge_vector_a]	;destination
	call	f_edge_vector	;get edge vector (uses rcx as offset)
	add	rcx, 2	;next line in poly
	lea	r13, [edge_vector_b]	;same same
	call	f_edge_vector
	sub	rcx, 2	;restore value of c
	lea	r15, [edge_vector_a]	;cross product this matrix
	lea	r14, [edge_vector_b]	;with this one
	lea	r13, [cross_product]	;and store here!
	call	f_cross_product
	movzx	r9, word[rsi+rcx]	;moves index of line into r9
	mov	rax, 16	;multiply val
	mul	r9	;multiply together, get offset of first index and result in rax
	fld	dword[camera_position]	;load camera position X
	fld	dword[rdi+rax+4]	;and vertex position X
	fsub	st1	;subtract camera X from vertex X
	fst	dword[edge_vector_a]	;store here
	fld	dword[camera_position+4]	;do the same for other dimensions
	fld	dword[rdi+rax+8]
	fsub	st1
	fst	dword[edge_vector_a+4]
	fld	dword[camera_position+8]
	fabs
	fchs
	fld	dword[rdi+rax+12]
	fsub	st1
	fst	dword[edge_vector_a+8]
	emms	;clear stack
	fld	dword[edge_vector_a]	;load camera vector
	fld	dword[cross_product]	;load the cross product
	fmul	st1	;multiply them together (dot product stage)
	fld	dword[edge_vector_a+4]	;do the same with Y vals
	fld	dword[cross_product+4]
	fmul	st1
	fld	dword[edge_vector_a+8]	;and Z vals
	fld	dword[cross_product+8]
	fmul	st1
	fadd	st2	;then add them all together
	fadd	st4
	fldz	;load zero
	fxch	;swap so the dot product is in st0 and 0 is in st1
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
f_node_screen:
	push	rax	;push registers
	push	rbx	;...
	push	rcx	;..
	push	rdx	;.
	xor	rcx, rcx	;xor register used for screen resetting offset
	mov	rdx, [framebuf]	;load frame buffer
.loop_reset:
	cmp	ecx, dword[screen_size]	;checks if offset is same as screen size in bytes
	jz	.end_reset	;if yes, finished resetting
	cmp	byte[rdx+rcx+TOP_SIZE], 27	;checks if current char is escape
	jnz	.no_set	;if no, dont reset bc its part of ui
	mov	word[rdx+rcx+7+TOP_SIZE], "23"	;otherwise, set the colour of the pixel to black
	mov	byte[rdx+rcx+9+TOP_SIZE], "2"	;232
.no_set:
	add	rcx, 13	;increase rcx by 13 (unit size)
	jmp	.loop_reset	;loop over
.end_reset:
	xor	rcx, rcx	;reset rcx bc its used for screen offset also
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
.line_loop:
	cmp	word[r14+rcx], 65535	;checks if at end of string
	jz	.end	;if yes, done!
	cmp	word[r14+rcx], 65534	;checks if at side separator
	jz	.draw_poly	;if yes, draw the poly here
	add	rcx, 2	;otherwise increase rcx (counter) by 2
	jmp	.line_loop	;and check again
.draw_poly:
	call	f_cull_backfaces	;cull backfaces
	cmp	r8, 0	;if val is 0, then the face isnt valid
	jz	.dont_draw	;if val is 1, then draw the face
	call	f_map_texture
	;mov	rdx, 101
	;call	f_kill
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
	call	f_check_visible	;check if face is visible
	cmp	r8, 2	;if it isnt,
	jz	.dont_draw_1	;go to loop over
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
	call	f_check_visible	;check if face is visible
	cmp	r8, 2
	jz	.dont_draw_2	;if not then yeah
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
f_draw_point:
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
	movzx	rdx, word[rdi]
	mov	word[rcx+rax+7+TOP_SIZE], dx	;and move escapes for color
	movzx	rdx, byte[rdi+2]
	mov	byte[rcx+rax+9+TOP_SIZE], dl	;move colour
	pop	rdx	;....
	pop	rcx	;...
	pop	rbx	;..
	pop	rax	;.
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
	call	f_draw_point	;draw the point
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
f_generate_row:
	push	rax	;help this was so hard to debuggg
	push	rbx
	push	rcx
	mov	dword[r15+rbx-4], r14d	;move the byte to write into first space
.generate_middle:
	cmp	rcx, 2	;checks if rcx (column counter) is 2 (finished middle)
	jz	.end	;if yes, go to end
	mov	dword[r15+rbx], r13d	;else, move in middle counter
	add	rbx, 4	;next space
	dec	rcx	;decrease column counter
	jmp	.generate_middle	;loop over
.end:
	mov	dword[r15+rbx], r12d	;move in end char
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
	push	r15
	add	r15, 4
	mov	rbx, 16
	mul	rbx
	add	r15, rax
	fld	dword[center_coords+8]
	fld	dword[center_coords+4]
	fld	dword[center_coords]
	fld	dword[r15+8]
	fsub	st3
	fld	dword[r15+4]
	fsub	st3
	fld	dword[r15]
	fsub	st3
	fld	dword[operation_multiplier]
	fmul	TO	st1
	fmul	TO	st2
	fmulp	st3
	fadd	st3
	fstp	dword[r15]
	fadd	st3
	fstp	dword[r15+4]
	fadd	st3
	fstp	dword[r15+8]
	emms
	pop	r15
	ret
