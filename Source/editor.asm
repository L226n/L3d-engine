%macro	bbar_enabled	1
	cmp	%1, 0	;check if param is 0
	jnz	%%enabled	;if no then print enabled thing
	insert_str	BBAR_DISABLED	;otherwise print disabled
	jmp	%%end	;then go to end
%%enabled:
	insert_str	BBAR_ENABLED	;enabled str
%%end:
%endmacro
%macro	prepare_zone	2	;this prepares a zone for gui in editor
	push	rax	;by clearing escapes
	mov	rbx, %2 + 1	;move in gui height + 1
%%loop:
	dec	rbx	;then decrease it (thats why u use +1)
	jz	%%end	;if its 0 then finish
	mov	byte[r15+rax], 0	;otherwise move a 0 into the current byte
	mov	byte[r15+rax+1], 27	;then a 27, to begin escape
	mov	word[r15+rax+2], "[0"	;then clear colours escape bits
	mov	byte[r15+rax+4], "m"
	mov	qword[r15+rax+5], 0	;and blank qword bc fsr it needs this
	%assign	COUNTER	13	;then!!! use offset to skip the clear colours
	%rep	((%1 >> 1) - 1) * UNIT_SIZE	;and repeat to clear the whole rest of row,
		mov	byte[r15+rax+COUNTER], 0	;clear current byte..
		%assign	COUNTER	COUNTER + 1	;then go to next byte
	%endrep
	add	rax, qword[row_width_editor]	;go to next row
	jmp	%%loop	;and repeat
%%end:
	pop	rax	;get back rax
	add	rax, 13	;and add 13 to skip colour clear
%endmacro
%macro	get_box_tl_editor	2
	mov	rax, qword[offset_graphics_window]	;gets tl for graphics window
	movzx	rbx, word[preview_width]	;get width, (which is in half anyway)
	shr	rbx, 1	;now div by 2
	sub	rbx, (%1 >> 2)	;and subtract gui width /4
	imul	rbx, 13	;multiply by unit size
	add	rax, rbx	;now add to the base offset
	movzx	rbx, word[preview_height]	;now get height
	shr	rbx, 1	;halfed
	sub	rbx, (%2 >> 1)	;and subtract gui height /2
	imul	rbx, qword[row_width_editor]	;multiply by row width
	add	rax, rbx	;and add back to rax again
%endmacro
%macro	generic_opt_init	2
	mov	qword[update_func], .update	;macro that expands for
	mov	qword[apply_func], .apply	;generic option init
	call	f_clear_lbar	;thingies
	mov	byte[scope], 1	;if its different
	mov	byte[option_divisor], %1 * 4	;and u need other opts
	mov	word[selected_option], 0	;then just do it after
	mov	rax, qword[lbar_offset]
	insert_str	%2
	add	rax, 4
	times 2	add	rax, qword[row_width_editor]	;it also inserts title
	mov	dword[r15+rax], ">"
%endmacro
%macro	insert_row	5
	mov	byte[menu_entries+(%3 << 1)], %4	;insert id here
	mov	r8, 1	;use this bc u cant do comparisons between 2 immediates
	cmp	r8, %4	;check if its 1
	jnz	%%not_id	;if its not then go here
	mov	word[option_data_id+(%5 << 1)], "!!"	;otherwise reset id
	mov	byte[menu_entries+(%3 << 1)+1], (%5 << 1)	;and store offset
	jmp	%%loaded_defaults	;skip the rest
%%not_id:
	inc	r8	;increase comparison thing
	cmp	r8, %4	;same thing
	jnz	%%not_pos
	mov	dword[option_data_pos+(%5 << 2)], 0	;but reset position
	mov	byte[menu_entries+(%3 << 1)+1], (%5 << 2)	;it also uses different bit shifts
	jmp	%%loaded_defaults
%%not_pos:
	inc	r8
	cmp	r8, %4	;saaaameeee
	jnz	%%not_angle
	mov	word[option_data_rot+(%5 << 1)], 0
	mov	byte[menu_entries+(%3 << 1)+1], (%5 << 1)
	jmp	%%loaded_defaults
%%not_angle:
	mov	byte[menu_entries+(%3 << 1)+1], 0	;for selection, just set this as 0
%%loaded_defaults:
	mov	dword[menu_options+(%3 << 2)], eax	;save offset here
	insert_str	%1	;insert label for thingy
	push	rax	;push rax now
	add	rax, (COUNTER << 2) - 4	;go to end of string
	insert_str	%2	;insert the option string
	pop	rax	;popback
	add	rax, qword[row_width_editor]	;and go to next row
%endmacro
%macro	clear_error	1
	mov	eax, dword[menu_options+%1]	;move in the space wanted
	add	rax, qword[row_width_editor]	;and go to next one
%%loop:
	cmp	dword[r15+rax], "│"	;check if at end
	jz	%%end	;if yes done
	mov	dword[r15+rax], " "	;otherwise move in space
	add	rax, 4	;loop
	jmp	%%loop	;done
%%end:
%endmacro
%macro	raise_error	2
	mov	eax, dword[menu_options+%1]	;same as above
	add	rax, qword[row_width_editor]
	%assign	COUNTER	0
	%rep	5	;except this time
		mov	ebx, dword[editor_err+COUNTER]	;it inserts the error string
		mov	dword[r15+rax+COUNTER], ebx	;thing
		%assign	COUNTER	COUNTER + 4	;its well made
	%endrep
	add	rax, COUNTER - 8	;go to end of thing
	insert_str	%2	;then insert error string
	add	rax, (COUNTER << 2) + 4	;go to end of THAT
	mov	byte[r15+rax], 27	;and then move in clear escape
	mov	word[r15+rax+1], "[0"
	mov	byte[r15+rax+3], "m"
%endmacro
%macro	update_preview	0
	mov	r15, qword[framebuf]	;make sure this r15 has the fbuf loaded
	mov	rax, qword[bbar_items.vertices]	;now load vertices offset
	mov	rbx, qword[edited_obj_offset]	;and value which has vertex count
	sub	rbx, 20	;subtract 20 (origin + column size)
	shr	rbx, 4	;now divide by 16
	call	f_modify_ascii	;insert that into bbar
	mov	rax, qword[bbar_items.triangles]	;same with triangle count
	mov	rbx, qword[edited_faces_offset]
	shr	rbx, 3	;except divide by 8
	call	f_modify_ascii
	call	f_clear_preview	;then clear the preview window
	mov	r15, qword[edited_obj]	;object to display
	call	f_apply_transformation	;apply screen space transformations
	call	f_display_points	;show these points on screen
%endmacro
%macro	insert_str	1
	%strlen	STR_LEN	%1	;get length of string
	%assign	COUNTER	1
	%rep	STR_LEN
		%substr	CHAR	%1	COUNTER	;get char at index
		mov	dword[r15+rax+(COUNTER << 2)+4], CHAR	;move it into the right position
		%assign	COUNTER	COUNTER+1	;increase char counter
	%endrep
%endmacro
%include	"editor_functions.asm"
f_editor:
	call	f_initialise_editor	;initialise editor window
	cmp	byte[scope], -1
	jz	.skip_reserves
	mov	rax, 9	;sys_mmap
	xor	rdi, rdi	;clear for automatic memory start
	mov	rsi, 4096	;reserve this to start
	mov	rdx, 3	;and this is a thingy (consult f_calc_malloc in math.asm)
	mov	r10, 2 | 32
	mov	r8, -1
	xor	r9, r9
	syscall
	mov	qword[edited_obj], rax	;save addr here
	mov	dword[edited_obj_len], 4096	;and space reserved here
	mov	word[edited_obj_available], 4072	;and reserved space remaining here
	mov	dword[rax], 16	;initialise with origin point
	mov	dword[rax+16], 0x3F800000 ;1.0 thing
	mov	dword[rax+20], 234356	;end of string
	mov	qword[edited_obj_offset], 20	;offset when adding new point
	mov	rax, 9	;sys_mmap again
	xor	rdi, rdi	;same as above
	mov	rsi, 4096
	mov	rdx, 3
	mov	r10, 2 | 32
	mov	r8, -1
	xor	r9, r9
	syscall
	mov	qword[points_dat], rax	;save here instead
	mov	dword[points_dat_len], 4096	;same, save various bits of data abt it
	mov	word[points_dat_available], 4092
	mov	byte[rax], 0b00000001	;origin info string
	mov	word[rax+1], "!!"	;id is always !!
	mov	dword[point_dat_offset], 4	;offset for new data entry
	mov	rax, 9	;sys_mmap again
	xor	rdi, rdi	;same as above
	mov	rsi, 4096
	mov	rdx, 3
	mov	r10, 2 | 32
	mov	r8, -1
	xor	r9, r9
	syscall
	mov	qword[edited_faces], rax
	mov	dword[edited_faces_len], 4096
	mov	word[edited_faces_available], 4094
	mov	word[rax], 65535
	mov	qword[edited_faces_offset], 0
.skip_reserves:
	mov	byte[scope], 0
	lea	r15, [preview_height]	;thsee are width and height of window
	lea	r14, [preview_width]
	call	f_init_matrices	;initialise matrices for preview window
	update_preview
.print_screen:
	mov	r15, qword[framebuf]	;make sure this is here
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, r15	;print it
	mov	rdx, qword[print_length]	;length of frame buffer
	syscall
	mov	dword[buf1], 0
	mov	rax, 0	;get an input
	mov	rdi, 1
	mov	rsi, buf1
	mov	rdx, 4
	syscall
	call	f_editor_binds	;and then call keybind handler
	cmp	byte[scope], -1
	jz	f_editor
	cmp	byte[update+1], 0
	jz	.no_input
	lea	r15, [preview_height]	;thsee are width and height of window
	lea	r14, [preview_width]
	call	f_init_matrices	;initialise matrices for preview window
	update_preview
	mov	byte[update+1], 0
	jmp	.print_screen
.no_input:
	cmp	byte[update], 0	;check if this is 0
	jz	.print_screen	;if its not loop over
	update_preview	;otherwise update screen
	mov	byte[update], 0	;and reset this byte
	jmp	.print_screen	;THEN loop
f_initialise_editor:
	;NOTE this is a horrible code, nasty abomination
	movzx	rax, word[window_size+2]	;window width
	movzx	rbx, word[window_size]	;and height
	shl	rax, 1	;double window width to get normal width
	push	rax	;save for near future
	mov	r9, rax	;save it in r9
	shl	r9, 2	;and mul by 4 to get row length in bytes (1 char isdword)
	mul	rbx	;multiply width by height
	mov	rcx, rax	;save in rcx
	pop	rax	;get back column val
	sub	rax, EDITOR_LBAR	;subtract left bar width
	mov	r10, rax	;save in r10 (will be middle row byte len)
	shr	r10, 1	;half r10 bc its pixel length of preview win now
	imul	r10, UNIT_SIZE	;multiply by 13 to get size in bytes
	add	r10, (EDITOR_LBAR << 2) + 4	;add the size of the left bar in bytes
	mov	word[preview_width], ax	;save preview width
	shr	word[preview_width], 1	;and half it to get width in chars
	sub	rbx, 2+EDITOR_BBAR	;subtract top bar and bottom bar from window height
	mov	word[preview_height], bx	;save height here
	mul	rbx	;multiply preview width by height to get preview size
	sub	rcx, rax	;subtract this from total screen space to get size taken by ui
	shl	rcx, 2	;x4 to get size in bytes
	shr	rax, 1	;half rax to get half of preview window
	imul	rax, UNIT_SIZE	;multiply by 13 to get size of pixels in previewin bytes
	add	rcx, rax	;add to size occupied by ui to get total size
	movzx	rdx, word[window_size]	;move window height into rdx
	shl	rdx, 2	;x4
	add	rcx, rdx	;add this to rdx (colour clear escapes)
	mov	qword[print_length], rcx	;move it here
	mov	rbx, 4	;start at 4 bc f_generate_row is weird and needs the offset to be +4
	movzx	rcx, word[window_size+2]	;move window width into rcx
	shl	rcx, 1	;double again rolling eyes emoji
	push	rcx	;push to stack for whatever reason
	mov	r14, "│"	;chars for the top
	mov	r13, " "
	mov	r12, "│"
	mov	r8, 255	;dont pad
	call	f_generate_row	;make a row
	add	rbx, r9	;look its r9 from earlier!
	mov	r14, "├"
	mov	r13, "─"
	mov	r12, "╯"
	call	f_generate_row	;another row
	mov	dword[r15+rbx+(EDITOR_LBAR << 2)-8], "┬"	;crazy immediate addr for fixing ui
	add	rbx, r9	;next row
	mov	rcx, EDITOR_LBAR	;move in left bar width
	movzx	rax, word[window_size]	;and win height into rax
	sub	rax, 2+EDITOR_BBAR	;subtract ui things from here
	push	rbx	;quick little operation
	add	rbx, EDITOR_LBAR-1 << 2	;get offset for escape window start
	mov	qword[offset_graphics_window], rbx	;save it here
	mov	qword[row_width_editor], r10	;save this guy too hes important
	pop	rbx	;you saw nothing
	mov	qword[lbar_offset], rbx
.loop_middle:
	mov	r14, "│"	;middle thingies
	mov	r13, " "
	mov	r12, "│"
	call	f_generate_row	;generate row for part of the screen
	push	rbx	;push this bc its modified
	add	rbx, EDITOR_LBAR-1 << 2	;add width of lbar in bytes
	call	f_generate_escapes	;generate empty escapes for this
	pop	rbx	;get back nice offset 😊
	add	rbx, r10	;add that cool offset from earlier to go to next row and skip escapes
	dec	rax	;decrease iterator (is that a word??)
	jnz	.loop_middle	;holy fucking shit gonna have to rewrite so many loops
.finished_middle:
	mov	r14, "│"	;end!!!
	mov	r13, "─"
	mov	r12, "╮"
	pop	rcx	;oh hello rcx its you from earlier
	call	f_generate_row	;row using old row counter
	push	rbx	;push this offset
	add	rbx, r9	;add an offset
	%rep	EDITOR_BBAR-2
		mov	r14, "│"	;generate end middle bits
		mov	r13, " "
		mov	r12, "│"
		call	f_generate_row
		add	rbx, r9
	%endrep
	mov	r14, "╰"	;super end
	mov	r13, "─"
	mov	r12, "╯"
	call	f_generate_row
	pop	rbx	;get back rbx
	add	rbx, 4	;add 4
	mov	rcx, EDITOR_LBAR-1	;this fixes ui being weird
	mov	r14, " "	;clears some hyphens that are actually box chars
	mov	r13, " "
	mov	r12, "├"
	call	f_generate_row
	push	rbx
	add	rbx, (EDITOR_LBAR << 2) - 4	;get start of bbar stuffs
	add	rbx, r9
	mov	qword[bbar_offset], rbx
	call	f_insert_bbar
	pop	rbx
	add	rbx, r9
	%rep	EDITOR_BBAR-2	;for all middle sections of bottom bar,
		mov	r14, " "	;make a row like this
		mov	r13, " "
		mov	r12, "│"
		call	f_generate_row
		add	rbx, r9
	%endrep
	mov	dword[r15+rbx+(EDITOR_LBAR << 2)-12], "┴"	;and then only 1 char is needed here
	mov	qword[row_width_bars], r9	;save this bc its used laterrrr
	ret
f_insert_bbar:
	mov	rax, rbx	;this function generates bbar values
	mov	qword[bbar_items.scope], rax	;save this addr as scope position
	add	qword[bbar_items.scope], 20	;add 20 to that
	sub	rax, 8	;but add 8 to rax
	push	rax	;push rax bc its needed as a base offset
	insert_str	"Scope: "	;now put in this label
	mov	rax, qword[bbar_items.scope]	;now move in addr for this (done in weird way huh)
	insert_str	SCOPE_0	;then put in this scope str
	add	rax, 80	;go to next column
	insert_str	"Vertex count: "	;and vertex count str
	add	rax, 64	;add offset for actual value
	mov	qword[bbar_items.vertices], rax	;now do the same which is done in other points
	mov	rbx, qword[edited_obj_offset]	;load value for vertices
	sub	rbx, 20	;and sub origin + width of matrix
	shr	rbx, 4	;div by 16
	call	f_modify_ascii	;and print the ascii
	pop	rax	;pop back rax bc this row is done
	add	rax, r9	;add row val
	push	rax	;push it again
	insert_str	"Culling: "	;now culling
	add	rax, 36
	mov	qword[bbar_items.culling], rax	;save the addr
	bbar_enabled	byte[culling]	;now detect if culling is on or off and insert correct str
	add	rax, 72	;now go to next column
	insert_str	"Triangle count: "	;and do triangle count
	add	rax, 72	;offset,,,
	mov	qword[bbar_items.triangles], rax	;and save offset
	mov	rbx, qword[edited_faces_offset]	;AND get amount of triangles
	shr	rbx, 3
	call	f_modify_ascii	;then insert
	pop	rax	;now a new row
	add	rax, r9
	push	rax
	insert_str	"Type ID: "	;type id str
	add	rax, 36	;and offset
	mov	qword[bbar_items.typeid], rax
	bbar_enabled	byte[type_id]	;another binary val, detect state
	add	rax, 72
	insert_str	"File saved: "
	add	rax, 48
	mov	qword[bbar_items.saved], rax	;file is saved yk
	bbar_enabled	byte[project_saved]
	pop	rax
	add	rax, r9	;new row again
	push	rax
	insert_str	"Selection length: "
	add	rax, 78
	mov	qword[bbar_items.selection], rax	;now it does modify ascii with selection length instead
	movzx	rbx, byte[selection_length]
	call	f_modify_ascii
	pop	rax
	ret
f_modify_id:
	xor	rbx, rbx
	mov	r15, qword[points_dat]	;thing for selections
.loop_selection:
	cmp	ebx, dword[point_dat_offset]	;check ifat end
	jz	.cleared_selection	;if yes yeah done
	and	byte[r15+rbx], 0b00000001	;clear all preview/selections
	add	rbx, 4	;add 4
	jmp	.loop_selection	;loop
.cleared_selection:
	movzx	rbx, byte[menu_entries+rcx+1]	;move in offset for id data
	shl	rcx, 1	;correct rcx
	mov	ax, word[option_data_id+rbx]	;and load current into ax
	cmp	byte[buf1], "+"	;check if uwanna increase
	jz	.increase_id	;if ys go here
	cmp	ax, "!!"	;otherwise check if !!
	jnz	.decrease_normal	;if no do normal operation
	mov	ax, word[max_id]	;otherwise loop around to max id
	jmp	.dont_reset	;skip rest
.decrease_normal:
	dec	al	;decrease lower byte
	cmp	al, " "	;check if its " " (underflow)
	jnz	.dont_reset	;if no, ur good
	mov	al, 126	;otherwise move in max val for al
	dec	ah	;and decrease ah
	jmp	.dont_reset	;done
.increase_id:
	cmp	ax, word[max_id]	;now compare max id
	jnz	.increase_normal	;if no normal increase
	mov	ax, "!!"	;if yes go to origin (overflow)
	jmp	.dont_reset
.increase_normal:
	inc	al	;same as above yk
	cmp	al, 127
	jnz	.dont_reset
	mov	al, "!"
	inc	ah
.dont_reset:
	mov	word[option_data_id+rbx], ax	;store new id
	xor	rdi, rdi
.insert_id:
	mov	edx, dword[menu_options+rcx]	;move offset for current point
	mov	r15, qword[framebuf]	;and framebuf here
	add	r15, rdx	;add together
.loop_get_end:
	cmp	dword[r15], "["	;get square bracket pos thing
	jz	.got_end
	add	r15, 4
	jmp	.loop_get_end
.got_end:
	add	r15, 4
	movzx	eax, byte[option_data_id+rbx]	;then move in id byte 1
	mov	dword[r15], eax	;put here
	movzx	eax, byte[option_data_id+rbx+1]	;if byte 2
	mov	dword[r15+4], eax	;put after
	cmp	rdi, 255	;check if skipping update thing
	jz	.retpoint
	mov	rax, qword[update_func]	;now update
	jmp	rax
.retpoint:
	ret
f_type_id:
	mov	al, byte[buf1]	;get inputed char
	movzx	rbx, byte[menu_entries+rcx+1]	;get offset of id
	shl	rcx, 1	;correct this val for modify_id.insert_id
	cmp	byte[option_data_id+rbx+1], " "	;check if space is still there at end
	jnz	.clear_id	;if no go here
	mov	byte[option_data_id+rbx+1], al	;otherwise put the input byte into here
	mov	rdi, 255	;without calling update
	jmp	f_modify_id.insert_id	;do this
.clear_id:
	mov	byte[option_data_id+rbx], al	;move in lower val first
	mov	byte[option_data_id+rbx+1], " "	;and a space
	mov	rdi, 255	;without calling update function,
	jmp	f_modify_id.insert_id	;insert said id
f_modify_pos:
	movzx	rbx, byte[menu_entries+rcx+1]
	shl	rcx, 1
	fld	dword[option_data_pos+rbx]	;same as above but with pos !id
	fld	dword[step]	;load step
	cmp	byte[buf1], "+"	;check if +
	jz	.increase_pos	;go here if yes
	fsubr	st1	;otherwisesubtract step
	jmp	.finished_modify
.increase_pos:
	fadd	st1	;add step
.finished_modify:
	fst	dword[option_data_pos+rbx]	;store back
	emms	;clear fpu
	mov	edx, dword[menu_options+rcx]	;move in menu option offset
	lea	r13, [r15+rdx]	;put ascii string here
	lea	r15, [option_data_pos+rbx]	;convert this float
	xor	r14, r14
.get_data_start:
	cmp	dword[r13+r14], "["	;just get r14 to be correct offset
	jz	.convert_float
	add	r14, 4
	jmp	.get_data_start
.convert_float:
	add	r14, 4	;yeah skip square bracket
	call	f_float_ascii	;get ascii string for this
	mov	dword[r13+r14+4], "]"	;then close bracket
	lea	r13, [r13+r14+8]
.loop_clear:
	cmp	dword[r13], "│"	;continue clearing until u get here
	jz	.finish_clear
	mov	dword[r13], " "	;easyto understand
	add	r13, 4
	jmp	.loop_clear
.finish_clear:
	mov	rax, qword[update_func]	;update
	jmp	rax
f_modify_angle:
	movzx	rbx, byte[menu_entries+rcx+1]	;offset
	shl	rcx, 1
	movzx	rax, word[option_data_rot+rbx]	;then get angle
	cmp	byte[buf1], "+"	;check waht operation to do
	jz	.increase_angle
	sub	ax, word[step_angle_int]	;sub step amount
	cmp	ax, 0	;check if its 0
	jge	.dont_reset	;if its okay dont do anything
	add	ax, 360	;otherwise loop around
	jmp	.dont_reset
.increase_angle:
	add	ax, word[step_angle_int]	;same thing
	cmp	ax, 360
	jl	.dont_reset
	sub	ax, 360	;but loop around other way
.dont_reset:
	mov	word[option_data_rot+rbx], ax	;move new val into ax
	mov	rbx, 10	;move divisor
	%rep	2
		xor	rdx, rdx	;repeated divide it to get numbers
		idiv	rbx
		push	rdx
	%endrep
	pop	rdx	;pop back first val
	add	eax, 48	;now add ascii 0 to all
	add	edx, 48
	mov	ebx, dword[menu_options+rcx]	;menu option offset
	mov	r15, qword[framebuf]	;and framebuf
	add	r15, rbx	;add together to get offset
.loop_get_end:
	cmp	dword[r15], "["	;get square bracket thing again...
	jz	.got_end
	add	r15, 4
	jmp	.loop_get_end
.got_end:
	add	r15, 4	;position to put angle
	cmp	eax, 48	;check if first num is 0
	jz	.tens	;if yes dont show it
	mov	dword[r15], eax	;otherwise show it!
	add	r15, 4	;next space
	jmp	.skip_ones	;and skip this comparison
.tens:
	cmp	edx, 48	;check ifsecond is 0
	jz	.ones	;if yes dont show that either
.skip_ones:
	mov	dword[r15], edx	;move in second number
	add	r15, 4
.ones:
	pop	rdx	;pop backthis
	add	edx, 48	;add ascii 0
	mov	dword[r15], edx	;and insert first number!
	add	r15, 4
.finish_insert:
	mov	dword[r15], "]"	;move in square bracket
	mov	dword[r15+4], " "	;and some clears
	mov	dword[r15+8], " "
	mov	rax, qword[update_func]	;then update
	jmp	rax
f_toggle_option:
	xor	rbx, rbx
	mov	r15, qword[points_dat]	;thing for selections
.loop_selection:
	cmp	ebx, dword[point_dat_offset]	;check ifat end
	jz	.cleared_selection	;if yes yeah done
	and	byte[r15+rbx], 0b00000001	;clear all preview/selections
	add	rbx, 4	;add 4
	jmp	.loop_selection	;loop
.cleared_selection:
	not	byte[menu_entries+rcx+1]	;not selected opt
	movzx	rax, byte[menu_entries+rcx+1]	;move into rax
	shl	rcx, 1	;correct rcx to be in multiples of 4
	mov	ebx, dword[menu_options+rcx]	;move in offset for option
	mov	r15, qword[framebuf]	;and framebuf
	add	r15, rbx	;add together
.loop_get_end:
	cmp	dword[r15], "["	;check if at option start bracket thing
	jz	.got_end	;if yes u have end
	add	r15, 4	;otherwise add 4
	jmp	.loop_get_end	;loop over
.got_end:
	add	r15, 4	;go to space between
	mov	dword[r15], " "	;insert a space
	cmp	rax, 0	;if rx is 0
	jz	.cleared_opt	;ur done
	mov	dword[r15], "/"	;otherwise add a /
.cleared_opt:
	mov	rax, qword[update_func]	;update
	jmp	rax
f_apply_points:
	;this func makes the preview points actual points
	mov	r15, qword[framebuf]
	mov	rax, qword[bbar_items.saved]
	insert_str	BBAR_DISABLED
	mov	ax, word[max_id]	;put max id here
	xor	r15, r15	;reset this toget offset of points dat
	mov	r15d, dword[point_dat_offset]
	add	r15, qword[points_dat]	;do that now
.loop:
	cmp	rbx, 0	;rbx is the counter for how many points to 'create'
	jz	.end	;if its nil go to end tho
	inc	al	;otherwise increase the id counter
	cmp	al, 127	;u have done this before its easy
	jnz	.dont_reset
	mov	al, "!"
	inc	ah
.dont_reset:
	mov	byte[r15], 0b00000000	;then CEMENT its place as a new point with a cool colour
	mov	word[r15+1], ax	;and an id of its very own...
	add	dword[point_dat_offset], 4	;coorrrrreeect offsets
	add	qword[edited_obj_offset], 16
	dec	rbx	;decrease counter
	add	r15, 4	;and increase this thing
	jmp	.loop	;keep going now
.end:
	mov	word[max_id], ax	;when done update max id also
	ret
f_update_points:
	;this function updates the position of previous points
	;assumes that rcx contains the offset of the points for single updates
	mov	r15, qword[framebuf]
	mov	rax, qword[bbar_items.saved]
	insert_str	BBAR_DISABLED
	cmp	rbx, 1	;check if multiple updates to do
	ja	.update_selection
	mov	rax, qword[edited_obj_offset]	;offset for this GUY
	movups	xmm0, [r14+rax]	;move thing at end into xmm0
	movups	[r14+rcx], xmm0	;then move into place to update
	mov	dword[r14+rax], 234356	;then finally terminate edited_obj
	ret
.update_selection:
	;for multiple, it assumes its in selection for offset
	mov	rax, qword[edited_obj_offset]	;same here...
	xor	rdi, rdi	;counter
.loop:
	cmp	rbx, 0	;check if iter counter is 0
	jz	.end	;if yea done
	movups	xmm0, [r14+rax]	;save this end addr into xmm0
	mov	edx, dword[selection+rdi]	;move selection addr into rdx
	movups	[r14+rdx], xmm0	;then move the end into here to update
	dec	rbx	;decrease iterator
	add	rdi, 4	;and this thing for addr
	add	rax, 16	;and this thing for other addr
	jmp	.loop
.end:
	add	r15, qword[edited_obj_offset]
	mov	dword[r15], 234356	;then terminate like in the singular one
	ret
f_select_selection:
	movzx	rax, byte[selection_length]	;get selection length here to iter over
	xor	rbx, rbx	;xor this counter
	mov	rdi, 4	;then this starts from 4 to skip offset
.loop_select:
	cmp	rax, 0	;check if finished selecting
	jz	.selected_selection	;if yes go here
	mov	edx, dword[selection+rbx]	;otherwise save the addr of current select to edx
	movups	xmm0, [r14+rdx]	;then save the coords in xmm0
	subps	xmm0, xmm6	;and sub center coords (set xmm6 to 0 if u dont wanna do this)
	movups	[r13+rdi], xmm0	;put it into a buffer for processing (form a matrix)
	sub	edx, 4	;convert edited_obj offset to pointsdat offset
	shr	edx, 2
	or	byte[r15+rdx], r12b	;or it with wanted bitmask
	add	rbx, 4	;go to next selection
	add	rdi, rcx	;correct offset for result matrix
	dec	rax	;decrease counter
	jmp	.loop_select	;and keep going
.selected_selection:
	mov	dword[r13], ecx	;at end, put the matrix size here at start
	mov	dword[r13+rdi], 234356	;and end it properly
	ret
f_append_selection:
	movzx	rax, byte[selection_length]	;selection length for iteration again
	xor	rbx, rbx	;counters...
	xor	rcx, rcx
	xor	rdi, rdi
	xor	r15, r15	;clear high bits
	mov	r15d, dword[point_dat_offset]	;and move in this offset
	add	r15, qword[points_dat]	;then add the addr offset
	mov	r14, qword[edited_obj]	;same offset routine but with this memory
	add	r14, qword[edited_obj_offset]
.loop_append:
	cmp	rax, 0	;check if rax is 0
	jz	.appended_preview	;if yes go hereee
	movups	xmm0, [r13+rbx+4]	;move in transformed data
	addps	xmm0, xmm6	;add back origin
	movups	[r14+rdi], xmm0	;and save it at end of this data thing
	mov	dword[r14+rdi+12], 0x3F800000	;terminate with 1.0
	mov	byte[r15+rcx], 0b00000010	;and set as preview
	mov	word[r15+rcx+1], "  "	;with blank id
	mov	byte[r15+rcx+3], 0b00000001
	add	rbx, rdx	;go to next point
	dec	rax	;decrease counter
	add	rcx, 4	;and go to next other thing
	add	rdi, 16
	jmp	.loop_append
.appended_preview:
	mov	dword[r14+rdi], 234356	;terminate properly
	ret
f_apply:
	mov	r14, qword[edited_obj]	;these are important addresses
	mov	r15, qword[points_dat]	;for making this thing work
	cmp	byte[menu_entries+rsi], 0	;check if selection off
	jnz	.apply_selection	;if its on go here
	cmp	byte[menu_entries+rdi], 0	;check for duplicate opt
	jz	.dont_dupe	;if its off go here
	mov	rbx, 1	;else, just apply one point
	call	f_apply_points	;(create new points pos)
.done:
	ret
.dont_dupe:
	mov	ax, word[option_data_id]	;put this here
	call	f_get_id_offset	;get offset (rcx and rdx set)
	mov	rbx, 1	;only 1 opt
	call	f_update_points	;then update old point pos
	jmp	.done
.apply_selection:
	movzx	rbx, byte[selection_length]	;move in option for functions
	cmp	byte[menu_entries+rdi], 0	;check if duplicate
	jnz	.new_from_selection	;if yes use apply_points
	call	f_update_points	;otherwise use update points
	jmp	.done
.new_from_selection:
	call	f_apply_points
	jmp	.done
f_save_file:
	mov	byte[working_file], 0	;move in a 0
.check_saved:
	cmp	byte[working_file], 0	;check if this is 0
	jnz	.new_file	;if its not then just save normally w/o dialog
	mov	r9, qword[row_width_editor]	;otherwise, put this here
	get_box_tl_editor	FLOAD_WIDTH, FLOAD_HEIGHT	;and get tl
	mov	r15, qword[framebuf]	;this is needed
	prepare_zone	FLOAD_WIDTH, FLOAD_HEIGHT	;now clear the zone!! addr of start in rax
	mov	byte[buf2], 255	;put this in buf2, its to indicate save mode for open file dialog
	lea	r14, [buf3]	;use whatever for msg
	call	f_open_file_dialog.insert_editor	;get save dialog
	cmp	rax, -1	;check if rax is -1 (pressed esc)
	jz	.retpoint	;if yes, dont do anything
	movzx	rax, word[cwd_end]	;get end of cwd otherwise
	mov	dword[cwd_file+rax], ".l3d"	;and insert extension
	mov	byte[cwd_file+rax+4], 0	;then move a 0 after that
	mov	rax, 2	;open syscall, check if file exists
	mov	rdi, cwd_file
	xor	rsi, rsi
	syscall
	cmp	rax, 3	;check if rax is 3
	jl	.new_file	;if its lower then the file is a new file
	mov	rdi, rax	;otherwise, close the file
	mov	rax, 3
	syscall
	get_box_tl_editor	FLOAD_WIDTH, FLOAD_HEIGHT	;get tl for editor
	add	rax, 13	;skip escape
	mov	r9, qword[row_width_editor]	;now get row width here also
	mov	rbx, FLOAD_WIDTH	;and then get offset a width
	sub	rbx, L3D_OW_WIDTH	;subtract another window width
	shl	rbx, 1	;then half
	add	rax, rbx	;add to offset
	mov	rbx, FLOAD_HEIGHT >> 1	;and do same thing for height now
	sub	rbx, L3D_OW_HEIGHT >> 1
	imul	rbx, qword[row_width_editor]	;multiply by rows
	add	rax, rbx	;and add
	mov	word[choice_width], L3D_OW_WIDTH	;now create a choice menu of said dimensions
	mov	word[choice_height], L3D_OW_HEIGHT
	lea	r14, [confirm_ow_str]	;with this str
	call	f_choice_menu.insert_editor
	cmp	byte[choice], 255	;check if choice is no
	jz	f_save_file	;if yes loop over
.new_file:
	mov	byte[project_saved], 255	;save project
	mov	r15, qword[edited_obj]	;move this addr in
	mov	dword[r15+16], 16	;now modify this so it doesnt save origin point
	mov	r14, qword[edited_faces]	;and put this addr here
.loop_dec:
	cmp	word[r14], 65535	;check if at end of struct
	jz	.end_dec	;if yes done
	dec	word[r14]	;otherwise decrease each face index
	dec	word[r14+2]
	dec	word[r14+4]
	add	r14, 8	;and go to next face
	jmp	.loop_dec	;looping over
.end_dec:
	mov	r15, qword[edited_obj]	;once done, go into here
	add	r15, 16	;and add a 16 to skip origin
	mov	r14, qword[edited_faces]	;and use this
	lea	r10, [working_file]	;and this for file to save to
	cmp	byte[working_file], 0	;check if not set
	jnz	.use_saved_addr	;if no then use it
	lea	r10, [cwd_file]	;otherwise use this
.use_saved_addr:
	call	f_write_obj	;save the object
	mov	r14, qword[edited_faces]	;and put this back here
.loop_inc:
	cmp	word[r14], 65535	;then increase points again
	jz	.retpoint
	inc	word[r14]
	inc	word[r14+2]
	inc	word[r14+4]
	add	r14, 8
	jmp	.loop_inc
.retpoint:
	mov	r15, qword[edited_obj]	;use this thing here
	mov	dword[r15+16], 0x3F800000	;and insert a 1.0 so origin terminates properly
	jmp	f_open_file.transfer_cwd	;go to other function to save cwd addr
f_new_file:
	mov	r9, qword[row_width_editor]
	cmp	byte[project_saved], 255
	jz	.skip_new_prompt
	get_box_tl_editor	EDITOR_UNSAVED_WIDTH, EDITOR_UNSAVED_HEIGHT	;otherwise get tl for dialog
	mov	r15, qword[framebuf]	;and put framebuf here
	prepare_zone	EDITOR_UNSAVED_WIDTH, EDITOR_UNSAVED_HEIGHT	;prepare a zone for it
	mov	word[choice_width], EDITOR_UNSAVED_WIDTH	;new choice menu init
	mov	word[choice_height], EDITOR_UNSAVED_HEIGHT
	lea	r14, [confirm_unsaved_str]	;and str to use
	call	f_choice_menu.insert_editor	;choice menu!
	cmp	byte[choice], 0	;check if byte for said choice is 0
	jnz	.retpoint	;if not wanting to open, return
.skip_new_prompt:
	mov	r15, qword[edited_obj]
	mov	r14, qword[edited_faces]
	mov	dword[r15+20], 234356
	mov	word[r14], 65535
	mov	qword[edited_obj_offset], 20
	mov	dword[point_dat_offset], 4
	mov	qword[edited_faces_offset], 0
	mov	byte[selection_length], 0
	mov	byte[project_saved], 255
	mov	byte[working_file], 0
	mov	word[max_id], "!!"
.retpoint:
	mov	byte[scope], -1
	mov	r15, qword[framebuf]
	ret
f_open_file:
	mov	r9, qword[row_width_editor]	;use this here again its important
	cmp	byte[project_saved], 255	;and check if project is saved
	jz	.skip_load_prompt	;if yes then skip load prompt as label says
	get_box_tl_editor	EDITOR_UNSAVED_WIDTH, EDITOR_UNSAVED_HEIGHT	;otherwise get tl for dialog
	mov	r15, qword[framebuf]	;and put framebuf here
	prepare_zone	EDITOR_UNSAVED_WIDTH, EDITOR_UNSAVED_HEIGHT	;prepare a zone for it
	mov	word[choice_width], EDITOR_UNSAVED_WIDTH	;new choice menu init
	mov	word[choice_height], EDITOR_UNSAVED_HEIGHT
	lea	r14, [confirm_unsaved_str]	;and str to use
	call	f_choice_menu.insert_editor	;choice menu!
	cmp	byte[choice], 0	;check if byte for said choice is 0
	jnz	.retpoint	;if not wanting to open, return
.skip_load_prompt:
	lea	r14, [open_obj_str]	;now open file dialog
	get_box_tl_editor	FLOAD_WIDTH, FLOAD_HEIGHT	;use this tl
	mov	r15, qword[framebuf]	;and r15 ofc
	prepare_zone	FLOAD_WIDTH, FLOAD_HEIGHT	;and prepare the zone again
	mov	byte[buf2], 0	;not a save file dialog
	call	f_open_file_dialog.insert_editor	;open file!
	cmp	rax, -1	;check if returned as esc
	jz	.retpoint	;if yes return
	movzx	rax, word[cwd_end]	;otherwise load end
	cmp	dword[cwd_file+rax-4], ".l3d"	;and check if extension valid
	jz	.continue_load	;if yes continue loading
	get_box_tl_editor	FLOAD_WIDTH, FLOAD_HEIGHT	;otherwise, get editor tl again
	add	rax, 13	;skip escapes
	mov	r9, qword[row_width_editor]	;and the newl thing
	mov	rbx, FLOAD_WIDTH	;and p much another choice menu, similar to f_save_file
	sub	rbx, LSC_WARN_WIDTH
	shl	rbx, 1
	add	rax, rbx
	mov	rbx, FLOAD_HEIGHT >> 1
	sub	rbx, NR_WARN_HEIGHT >> 1
	imul	rbx, qword[row_width_editor]
	add	rax, rbx	;final offset
	mov	word[choice_width], LSC_WARN_WIDTH	;choice init againnnn
	mov	word[choice_height], NR_WARN_HEIGHT
	lea	r14, [confirm_n3d_str]
	call	f_choice_menu.insert_editor	;create choice menu
	cmp	byte[choice], 0	;check if chose not to load file
	jnz	.skip_load_prompt	;if yes loop over
.continue_load:
	lea	r15, [cwd_file]	;if the file load was wanted, load cwd file here
	mov	r12, qword[edited_obj]	;addr of place to save data
	add	r12, 16	;offset to skip origin
	mov	byte[load_editor], 255	;so it knows to put data in r12
	call	f_read_obj	;read the object chosen
	mov	r15, qword[edited_obj]	;now load that addr to r15
	mov	dword[r15+16], 0x3F800000	;and put a 1.0 after origin
	add	r15, 20	;add 20 to skip origin
	mov	r14, qword[points_dat]	;points dat addr
	add	r14, 4	;skip origin data again
	mov	qword[edited_obj_offset], 20	;clear offsets p much
	mov	dword[point_dat_offset], 4
	mov	ax, "!!"	;and move a !! in here for id assigning
.loop_assign_ids:
	cmp	dword[r15], 234356	;check if at end of id assigns
	jz	.finish_assign_ids	;if yes stop
	inc	al	;otherwise, increase current id
	cmp	al, 127	;check if overflow
	jnz	.dont_reset	;if no, dont increase ah
	mov	al, "!"	;otherwise guess what
	inc	ah
.dont_reset:
	mov	byte[r14], 0b00000000	;put a 0 in here for normal point
	mov	word[r14+1], ax	;save id here
	mov	byte[r14+3], 0b00000001	;and this is for culling backfaces
	add	r14, 4	;next points_dat thing
	add	r15, 16	;and next point
	add	qword[edited_obj_offset], 16	;offset correction
	add	dword[point_dat_offset], 4
	jmp	.loop_assign_ids	;loop over
.finish_assign_ids:
	mov	word[max_id], ax	;once done, set max id
	add	r15, 4	;and add 4 to the counter for this to skip end 234356
	mov	r14, qword[edited_faces]	;move in faces thing
	mov	qword[edited_faces_offset], 0	;and set this to 0
.loop_move_faces:
	cmp	word[r15], 65535	;now, check if at end
	jz	.finish_move_faces	;if yes done
	mov	rax, qword[r15]	;otherwise, move data into rax
	mov	qword[r14], rax	;and transfer it to the edited_faces struct
	inc	word[r14]	;and increase indexes
	inc	word[r14+2]
	inc	word[r14+4]
	add	r15, 8	;next face
	add	r14, 8	;for both structs
	add	qword[edited_faces_offset], 8	;correct offset again
	jmp	.loop_move_faces	;and loop over
.finish_move_faces:
	mov	byte[project_saved], 255	;set project as saved
	mov	byte[selection_length], 0
	mov	word[r14], 65535	;and terminate this str
.transfer_cwd:
	xor	rcx, rcx	;now xor this counter
.loop_transfer:
	mov	al, byte[cwd_file+rcx]	;move byte in cwd here
	mov	byte[working_file+rcx], al	;and put it in working file
	cmp	al, 0	;check if al was null terminator
	jz	.retpoint	;if yes done
	inc	rcx	;otherwise increase counter
	jmp	.loop_transfer	;and loop over
.retpoint:
	mov	byte[scope], -1	;now, set scope to reset
	mov	r15, qword[framebuf]	;this needs to be so
	ret	;return
f_modify_ascii:
	push	rax	;this is actually used in the angle increase function
	mov	r10, rax	;save this to r10 bc rax must be used for div
	mov	rax, rbx	;move in value to convert into rax
	mov	rbx, 10	;and divisor is 10
	%rep	2	;rep 2 times (3 digits),
		xor	rdx, rdx	;reset rdx bc it changes div sometimes
		idiv	rbx	;divide by 10
		push	rdx	;and push remainder
	%endrep
	pop	rdx	;pop back first val
	add	eax, 48	;add ascii 0 to all of them
	add	edx, 48
	cmp	eax, 48	;check if eax is ascii 0
	jz	.tens	;if yes skip displaying it
	mov	dword[r15+r10], eax	;otherwise do display it!
	add	r10, 4	;add 4 to next dword
	jmp	.skip_ones	;and skip comparison for rdx="0"
.tens:
	cmp	edx, 48	;check if rdx is 0 also
	jz	.ones	;if it is the only display 1 digit
.skip_ones:
	mov	dword[r15+r10], edx	;otherwise put rdx in here
	add	r10, 4	;and next dword
.ones:
	pop	rdx	;pop back final rdx
	add	edx, 48	;add 0
	mov	dword[r15+r10], edx	;and then move it here
	mov	dword[r15+r10+4], " "	;for values with only 1 digit fill with " " to clear
	mov	dword[r15+r10+8], " "
	pop	rax	;pop back rax
	ret	;and done!
