f_tex_menu:
	generic_opt_init	10, PEN_COLOUR	;snooze,
	widget_int	PRIMARY_R, DEFAULT_USTRING, 0, INT_256, 0	;use cool new macros
	widget_int	PRIMARY_G, DEFAULT_USTRING, 1, INT_256, 1	;they are way cooler
	widget_int	PRIMARY_B, DEFAULT_USTRING, 2, INT_256, 2
	widget_int	PRIMARY_A, DEFAULT_USTRING, 3, INT_8, 3
	add	rax, qword[row_width_editor]	;new row for secondary colours
	widget_int	SECONDARY_R, DEFAULT_USTRING, 4, INT_256, 4
	widget_int	SECONDARY_G, DEFAULT_USTRING, 5, INT_256, 5
	widget_int	SECONDARY_B, DEFAULT_USTRING, 6, INT_256, 6
	widget_int	SECONDARY_A, DEFAULT_USTRING, 7, INT_8, 7
	add	rax, qword[row_width_editor]	;new row again
	push	rax	;PUSH rax
	xor	rcx, rcx	;and clear this
	lea	rax, [r15+rax+8]	;move addr + 8 into rax
	mov	qword[pen_prev_pos], rax	;and save to pen preview offset
.add_preview:
	mov	bl, byte[pen_prev+rcx]	;now it creates the preview thing
	cmp	bl, 0	;byte transfer to fbuf easy
	jz	.added_preview
	mov	byte[rax], bl
	inc	rax
	inc	rcx
	jmp	.add_preview
.added_preview:
	pop	rax	;get back rax
	times 2	add	rax, qword[row_width_editor]	;go down some rows
	widget_int	TEX_WIDTH, USTRING_2, 8, INT_100, 8	;and put resize widgets
	widget_int	TEX_HEIGHT, USTRING_2, 9, INT_100, 9
	mov	ax, word[dimensions]	;load dimensions
	sub	ax, word[step_angle_int]	;subtract a step
	mov	word[option_data_rot+16], ax	;put it in option data thing
	mov	byte[buf1], "+"	;and simulate + pressed
	mov	qword[update_func], .retpoint	;make sure it doesnt call .update
	mov	rcx, 16	;offset for option
	call	f_modify_angle	;now it puts the image dimensions in place
	mov	ax, word[dimensions+2]	;same but for the other options
	sub	ax, word[step_angle_int]
	mov	word[option_data_rot+18], ax
	mov	rcx, 18	;with a different offset also
	call	f_modify_angle
	mov	qword[update_func], .update	;get the correct val back
.retpoint:
	ret
.apply:
	ret
.update:
	mov	r15, qword[edited_texture]	;get texture here
	lea	r14, [option_data_rot+16]	;and resize to vals here
	lea	r13, [option_data_rot+18]
	call	f_resize_texture
	lea	r15, [option_data_rot]	;now load rgb values for primary pen
	lea	r14, [option_data_rot+2]
	lea	r13, [option_data_rot+4]
	mov	r12, qword[pen_prev_pos]	;and the position
	lea	r11, [color_pri]	;aand what var to set
	lea	r10, [option_data_rot+6]
	call	f_rgb_to_ansi	;then convert the rgb to ansi
	lea	r15, [option_data_rot+8]	;same with secondary pen colours
	lea	r14, [option_data_rot+10]
	lea	r13, [option_data_rot+12]
	mov	r12, qword[pen_prev_pos]
	add	r12, UNIT_SIZE	;its 13 bytes over
	lea	r11, [color_sec]	;use this instead ofc
	lea	r10, [option_data_rot+14]
	call	f_rgb_to_ansi	;go!
	mov	byte[update], 1	;update also
	ret

