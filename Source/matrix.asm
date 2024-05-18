f_multiply_matrix:
	push	rax	;push multiplication register
	push	rbx	;push register used for matrix A offset
	push	rcx ;push register used for matrix B offset
	push	rdx ;push register used for matrix C offset
	push	rdi	;push register used for counting
	push	r12	;push register used for matrix A end calculation
	mov	rbx, 4	;reset all offset registers
	xor	rcx, rcx	;...
	xor	rdx, rdx	;..
	mov	r12, 4	;.
	mov	edi, dword[r15]	;move matrix A column value (and matrix B row value) into rdi
	mov	esi, dword[r14]	;move matrix B column value into rsi
	mov	dword[r13], esi	;moves matrix B column value into matrix C column value (inherited)
.loop_matrix_a:
	cmp	dword[r15+r12], 234356	;checks if at end of struct
	jz	.end_matrix_a	;if yes, finished multiplying matrix
	add	r12, rdi	;if no, add on matrix A column value (next line) to position counter
	push	rsi	;push matrix B column value, as it is iterated over
.loop_matrix_b:
	cmp	esi, 0	;checks if reached end of columns
	jz	.end_matrix_b	;if yes, finished one interation over matrix B columns
	sub	esi, 4	;if no, subtract one dword from rsi
	add	rcx, 4	;add one dword to matrix B column counter (next column)
	add	rdx, 4	;add one dword to matrix C position counter
	fldz
	fst	dword[r13+rdx]
	push	rdi	;push rdi (matrix A column value), as it is iterated over
	push	rbx	;push rbx (matrix A offset)
	push	rcx	;push rcx (matrix B offset)
.loop_multiply:
	cmp	edi, 0	;check if finished iterating over rows / columns (they are the same number!)
	jz	.end_multiply	;if yes, finished multiplying for this current value in matrix C
	fld	dword[r15+rbx]	;load matrix A value
	fld	dword[r14+rcx]	;load matrix B value
	fmul	st1	;multiply them by each other
	fld	dword[r13+rdx]	;load matrix C value
	fadd	st1	;add multiplied matrix value to matrix C place
	fst	dword[r13+rdx]	;store back in matrix C
	emms	;all registers free
	add	rbx, 4	;adds matrix item size in bytes to matrix A position counter
	add	ecx, dword[r14]	;adds matrix B row length in bytes to matrix B position counter
	sub	edi, 4	;subtract one dword from rdi
	jmp	.loop_multiply	;and start over..
.end_multiply:
	pop	rcx	;pop back matrix B offset
	pop	rbx	;pop back matrix A offset
	pop	rdi	;pop back matrix A column value
	jmp	.loop_matrix_b	;go back to looping over columns in matrix B
.end_matrix_b:
	pop	rsi	;pop back rsi (matrix B column counter)
	add	rbx, rdi	;add matrix A column value to matrix A offset (next row)
	xor	rcx, rcx	;reset matrix B offset (back to column 0)
	jmp	.loop_matrix_a	;go to next row in matrix A
.end_matrix_a:
	mov	dword[r13+rdx+4], 234356
	pop	r12	;pop back offset registers
	pop	rdi	;.....
	pop	rdx	;....
	pop	rcx	;...
	pop	rbx	;..
	pop	rax	;.
	ret
f_normalise_matrix:
	;!!!NOTE!!! normalised z coord is calculated
	;and un-normalised is stored in an ndc matrix!!
	mov	dword[r15], 16
	push	rbx	;push used register
	xor	rbx, rbx	;reset rax
.loop:
	cmp	dword[r15+rbx+4], 234356	;check if at end of matrix
	jz	.end	;if yes, go to end
	add	rbx, 16	;otherwise add column length to rax (next row)
	fld	dword[r15+rbx]	;load W value
	fld	dword[r15+rbx-4]	;load z value
	fst	dword[matrix_ndc+rbx-4]	;store non-normalised val
	fdiv	st1	;divide z by W
	fst	dword[r15+rbx-4]	;store new value
	fld1
	fcomi	st1
	jb	.clip
	fchs
	fcomi	st1
	ja	.clip
	fld	dword[r15+rbx-8]	;load Y value
	fdiv	st3	;divide Y by W
	fst	dword[r15+rbx-8]	;store new value
	fld	dword[r15+rbx-12]	;load X value
	fdiv	st4	;divide X by W
	fst	dword[r15+rbx-12]	;store new value
	fld1	;load value of 1
	fst	dword[r15+rbx]	;store in W value
	emms	;reset
	jmp	.loop	;loop over
.end:
	pop	rbx	;pop back register
	ret
.clip:
	mov	dword[r15], 0
	pop	rbx
	ret
f_camera_rotation_matrix:
	mov eax, dword[matrix_right+4]	;this code generates the camera matrix
	mov	dword[matrix_camera_rotate+4], eax	;its pretty boring and repetitive
	mov eax, dword[matrix_right+8]	;bc it just moves memory in other locations into others
	mov	dword[matrix_camera_rotate+20], eax	;blah blah blah
	mov eax, dword[matrix_right+12]
	mov	dword[matrix_camera_rotate+36], eax
	mov eax, dword[matrix_up+4]
	mov	dword[matrix_camera_rotate+8], eax
	mov eax, dword[matrix_up+8]
	mov	dword[matrix_camera_rotate+24], eax
	mov eax, dword[matrix_up+12]
	mov	dword[matrix_camera_rotate+40], eax
	mov eax, dword[matrix_fwd+4]
	mov	dword[matrix_camera_rotate+12], eax
	mov eax, dword[matrix_fwd+8]
	mov	dword[matrix_camera_rotate+28], eax
	mov eax, dword[matrix_fwd+12]
	mov	dword[matrix_camera_rotate+44], eax
	ret
f_copy_matrix:
	xor	rbx, rbx	;crazy complex insane code
	xor	rax, rax
	mov	eax, dword[r15]
	mov	dword[r14], eax
	add	rbx, 4
.loop:
	cmp	dword[r15+rbx], 234356
	jz	.end
	movups	xmm0, [r15+rbx]
	movups	[r14+rbx], xmm0
	jz	.end
	add	rbx, rax
	jmp	.loop
.end:
	mov	dword[r14+rbx], 234356
	ret
f_translation_matrix:
	mov	eax, dword[translation]	;wow how could this work 🤔🤔 
	mov	dword[matrix_translate+52], eax
	mov	eax, dword[translation+4]
	mov	dword[matrix_translate+56], eax
	mov	eax, dword[translation+8]
	mov	dword[matrix_translate+60], eax
	ret
f_rotate_matrix_x:
	fld	dword[r15]	;loads the angle to rotate by
	fsincos	;gets sin and cos value of the angle bc its in st0
	fst	dword[matrix_rotation_x+24]	;store the cos in the location needed
	fstp	dword[matrix_rotation_x+44]	;store that in another location and pop the stack so sin is in st0
	fst	dword[matrix_rotation_x+28]	;put the sin value in correct place
	fchs	;negate that
	fst	dword[matrix_rotation_x+40]	;and place in other location
	emms
	ret
f_rotate_matrix_y:
	fld	dword[r15]	;same as above mostly
	fsincos	;but with different destination addrs
	fst	dword[matrix_rotation_y+44]
	fstp	dword[matrix_rotation_y+4]
	fst	dword[matrix_rotation_y+36]
	fchs
	fst	dword[matrix_rotation_y+12]
	emms
	ret
f_rotate_matrix_z:
	fld	dword[r15]	;yep
	fsincos
	fst	dword[matrix_rotation_z+4]
	fstp	dword[matrix_rotation_z+24]
	fst	dword[matrix_rotation_z+8]
	fchs
	fst	dword[matrix_rotation_z+20]
	emms
	ret
f_screen_matrix:
	mov	rax, r14	;load window width val
	shr	rax, 1	;diide it by 2, not accounting for floats
	mov	dword[buf1], eax	;move this value into first buffer
	fild	dword[buf1]	;loads onto fpu stack
	fst	dword[matrix_screen+4]	;and store
	fst	dword[matrix_screen+52]	;in places needed
	mov	rax, r15	;load window width val
	shr	rax, 1	;half it without accounting for floats
	mov	dword[buf1], eax	;move into buffer 1
	fild	dword[buf1]	;load it onto FPU stack
	fst	dword[matrix_screen+56]	;store in place needed
	fchs	;negate value
	fst	dword[matrix_screen+24]	;and store again
	emms	;all registers free
	ret
f_projection_matrix:
	fild	dword[two]	;push the value of 2 onto fpu stack (integer)
	fld	dword[camera_h_fov]	;push the camera h fov to fpu stack (its a float!)
	fdiv	st1	;divide h fov by 2
	fptan	;get tangeant of that value (in st0)
	fxch	;swap around st1 and st0 bc what u want is in st1
	fld	st0	;pushes st0 onto fpu stack (duplicate)
	fadd	st1	;adds st0 to st1 (multiplied original tangeant by 2)
	fdivr	st3	;divide 2 (which is now in st3) by doubled tangeant
	fstp	dword[matrix_projection+4]	;moves result into m00 place
	fxch	st2	;swap st2 (2) and st0
	fld	dword[camera_v_fov]	;do the same thing as above but again
	fdiv	st1	;except this time u dont have to load two back
	fptan	;because its still on the stack from last time!
	fxch	;now its just the same as before
	fld	st0	
	fadd	st1
	fdivr	st3
	fstp	dword[matrix_projection+24]	;use 24 here bc thats m11 place
	emms	;mark everything as unused
	fld	dword[camera_near_plane]	;push near plane into fpu stack
	fld	dword[camera_far_plane]	;push far plane into fpu stack
	fsubr	TO st1	;subtract st1 from st0 and store result in st1
	fld	dword[camera_near_plane]	;push near plane into fpu stack
	fadd	st1	;add st0 to st1 (near plane)
	fdiv	st2	;divide far + near with far - near
	fst	dword[matrix_projection+44]	;use 44 here bc thats m22 place
	fld	dword[camera_near_plane]	;push near plane
	fild	dword[two]	;push the number 2 (two)
	fchs	;change sign bit
	fmul	st1	;multiply -2 by st1 (near plane)
	fmul	st3	;multiply that by st3 (far plane from m22)
	fdiv	st4	;divide that by far - near (was computed in m22)
	fst	dword[matrix_projection+60]	;use 60 here bc thats m32 place
	emms	;mark everything as unused for next time the fpu is needed
	ret
f_camera_translation_matrix:
	fld	dword[camera_position]	;this just loads the camera pos
	fchs	;inverts it
	fst	dword[matrix_camera_translate+52]	;and then puts it into the translation matrix
	fld	dword[camera_position+4]
	fchs
	fst	dword[matrix_camera_translate+56]
	fld	dword[camera_position+8]
	fchs
	fst	dword[matrix_camera_translate+60]
	emms
	ret
f_update_camera_axis:
	lea	r15, [camera_pitch]	;generate rotation matrix for camera x
	call	f_rotate_matrix_x	;yes
	lea	r15, [camera_yaw]	;and camera y (which uses yaw)
	call	f_rotate_matrix_y
	lea	r15, [matrix_rotation_x]	;use rotation_x
	lea	r14, [matrix_rotation_y]	;and rotation_y
	lea	r13, [obj_aux_1]	;store in this buffer
	call	f_multiply_matrix	;and multiply them together
	lea	r15, [matrix_fwd_2]	;multiply blank fwd matrix
	lea	r14, [obj_aux_1]	;by multiplied rotation matrix
	lea	r13, [matrix_fwd]	;and store in original one
	call	f_multiply_matrix	;go
	lea	r15, [matrix_up_2]	;do the same for the other ones
	lea	r14, [obj_aux_1]
	lea	r13, [matrix_up]
	call	f_multiply_matrix
	lea	r15, [matrix_right_2]
	lea	r14, [obj_aux_1]
	lea	r13, [matrix_right]
	call	f_multiply_matrix
	ret
