%include	"input.asm"
%include	"matrix.asm"
%include	"graphics.asm"
%include	"math.asm"
%include	"clock.asm"
%include	"poll.asm"
%include	"files.asm"
;external files
section	.data
	TOP_SIZE	equ	4
	ICANON	equ	1<<1
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
	translation	dd	0, 0, 0
	matrix_camera	times 18	dd	0.0
	;matrix labels
	camera_h_fov	dd	1.0471975511965976
	camera_v_fov	dd	0
	;camera field of views
	camera_near_plane	dd	0.1
	camera_far_plane	dd	100.0
	;camera viewing planes
	two	dd	2
	three	dd	3
	;2
	angle	dd	0.05
	cube_angle	dd	0.0
	;this is a buffer for rotation angles
	angle_neg	dd	-0.05
	;and this is the negative version
	obj_matrix	dd	16, -0.5, -0.5, -0.5, 1.0, 0.5, -0.5, -0.5, 1.0, -0.5, 0.5, -0.5, 1.0, 0.5, 0.5, -0.5, 1.0, -0.5, -0.5, 0.5, 1.0, 0.5, -0.5, 0.5, 1.0, -0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.0, 234356
	obj_faces	dw	0, 1, 2, 65534, 3, 2, 1, 65534, 2, 3, 6, 65534, 7, 6, 3, 65534, 3, 1, 5, 65534, 7, 3, 5, 65534, 1, 0, 4, 65534, 4, 5, 1, 65534, 0, 2, 4, 65534, 4, 2, 6, 65534, 4, 7, 5, 65534, 4, 6, 7, 65534, 65535
	obj_uv	dd	1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 234356
	obj_texture	db	"200", "200", "200", "200", "200", "200", "200", "200"
			db	"200", "177", "177", "177", "177", "177", "177", "200"
			db	"200", "177", "200", "177", "177", "200", "177", "200"
			db	"200", "177", "177", "177", "177", "177", "177", "200"
			db	"200", "177", "200", "177", "177", "200", "177", "200"
			db	"200", "177", "177", "200", "200", "177", "177", "200"
			db	"200", "177", "177", "177", "177", "177", "177", "200"
			db	"200", "200", "200", "200", "200", "200", "200", "200"
	dimensions	dw	8, 8
	;these are matrices for a cube
	obj_aux_1	times 34	dd	0.0
	obj_aux_2	times 34	dd	0.0
	matrix_ndc	times 34	dd	0.0
	;+ aux versions
	unit_template	db	27, "[48;5;000m  "
	;template for units
	screen_size	dd	0
	;buffer for screen size
	unit_size	dd	13
	;size of a unit
	buf1	dd	0, 0, 0, 0
	buf2	dd	0
	buf3	dd	0
	;buffers
	line_start	dd	1.0, 0.0
	line_end	dd	0.0, 1.0
	line_buf	dd	0.0, 0.0
	line_val	dd	0.0
	line_i	dd	1.0, -1.0
	line_int	dd	0, 0
	;buffers for line drawing alg
	movement_speed	dd	0.2
	;movement speed
	align	16
	camera_position_cull	dd	0.0, -0.0, -3.0
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
	;time struct
	handler:
		dq	f_kill
		dd	0x04000000
	;signal handler struct
	float_test	dd	-9.38
	float_multiplier	dd	100.0
	cw	dw	0
	;fpu control word
	file_separator	dw	65535
	;separator between 1 and 0
	file	db	"fish.lsc", 0, "xxxxxxxxxxxxxxxxxxxxxxx"
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
	center_coords	dd	0.0, 0.0, 0.0
	operation_multiplier	dd	2.0
	vertex_depth	dd	0.0
	vertex_dist	dd	0.0
	bounding_box	dd	0, 0, 0, 0
	interpolated_uvd	dd	0, 0, 0
	scene_meta	db	"fish.l3d", 0, "fish.luv", 0, "fish.ltx", 1, "ground.l3d", 0, "ground.luv", 0, "ground.ltx", 1, "cube.l3d", 0, "cube.luv", 0, "cube.ltx", 10
	obj_count	dw	3
	init_info	db	0
			db	0
			db	"075"
			db	1
			dw	0
			dd	3.0, 0.5, 3.0
			db	1
			dw	2
			dd	0.0, 0.5, 3.0
			db	1
			dw	1
			dd	0.0, 0.0, 5.0
			db	255
	obj_addr	dq	0
	obj_addr_counter	dq	0
	obj_counter	db	0
	point_depth	dd	0
	sky_colour	db	"232"
	align	16
	triangle	dd	0, 0, 0, 0, 0, 0
	align	16
	bc_vectors	dd	0, 0, 0, 0, 0, 0, 0, 0
	align	16
	point	dd	0, 0
	align	16
	edge_vector_a	dd	0, 0, 0, 0
	align	16
	edge_vector_b	dd	0, 0, 0, 0
	align	16
	cross_product	dd	0, 0, 0, 0
	align	16
	simd_ones	dd	1.0, 1.0, 1.0, 1.0
	align	16
	simd_zeros	dd	0.0, 0.0, 0.0, 0.0
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
section	.text
	global	_start
_start:
	;lea	r15, [cube_texture]
	;lea	r14, [dimensions]
	;call	f_write_tex
	;mov	rdx, 101
	;call	f_kill
	lea	r15, [scene_meta]
	lea	r14, [obj_count]
	lea	r13, [init_info]
	call	f_write_scene
	call	f_read_scene
	finit	;initialise FPU control words
	mov	rax, 13	;system call for sys_rt_sigaction
	mov	rdi, 2	;signal here is SIGINT
	mov	rsi, handler	;handler structure
	mov	rdx, 0	;previous struct is nil
	mov	r10, 8	;size of something who knows it works
	syscall
	mov	rax, 13	;sys_rt_sigaction again
	mov	rdi, 11	;SIGSEGV this time
	syscall
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
	mov	rax, 16	;system call for sys_ioctl
	mov	rdi, 1	;stdout
	mov	rsi, 21505	;TCGETS
	mov	rdx, termios	;buffer
	syscall
	and	dword[c_lflag], ~ICANON	;clears canonical flag
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
	movzx	rax, word[window_size]
	sub	rax, 3
	mov	word[available_window], ax
	test	word[window_size+2], 1	;test LSB of rax 
	jnz	f_kill	;if its a 1 (odd) then kill
	shr	word[window_size+2], 1
	movzx	rax, word[window_size+2]	;moves window width into rax
	mul	word[window_size]	;multiply window height by width
	mov	rbx, 13	;then multiplies it by 13 (one unit is 13 bytes)
	mul	rbx	;actual multiplication
	mov	dword[screen_size], eax	;moves result into screen size
	call	f_initialise_screen	;prepare the screen for display
	mov	rax, 22	;system call for sys_pipe	
	mov	rdi, pipe	;store resulting fds here
	syscall
	mov	rax, 57	;system call for sys_fork
	syscall
	cmp	rax, 0	;checks if child process
	jz	f_clock	;if yes, go to clock process
	mov	qword[tv_usec], 33333334
	mov	rax, 57	;fork again
	syscall
	cmp	rax, 0	;check if child
	jz	f_poll	;if yes, go to polling process
	fild	word[window_size+2]	;load window width
	fild	word[window_size]	;load window height
	fdiv	st1	;divide window height by width
	fld	dword[camera_h_fov]	;load h_fov
	fmul	st1	;multiply it by window height / width
	fst	dword[camera_v_fov]	;and thats camera_vfov
	emms	;clearrr
	call	f_projection_matrix	;generate projection matrix
	call	f_screen_matrix	;and screen matrix
	call	f_pos_string	;generate location string
	call	f_insert_location	;then insert it into framebuf
	call	f_update_camera_axis	;update camera axis
	call	f_camera_rotation_matrix	;and then regenerate the rotation matrix
	call	f_camera_translation_matrix	;and translation matrix
.loop:
	mov	rax, [poll]	;moves the address of the shared memory for polling 
	mov	qword[rax], 0	;then clears the previously polled inputs
	mov	rax, [frames]	;moves address for frames into rax
	inc	dword[rax]	;increases it so a successful frame is counted
	mov	rax, 0	;system call for READ
	mov	edi, dword[pipe]	;pipe fd for pipe
	mov	rsi, buf1	;buffer to store result (discarded)
	mov	rdx, 1	;length to read (doesnt matter)
	syscall
	call	f_clear_screen	;clear screen of old chars and also clear depth buffer
	call	f_input_cases	;input cases yeah
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
.loop_object:
	movzx	rdx, byte[obj_counter]	;move it into rbx
	mov	rax, 32	;move in 32 (size of all object addresses)
	mul	rdx	;multiply it by the object iter
	inc	byte[obj_counter]	;increase said counter
	mov	rbx, qword[obj_addr]	;move address of object addresses into rbx
	mov	rcx, qword[rbx+rax]	;and move address of vertex data into rcx
	mov	qword[imported_addr], rcx	;save that in vertex data start
	mov	rcx, qword[rbx+rax+8]	;vertex edges
	mov	qword[imported_addr+8], rcx
	mov	rcx, qword[rbx+rax+16]	;object uv
	mov	qword[imported_addr+16], rcx
	mov	rcx, qword[rbx+rax+24]	;object texture
	mov	qword[imported_addr+24], rcx
.loop_objects:
	mov	r15, [imported_addr]	;use object vertices
	lea	r14, [matrix_camera]	;multiply by new camera matrix
	lea	r13, [obj_aux_2]	;result in copy memory
	call	f_multiply_matrix	;multiply them
	lea	r15, [obj_aux_2]	;nodes from last multiplication in obj_aux_1
	lea	r14, [matrix_projection]	;multiply by projection matrix
	lea	r13, [obj_aux_1]	;and result in first cube matrix
	call	f_multiply_matrix	;go
	lea	r15, [obj_aux_1]	;use r15 to hold matrix to normalise
	call	f_normalise_matrix	;normalise matrix
	lea	r15, [obj_aux_1]	;matrix A is result of normalisation
	lea	r14, [matrix_screen]	;matrix B is screen matrix
	lea	r13, [obj_aux_2]	;result matrix
	call	f_multiply_matrix	;bdsaojoicxzoiwadpszx
	lea	r15, [obj_aux_2]	;matrix to put onto screen
	mov	r14, [imported_addr+8]	;array containing cube edge indexes
	mov	r13, [imported_addr]	;containing cube vertices
	mov	r12, [imported_addr+16]	;containing cube uv mapping
	call	f_node_screen	;project onto screen
	movzx	rdx, byte[obj_counter]
	cmp	dx, word[obj_count]	;if its at the end then done process more objects
	jz	.loop	;finish frame if it is
	jmp	.loop_object	;loop over
f_kill:
	push	rdx
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
	jmp	.unmap_loop
.done:
	mov	rax, 60	;sys_exit
	pop	rdx
	mov	rdi, rdx	;weird exit code so yk it exited right
	syscall
