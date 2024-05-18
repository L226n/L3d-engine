%include	"definitions.asm"
%include	"editor.asm"
%include	"input.asm"
%include	"matrix.asm"
%include	"graphics.asm"
%include	"math.asm"
%include	"files.asm"
%include	"gui.asm"
;external files
section	.data
	msg	db	"msg", 10
	matrix_screen	dd	16, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 234356
	matrix_projection	dd	16, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 234356
	matrix_camera_rotate	dd	16, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 234356
	matrix_camera_translate	dd	16, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, -0.5, -1.0, 3.9, 1.0, 234356
	matrix_rotation_x	dd	16, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 234356
	matrix_rotation_y	dd	16, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 234356
	matrix_rotation_z	dd	16, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 234356
	matrix_translate	dd	16, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 234356
	matrix_fwd	dd	16, 0.0, 0.0, 1.0, 1.0, 234356
	matrix_up	dd	16, 0.0, 1.0, 0.0, 1.0, 234356
	matrix_right	dd	16, 1.0, 0.0, 0.0, 1.0, 234356
	matrix_fwd_2	dd	16, 0.0, 0.0, 1.0, 1.0, 234356
	matrix_up_2	dd	16, 0.0, 1.0, 0.0, 1.0, 234356
	matrix_right_2	dd	16, 1.0, 0.0, 0.0, 1.0, 234356
	camera_pitch	dd	0.0
	camera_yaw	dd	0.0
	align	16
	translation	dd	0, 0, 0, 0
	matrix_camera	times 18	dd	0.0
	;matrix labels
	camera_h_fov	dd	1.0471975511965976
	camera_v_fov	dd	0
	;camera field of views
	camera_near_plane	dd	0.1
	camera_far_plane	dd	100.0
	;camera viewing planes
	one	dd	1.0
	two	dd	2
	three	dd	3
	eight	dd	8.0
	nearly_one	dd	0.99
	;2
	angle	dd	0.05
	cube_angle	dd	0.0
	;this is a buffer for rotation angles
	angle_neg	dd	-0.05
	;and this is the negative version
	obj_matrix	dd	16, -0.5, -0.5, -0.5, 1.0, 0.5, -0.5, -0.5, 1.0, -0.5, 0.5, -0.5, 1.0, 0.5, 0.5, -0.5, 1.0, -0.5, -0.5, 0.5, 1.0, 0.5, -0.5, 0.5, 1.0, -0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.0, 234356
	obj_faces	dw	0, 1, 2, 65534, 3, 2, 1, 65534, 2, 3, 6, 65534, 7, 6, 3, 65534, 3, 1, 5, 65534, 7, 3, 5, 65534, 1, 0, 4, 65534, 4, 5, 1, 65534, 0, 2, 4, 65534, 4, 2, 6, 65534, 4, 7, 5, 65534, 4, 6, 7, 65534, 65535
	obj_uv	dd	0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 234356
	obj_texture	db	"239", "239", "239", "239", "239", "239", "239", "239"
			db	"239", "244", "244", "244", "244", "244", "244", "239"
			db	"239", "244", "244", "244", "244", "244", "244", "239"
			db	"239", "244", "244", "244", "244", "244", "244", "239"
			db	"239", "244", "244", "244", "244", "244", "244", "239"
			db	"239", "244", "244", "244", "244", "244", "244", "239"
			db	"239", "244", "244", "244", "244", "244", "244", "239"
			db	"239", "239", "239", "239", "239", "239", "239", "239"
	dimensions	dw	8, 8
	;these are matrices for a whatever
	obj_aux_0	times 402	dd	0.0
	obj_aux_1	times 402	dd	0.0
	obj_aux_2	times 402	dd	0.0
	matrix_ndc	times 402	dd	0.0
	;+ aux versions
	unit_template	db	27, "[48;5;232m  "
	;template for units
	screen_size	dd	0
	;buffer for screen size
	unit_size	dd	13
	;size of a unit
	align	16
	buf1	dd	0, 0, 0, 0
	buf2	dd	0
	buf3	dq	0
	buf4	dq	0
	;buffers
	line_start	dd	0.0, 0.0
	line_end	dd	8.0, 8.0
	line_buf	dd	0.0, 0.0
	line_val	dd	0.0
	line_i	dd	1.0, -1.0
	line_int	dd	0, 0
	;buffers for line drawing alg
	movement_speed	dd	0.2
	;movement speed
	align	16
	camera_position_cull	dd	0.0, 0.0, -3.0
	camera_position	dd	0.0, 0.0, -3.0
	;camera position matrix
	poll	dq	0
	framebuf	dq	0
	frames	dq	0
	;address storage
	fps_counter	dd	48, 48
	location_string	times 32	dd	" "
	;various stats counter
	fps_space	dd	0
	keys_space	dd	0
	location_space	dd	0
	;address spaces
	available_window	dw	0
	time:
		tv_sec	dq	0
		tv_usec	dq	33333333
	frame_start	dq	0
	frame_start_sec	dq	0
	frame_delta	dq	1000000000
	frame_raw_delta	dq	1000000000
	;time struct
	handler_int:
		dq	f_int
		dd	0x04000000
	handler_seg:
		dq	f_seg
		dd	0x04000000
	;signal handler struct
	float_test	dd	-9.38
	float_multiplier	dd	10000.0
	cw	dw	0
	;fpu control word
	file_separator	dw	65535
	;separator between 1 and 0
	file	db	"../Resources/tetrapod.lsc", 0, "xxxxxxxxxxxxxxxxxxxxxxx"
	;file path
	filesize	dq	0
	;size of file data
	mem_available	dq	0
	;available memory
	last_memory	dq	0
	;last memory addr  space
	reserved_pos	dw	0
	;position in reserved memory buffer
	imported_addr	dq	0, 0, 0, 0
	;place to store address of all the object stuff for current iteration
	mainloop	dq	0
	;place to store address of mainloop info
	translation_index	dq	0
	;index of mainloop to continue back from
	center_coords	dd	0.0, 0.0, 0.0
	;coords for point extrusion maybe other stuff in future
	operation_multiplier	dd	2.0
	;multiplier for point extrusion
	vertex_depth	dd	0.0
	;used in texture mapping for storing depth of vertex
	vertex_dist	dd	0.0
	bounding_box	dq	0, 0, 0, 0
	;also texture mapping to get the box in which a triangle exists
	interpolated_uvd	dd	0, 0, 0
	;pretty easy
	scene_meta	db	"tetrapod.l3d", 0, "tetrapod.luv", 0, "tetrapod.ltx", 10
	obj_count	dw	1
	init_info	db	255
			db	0
			db	"075"
			db	1
			dw	1
			dd	0.0, 0.0, 5.0
			db	1
			dw	2
			dd	0.0, 0.5, 3.0
			db	1
			dw	3
			dd	-1.0, 1.5, 7.0
			db	255
	obj_addr	dq	0
	;address holder for allll object info thats alot
	obj_addr_counter	dq	0
	;counter for where u are in the thing
	obj_counter	db	0
	;counts which object ur iterating over
	point_depth	dd	-1.0
	;holds depth of point to be passed to depth buffer
	sky_colour	db	"232"
	;guess what
	align	16
	triangle	dd	0, 0, 0, 0, 0, 0
	;stores triangle points
	align	16
	bc_vectors	dd	0, 0, 0, 0, 0, 0, 0, 0
	;stores vectors used in barycentric calcs
	align	16
	point	dq	0, 0
	;another thing used for barycentrics
	align	16
	edge_vector_a	dd	0, 0, 0, 0
	;temporary buffers tbh
	align	16
	edge_vector_b	dd	0, 0, 0, 0
	align	16
	cross_product	dd	0, 0, 0, 0
	;used to store cross products
	align	16
	simd_ones	dd	1.0, 1.0, 1.0, 1.0
	align	16
	simd_zeros	dd	0.0, 0.0, 0.0, 0.0
	;these 2 are used for counters
	aux_counter	db	0
	;this is to count which aux buffers to use in which order
	;however it doesnt seem like it changes anything so for now it does nothing
	message_clear	db	"  "
	;clears old msg parts, stored in mem for compatability with f_draw_ui
	alerted	db	0
	;bool for alerted
	alert_tick	dq	0
	;ticker for alert duration
	alert_end	db	0
	;byte to tell engine to clear message
	alert_y_offset	dw	0
	;y offset for msg
	alert_x_offset	dw	0
	;x offset
	screen_x_center	dw	0
	;center of screen
	paused	db	0
	wireframe	db	0
	culling	db	255
	type_id	db	0
	;bools for various settings
	white_ansi	db	"231"
	black_ansi	db	"232"
	red_ansi	db	"124"
	blue_ansi	db	"019"
	yellow_ansi	db	"172"
	green_ansi	db	"034"
	purple_ansi	db	"092"
	alpha_ansi	db	"000"
	converted_ansi	db	"0000"
	editor_invis_ansi	db	"016"
	;ansi codes for various things (in memory for compat)
	print_length	dq	0
	;length of framebuf used sometimes messy code strikes again
	selected_option	dw	0
	;store offset of arrow selector p much
	base_brk	dq	0
	;base program brk
	brk_reserved	dq	0
	;amount reserved
	clear	db	27, "[H", 27, "[J"
	;clear sequence
	brk	dq	0
	;what
	brk_len	dq	0
	;whats the difference
	previous_written	dq	0
	;used to see if enough memory allocated in sys_getdents loop
	current_scroll	dw	0
	;current files scroll
	file_count	dw	0
	;number of files in dir
	round_errors	db	0
	;bubble sort errors in round
	cwd_end	dw	0
	;end of cwd string position
	first_run	db	0
	;not sure if this is actually used
	pad_row	db	0
	;pad row byte
	up_dir	db	"..", 0
	;up a dir thingie
	choice	db	0
	;return from choice window
	choice_width	dw	0
	choice_height	dw	0
	;words for size of choice window
	editor	db	0
	;editor bool
	preview_width	dw	0
	preview_height	dw	0
	main_width	dq	0
	max_width	dq	0
	max_height	dq	0
	offset_graphics_window	dq	0
	row_width_editor	dq	0
	row_width_bars	dq	0
	;values for offset graphics window
	edited_obj	dq	0
	edited_obj_len	dd	0
	edited_obj_available	dw	0
	edited_faces	dq	0
	edited_faces_len	dd	0
	edited_faces_available	dw	0
	points_dat	dq	0
	points_dat_len	dd	0
	points_dat_available	dw	0
	edited_texture	dq	0
	edited_texture_len	dd	0
	edited_texture_available	dw	0
	edited_uv	dq	0
	edited_uv_len	dd	0
	edited_uv_available	dw	0
	lbar_offset	dq	0
	bbar_offset	dq	0
	option_divisor	db	0
	scope	db	0
	steps:
		step_xs	dd	0.001
		step_s	dd	0.01
		step_m	dd	0.1
		step_l	dd	1.0
	step	dd	0.1
	step_angle_int	dw	1
	step_angle	dd	0.01745329251
	current_step	db	8
	current_step_angle	db	0
	update	db	0, 0
	max_id	db	"!!"
	jump_point	dq	0
	edited_obj_offset	dq	20
	edited_faces_offset	dq	0
	edited_uv_offset	dq	0
	point_dat_offset	dd	4
	line_colour	dq	0
	update_func	dq	0
	apply_func	dq	0
	operation_angle	dd	0, 0, 0
	selection_length	db	0
	error_space	db	0
	load_editor	db	0
	project_saved	db	255
	project_saved_3d	db	255
	project_saved_tx	db	255
	edit_texture	db	0
	texture_pos	dw	0, 0
	texture_offset	dw	0, 0
	texel_mode	dw	0
	color_pri	db	0b10000000, "16"
	color_sec	db	0b10000000, "16"
	use_secondary	db	0
	int_ui_limit	dw	360
	pen_prev_pos	dq	0
	usec	dq	UDELTA
	fd_old	dq	0
	rspbuf	dq	0
	pollfd:
		dd	0
		dw	1
		dw	0
	bbar_items:
		.scope	dq	0
		.culling	dq	0
		.typeid	dq	0
		.selection	dq	0
		.vertices	dq	0
		.triangles	dq	0
		.saved	dq	0
	start_menu:
		dd	"╭", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "╮"
		dd	"│", " ", " ", "_", " ", " ", " ", " ", " ", " ", "_", "_", "_", "_", "_", "_", "_", "_", " ", " ", " ", "│"
		dd	"│", " ", "|", " ", "|", " ", " ", " ", " ", "|", "_", "_", "_", " ", " ", " ", "_", " ", "\", " ", " ", "│"
		dd	"│", " ", "|", " ", "|", " ", " ", " ", " ", " ", " ", "|", "_", " ", " ", "|", " ", "|", " ", "|", " ", "│"
		dd	"│", " ", "|", " ", "|", "_", "_", "_", " ", " ", "_", "_", "_", ")", " ", "|", "_", "|", " ", "|", " ", "│"
		dd	"│", " ", "|", "_", "_", "_", "_", "_", "|", "|", "_", "_", "_", "_", "_", "_", "_", "_", "/", " ", " ", "│"
		dd	"│", " ", "V", "0", ".", "3", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "│"
		dd	"│", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "│"
		dd	"│", " ", ">", " ", "L", "o", "a", "d", " ", "g", "a", "m", "e", " ", " ", " ", " ", " ", " ", " ", " ", "│"
		dd	"│", " ", " ", " ", "E", "d", "i", "t", "o", "r", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "│"
		dd	"│", " ", " ", " ", "C", "r", "e", "d", "i", "t", "s", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "│"
		dd	"│", " ", " ", " ", "E", "x", "i", "t", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "│"
		dd	"╰", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "─", "╯"
	timer:
		timer_seconds	dq	0
		timer_nanoseconds	dq	0
	mainloop_info:
		dw	0	;object index (fish)
		db	0	;transformation condition (always)
		db	1	;transformation type (rotation)
		db	1	;rotation axis (y)
		dd	0.03	;rotation increment 
		dd	0.0	;current rotation
		dw	-1
		dw	0	;another object index again it is a FISH
		db	0	;condition is always
		db	0	;set position
		dd	3.0, 0.7, 3.0	;position to set
		dw	0
		db	0
		db	2	;translate with function (+3)
		db	0	;function to use (sin) (+4)
		dd	0.0, 0.3, 0.0	;translation (+5)
		dd	0.1	;function increment (+17)
		dd	0.0	;current value to pass to function (+21)
		dw	3
		db	0
		db	2	;translate with function (+3)
		db	0	;function to use (sin) (+4)
		dd	1.0, 0.0, 0.0	;translation (+5)
		dd	0.2	;function increment (+17)
		dd	0.0	;current value to pass to function (+21)
		dw	3
		db	0
		db	2	;translate with function (+3)
		db	1	;function to use (cos) (+4)
		dd	0.0, 0.0, 1.0	;translation (+5)
		dd	0.2	;function increment (+17)
		dd	0.0	;current value to pass to function (+21)
		dw	-1	;end
	resize_msg	db	"This software only works if your terminal size is ≥ 102x20!", 10
	resize_len	equ	$ - resize_msg
	even_msg	db	"This software only works if your terminal width is even!", 10
	even_len	equ	$ - even_msg
	exit_msg	db	"Program exited with code ", 48, 0, 0, 0, 10
	exit_len	equ	$ - exit_msg
	exit_code_offset	equ	25
	open_game_str	db	"Open .lgm/.lsc files", 0
	open_obj_str	db	"Open .l3d files", 0
	open_tex_str	db	"Open .ltx files", 0
	confirm_lsc_msg:
		db	"WARNING: .lsc files represent a particular", 1
		db	"scene in a game, rather than the full game.", 1
		db	"The file can still be loaded, however the", 1
		db	"scene will not act the same way that it", 1
		db	"would in a full game, and will instead be", 1
		db	"loaded with L3d defaults. Load anyway?", 0
	confirm_nr_msg:
		db	"WARNING: The selected file does not have", 1
		db	"an extension recognised by L3d as a", 1
		db	"playable file, you can still load the", 1
		db	"file but the data may not be valid. Load", 1
		db	"anyway?", 0
	confirm_n3d_str:
		db	"WARNING: The selected file does not have", 1
		db	"an extension recognised by L3d as a", 1
		db	"3d object file, you can still load the", 1
		db	"file but the data may not be valid. Load", 1
		db	"anyway?", 0
	confirm_unsaved_str:
		db	"WARNING: Your project has unsaved", 1
		db	"changes, which will be lost when", 1
		db	"loading a new object, load anyway?", 0
	confirm_ow_str:
		db	"WARNING: The file you chose already", 1
		db	"exists, and saving will overwrite", 1
		db	"the already existing file, save", 1
		db	"anyway?", 0
	save_type_str	db	"Save file type", 0
	save_uv	db	"Save UV file", 0
	save_obj	db	"Save 3d file", 0
	editor_err:
		db	27, "[31"
		dd	"m"
		dd	"ER"
		dd	"RO"
		dd	"R_"
	pen_prev:
		db	27, "[48;5;000m 0", 27, "[48;5;000m 0", 27, "[0m     ", 0
	;various messages
	working_file	dq	working_file_3d
section	.bss
	termios:
		c_iflag	resd	1
		c_oflag	resd	1
		c_cflag	resd	1
		c_lflag	resd	1
		c_line	resb	1
		c_cc	resb	1
	;terminal struct
	input_buf	resb	4
	;buffer for various input
	window_size	resw	8
	;window size struct
	pipe	resd	2
	;pipe fd
	reserved_memory	resq	100
	;array for start addresses and lengths of reserved memory
	dot_products	resd	5
	denom	resq	1
	barycentric	resd	3
	vertex_attr	resd	12
	files	resb	96
	depth_buffer	resd	38400
	message	resb	128
	cwd_file	resb	1024
	file_indexes	resd	FLOAD_HEIGHT-3
	file_swap_buffer	resb	512
	menu_options	resd	50
	;menu options offsets
	menu_entries	resw	50
	option_data_id	resw	10	;10 id slots
	option_data_rot	resb	36	;18 rotation slots
	option_data_pos	resd	9	;9 translation slots
	selection	resd	50
	working_file_3d	resb	100
	working_file_tx	resb	100
	working_file_uv	resb	100
section	.text
	global	_start
_start:
	lea	r15, [scene_meta]
	lea	r14, [obj_count]
	lea	r13, [init_info]
	lea	r12, [mainloop_info]
	call	f_write_scene
	finit	;initialise FPU control words
	fstcw	word[cw]	;stores current control word in cw
	and	word[cw], 0xFCFF	;uses bitmasks to change
	or	word[cw], 0x0C00	;to truncating on fist/p
	fldcw	word[cw]	;load the new control word
	mov	rax, 12	;sys_brk woof!!!!!!! (sorry)
	xor	rdi, rdi	;0 to get current brk
	syscall
	mov	qword[base_brk], rax
	mov	rax, 13	;system call for sys_rt_sigaction
	mov	rdi, 2	;signal here is SIGINT
	mov	rsi, handler_int	;handler structure
	mov	rdx, 0	;previous struct is nil
	mov	r10, 8	;size of something who knows it works
	syscall
	mov	rax, 13	;sys_rt_sigaction again
	mov	rdi, 11	;SIGSEGV this time
	mov	rsi, handler_seg
	syscall
	mov	rax, 16	;system call for sys_ioctl
	mov	rdi, 1	;stdout
	mov	rsi, 21505	;TCGETS
	mov	rdx, termios	;buffer
	syscall
	and	dword[c_lflag], ~(1 << 1)	;clears canonical flag
	and	dword[c_lflag], ~(1 << 3)	;clears the echo flag
	mov	rax, 16	;system call for sys_ioctl
	mov	rdi, 1	;stdout
	mov	rsi, 21506	;TCSETS
	mov	rdx, termios	;buffer
	syscall
	mov	rax, 16	;system call for sys_ioctl
	mov	rdi, 1	;stdout
	mov	rsi, 21523	;TIOCGWINSZ
	mov	rdx, window_size	;buffer for window size
	syscall
	cmp	word[window_size], 20	;you can guess here
	jl	.term_small
	cmp	word[window_size+2], 102
	jl	.term_small
	jmp	.term_ok
.term_small:
	mov	rax, 1	;print 'too small' string
	mov	rdi, 1
	mov	rsi, resize_msg	;msg and len are stored
	mov	rdx, resize_len
	syscall
	mov	dword[exit_msg+exit_code_offset], "0" << 24	;move in 0 to say successful exit
	mov	r15, -1	;some sorta param
	call	f_kill
.term_ok:
	movzx	rax, word[window_size]	;move window height into rax
	sub	rax, 3	;sub 3 to get available window space
	mov	word[available_window], ax	;
	sub	rax, 2
	mov	word[alert_y_offset], ax
	test	word[window_size+2], 1	;test LSB of rax 
	jz	.term_even	;if its even skip killing bc of width
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, even_msg
	mov	rdx, even_len
	syscall
	mov	dword[exit_msg+exit_code_offset], "0" << 24
	mov	r15, -1
	call	f_kill
.term_even:
	shr	word[window_size+2], 1
	movzx	rax, word[window_size+2]	;moves window width into rax
	mov	word[screen_x_center], ax
	shr	word[screen_x_center], 1
	mul	word[window_size]	;multiply window height by width
	mov	rbx, 13	;then multiplies it by 13 (one unit is 13 bytes)
	mul	rbx	;actual multiplication
	mov	dword[screen_size], eax	;moves result into screen size
	mov	rax, 9	;sys_mmap
	mov	rdi, 0	;automatic offset
	mov	rsi, 499712	;size to reserve (multiple of 4096)
	mov	rdx, 3	;PROT_READ and PROT_WRITE are true
	mov	r10, 1 | 32	;MAP_SHARED and MAP_ANONYMOUS are true
	mov	r8, -1	;anonymous mapping so no fd needed
	mov	r9, 0	;some other automatic thing
	syscall
	mov	qword[poll], rax	;polling memory is start of region
	mov	qword[frames], rax	;frame counter
	add	qword[frames], 8	;frame counter is after polling memory
	mov	qword[framebuf], rax	;framebuf is uh
	add	qword[framebuf], 16	;same thing but 16 bytes after
	call	f_start_menu
	cmp	byte[editor], 255
	jnz	.not_editor
	call	f_editor
.not_editor:
	call	f_initialise_screen	;prepare the screen for display
	lea	r15, [window_size]
	lea	r14, [window_size+2]
	call	f_init_matrices
	call	f_pos_string	;generate location string
	call	f_insert_location	;then insert it into framebuf
	call	f_read_scene	;read the selected scene now
	movzx	rax, word[window_size+2]	;move in window width
	imul	rax, UNIT_SIZE	;multiply by unit size now
	mov	qword[main_width], rax	;and store as main width (screen width bytes)
	sub	rax, UNIT_SIZE	;subtract this 
	mov	qword[max_width], rax	;and now this is max x pos
	movzx	rbx, word[window_size]	;use y pos
	sub	rbx, 4	;subtract task bar thing
	add	rax, UNIT_SIZE	;get row length now
	imul	rax, rbx	;and mul by height
	mov	qword[max_height], rax	;to get max height!
.loop:
	mov	qword[rspbuf], rsp	;store stack pointer here for draw ordering
	mov	rax, [poll]	;moves the address of the shared memory for polling 
	mov	qword[rax], 0	;then clears the previously polled inputs
	mov	rax, [frames]	;moves address for frames into rax
	inc	dword[rax]	;increases it so a successful frame is counted	
	mov	rax, UFRAME	;move frame time in ns into rax
	sub	rax, qword[frame_raw_delta]	;now subtract the delta, get time remaining in frame
	mov	qword[tv_sec], 0	;reset this
	mov	qword[tv_usec], rax	;now wait for that amount of time
	mov	rax, 35	;sys_nanosleep
	mov	rdi, time	;this struct
	xor	rsi, rsi
	syscall
	mov	rax, 228	;sys_gettime
	mov	rdi, 4	;use CLOCK_MONOTONIC_RAW
	mov	rsi, time	;put the results here
	syscall
	mov	rbx, qword[tv_usec]	;move in nanoseconds
	sub	rbx, qword[frame_start]	;and subtract time in frame start
	mov	rax, qword[tv_sec]	;same with seconds
	sub	rax, qword[frame_start_sec]
	mov	rcx, USEC	;move 1s in nanoseconds into rcx
	mul	rcx	;now multiply seconds time difference by that
	add	rax, rbx	;and add nanosecond time to get time delta
	mov	qword[frame_delta], rax	;store here
	mov	rax, qword[tv_usec]	;move in the nanoseconds currently
	mov	rbx, qword[tv_sec]	;and seconds
	mov	qword[frame_start], rax	;then store in frame start thing (new area p much)
	mov	qword[frame_start_sec], rbx
	mov	rax, USEC	;move in 1 second
	mov	rbx, qword[frame_delta]	;and the frame delta
	div	rbx	;now divide the second by the delta to get fps
	xor	rcx, rcx	;reset high bits
	mov	ecx, dword[fps_space]	;and move in fps space var
	mov	r15, [framebuf]	;use framebuf
	add	r15, rcx	;and add on fps space
	inc	rax	;inc this bc its never full fps
	call	f_int_ascii	;now convert int to ascii in fbuf
	cmp	byte[alert_end], 0	;check if alert end is low
	jz	.skip_clear_alert	;if yes dont do this
	call	f_clear_alert	;otherwise do what this is
.skip_clear_alert:
	mov	rax, 7	;sys_poll
	mov	rdi, pollfd	;poll using this thing
	mov	rsi, 1	;forgot what this is but bleh
	mov	rdx, 0
	syscall
	cmp	rax, 0	;check if return is 0
	jle	.skip_read	;if it is that or lower skip read
	mov	rax, 0	;otherwise read 4 bytes into poll space
	mov	rdi, 0
	mov	rsi, qword[poll]
	mov	rdx, 4
	syscall
.skip_read:
	call	f_input_cases	;input cases yeah
	cmp	byte[paused], 0	;check if paused
	jz	.not_paused	;ugh gonna cry
	call	f_alert	;sdtill doesnt feel like an actual human being
	jmp	.loop	;this is so stupid
.not_paused:
	call	f_clear_screen	;clear screen of old chars and also clear depth buffer
	mov	rax, [poll]	;move in polling space
	cmp	byte[rax], 0	;check if no char is sent
	jz	.no_input	;if no char, theres no input
	call	f_update_camera_axis	;otherwise, update camera axis
	call	f_camera_rotation_matrix	;and then regenerate the rotation matrix
	call	f_camera_translation_matrix	;and translation matrix
.no_input:
	lea	r15, [matrix_camera_translate]	;matrix A is translation matrix
	lea	r14, [matrix_camera_rotate]	;matrix B is rotation matrix
	lea	r13, [matrix_camera]	;matrix C is camera matrix (result)
	call	f_multiply_matrix	;get camera matrix!
	mov	byte[obj_counter], 0	;reset obj counter
	mov	qword[translation_index], 0
.loop_object:
	movzx	rdx, byte[obj_counter]	;move it into rbx
	mov	rax, 32	;move in 32 (size of all object addresses)
	mul	rdx	;multiply it by the object iter
	mov	rbx, qword[obj_addr]	;move address of object addresses into rbx
	mov	rcx, qword[rbx+rax]	;and move address of vertex data into rcx
	mov	qword[imported_addr], rcx	;save that in vertex data start
	mov	rcx, qword[rbx+rax+8]	;vertex edges
	mov	qword[imported_addr+8], rcx
	mov	rcx, qword[rbx+rax+16]	;object uv
	mov	qword[imported_addr+16], rcx
	mov	rcx, qword[rbx+rax+24]	;object texture
	mov	qword[imported_addr+24], rcx
	test	byte[rcx], 0b10000000	;test the texture dimension thing
	jz	.draw_opaque	;if high bit is 1 then its transparent
	movzx	rax, byte[rcx]
	push	qword[imported_addr]	;if it is transparent push all these addresses
	push	qword[imported_addr+8]	;theres quite a few
	push	qword[imported_addr+16]
	push	qword[imported_addr+24]
	push	word[obj_counter]	;also push this counter
	push	qword[translation_index]	;and the index for translations
	call	f_get_translation_index	;then get the next offset for the next object also
	inc	byte[obj_counter]	;increase said counter
	jmp	.skip_draw	;now skip doing the rest of the draw
.draw_opaque:
	call	f_process_translations	;forgot what this even does o wait nvm
	inc	byte[obj_counter]	;increase said counter
.loop_objects:
	mov	r15, [imported_addr]	;use object vertices
	call	f_apply_transformation	;does all matrix stuff, result in obj_aux_2
	cmp	dword[r15], 0
	jz	.skip_draw
	lea	r15, [obj_aux_2]	;matrix to put onto screen
	mov	r14, [imported_addr+8]	;array containing cube edge indexes
	mov	r13, [imported_addr]	;containing cube vertices
	mov	r12, [imported_addr+16]	;containing cube uv mapping
	call	f_node_screen	;project onto screen
.skip_draw:
	movzx	rdx, byte[obj_counter]
	cmp	dx, word[obj_count]	;if its at the end then done process more objects
	jnz	.new_object
.draw_transparent:
	cmp	rsp, qword[rspbuf]	;check if stack has been fully stopped
	jz	.done_transparent	;if yes finished with transparent things!
	pop	qword[translation_index]	;now pop back all the stuff u pushed
	pop	word[obj_counter]	;bc its needed for the rest of this process
	pop	qword[imported_addr+24]
	pop	qword[imported_addr+16]
	pop	qword[imported_addr+8]
	pop	qword[imported_addr]
	call	f_process_translations	;process the translations for this obj
	mov	r15, [imported_addr]	;use object vertices
	call	f_apply_transformation	;does all matrix stuff, result in obj_aux_2
	cmp	dword[r15], 0
	jz	.draw_transparent
	lea	r15, [obj_aux_2]	;matrix to put onto screen
	mov	r14, [imported_addr+8]	;array containing cube edge indexes
	mov	r13, [imported_addr]	;containing cube vertices
	mov	r12, [imported_addr+16]	;containing cube uv mapping
	mov	r10, qword[imported_addr+24]
	and	byte[r10], 0b01111111	;clear high bit so it doesnt fuck dimensions
	call	f_node_screen	;project onto screen
	mov	r10, qword[imported_addr+24]	;then set it again for the future
	or	byte[r10], 0b10000000
	jmp	.draw_transparent	;loop over
.done_transparent:
	mov	rax, 1	;print the current frame
	mov	rdi, 1
	mov	rsi, [framebuf]
	mov	edx, dword[screen_size]
	add	edx, TOP_SIZE
	syscall
	mov	rax, 228	;now sys_gettime again
	mov	rdi, 4	;raw monotonic
	mov	rsi, time
	syscall
	mov	rbx, qword[tv_usec]	;move in current time
	sub	rbx, qword[frame_start]	;and subtract the frame start time
	mov	rax, qword[tv_sec]	;same with seconds
	sub	rax, qword[frame_start_sec]
	mov	rcx, USEC
	mul	rcx	;and do the mul thing
	add	rbx, rax	;add together!
	mov	qword[frame_raw_delta], rbx	;this is now the frame delta
	jmp	.loop
.new_object:
	cmp	byte[alerted], 0	;check if not alerted
	jz	.no_alert	;its okay!
	call	f_alert	;dont cry you have someone
	;but you may not deserve her
.no_alert:
	jmp	.loop_object	;loop over
f_int:
	mov	dword[exit_msg+exit_code_offset], "1" << 24
	call	f_kill
f_seg:
	mov	dword[exit_msg+exit_code_offset], "-1" << 16
	call	f_kill
f_kill:
	push	rdx	;kill code
	mov	rax, 12	;sys_brk
	mov	rdi, qword[brk]	;program original breakpoint
	syscall
	or	dword[c_lflag], 1<<3	;just reset terminal struct
	or	dword[c_lflag], 1<<1
	mov	rax, 16	;system call for sys_ioctl
	mov	rdi, 1	;stdout
	mov	rsi, 21506	;TCSETS
	mov	rdx, termios	;buffer
	syscall
	cmp	qword[edited_obj], 0	;check if editor was used
	jz	.skip_editor_unmaps	;if no skip this
	mov	rax, 11	;if yes, sys_munmap
	mov	rdi, qword[edited_obj]	;various addr to unmap
	xor	rsi, rsi
	mov	esi, dword[edited_obj_len]	;and length
	syscall
	mov	rax, 11	;and same again
	mov	rdi, qword[points_dat]
	xor	rsi, rsi
	mov	esi, dword[points_dat_len]
	syscall
	mov	rax, 11	;and same again
	mov	rdi, qword[edited_faces]
	xor	rsi, rsi
	mov	esi, dword[edited_faces_len]
	syscall
	mov	rax, 11	;and same again
	mov	rdi, qword[edited_texture]
	xor	rsi, rsi
	mov	esi, dword[edited_texture_len]
	syscall
	mov	rax, 11	;and same again
	mov	rdi, qword[edited_uv]
	xor	rsi, rsi
	mov	esi, dword[edited_uv_len]
	syscall
.skip_editor_unmaps:
	mov	rax, 11	;sys_munmap
	mov	rdi, [poll]	;start of memory to unmap
	mov	rsi, 499712	;size of memory blah blah
	syscall
	xor	rbx, rbx
.unmap_loop:
	cmp	qword[reserved_memory+rbx], 0	;check if at end of reserved memory string
	jz	.done	;if yes, stop unmapping
	mov	r8, qword[reserved_memory+rbx]	;move address of unmap into r8
	mov	rax, 11	;sys_munmap
	mov	rdi, r8	;address
	mov	rsi, qword[reserved_memory+rbx+8]	;and length
	syscall
	add	rbx, 16	;go to next bit to unmap
	jmp	.unmap_loop	;shoutout to Shosela from freddy five night
.done:
	cmp	r15, -1
	jz	.no_clear
	mov	rax, 1	;print a clear terminal sequence
	mov	rdi, 1
	mov	rsi, clear
	mov	rdx, 6
	syscall
.no_clear:
	mov	rax, 1	;move in exit messages
	mov	rdi, 1
	mov	rsi, exit_msg	;yep
	mov	rdx, exit_len
	syscall
	pop	rdx
	mov	rax, 60	;sys_exit
	mov	rdi, rdx	;exit msg thing
	syscall
