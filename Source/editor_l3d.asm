f_map_face:
	cmp	qword[edited_faces_offset], 0
	jz	.ret
	generic_opt_init	9, MAP_FACE_STR
	widget_face	FACE_ID, "[", 0, 0
	add	rax, qword[row_width_editor]
	widget_pos	FACE_U0, DEFAULT_STRING, 1, 0
	widget_pos	FACE_V0, DEFAULT_STRING, 2, 1
	add	rax, qword[row_width_editor]
	widget_pos	FACE_U1, DEFAULT_STRING, 3, 2
	widget_pos	FACE_V1, DEFAULT_STRING, 4, 3
	add	rax, qword[row_width_editor]
	widget_pos	FACE_U2, DEFAULT_STRING, 5, 4
	widget_pos	FACE_V2, DEFAULT_STRING, 6, 5
	add	rax, qword[row_width_editor]
	widget_button	MAP_FACE, 7
	widget_button	DISCARD_UV, 8
	mov	byte[buf1], "-"
	xor	rcx, rcx
	mov	word[option_data_id], 1
	call	f_modify_face
	jmp	.update
.ret:
	ret
.update:
	mov	rax, qword[edited_faces_offset]
	shr	rax, 3
	imul	rax, 24
	
	mov	r14, qword[edited_faces]
	mov	r15, qword[edited_uv]
	mov	rbx, qword[option_data_pos]
	mov	qword[r15+rax], rbx
	
	mov	rbx, qword[option_data_pos+8]
	mov	qword[r15+rax+8], rbx
	
	mov	rbx, qword[option_data_pos+16]
	mov	qword[r15+rax+16], rbx
	
	movzx	rax, word[option_data_id]
	shl	rax, 3
	mov	rbx, qword[r14+rax]
	add	r14, qword[edited_faces_offset]
	mov	qword[r14], rbx
	mov	word[r14+6], 65531
	mov	word[r14+8], 65535
	mov	byte[update], 1
	mov	r15, qword[framebuf]
	ret
.apply:
	mov	r15, qword[edited_faces]
	mov	r14, qword[edited_uv]
	cmp	rcx, 32
	jz	.remove_map
	movzx	rax, word[option_data_id]
	imul	rax, 24
	mov	rbx, qword[edited_faces_offset]
	shr	rbx, 3
	imul	rbx, 24
	mov	rcx, qword[r14+rbx]
	mov	qword[r14+rax], rcx
	mov	rcx, qword[r14+rbx+8]
	mov	qword[r14+rax+8], rcx
	mov	rcx, qword[r14+rbx+16]
	mov	qword[r14+rax+16], rcx
	movzx	rax, word[option_data_id]
	shl	rax, 3
	mov	word[r15+rax+6], 65532
	jmp	.update
.remove_map:
	movzx	rax, word[option_data_id]
	shl	rax, 3
	mov	word[r15+rax+6], 65534
	imul	rax, 3
	mov	qword[r14+rax], 0
	mov	qword[r14+rax+8], 0
	mov	qword[r14+rax+16], 0
	jmp	.update
f_remove_face:
	cmp	qword[edited_faces_offset], 0
	jz	.ret
	generic_opt_init	2, REMOVE_FACE_STR
	widget_face	FACE_ID, "[", 0, 0
	widget_button	REMOVE_FACE, 1
	mov	byte[buf1], "-"
	xor	rcx, rcx
	mov	word[option_data_id], 1
	call	f_modify_face
	jmp	.update
.ret:
	ret
.update:
	movzx	rax, word[option_data_id]
	shl	rax, 3
	mov	r14, qword[edited_faces]
	mov	rbx, qword[r14+rax]
	add	r14, qword[edited_faces_offset]
	mov	qword[r14], rbx
	mov	word[r14+6], 65533
	mov	word[r14+8], 65535
	mov	byte[update], 1
	ret
.apply:
	mov	r15, qword[edited_faces]
	mov	r14, qword[edited_uv]
	movzx	rax, word[option_data_id]
	mov	rdx, rax
	imul	rdx, 24
	mov	rcx, qword[edited_faces_offset]
	sub	rcx, 8
	shl	rax, 3
.loop_move:
	cmp	rax, rcx
	jz	.finish_move
	mov	rbx, qword[r15+rax+8]
	mov	qword[r15+rax], rbx
	mov	rbx, qword[r14+rdx+24]
	mov	qword[r14+rdx], rbx
	mov	rbx, qword[r14+rdx+32]
	mov	qword[r14+rdx+8], rbx
	mov	rbx, qword[r14+rdx+40]
	mov	qword[r14+rdx+16], rbx
	add	rax, 8
	add	rdx, 24
	jmp	.loop_move
.finish_move:
	mov	qword[edited_faces_offset], rcx
	cmp	rcx, 0
	jnz	.dont_esc
	mov	byte[buf1], 27
	mov	byte[buf1+1], 0
	mov	r15, qword[framebuf]
	call	f_editor_binds
	mov	byte[update], 1
	ret
.dont_esc:
	mov	byte[buf1], "-"
	xor	rcx, rcx
	call	f_modify_face
	mov	byte[update], 1
	ret
f_rotate_normal:
	generic_opt_init	9, ROTATE_NORMAL_STR	;normal init
	mov	byte[error_space], 24	;and save the error space
	widget_id	ROTATE_ID, DEFAULT_POINT, 0, 0	;lots of ids here
	widget_id	CENTER_ID, DEFAULT_POINT, 1, 1
	widget_id	VERTEX_1, DEFAULT_POINT, 2, 2	;ids for plane
	widget_id	VERTEX_2, DEFAULT_POINT, 3, 3
	widget_id	VERTEX_3, DEFAULT_POINT, 4, 4
	widget_int	ANGLE, DEFAULT_USTRING, 5, INT_360, 0
	widget_button	ROTATE_POINT, 6
	add	rax, qword[row_width_editor]	;add row now
	widget_box	DUPLICATE_POINT, DEFAULT_OPT, 7	;and checkboxx
	widget_box	USE_SELECTION, DEFAULT_OPT, 8	;and an option to duplicate points
	mov	byte[update], 1
	ret
.update:
	mov	r15, qword[points_dat]	;use this for id offset calc
	mov	r14, qword[edited_faces]	;now go to face end
	add	r14, qword[edited_faces_offset]	;bc ur gonna add one
	%assign	COUNTER	4	;offset id thingy
	%rep	3
		mov	ax, word[option_data_id+COUNTER]	;move in id for face
		call	f_get_id_offset	;get the offset
		push	rcx	;push it
		or	byte[r15+rdx], 0b00000100	;and colour it green
		shr	rdx, 2	;quarter of rdx
		mov	word[r14+COUNTER-4], dx	;then put this at end of faces thing to draw a face
		%assign	COUNTER	COUNTER+2	;and next thing here
	%endrep
	mov	word[r14+COUNTER-4], 65533	;put preview delimiter
	mov	word[r14+COUNTER-2], 65535	;and true faces end
	mov	r14, qword[edited_obj]	;move edited obj addr here
	mov	ax, word[option_data_id+2]	;now get center id offset
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00000100	;make it green also
	movups	xmm6, [r14+rcx]	;save it to xmm6
	cmp	byte[menu_entries+17], 0	;check if selection is needed
	jnz	.select_selection	;if yes go here
	mov	ax, word[option_data_id]	;otherwise get offset for point to move
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00001000	;and colour it purple (normal)
	movups	xmm0, [r14+rcx]	;move it to xmm0
	subps	xmm0, xmm6	;subtract origin
	movups	[dot_products+4], xmm0	;now put it in this matrix
	mov	dword[dot_products], 12	;and its only 3 vals
	mov	dword[dot_products+16], 234356	;delimiter
.finished_point_matrix:
	pop	rcx	;get back edited_obj addr of face points
	mov	r14, qword[edited_obj]	;move the addr for that back
	movups	xmm0, [r14+rcx]	;move v3 in here
	pop	rcx	;pop back rcx
	movups	xmm1, [r14+rcx]	;now move v2 in here
	pop	rcx	;pop again
	movups	xmm2, [r14+rcx]	;now move v1 in here!
	subps	xmm0, xmm1	;get vectors between both
	subps	xmm2, xmm1	;for cross product
	fild	word[option_data_rot]	;load the rotation
	fld	dword[step_angle]	;and degree to radian multiplier
	fmul	st1	;multiply!!!!! to radians.
	fst	dword[buf3]	;store here
	emms
	movaps	[edge_vector_a], xmm0	;load these vectors into these addr
	movaps	[edge_vector_b], xmm2
	lea	r15, [edge_vector_a]	;now, using both vectors
	lea	r14, [edge_vector_b]
	lea	r13, [cross_product+4]	;and storing here,
	call	f_cross_product	;calculate a cross product
	movups	xmm0, [cross_product+4]	;move the result in here
	movaps	xmm1, [simd_zeros]	;and the 0s for comparison
	cmpneqps	xmm0, xmm1	;then compare xmm0 with 0s
	movmskps	eax, xmm0	;and move the bitmask into here
	test	al, 0b00000111	;its big endian, so least 3 bits will be 1 if comparison is true
	jz	.retpoint	;if its 111 then it means that those vals where 0, 0, 0 so return
	mov	dword[cross_product], 12	;length is 3 so put a 12 in the surface normal thing
	mov	dword[cross_product+16], 234356	;and this end thing
	lea	r15, [cross_product]	;now using this axis
	lea	r14, [buf3]	;and this angle
	call	f_rodrigues_rotation	;calculate a rotation matrix for it
	lea	r15, [dot_products]	;ok nowww using the matrix containing points
	lea	r14, [obj_aux_2]	;multiply that by the rodrigues rotation matrrix
	lea	r13, [obj_aux_1]	;and store here
	call	f_multiply_matrix
	cmp	byte[menu_entries+17], 0	;check if selection is on
	jnz	.insert_selection	;if yes, go there
	mov	r15, qword[edited_obj]	;move the points thing here
	add	r15, qword[edited_obj_offset]	;and add offset
	movups	xmm0, [obj_aux_1+4]	;move in multiplication result
	addps	xmm0, xmm6	;add back on origin
	movups	[r15], xmm0	;now save it at end
	mov	dword[r15+12], 0x3F800000	;put a 1.0 also
	mov	dword[r15+16], 234356	;and terminate with this guy
	mov	eax, dword[point_dat_offset]	;now for points_dat stuffs
	mov	r15, qword[points_dat]
	add	r15, rax	;go to end
	mov	byte[r15], 0b00000010	;selection thing
	mov	word[r15+1], "  "	;double space
	mov	byte[r15+3], 0b00000001	;and make it smth to do with smth
.retpoint:
	mov	byte[update], 1
	ret
.select_selection:
	lea	r13, [dot_products]	;use this buffer for stuff
	mov	r12b, 0b00001000	;and this byte to select stuff
	mov	rcx, 12	;column value
	call	f_select_selection	;select from selection and form matrix
	jmp	.finished_point_matrix	;go back to continuation point
.insert_selection:
	lea	r13, [obj_aux_1]	;use this result thingymabob
	mov	rdx, 12	;add column value is 12 again
	call	f_append_selection	;now append this to end
	jmp	.retpoint
.apply:
	clear_error	24	;clears error for error space
	mov	r15, qword[edited_obj]	;and gets end of edited_obj
	add	r15, qword[edited_obj_offset]
	cmp	dword[r15], 234356	;check if no point is being drawn
	jz	f_raise_inval	;if yes then ur ids are wrong
	cmp	word[option_data_id], "!!"	;check if ur trying to change origin
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+15], 0	;and if you have duplicate point off
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+17], 0	;AND if u have use selection off
	jz	f_raise_origin	;if all of the above then raise origin
.dont_raise_origin:
	mov	rdi, 15	;otherwise, use this addr for duplicate id
	mov	rsi, 17	;and this for use selection
	call	f_apply	;and apply the points
	mov	rax, qword[update_func]	;then call update func
	jmp	rax
f_vector_trig:
	generic_opt_init	6, TRIG_MOVE	;you know by now how this works
	mov	byte[error_space], 16
	widget_id	FACE_1, DEFAULT_POINT, 0, 0
	widget_id	FACE_2, DEFAULT_POINT, 1, 1
	widget_id	FACE_3, DEFAULT_POINT, 2, 2
	widget_int	ANGLE, DEFAULT_USTRING, 3, INT_360, 0
	widget_button	APPLY_MOV, 4
	add	rax, qword[row_width_editor]
	widget_box	DUPLICATE_POINT, DEFAULT_OPT, 5	;and checkboxx
	mov	byte[update], 1
	ret
.update:
	mov	r15, qword[points_dat]
	mov	r14, qword[edited_obj]
	mov	ax, word[option_data_id]
	call	f_get_id_offset	;select first id (no selections bc cant be bothered
	movups	xmm0, [r14+rcx]	;move this into this reg for later
	or	byte[r15+rdx], 0b00001000	;first id so select it
	mov	ax, word[option_data_id+2]	;this is the pivot point
	call	f_get_id_offset
	push	rcx	;so push this val
	or	byte[r15+rdx], 0b00000100	;and make it green
	mov	ax, word[option_data_id+4]	;this is right angle point
	call	f_get_id_offset	;get offset for that too
	movups	xmm1, [r14+rcx]	;save it in xmm1
	movaps	xmm4, xmm1	;and also dupe to xmm4 (?)
	or	byte[r15+rdx], 0b00000100	;select that
	mov	byte[update], 1
	mov	r15, qword[edited_obj]
	mov	r14, r15	;clone this thing
	add	r15, rcx	;now add offset for right angle to this
	pop	rcx	;pop back pivot point offset
	add	r14, rcx	;now add it to r14, bc it was cloned
	mov	ax, word[option_data_id]	;checking if id to move is the same as the other points
	cmp	ax, word[option_data_id+2]
	jz	.retpoint	;if yea then stop
	cmp	ax, word[option_data_id+4]
	jz	.retpoint
	call	f_euclidean_distance	;otherwise calculate the euclidean distance between right and pivot point
	fild	word[option_data_rot]	;get the current angle thing
	fld	dword[step_angle]
	fmul	st1
	fptan	;get the tan of it
	fld	dword[vertex_dist]	;and now load euclidean distance
	fmul	st2	;then multiply by the tan
	fst	dword[option_data_pos]	;and store the result (which is right angle to operating point dist) here
	emms
	mov	r15, qword[points_dat]	;now prepare these things
	mov	r14, qword[edited_obj]
	jmp	f_move_along_vec.insert_trig	;and let move along vector do the rest
.apply:
	clear_error	16
	cmp	byte[menu_entries+11], 0	;check if the duplicate option is off
	jz	.dont_dupe	;if yes dontdupe it
	mov	rbx, 1	;otherwise call dupe thingy
	call	f_apply_points
.update_func:
	mov	rax, qword[update_func]	;then call update func
	jmp	rax
.dont_dupe:
	cmp	word[option_data_id], "!!"	;otherwise check if at origin here
	jz	f_raise_origin	;if yes raise origin error (cant move origin)
	mov	r14, qword[edited_obj]	;needed for f_update_points
	mov	r15, qword[points_dat]
	mov	ax, word[option_data_id]	;get offset of id to rotate
	call	f_get_id_offset	;get offset
	mov	rbx, 1	;and only update 1 point
	call	f_update_points	;updateado
	jmp	.update_func
.retpoint:
	ret
f_rotate_axis:
	generic_opt_init	7, ROTATE_AXIS_STR
	mov	byte[error_space], 16
	widget_id	POINT_ID, DEFAULT_POINT, 0, 0	;3 ids
	widget_id	AXIS_A, DEFAULT_POINT, 1, 1
	widget_id	AXIS_B, DEFAULT_POINT, 2, 2
	widget_int	ANGLE, DEFAULT_USTRING, 3, INT_360, 0	;angle
	widget_button	ROTATE_POINT, 4	;button
	add	rax, qword[row_width_editor]
	widget_box	DUPLICATE_POINT, DEFAULT_OPT, 5	;and checkboxx
	widget_box	USE_SELECTION, DEFAULT_OPT, 6	;and an option to duplicate points
	mov	byte[update], 1
	ret
.apply:
	clear_error	16	;generic stuff, has gone over it already
	mov	r15, qword[edited_obj]	;u can understand now
	add	r15, qword[edited_obj_offset]
	cmp	dword[r15], 234356
	jz	f_raise_inval
	cmp	word[option_data_id], "!!"
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+11], 0
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+13], 0
	jz	f_raise_origin
.dont_raise_origin:
	mov	rdi, 11
	mov	rsi, 13
	call	f_apply
	mov	rax, qword[update_func]	;then call update func
	jmp	rax
.update:
	mov	ax, word[option_data_id+2]	;check if preview is invalid
	cmp	ax, word[option_data_id+4]	;bc two points are same pos..
	jz	.invalid_preview	;if yes dont process stuff
	mov	r15, qword[points_dat]	;and move in the data for search thing
	mov	r14, qword[edited_obj]	;and points thing
	mov	r13, qword[edited_faces]
	add	r13, qword[edited_faces_offset]
	mov	ax, word[option_data_id+2]	;and do the same for other 2 ids
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00000100	;except they are green
	shr	rdx, 2
	mov	word[r13], dx
	movups	xmm0, [r14+rcx]	;and store in xmm0
	mov	ax, word[option_data_id+4]
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00000100
	shr	rdx, 2
	mov	word[r13+2], dx
	mov	word[r13+4], dx
	mov	word[r13+6], 65533
	mov	word[r13+8], 65535
	movups	xmm1, [r14+rcx]	;or xmm1
	movups	xmm6, xmm0	;save xmm0 (vector start) to xmm4
	subps	xmm0, xmm1	;get vector / axis
	movups	[edge_vector_a+4], xmm0	;save it here
	movaps	xmm1, [simd_zeros]
	cmpneqps	xmm0, xmm1
	movmskps	eax, xmm0
	test	al, 0b00000111
	jz	.retpoint
	mov	dword[edge_vector_a], 12	;and terminate it properly
	mov	dword[edge_vector_a+16], 234356
	cmp	byte[menu_entries+13], 0
	jnz	.select_selection
	mov	dword[obj_aux_0], 12	;do same for this (point to rotate)
	mov	ax, word[option_data_id]	;move in first id
	call	f_get_id_offset	;get offset
	or	byte[r15+rdx], 0b00001000	;and make first point purple
	movups	xmm0, [r14+rcx]	;save it in this reg
	subps	xmm0, xmm6	;subtract vector start from position (move to 0, 0, 0 p much)
	movups	[obj_aux_0+4], xmm0	;save it here
	mov	dword[obj_aux_0+16], 234356	;then terminate also
.finished_point_matrix:
	mov	eax, dword[point_dat_offset]	;put this in eax first
	add	r15, rax	;then get the end offset
	mov	byte[r15], 0b00000010	;set preview bc its previewing rotation
	mov	word[r15+1], "  "	;blank id..
	mov	byte[r15+3], 0b00000001
	fild	word[option_data_rot]	;load the rotation
	fld	dword[step_angle]	;and degree to radian multiplier
	fmul	st1	;multiply!!!!! to radians.
	fst	dword[buf3]	;store here
	emms
	lea	r15, [edge_vector_a]	;use this vector
	lea	r14, [buf3]	;and this angle
	call	f_rodrigues_rotation	;calculate rotation matrix for it
	lea	r15, [obj_aux_0]	;then, multiply aux_0 (point) by aux_2 (matrix)
	lea	r14, [obj_aux_2]
	lea	r13, [obj_aux_1]	;store here
	call	f_multiply_matrix
	cmp	byte[menu_entries+13], 0
	jnz	.insert_selection
	mov	eax, dword[point_dat_offset]	;put this in eax first
	add	r15, rax	;then get the end offset
	mov	byte[r15], 0b00000010	;set preview bc its previewing rotation
	mov	word[r15+1], "  "	;blank id..
	mov	byte[r15+3], 0b00000001
	mov	r14, qword[edited_obj]	;get end
	add	r14, qword[edited_obj_offset]
	movups	xmm0, [obj_aux_1+4]	;get result
	addps	xmm0, xmm6	;add back on the vector offset
	movups	[r14], xmm0	;save result at end here
	mov	dword[r14+12], 0x3F800000	;and put a 1.0 also dont forget
	mov	dword[r14+16], 234356	;and that thing
.retpoint:
	mov	byte[update], 1
	ret
.select_selection:
	lea	r13, [obj_aux_0]	;this again just prepares stuff for selection
	mov	r12b, 0b00001000	;its mostly the same as move along normal
	mov	rcx, 12
	call	f_select_selection
	jmp	.finished_point_matrix
.insert_selection:
	lea	r13, [obj_aux_1]	;and then again this is mostly the same as before
	mov	rdx, 12
	call	f_append_selection
	jmp	.retpoint
.invalid_preview:
	mov	r14, qword[edited_obj]
	add	r14, qword[edited_obj_offset]
	mov	dword[r14], 234356	;just terminate the thing so it shows nothing
	mov	byte[update], 1
	ret
f_move_along_vec:
	generic_opt_init	6, MOVE_VECTOR_STR
	mov	byte[error_space], 16
	widget_id	POINT_ID, DEFAULT_POINT, 0, 0	;two idsand a distance
	widget_id	VECTOR_A, DEFAULT_POINT, 1, 1
	widget_id	VECTOR_B, DEFAULT_POINT, 2, 2
	widget_pos	MOVE_DIST, DEFAULT_STRING, 3, 0
	widget_button	APPLY_MOV, 4
	add	rax, qword[row_width_editor]
	widget_box	DUPLICATE_POINT, DEFAULT_OPT, 5	;+ a little checkbox
	mov	byte[menu_entries+13], 0
	mov	byte[update], 1
	ret
.apply:
	clear_error	16	;ah cmon now u can figure it
	mov	r15, qword[edited_obj]
	add	r15, qword[edited_obj_offset]
	cmp	dword[r15], 234356	;invalid check
	jz	f_raise_inval
	cmp	word[option_data_id], "!!"	;and origin checks
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+13], 0
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+11], 0
	jz	f_raise_origin
.dont_raise_origin:
	mov	rdi, 11
	mov	rsi, 13
	call	f_apply
	mov	rax, qword[update_func]
	jmp	rax
.update:
	mov	ax, word[option_data_id+2]	;id for point to move
	cmp	ax, word[option_data_id+4]
	jz	.inval_preview
	mov	r14, qword[edited_obj]	;important for saving to xmm
	mov	r15, qword[points_dat]
	call	f_get_id_offset	;get id.....
	movups	xmm0, [r14+rcx]	;then save coords for point to move
	or	byte[r15+rdx], 0b00000100	;and select it with purple 🟣
	shr	rdx, 2
	mov	ax, word[option_data_id]
	call	f_get_id_offset
	movups	xmm4, [r14+rcx]
	or	byte[r15+rdx], 0b00001000
	mov	ax, word[option_data_id+4]	;now do it with vector id
	call	f_get_id_offset
	movups	xmm1, [r14+rcx]	;and save ofc
	or	byte[r15+rdx], 0b00000100	;then select with green 🟢
.insert_trig:
	mov	eax, dword[point_dat_offset]	;okay now put offset in here
	mov	byte[r15+rax], 0b00000010	;and set last point as a preview
	mov	word[r15+rax+1], "  "	;clear the id!
	mov	byte[r15+rax+3], 0b00000001
	add	r14, qword[edited_obj_offset]	;get full offset of this
	subps	xmm1, xmm0	;get vector now
	movaps	xmm5, xmm1
	movaps	xmm6, [simd_zeros]
	cmpneqps	xmm5, xmm6
	movmskps	eax, xmm5
	test	al, 0b00000111
	jz	.retpoint
	movaps	xmm2, xmm1	;then duplicate it to xmm2
	mulps	xmm1, xmm2	;square xmm1 p much
	shufps	xmm3, xmm1, 0b00000010	;duplicate the 3rd val to xmm3
	haddps	xmm1, xmm1	;horizontal add xmm1 (first val = v1+v2)
	addss	xmm1, xmm3	;add v1+v2 to v3, which is in xmm3
	movss	dword[buf4], xmm1
	fld	dword[buf4]
	fabs
	fsqrt
	fst	dword[buf4]
	movss	xmm1, dword[buf4]
	shufps	xmm1, xmm1, 0b00000000	;then duplicate it accross the register
	divps	xmm2, xmm1	;divide the vector by the square root!
	movups	xmm1, [option_data_pos]	;move in position to use
	shufps	xmm1, xmm1, 0b00000000	;put it in every place in register
	mulps	xmm1, xmm2	;multiply vals together
	addps	xmm4, xmm1	;and then add to the original position of the point
	movups	[r14], xmm4	;then put in the edited_obj thing
	mov	dword[r14+12], 0x3F800000	;terminate with 1.0 for normalising
	mov	dword[r14+16], 234356	;and a... thing
.retpoint:
	mov	byte[update], 1
	ret
.inval_preview:
	mov	r15, qword[edited_obj]	;offst and such
	add	r15, qword[edited_obj_offset]
	mov	dword[r15], 234356	;terminate it properly
	mov	byte[update], 1
	ret
f_create_selection:
	generic_opt_init	4, POINT_SELECTION_STR
	mov	byte[error_space], 12
	widget_id	POINT_ID, DEFAULT_POINT, 0, 0	;id for point to add/sub from selection
	widget_button	SELECTION_ADD, 1	;and 2 buttons
	widget_button	SELECTION_SUB, 2
	widget_button	SELECTION_CLR, 3
	mov	byte[update], 1	;force update
	ret
.apply:
	clear_error	12	;clear current error
	mov	ax, word[option_data_id]	;move in the current id
	cmp	rcx, 12
	jnz	.not_clear
	mov	al, byte[selection_length]
	xor	rcx, rcx
	mov	r15, qword[points_dat]
.deselect:
	cmp	al, 0
	jz	.finish_deselect
	dec	al
	mov	edx, dword[selection+rcx]
	sub	edx, 4
	shr	edx, 2
	mov	byte[r15+rdx], 0b00000000
	add	rcx, 4
	jmp	.deselect
.finish_deselect:
	mov	byte[selection_length], 0
	jmp	.retpoint
.not_clear:
	cmp	rcx, 8	;check if remove button used
	jz	.remove_selection	;if yea remove
	cmp	ax, "!!"	;check if its origin
	jz	f_raise_origin	;if yes do nothing / raise error
	mov	r15, qword[points_dat]	;move in addr for point data
	call	f_get_id_offset	;get offset of current thing (uses rcx for selection)
	movzx	rax, byte[selection_length]	;move length here
	xor	rbx, rbx	;reset this counter
.loop_check_repeats:
	cmp	rax, 0	;check if finished checking for dupes
	jz	.checked_dupes	;if yes go here
	cmp	ecx, dword[selection+rbx]	;otherwise compare it with current val
	jz	f_raise_dupe	;if yes raise dupe error
	add	rbx, 4	;otherwise go check next value
	dec	rax	;use counter correctly
	jmp	.loop_check_repeats	;loop
.checked_dupes:
	movzx	rax, byte[selection_length]	;move length back here
	shl	rax, 2	;multiply by 4
	mov	dword[selection+rax], ecx	;move addr into end
	inc	byte[selection_length]	;increase selection length
.retpoint:
	mov	r15, qword[framebuf]
	mov	rax, qword[bbar_items.selection]
	movzx	rbx, byte[selection_length]
	call	f_modify_ascii
	mov	rax, qword[update_func]	;jump to update function
	jmp	rax
.remove_selection:
	mov	r15, qword[points_dat]
	call	f_get_id_offset	;get id offset for removing point
	movzx	rax, byte[selection_length]	;move selection length in here to iterate over
	xor	rbx, rbx	;reset counter for selection
.loop_check_present:
	cmp	rax, 0	;check if at end (not matched)
	jz	f_raise_not_selected	;if yes raise not selected error
	cmp	ecx, dword[selection+rbx]	;otherwise compare given offset with current point
	jz	.remove_point	;if its a match remove it
	dec	rax	;otherwise decrease rax
	add	rbx, 4	;go to next dword
	jmp	.loop_check_present	;and loop
.remove_point:
	mov	edx, dword[selection+rbx+4]	;then, move in next dword
	mov	dword[selection+rbx], edx	;and overwrite dword to be removed
	add	rbx, 4	;go to next pair
	dec	rax	;decrease rax again
	jz	.removed_point	;if its 0 u have removed the point
	jmp	.remove_point	;otherwise keep on shifting dwords
.removed_point:
	dec	byte[selection_length]	;decrease selection length
	jmp	.retpoint
.update:
	mov	ax, word[option_data_id]	;move in current id
	mov	r15, qword[points_dat]	;and point data
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00001000	;or current selection (make it purple)
	mov	byte[update], 1	;force update
	movzx	rax, byte[selection_length]	;move selection length here
	xor	rbx, rbx	;reset counter
.loop_select:
	cmp	rax, 0	;same as one in update
	jz	.end_select
	mov	edx, dword[selection+rbx]	;except this time it gets the current offset
	sub	rdx, 4	;converts it to format for points_dat
	shr	rdx, 2
	or	dword[r15+rdx], 0b00000100	;and selects it at  this offset
	dec	rax	;then moves on
	add	rbx, 4
	jmp	.loop_select	;and loop
.end_select:
	ret
f_rotate_point:
	generic_opt_init	8, ROTATE_POINT_STR
	mov	byte[error_space], 8
	widget_id	ROTATE_ID, DEFAULT_POINT, 0, 0	;two ids
	widget_id	CENTER_ID, DEFAULT_POINT, 1, 1
	widget_int	ROTATE_YAW, DEFAULT_USTRING, 2, INT_360, 0	;three angles
	widget_int	ROTATE_PITCH, DEFAULT_USTRING, 3, INT_360, 1
	widget_int	ROTATE_ROLL, DEFAULT_USTRING, 4, INT_360, 2
	widget_button	ROTATE_POINT, 5	;and a button
	add	rax, qword[row_width_editor]	;new row
	widget_box	DUPLICATE_POINT, DEFAULT_OPT, 6	;and an option to duplicate points
	widget_box	USE_SELECTION, DEFAULT_OPT, 7	;and an option to duplicate points
	mov	byte[update], 1
	ret
.update:
	mov	ax, word[option_data_id]	;move in current id
	mov	r15, qword[points_dat]	;and this thing for id offset
	mov	r14, qword[edited_obj]	;and this for later
	cmp	byte[menu_entries+15], 0
	jnz	.select_selection
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00001000	;select current id
	movups	xmm0, [r14+rcx]	;save coords of current id
	mov	ax, word[option_data_id+2]	;move in center id
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00000100	;select it with different colour
	movups	xmm1, [r14+rcx]	;move its coords here
	subps	xmm0, xmm1	;make the centerpoint 0, 0, 0 p much
	mov	dword[obj_aux_1], 16	;move in matrix len into this buffer
	movups	[obj_aux_1+4], xmm0	;and coords
	mov	dword[obj_aux_1+16], 0x3F800000 ;and 1.0 just in case
	mov	dword[obj_aux_1+20], 234356	;and end
.convert_angles:
	%assign	COUNTER	0
	%rep	3
		fld	dword[step_angle]	;1 degree in radians
		fild	word[option_data_rot+COUNTER]	;amount of degrees
		fmul	st1
		fst	dword[operation_angle+(COUNTER << 1)]	;store here for rotating
		%assign	COUNTER	COUNTER+2	;do same with other angles
	%endrep
	emms
	lea	r15, [operation_angle]	;angle 1
	call	f_rotate_matrix_y	;generate yaw rotation thing
	lea	r15, [operation_angle+4]	;and same with others
	call	f_rotate_matrix_x
	lea	r15, [operation_angle+8]
	call	f_rotate_matrix_z
	lea	r15, [obj_aux_1]	;then multiply them all by each other
	lea	r14, [matrix_rotation_y]	;so it rotates it by specified angles
	lea	r13, [obj_aux_2]
	call	f_multiply_matrix
	lea	r15, [obj_aux_2]
	lea	r14, [matrix_rotation_x]
	lea	r13, [obj_aux_1]
	call	f_multiply_matrix
	lea	r15, [obj_aux_1]
	lea	r14, [matrix_rotation_z]
	lea	r13, [obj_aux_2]
	call	f_multiply_matrix
	cmp	byte[menu_entries+15], 0
	jnz	.preview_selection
	mov	r15, qword[edited_obj]	;use this in here
	mov	rax, qword[edited_obj_offset]	;and an offset
	movups	xmm0, [obj_aux_2+4]	;store the new rotated coords in here
	addps	xmm0, xmm1	;add back to origin vals
	movups	[r15+rax], xmm0	;then store in end of the points list
	mov	dword[r15+rax+12], 0x3F800000	;insert ending 1.0
	mov	dword[r15+rax+16], 234356	;and the delimiter
	mov	r15, qword[points_dat]	;then,
	mov	eax, dword[point_dat_offset]
	mov	byte[r15+rax], 0b00000010	;make this a preview point
	mov	word[r15+rax+1], "  "	;with blank id ofc
	mov	byte[r15+rax+3], 0b00000001
	mov	byte[update], 1	;force update
	ret
.select_selection:
	mov	ax, word[option_data_id+2]	;move in center id
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00000100	;select it with different colour
	movups	xmm6, [r14+rcx]	;save center id to xmm6
	lea	r13, [obj_aux_1]
	mov	r12b, 0b00001000
	mov	rcx, 16
	call	f_select_selection
	jmp	.convert_angles	;continue normally
.preview_selection:
	mov	rdx, 16
	lea	r13, [obj_aux_2]
	call	f_append_selection
	mov	byte[update], 1	;and update
	ret
.apply:
	clear_error	20	;but whatever
	mov	rcx, 20
	cmp	word[option_data_id], "!!"
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+15], 0
	jnz	.dont_raise_origin
	cmp	byte[menu_entries+13], 0
	jz	f_raise_origin
.dont_raise_origin:
	mov	rdi, 13
	mov	rsi, 15
	call	f_apply
	mov	rax, qword[update_func]
	jmp	rax
f_remove_point:
	generic_opt_init	2, REMOVE_POINT_STR
	mov	byte[error_space], 4
	widget_id	POINT_ID, DEFAULT_POINT, 0, 0	;just an id selector
	widget_button	REMOVE_POINT, 1	;and a button
	mov	byte[update], 1
	ret
.update:
	mov	r15, qword[points_dat]	;easy as pie
	mov	ax, word[option_data_id]	;it just selects the point
	call	f_get_id_offset
	or	byte[r15+rdx], 0b00000100	;ez
	mov	byte[update], 1
	ret
.apply:
	movzx	rcx, word[selected_option]	;now this is impossible gl
	clear_error	4
	cmp	word[option_data_id], "!!"
	jz	f_raise_origin
	mov	r15, qword[points_dat]	;points data
	mov	eax, dword[point_dat_offset]	;and offset
	sub	eax, 8	;subtract 8 to get the second to last point
	mov	bx, word[r15+rax+1]	;move in id from that
	mov	word[max_id], bx	;and set it to max id
	mov	ax, word[option_data_id]	;move current id into rax
	call	f_get_id_offset	;and get offset of it
	mov	r12, rcx
	push	rdx	;push this bc its used in point remapping
	mov	r14, qword[edited_faces]	;use faces struct
	shr	rdx, 2	;quarter of rdx = face index
	mov	r8b, byte[selection_length]
	xor	r9, r9
	xor	r10, r10
.loop_correct_selection:
	cmp	r8b, 0
	jz	.loop_faces_cull
	mov	r11d, dword[selection+r10]
	mov	dword[selection+r9], r11d
	cmp	r11d, r12d
	jz	.delete_selection
	jb	.continue_selection
	sub	dword[selection+r9], 16
.continue_selection:
	dec	r8b
	add	r9, 4
	add	r10, 4
	jmp	.loop_correct_selection
.delete_selection:
	dec	r8b
	dec	byte[selection_length]
	add	r10, 4
	jmp	.continue_selection
.loop_faces_cull:
	cmp	word[r14], 65535	;check if current thingy is at end
	jz	.end_faces_cull	;if yes finished culling faces contianing deleted id
	cmp	word[r14], dx	;otherwise, compare first word against deleted id
	ja	.above_a	;if its above, go here
	jz	.delete_face	;if its equal delete the face entirely
.ret_a:
	cmp	word[r14+2], dx	;same but with 2nd
	ja	.above_b
	jz	.delete_face
.ret_b:
	cmp	word[r14+4], dx	;and then 3rd words
	ja	.above_c
	jz	.delete_face
.ret_c:
	add	r14, 8	;if it passed all these checks then go to next face
	jmp	.loop_faces_cull	;and loop
.above_a:
	dec	word[r14]	;it just decreases ids to make up for the id deletion
	jmp	.ret_a
.above_b:
	dec	word[r14+2]	;same here
	jmp	.ret_b
.above_c:
	dec	word[r14+4]
	jmp	.ret_c
.delete_face:
	mov	qword[r14], 0	;just zero the entire face
	sub	qword[edited_faces_offset], 8	;and adjust offset
	jmp	.ret_c
.end_faces_cull:
	mov	r14, qword[edited_faces]	;restore base r14
.loop_faces_shift:
	cmp	word[r14], 65535	;check if at end
	jz	.end_faces	;if yes, go to end!
	cmp	qword[r14], 0	;check if at culled face
	jz	.shift_face	;if yes shift over next face to fill gap
	add	r14, 8	;else go to next face
	jmp	.loop_faces_shift	;and loop over
.shift_face:
	push	r14	;store r14 addr
.loop_shift_face:
	add	r14, 8	;go to next face bc first one is def 0
	cmp	qword[r14], 0	;check if at 0 byte
	jnz	.move_face	;if no then move over face to the blank
	jmp	.loop_shift_face	;otherwise keep looking
.move_face:
	mov	rax, qword[r14]	;move the face into rax
	mov	qword[r14], 0	;and zero the face in the array (prevent duplicate faces)
	pop	r14	;pop back r14
	mov	qword[r14], rax	;then move it into the blank space!
	cmp	dword[r14], 65535	;check if its a 65535
	jz	.end_faces	;if yes then ur done
	add	r14, 8	;otherwise add 8 and
	jmp	.loop_faces_shift	;keep checking for blanks
.end_faces:
	pop	rdx	;get back current point offset for points_dat
	mov	r14, qword[edited_obj]	;use edited_obj here to remove points also
.loop:
	cmp	dword[r14+rcx+16], 234356	;check if at end
	jz	.end	;if yes then,,,, who knows?
	movups	xmm0, [r14+rcx+16]	;move entire point into here
	movups	[r14+rcx], xmm0	;and then store it in previous points position (shift faces)
	mov	al, byte[r15+rdx+4]	;store the next info byte in al
	mov	byte[r15+rdx], al	;and shift it left
	add	rcx, 16	;go to next point
	add	rdx, 4	;and point data thing
	jmp	.loop	;loop overrr
.end:
	mov	dword[r14+rcx], 234356	;terminate points thingy
	sub	qword[edited_obj_offset], 16	;and correct offsets
	sub	dword[point_dat_offset], 4	;for these things	
	mov	rcx, 0
	mov	byte[buf1], "-"
	call	f_modify_id
	ret
f_new_face:
	generic_opt_init	4, ADD_FACE_STR
	mov	byte[error_space], 12
	widget_id	FACE_1, DEFAULT_POINT, 0, 0	;three id selectors
	widget_id	FACE_2, DEFAULT_POINT, 1, 1
	widget_id	FACE_3, DEFAULT_POINT, 2, 2
	widget_button	ADD_FACE, 3	;and a button
	mov	byte[update], 1
	ret
.update:
	mov	r14, qword[edited_faces]	;move this here
	add	r14, qword[edited_faces_offset]	;and add offset
	mov	r15, qword[points_dat]	;and this is at base for id offset thing
	%assign	COUNTER	0
	%rep	3
		movzx	rax, word[option_data_id+COUNTER]	;move in word here
		call	f_get_id_offset	;and get offset
		or	byte[r15+rdx], 0b00000100	;select it!
		shr	rdx, 2	;get point index by div by 4
		mov	word[r14+COUNTER], dx	;store in face thing
		%assign	COUNTER	COUNTER+2	;do next id
	%endrep
	mov	word[r14+6], 65533	;then preview delimiter
	mov	word[r14+8], 65535	;+full delimiter
	mov	byte[update], 1
	ret
.apply:
	movzx	rcx, word[selected_option]
	clear_error	12
	cmp	word[option_data_id], "!!"	;check if any values are origin
	jz	f_raise_origin	;if they are raise origin error
	cmp	word[option_data_id+2], "!!"
	jz	f_raise_origin
	cmp	word[option_data_id+4], "!!"
	jz	f_raise_origin
	mov	eax, dword[option_data_id]	;move in first 2 words
	mov	dword[option_data_id+6], eax	;save it at end here, itsto make next bit work
	%assign	COUNTER	0
	%rep	3
		mov	ax, word[option_data_id+COUNTER]	;move id in here
		cmp	ax, word[option_data_id+COUNTER+2]	;and compare it to next id
		jz	f_raise_dupe	;if they arethe same its adupe
		cmp	ax, word[option_data_id+COUNTER+4]	;check with second id after
		jz	f_raise_dupe	;same
		%assign	COUNTER	COUNTER+2
	%endrep
	mov	r15, qword[edited_faces]	;if no dupes, get offset here
	add	r15, qword[edited_faces_offset]	;of end
	mov	word[r15+6], 65534	;then delimit it with permeanant face
	add	qword[edited_faces_offset], 8	;correct face offset
	mov	byte[update], 1
	ret
f_new_point:
	generic_opt_init	5, ADD_POINT_STR
	widget_pos	POINT_X, DEFAULT_STRING, 0, 0	;3 positioncounters
	widget_pos	POINT_Y, DEFAULT_STRING, 1, 1
	widget_pos	POINT_Z, DEFAULT_STRING, 2, 2
	widget_id	RELATIVE_POINT, DEFAULT_POINT, 3, 0	;and 1 id
	widget_button	INSERT_POINT, 4	;and final button thing
	mov	byte[update], 1
	ret
.apply:
	mov	rbx, 1
	call	f_apply_points
	mov	rax, qword[update_func]
	jmp	rax
.update:
	mov	ax, word[option_data_id]	;move in current id
	mov	r15, qword[points_dat]	;and thing
	call	f_get_id_offset	;get offset
	or	byte[r15+rdx], 0b00000100	;select the rpoint
	mov	r15, qword[edited_obj]	;move this hting for applying coords
	movups	xmm1, [r15+rcx]	;save coords of rpoint here
	mov	rax, qword[edited_obj]	;offset for points end
	add	rax, qword[edited_obj_offset]
	movups	xmm0, [option_data_pos]	;move positions to change by here
	addps	xmm0, xmm1	;add together for relative point
	movups	[rax], xmm0	;save at end
	mov	dword[rax+12], 0x3F800000	;and set 1.0 thing
	mov	dword[rax+16], 234356	;end of thing!!
	mov	byte[update], 1	;force update here fsr
	mov	eax, dword[point_dat_offset]	;offsetttttt
	add	rax, qword[points_dat]
	mov	byte[rax], 0b00000010	;preview this thing
	mov	word[rax+1], "  "
	mov	byte[rax+3], 0b00000001
	ret
f_raise_origin:
	movzx	rcx, byte[error_space]	;various error msgs
	mov	r15, qword[framebuf]	;not much to say
	raise_error	rcx, "NO_ORIGIN"
	ret
f_raise_inval:
	movzx	rcx, byte[error_space]
	mov	r15, qword[framebuf]
	raise_error	rcx, "INVALID_IDS"
	ret
f_raise_dupe:
	movzx	rcx, byte[error_space]
	mov	r15, qword[framebuf]
	raise_error	rcx, "DUPLICATE_VALUES"
	ret
f_raise_not_selected:
	movzx	rcx, byte[error_space]
	mov	r15, qword[framebuf]
	raise_error	rcx, "NOT_SELECTED"
	ret
