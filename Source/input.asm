%macro	test_arrows	5
	cmp	%5, "[A"
	jz	%1
	cmp	%5, "[B"
	jz	%2
	cmp	%5, "[D"
	jz	%3
	cmp	%5, "[C"
	jz	%4
%endmacro
f_input_cases:
	xor	rcx, rcx	;xor register thats used for storing keys ui memory
	mov	rax, [poll]	;move addr of polling space into rax
	cmp	byte[rax], 0	;check if the first character is 0 (no input)
	jnz	.input	;if not, check input
	ret	;otherwise, do nothing
.input:
	cmp	byte[editor], 0
	jnz	.input_editor
	mov	rbx, [framebuf]	;move the frame buffer space into rbx for later
	cmp	byte[rax], 27	;checks if byte of polling space is 27
	jz	.escape	;if yes, escape sequence (arrows)
	cmp	byte[paused], 0	;if paused dont process movement
	jnz	.ret
	cmp	byte[rax], "w"	;check if byte is w
	jz	case_w	;if yes, go to the w case
	cmp	byte[rax], "s"	;do this for every key there is to grab
	jz	case_s
	cmp	byte[rax], "a"
	jz	case_a
	cmp	byte[rax], "d"
	jz	case_d
	cmp	byte[rax], "q"
	jz	case_q
	cmp	byte[rax], "e"
	jz	case_e
.ret:
	ret
.input_editor:
	mov	byte[update+1], 1	;remember to update camera matrices also reminder
	cmp	byte[rax], 27	;check escapes
	jz	.escape_editor	;and normal keys after its easy
	cmp	byte[rax], "w"
	jz	case_w.editor	;these use a different start point tho
	cmp	byte[rax], "s"
	jz	case_s.editor
	cmp	byte[rax], "a"
	jz	case_a.editor
	cmp	byte[rax], "d"
	jz	case_d.editor
	cmp	byte[rax], "q"
	jz	case_q.editor
	cmp	byte[rax], "e"
	jz	case_e.editor
	ret
.escape_editor:
	test_arrows\
	.case_up_editor, .case_down_editor, .case_left_editor,\
	.case_right_editor, word[rax+1]
	ret
.escape:
	cmp	byte[paused], 0	;only check for f keys so you can actually unpause
	jnz	.check_fkeys
	cmp	word[rax+1], "[D"	;arrow keys are weird and sent odd escapes
	jz	.case_left	;this one is left
	cmp	word[rax+1], "[C"
	jz	.case_right
	cmp	word[rax+1], "[A"
	jz	.case_up
	cmp	word[rax+1], "[B"
	jz	.case_down
.check_fkeys:
	cmp	word[rax+1], "OP"	;wow like the alphabet P Q R S
	jz	.case_f1
	cmp	word[rax+1], "OQ"
	jz	.case_f2
	cmp	word[rax+1], "OR"
	jz	.case_f3
	;cmp	word[rax+1], "OS"
	;jz	.case_f4
	ret	;return if it was smth like escape key
.case_f3:
	not	byte[alert_end]	;set alert end byte
	call	f_clear_alert	;clear previous alert thing
	not	byte[culling]	;toggle culling
	cmp	byte[culling], 0	;check if culling is to be enabled
	jnz	.enable_culling	;if it is do that
	mov	dword[message], "[Cul"	;boring
	mov	dword[message+4], "ling"
	mov	dword[message+8], " dis"
	mov	dword[message+12], "able"
	mov	word[message+16], "d]"
	mov	byte[message+18], 0	;end of string
	mov	ax, word[screen_x_center]	;move in screen center
	sub	ax, 5	;decrease by 5 (half of msg length)
	mov	word[alert_x_offset], ax	;stoooooooooooooooore here
	mov	qword[alert_tick], 120	;ticks for the message to stay for
	mov	byte[alerted], 255	;set the alerted byte
	ret
.enable_culling:
	mov	dword[message], "[Cul"	;same thing but other things yyyyyyk so bored
	mov	dword[message+4], "ling"
	mov	dword[message+8], " ena"
	mov	dword[message+12], "bled"
	mov	word[message+16], " ]"
	mov	byte[message+18], 0
	mov	ax, word[screen_x_center]
	sub	ax, 5
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.case_f2:
	not	byte[alert_end]
	call	f_clear_alert
	not	byte[wireframe]
	cmp	byte[wireframe], 0
	jz	.no_wireframe
	mov	dword[message], "[Wir"
	mov	dword[message+4], "efra"
	mov	dword[message+8], "me e"
	mov	dword[message+12], "nabl"
	mov	dword[message+16], "ed ]"
	mov	byte[message+20], 0
	mov	ax, word[screen_x_center]
	sub	ax, 5
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.no_wireframe:
	mov	dword[message], "[Wir"
	mov	dword[message+4], "efra"
	mov	dword[message+8], "me d"
	mov	dword[message+12], "isab"
	mov	dword[message+16], "led]"
	mov	byte[message+20], 0
	mov	ax, word[screen_x_center]
	sub	ax, 5
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.case_f1:
	not	byte[alert_end]
	call	f_clear_alert
	not	byte[paused]
	cmp	byte[paused], 0
	jz	.unpause
	mov	dword[message], "[Pau"
	mov	dword[message+4], "sed]"
	mov	byte[message+8], 0
	mov	ax, word[screen_x_center]
	sub	ax, 2
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], -1
	mov	byte[alerted], 255
	ret
.unpause:
	mov	dword[message], "[Unp"
	mov	dword[message+4], "ause"
	mov	word[message+8], "d]"
	mov	byte[message+10], 0
	mov	ax, word[screen_x_center]
	sub	ax, 3
	mov	word[alert_x_offset], ax
	mov	qword[alert_tick], 120
	mov	byte[alerted], 255
	ret
.case_left:
	mov	ecx, dword[keys_space]	;move the keys space offset into ecx
	call	f_shift_keys	;shift the keys over 1 space
	mov	dword[rbx+rcx], "⮜"	;insert left char
.case_left_editor:
	lea	r15, [angle]	;load rotation angle
	lea	r14, [camera_yaw]	;then load camera yaw to change yaw
	jmp	.multiply	;go
.case_right:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "⮞"
.case_right_editor:
	lea	r15, [angle_neg]	;this one uses a negative angle
	lea	r14, [camera_yaw]
	jmp	.multiply
.case_up:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "⮝"
.case_up_editor:
	lea	r15, [angle]
	lea	r14, [camera_pitch]	;and this uses pitch instead
	jmp	.multiply
.case_down:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "⮟"
.case_down_editor:
	lea	r15, [angle_neg]
	lea	r14, [camera_pitch]
.multiply:
	fld	dword[r15]
	fld	dword[r14]
	fsub	st1
	fst	dword[r14]
	emms
	ret	;return
case_w:
	mov	ecx, dword[keys_space]	;move in key space
	call	f_shift_keys	;shift keys over
	mov	dword[rbx+rcx], "W"	;and insert a W
.editor:
	mov	r14, 1	;move 1 into r14 (important for camera translation)
	lea	r15, [matrix_fwd]	;use fwd
	call	f_translate_camera	;translate camera matrix
	ret	;return
case_s:
	mov	ecx, dword[keys_space]	;same thing
	call	f_shift_keys
	mov	dword[rbx+rcx], "S"
.editor:
	xor	r14, r14
	lea	r15, [matrix_fwd]
	call	f_translate_camera
	ret
case_a:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "A"
.editor:
	xor	r14, r14
	lea	r15, [matrix_right]
	call	f_translate_camera
	ret
case_d:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "D"	
.editor:
	mov	r14, 1
	lea	r15, [matrix_right]
	call	f_translate_camera
	ret
case_q:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "Q"
.editor:
	xor	r14, r14
	lea	r15, [matrix_up]
	call	f_translate_camera
	ret
case_e:
	mov	ecx, dword[keys_space]
	call	f_shift_keys
	mov	dword[rbx+rcx], "E"
.editor:
	mov	r14, 1
	lea	r15, [matrix_up]
	call	f_translate_camera
	ret
f_shift_keys:
	mov	edx, dword[rbx+rcx+48]	;move second to last char into edx
	mov	dword[rbx+rcx+56], edx	;and moves it to last char
	mov	edx, dword[rbx+rcx+40]	;uses third to last now
	mov	dword[rbx+rcx+48], edx	;and moves it into second to last
	mov	edx, dword[rbx+rcx+32]	;u can kinda guess where this is going
	mov	dword[rbx+rcx+40], edx
	mov	edx, dword[rbx+rcx+24]
	mov	dword[rbx+rcx+32], edx
	mov	edx, dword[rbx+rcx+16]
	mov	dword[rbx+rcx+24], edx
	mov	edx, dword[rbx+rcx+8]
	mov	dword[rbx+rcx+16], edx
	mov	edx, dword[rbx+rcx]
	mov	dword[rbx+rcx+8], edx
	ret
f_translate_camera:
	emms
	fld	dword[r15+12]	;load the values in the directional matrix
	fld	dword[r15+8]	;all of them
	fld	dword[r15+4]
	fld	dword[movement_speed]	;then load the movement speed
	fmul	TO	st1	;multiply all of them by this val
	fmul	TO	st2
	fmul	TO	st3
	fld	dword[camera_position+8]	;then load camera positions
	fld	dword[camera_position+4]
	fld	dword[camera_position]
	cmp	r14, 0	;check if r14 (forwards or backwards thing) is 0
	jz	.sub	;if yes, subtract instead of add
	fadd	st4	;add all of the values to the camera position
	fxch	st1	;swapping when necasarry
	fadd	st5
	fxch	st2
	fadd	st6
	jmp	.end	;skip sub operation
.sub:
	fsub	st4	;same thing but with subtraction
	fxch	st1
	fsub	st5
	fxch	st2
	fsub	st6
.end:
	fst	dword[camera_position+8]	;store new values in camera matrix
	fabs
	fchs
	fst	dword[camera_position_cull+8]	;store negative value here (culling use)
	fxch	st2
	fst	dword[camera_position+4]
	fst	dword[camera_position_cull+4]
	fxch	st1
	fst	dword[camera_position]
	fst	dword[camera_position_cull]
	emms
	cmp	byte[editor], 0
	jnz	.ret
	call	f_pos_string	;generate new location string
	call	f_insert_location	;move into framebuf
.ret:
	ret
f_editor_binds:
	cmp	byte[scope], 0	;scope 0 has different checking stuff
	jz	.scope_0
	cmp	byte[buf1], 27	;check if escape key pressed
	jnz	.skip_escape_check	;if no go away
	cmp	byte[buf1+1], 0	;escape key can only be confirmed in 2 bytes
	jnz	.skip_escape_check	;sob
	mov	byte[scope], 0	;if escape pressed, always return to top scope
	mov	rax, qword[bbar_items.scope]
	insert_str	SCOPE_0
	mov	rax, qword[edited_obj]	;move addr for edited objects in here
	mov	rbx, qword[edited_obj_offset]	;and offset
	mov	dword[rax+rbx], 234356	;terminate preview point to its now shown
	mov	rax, qword[edited_faces]
	mov	rbx, qword[edited_faces_offset]
	mov	word[rax+rbx], 65535	;terminate preview face also
	xor	rbx, rbx	;reset this to clear potential high bit problems
	mov	rax, qword[points_dat]	;move in points data space
.unselect:
	cmp	ebx, dword[point_dat_offset]	;check if at end of str
	jz	.done_unselect	;if yes stop
	and	byte[rax+rbx], 0b00000011	;otherwise clear the selected bit
	add	rbx, 4	;loop over
	jmp	.unselect
.done_unselect:
	mov	byte[update], 1	;and force update
	ret
.skip_escape_check:
	cmp	byte[scope], 1	;check scope
	jz	.lbar_binds	;if its 1 then do lbar processing
	cmp	byte[scope], 2	;preview scope
	jz	.preview_init
	ret
.scope_0:
	cmp	word[buf1+1], "OS"	;check f4
	jnz	.not_f4	;and do this if its not
	not	byte[type_id]	;otherwise activate type id mode
	mov	rax, qword[bbar_items.typeid]
	insert_str	BBAR_DISABLED
	cmp	byte[type_id], 0
	jz	.retpoint
	insert_str	BBAR_ENABLED
	ret
.not_f4:
	cmp	word[buf1+1], "OR"	;check f3
	jnz	.not_f3	;if no yea
	not	byte[culling]	;otherwise toggle culling
	mov	byte[update], 1	;this updates visuals
	mov	rax, qword[bbar_items.culling]
	insert_str	BBAR_DISABLED
	cmp	byte[culling], 0
	jz	.retpoint
	insert_str	BBAR_ENABLED
	ret
	ret
.not_f3:
	mov	rax, qword[bbar_items.scope]
	cmp	byte[buf1], "p"	;otherwise check global scope binds
	jz	.preview_mode	;if p then its different
	insert_str	SCOPE_1
	cmp	byte[buf1], 27
	jnz	.not_escapes
	cmp	word[buf1+1], "[D"
	jnz	.not_left
	mov	byte[scope], 1
	ret
.not_left:
.not_escapes:
	cmp	byte[edit_texture], 255
	jz	.global_binds
	cmp	byte[buf1], "P"		
	jz	f_new_point	;P = draw new point
	cmp	byte[buf1], "F"
	jz	f_new_face	;F is new face
	cmp	byte[buf1], "R"	;its easy to find out what does what
	jz	f_remove_point
	cmp	byte[buf1], "r"
	jz	f_rotate_point
	cmp	byte[buf1], "s"
	jz	f_create_selection
	cmp	byte[buf1], "V"
	jz	f_move_along_vec
	cmp	byte[buf1], "A"
	jz	f_rotate_axis
	cmp	byte[buf1], "T"
	jz	f_vector_trig
	cmp	byte[buf1], "n"
	jz	f_rotate_normal
	cmp	byte[buf1], "f"
	jz	f_remove_face
	cmp	byte[buf1], "U"
	jz	f_map_face
.global_binds:
	insert_str	SCOPE_0	;put in scope string 0 if no keys in here
	cmp	byte[buf1], "O"
	jz	f_open_file
	cmp	byte[buf1], "S"
	jz	f_save_file.check_saved
	cmp	byte[buf1], "N"
	jz	f_save_file
	cmp	byte[buf1], "C"
	jz	f_new_file
	cmp	byte[buf1], "M"
	jz	f_edit_mode
.retpoint:
	ret
.preview_mode:
	mov	byte[scope], 2	;preview is scope 2
	insert_str	SCOPE_2	;then insert a scope 2 thing
	ret
.preview_init:
	cmp	byte[edit_texture], 255
	jz	f_test_texture
	lea	rax, [buf1]	;load buffer 1 into rax
	jmp	f_input_cases.input	;and now u can just reuse this subroutine
.lbar_binds:
	cmp	byte[buf1], 27	;check if escape sequence
	jz	.lbar_escapes	;if yes go here
	cmp	byte[buf1], 10	;and enter key
	jz	.lbar_enter
	cmp	byte[type_id], 0	;check if id typing is disabled
	jz	.skip_type_id	;if yes skip thisn ext bit
	movzx	rcx, word[selected_option]	;the next bit:
	shr	rcx, 1	;it checks to see if the current menu item is a id
	cmp	byte[menu_entries+rcx], WIDGET_ID	;if it is,
	jz	.check_type_id	;then skip normal binds
.skip_type_id:
	cmp	byte[buf1], "+"	;+ goes here
	jz	.lbar_plus_minus
	cmp	byte[buf1], "-"	;and minus goes to same place
	jz	.lbar_plus_minus
	cmp	byte[buf1], "["	;yea
	jz	.decrease_step
	cmp	byte[buf1], "]"
	jz	.increase_step
	ret
.check_type_id:
	mov	al, byte[buf1]	;move in buffer key
	sub	al, "!"	;subtract a !
	cmp	al, 126-"!"	;and compare with limit val
	ja	.retpoint	;if its above, (also below if signed) return
	call	f_type_id	;otherwise manage id type stuff
.decrease_step:
	mov	byte[step_angle_int], 1	;set this to 1 there are only 2 vals
	movzx	rax, byte[current_step]	;move in current step to rax
	cmp	rax, 0	;check if its zero
	jz	.retpoint	;if yes dont lower the step
	sub	byte[current_step], 4	;otherwise lower it
	fld	dword[steps+rax-4]
	fst	dword[step]
	emms
	ret
.increase_step:
	mov	byte[step_angle_int], 10	;and set this to 10
	movzx	rax, byte[current_step]
	cmp	rax, 12	;same but with max values
	jz	.retpoint
	add	byte[current_step], 4	;increase it
	fld	dword[steps+rax+4]
	fst	dword[step]
	emms
	ret
.lbar_enter:
	movzx	rcx, word[selected_option]	;get selected opt
	shr	rcx, 1	;correct to work with menu entries
	cmp	byte[menu_entries+rcx], WIDGET_BOX	;check if toggle box
	jz	f_toggle_option	;if yes go here
	cmp	byte[menu_entries+rcx], WIDGET_BUTTON	;check if its a button
	jnz	.not_apply	;if no then return
	mov	byte[project_saved], 0
	shl	rcx, 1	;then correct rcx again
	mov	rax, qword[apply_func]	;and call the apply function
	jmp	rax
.not_apply:
	ret
.lbar_plus_minus:
	movzx	rcx, word[selected_option]	;similar thing as above
	shr	rcx, 1
	cmp	byte[menu_entries+rcx], WIDGET_ID	;except it checks all these too
	jz	f_modify_id	;and if the type is correct go to the important bit here
	cmp	byte[menu_entries+rcx], WIDGET_POS
	jz	f_modify_pos
	cmp	byte[menu_entries+rcx], WIDGET_FACE
	jz	f_modify_face
	mov	word[int_ui_limit], 360
	cmp	byte[menu_entries+rcx], WIDGET_INT+INT_360
	jz	f_modify_angle
	mov	word[int_ui_limit], 256
	cmp	byte[menu_entries+rcx], WIDGET_INT+INT_256
	jz	f_modify_angle
	mov	word[int_ui_limit], 101
	cmp	byte[menu_entries+rcx], WIDGET_INT+INT_100
	jz	f_modify_angle
	mov	word[int_ui_limit], 9
	cmp	byte[menu_entries+rcx], WIDGET_INT+INT_8
	jz	f_modify_angle
	ret
.lbar_escapes:
	movzx	rax, word[selected_option]	;move selected option into rax!
	shr	rax, 1	;and half it for these next steps
	cmp	byte[type_id], 0	;if type id is disabled
	jz	.skip_type_checks	;check escapes normally
	push	r15	;otherwise push r15
	cmp	byte[menu_entries+rax], WIDGET_ID	;check if current val is a id box
	jnz	.finished_id	;if its NOT then go away mf u arent wanted 100 emoji
	movzx	rbx, byte[menu_entries+rax+1]	;otherwise its nice and friendly 😊
	shl	rax, 1	;get rax back
	mov	rcx, rax	;and save it here bc its important for certain calls
	cmp	byte[option_data_id+rbx+1], " "	;check if this is a blank
	jz	.clear_id	;if yes then set id to !!
	mov	ax, word[max_id]	;move in max id here
	cmp	al, byte[option_data_id+rbx]	;and do comparison to current id
	jb	.clear_id	;p much if its above
	cmp	ah, byte[option_data_id+rbx+1]	;then set to !!
	jb	.clear_id
	jmp	.finished_id
.clear_id:
	mov	word[option_data_id+rbx], "!!"	;overwrite with thsi guy
	xor	rdi, rdi	;then rdi=0 to do update call (its updated at end anyway)
	call	f_modify_id.insert_id	;and insert the id
.finished_id:
	xor	rbx, rbx	;reset this to clear high bits
	mov	r15, qword[points_dat]	;thing for selections
.loop_selection:
	cmp	ebx, dword[point_dat_offset]	;check if at end
	jz	.cleared_selection	;if yes yeah done
	and	byte[r15+rbx], 0b00000001	;clear all preview/selections
	add	rbx, 4	;add 4
	jmp	.loop_selection	;loop
.cleared_selection:
	movzx	rcx, word[selected_option]	;get selected opt
	shr	rcx, 1	;and half it now.,
	mov	rax, qword[update_func]	;get update function
	call	rax	;and call it
	pop	r15	;then get back r15
.skip_type_checks:
	movzx	rax, word[selected_option]
	mov	ebx, dword[menu_options+rax]	;move this offset into rbx
	mov	dword[r15+rbx], " "	;and clear it with a 0
	cmp	word[buf1+1], "[A"	;its simple cmon
	jz	.scroll_options_u
	cmp	word[buf1+1], "[B"
	jz	.scroll_options_d
	ret
.scroll_options_u:
	sub	word[selected_option], 4	;go up an option
	jmp	.set_option
.scroll_options_d:
	add	word[selected_option], 4	;go down an option
.set_option:
	movzx	rbx, byte[option_divisor]	;move divisor into rbx
	movsx	rax, word[selected_option]	;and signed extend selected opt into rax
	cmp	rax, -4	;border case nasty fix
	jnz	.get_remainder	;get remainder if its not border case
	movzx	ax, byte[option_divisor]
	sub	ax, 4
	mov	word[selected_option], ax	;otherwise use this constant
	jmp	.end	;and go to end
.get_remainder:
	xor	rdx, rdx	;otherwise reset this guy bc he affects stuff sometimes!
	div	rbx	;then divide it by divisor
	mov	word[selected_option], dx	;and move remainder into selected option
.end:
	movzx	rax, word[selected_option]	;(this just moves the cursor thing into position)
	mov	ebx, dword[menu_options+rax]
	mov	dword[r15+rbx], ">"	;its basic
	ret
f_test_texture:
	cmp	byte[buf1], 10
	jz	f_apply_texel
	cmp	byte[buf1], "x"
	jnz	.not_x
	not	byte[use_secondary]
	mov	byte[update], 1
	jmp	.not_arrow
.not_x:
	cmp	byte[buf1], "p"
	jnz	.not_p
	mov	byte[texel_mode], 0
	jmp	.not_arrow
.not_p:
	cmp	byte[buf1], "b"
	jnz	.not_b
	mov	byte[texel_mode], 1
	jmp	.not_arrow
.not_b:
	cmp	byte[buf1], "l"
	jnz	.not_l
	mov	byte[texel_mode], 2
	mov	byte[texel_mode+1], 0
	jmp	.not_arrow
.not_l:
	cmp	byte[buf1], 27
	jnz	.not_arrow
	test_arrows	\
	.key_up, .key_down, .key_left, .key_right, word[buf1+1]
	jmp	.not_arrow
.key_left:
	cmp	word[texture_pos], 0
	jz	.not_arrow
	dec	word[texture_pos]
	jmp	.not_arrow
.key_right:
	mov	ax, word[dimensions]
	dec	ax
	cmp	word[texture_pos], ax
	jz	.not_arrow
	inc	word[texture_pos]
	jmp	.not_arrow
.key_up:
	cmp	word[texture_pos+2], 0
	jz	.not_arrow
	dec	word[texture_pos+2]
	jmp	.not_arrow
.key_down:
	mov	ax, word[dimensions+2]
	dec	ax
	cmp	word[texture_pos+2], ax
	jz	.not_arrow
	inc	word[texture_pos+2]
.not_arrow:
	mov	byte[update], 1
	ret
