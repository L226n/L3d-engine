%macro	get_box_tl_mem	0
	movzx	rcx, word[choice_width]	;load these here first
	movzx	rdx, word[choice_height]	;just in case
	shr	rcx, 1	;and then half both of them
	shr	rdx, 1
	movzx	rax, word[window_size]	;same as get_box_tl but with memory location
	shr	rax, 1	;rather than constants
	sub	rax, rdx	;difference 1 is that rdx is used and not %2 >> 1
	movzx	rbx, word[window_size+2]
	sub	rbx, rcx	;and here its rcx and not %1 >> 1
	shl	rbx, 2	;thats all the differences
	movzx	r9, word[window_size+2]
	shl	r9, 3
	mul	r9
	add	rax, rbx
%endmacro
%macro	get_box_tl	2
	movzx	rax, word[window_size]	;move in window height
	shr	rax, 1	;half it
	sub	rax, %2 >> 1	;subtract half of window height to get top
	movzx	rbx, word[window_size+2]	;move in window width (its alr half dw)
	sub	rbx, %1 >> 1	;subtract half of window width
	shl	rbx, 2	;conv to dword
	movzx	r9, word[window_size+2]	;window width again
	shl	r9, 3	;get dword size of row
	mul	r9	;rax is row number, so get dword offset
	add	rax, rbx	;add column offset
%endmacro
%macro	insert_box	0
	%rep	START_HEIGHT	;repeat this for each row
		%rep	START_WIDTH	;and each column
			mov	edx, dword[start_menu+rsi]	;move start menu char
			mov	dword[r15+rbx], edx	;insert into framebuf
			add	rsi, 4	;increase various counters
			add	rbx, 4	;  ;P
		%endrep
		add	rax, r9	;increase row counter
		mov	rbx, rax	;and move column counter to start
	%endrep
%endmacro
f_choice_menu:
	mov	byte[choice], 0	;reset choice to 0
	push	r14	;push message string addr
	get_box_tl_mem	;get box tl
	mov	rbx, rax	;save return to rbx
	movzx	rcx, word[choice_width]	;width yep
	mov	r14, "╭"	;vals to use
	mov	r13, "─"
	mov	r12, "╮"
	mov	r8, 255	;this omits a certain part of generate row
	call	f_generate_row	;guess
	add	rbx, r9	;new row
	mov	rax, rbx	;save rbx to rax
	add	rax, 4	;add 4 to get position to insert strings
	push	rax	;push
	mov	r14, "│"	;middle sections
	mov	r13, " "
	mov	r12, "│"
	movzx	rax, word[choice_height]	;interation counter
.loop_middle:
	cmp	rax, 2	;check if finished middle
	jz	.finished_middle	;if yes, done
	call	f_generate_row	;otherwise new row
	add	rbx, r9	;increase row counter
	dec	rax	;decrease iter counter
	jmp	.loop_middle
.finished_middle:
	mov	r14, "╰"	;the end bit
	mov	r13, "─"
	mov	r12, "╯"
	call	f_generate_row	;row!
	pop	rax	;get back rax
	mov	rbx, rax ;save it here
	pop	r14	;get back msg string
	xor	rcx, rcx	;reset msg string counter
.loop_message_insert:
	cmp	byte[r14+rcx], 0	;check if at end of string
	jz	.finish_message_insert	;if yes, finished insert
	cmp	byte[r14+rcx], 1	;check if at eol
	jz	.new_row	;if yes, move to new line
.continue_row:
	movzx	rdx, byte[r14+rcx]	;other bytes, move into rdx
	mov	dword[r15+rbx], edx	;and but into framebuf
	inc	rcx	;increase counters
	add	rbx, 4
	jmp	.loop_message_insert	;and  loop over
.new_row:
	inc	rcx	;increase string counter to skip 0b1
	add	rax, r9	;new row
	mov	rbx, rax	;move into rbx to reset X
	jmp	.continue_row	;continue inserting
.finish_message_insert:
	times 2	add	rax, r9	;go 2 rows below msg string
	mov	r14, rax	;save this to r14
	mov	dword[r15+rax], ">"	;insert yes selection
	mov	dword[r15+rax+8], "Y"
	mov	dword[r15+rax+12], "e"
	mov	dword[r15+rax+16], "s"
	add	rax, r9	;new row
	mov	r13, rax	;save in r13
	mov	dword[r15+rax+8], "N"	;and no selection
	mov	dword[r15+rax+12], "o"
.print_menu:
	mov	rax, 1	;same as the stuff used at later points in this code
	mov	rdi, 1	;easy to figure out
	mov	rsi, qword[framebuf]
	mov	rdx, qword[print_length]
	syscall
	mov	rax, 0	;get user input
	mov	rdi, 1
	mov	rsi, buf1
	mov	rdx, 4
	syscall
	cmp	byte[buf1], 27	;check escapes
	jz	.test_escapes
	cmp	byte[buf1], 10	;and enter key
	jz	.enter
	jmp	.print_menu	;otherwise just loop over
.enter:
	xor	r8, r8	;reset r8 bc it screws up status bar in 3d engine
	ret
.test_escapes:
	cmp	word[buf1+1], "[A"	;if down key
	jz	.swap_option	;do this
	cmp	word[buf1+1], "[B"	;if up key
	jz	.swap_option	;do the same thing bc its only 2 options
	cmp	word[buf1+1], "[C"
	jz	.enter
	jmp	.print_menu	;otherwise do nothing
.swap_option:
	not	byte[choice]	;not the choice byte
	cmp	byte[choice], 0	;is it 0?
	jz	.set_yes	;if yes, set yes as selected
	mov	dword[r15+r13], ">"	;otherwise set no as selected
	mov	dword[r15+r14], " "	;uses saved r14 and r13 vals
	jmp	.print_menu
.set_yes:
	mov	dword[r15+r14], ">"	;same thing but flipped
	mov	dword[r15+r13], " "
	jmp	.print_menu
f_start_menu:
	call	f_initialise_menu	;initialise the framebuffer for the start menu
.print_menu:
	mov	rax, 1	;sys_write
	mov	rdi, 1	;aaaaaaaaaaaand stdout
	mov	rsi, qword[framebuf]	;print the framebuf
	mov	rdx, qword[print_length]	;length of framebuf
	syscall
	mov	rax, 0	;get input from user
	mov	rdi, 1
	mov	rsi, buf1	;temporary location
	mov	rdx, 4	;this is a good length
	syscall
	cmp	byte[buf1], 10	;check if enter is sent
	jz	.enter	;if yes, go here
	cmp	byte[buf1], 27	;check if escape keys (like arrows) sent
	jz	.test_escapes	;if yes, test them
	jmp	.print_menu	;loop over otherwise
.enter:
	cmp	byte[selected_option], 12	;check if selected option (multiples of 4) is option 4
	jz	f_kill	;if yes, kill program bc option 12 is exit
	cmp	byte[selected_option], 0	;check if its option 1
	jnz	.else_a	;if its not, skip the call
.return_no:
	lea	r14, [open_game_str]	;string to put in file open
	call	f_open_file_dialog	;call the game open dialog
	movzx	rax, word[cwd_end]	;move cwd end here
	cmp	dword[cwd_file+rax-4], ".lgm"	;to check the file extension
	jnz	.confirm_load	;if its not lgm ask some questions
.return_yes:
	call	f_fix_cwd	;fix the cwd string
	ret	;and return
.else_a:
	jmp	.print_menu	;loooooop over
.confirm_load:
	cmp	dword[cwd_file+rax-4], ".lsc"	;check if loading lsc
	jz	.confirm_lsc	;if it is, go here
	lea	r14, [confirm_nr_msg]	;otherwise load not recognised strings into these bits
	mov	word[choice_width], LSC_WARN_WIDTH	;same width
	mov	word[choice_height], NR_WARN_HEIGHT	;different height
	jmp	.ask_choice	;call choice menu
.confirm_lsc:
	lea	r14, [confirm_lsc_msg]	;same as above
	mov	word[choice_width], LSC_WARN_WIDTH
	mov	word[choice_height], LSC_WARN_HEIGHT
.ask_choice:
	call	f_choice_menu	;get choice menu
	cmp	byte[choice], 0	;check if chose yes
	jz	.return_yes	;go here if so
	jmp	.return_no	;and here otherwise
.test_escapes:
	cmp	word[buf1+1], "[A"	;is it up key?
	jz	.cycle_options_up	;yes! do that
	cmp	word[buf1+1], "[B"	;is it down?
	jz	.cycle_options_down	;yes! do this
	cmp	word[buf1+1], "[C"
	jz	.enter
	jmp	.print_menu	;otherwise whatevrrr who carez
.cycle_options_up:
	movzx	rbx, byte[selected_option]	;move the selected option into rbx
	mov	eax, dword[menu_options+rbx]	;get the offset of menu selector thing from here
	mov	dword[r15+rax], " "	;and move in a blank space
	cmp	byte[selected_option], 0	;check if option is 0, if it is it loops around
	jnz	.not_loop_a	;if no dont do this next bit
	mov	byte[selected_option], 16	;move in impossible val which goes to 12 after next bit
.not_loop_a:
	sub	byte[selected_option], 4	;see told you
	movzx	rbx, byte[selected_option]	;move this into rbx
	mov	eax, dword[menu_options+rbx]	;same thing as above
	mov	dword[r15+rax], ">"	;but insert an arrow instead
	jmp	.print_menu	;and loop over!
.cycle_options_down:
	movzx	rbx, byte[selected_option]	;this one is the same
	mov	eax, dword[menu_options+rbx]	;in this bit it clears
	mov	dword[r15+rax], " "
	cmp	byte[selected_option], 12	;but in this bit it checks if at bottom
	jnz	.not_loop_b
	mov	byte[selected_option], -4	;and uses -4 so it wraps around to 0
.not_loop_b:
	add	byte[selected_option], 4	;then same same again
	movzx	rbx, byte[selected_option]
	mov	eax, dword[menu_options+rbx]
	mov	dword[r15+rax], ">"
	jmp	.print_menu	;ye
f_initialise_menu:
	movzx	rax, word[window_size+2]	;move in window width
	shl	rax, 1	;double it bc its half width fsr
	movzx	rbx, word[window_size]	;and window height
	mul	rbx	;multiply quarter window width by window height
	shl	rax, 2	;quadruple it bc it needs to be in dwords
	mov	qword[print_length], rax	;save this here ohhh thats where it came from
	add	qword[print_length], 6	;add clear sequence length
	xor	rbx, rbx	;reset this guy
	mov	r15, qword[framebuf]	;move frame buffer into r15 it stays here FOREVER
	mov	byte[r15], 27	;insert clear sequence
	mov	word[r15+1], "[H"
	mov	byte[r15+3], 27
	mov	word[r15+4], "[J"
	add	r15, GUI_TOP_SIZE	;add clear sequence length
.loop:
	cmp	rax, 0	;check if this is 0 (iterate over every dword)
	jz	.space_populated	;if its done go away
	;mov	qword[r15+rbx], (" " << 32) || " "	;this is supervilain backstory
	mov	dword[r15+rbx], " "	;sobbing rn
	mov	dword[r15+rbx+4], " "	;god is cruel
	add	rbx, 8	;increase this
	sub	rax, 8	;and decrease this
	jmp	.loop	;loop over
.space_populated:
	get_box_tl	START_WIDTH, START_HEIGHT	;get top left of box
	mov	rbx, rax	;store in rbx
	xor	rsi, rsi	;reset this guy bc its start menu offset for insert_box
	push	rax	;save him
	insert_box	;insert a box at rbx
	pop	rax	;yay
	times 8	add	rax, r9	;increase by 8 rows to skip title rows
	add	rax, 8	;offset to get positions for the option text
	mov	dword[menu_options], eax	;save pos
	add	rax, r9	;increase row
	mov	dword[menu_options+4], eax	;repeat
	add	rax, r9
	mov	dword[menu_options+8], eax
	add	rax, r9
	mov	dword[menu_options+12], eax
	ret	;done!!1
f_open_file_dialog:	;o h god
	push	r14	;message string arg
	get_box_tl	FLOAD_WIDTH, FLOAD_HEIGHT	;this works here too but other vals
	mov	rbx, rax	;save tl in rbx
	push	rbx	;push it now
	xor	r14, r14	;counter of some sort
	add	rbx, 4	;increase tl by 4 (column 1)
	%rep	FLOAD_HEIGHT-4	;all places where files can go
		add	rbx, r9	;new row
		mov	dword[file_indexes+r14], ebx	;same addr
		add	r14, 4	;next file index
	%endrep
	times 2	add	rbx, r9
	mov	dword[file_indexes+r14], ebx
	pop	rbx
	mov	rcx, FLOAD_WIDTH	;width yep
	mov	r14, "╭"	;vals to use
	mov	r13, "─"
	mov	r12, "╮"
	mov	r8, 255	;this omits a certain part of generate row
	call	f_generate_row	;cant remember which part go check if u care
	add	rbx, r9	;next row
	mov	r14, "│"	;same thing but with mid sections
	mov	r13, " "
	mov	r12, "│"
	%rep	FLOAD_HEIGHT-4
		call	f_generate_row	;yeah
		add	rbx, r9
	%endrep
	mov	r14, "├"	;bottom bits
	mov	r13, "─"
	mov	r12, "┤"
	call	f_generate_row
	add	rbx, r9
	mov	r14, "│"
	mov	r13, " "
	mov	r12, "│"
	call	f_generate_row
	add	rbx, r9
	mov	r14, "╰"	;ezzzz
	mov	r13, "─"
	mov	r12, "╯"
	call	f_generate_row
	mov	rax, 79	;system call for sys_getcwd (current working directory)
	mov	rdi, cwd_file	;buffer for cwd
	mov	rsi, 1024	;length it shouldnt overflow
	syscall
	xor	rax, rax	;reset this counter
.find_cwd_end:
	cmp	byte[cwd_file+rax], 0	;check if at end of this thing
	jz	.insert_slash	;if it is insert a forward slash
	inc	rax	;keep going
	jmp	.find_cwd_end	;a
.insert_slash:
	mov	byte[cwd_file+rax], "/"	;sys_getcwd doesnt insert a forward slash DIY
	inc	rax
	mov	byte[cwd_file+rax], 0	;null terminate it also
	mov	word[cwd_end], ax	;and save end pos to avoid future calculations
	pop	r14
.open_directory:
	mov	rax, 80	;sys_chdir
	mov	rdi, cwd_file	;and change cwd to current file location
	syscall
	mov	ebx, dword[file_indexes+(FLOAD_HEIGHT-4)*4]	;move in extra index at end of data
	xor	rcx, rcx	;xor these counters
	xor	rdx, rdx	;!!
.loop_insert_msg:
	movzx	rax, byte[r14+rcx]	;move in byte in message string to rax
	cmp	rax, 0	;check if its 0
	jz	.msg_inserted	;if it is its inserted the msg
	mov	dword[r15+rbx], eax	;else put the char into the framebuffer
	add	rbx, 4	;increase framebuffer counter
	inc	rcx	;and message byte counter
	jmp	.loop_insert_msg	;loop
.msg_inserted:
	cmp	dword[r15+rbx], "│"	;check if the current byte is at end of info box
	jz	.dont_pad_msg	;if yes stop padding with " "
	mov	dword[r15+rbx], " "	;if no then pad with " "
	add	rbx, 4	;increase counter
	jmp	.msg_inserted	;loop over
.dont_pad_msg:
	mov	ebx, dword[file_indexes+(FLOAD_HEIGHT-4)*4]	;reload rbx with val from earlier
	times	FLOAD_WIDTH-5	add	rbx, 4	;this just moves to the end of info box
	movzx	rcx, word[cwd_end]	;store cwd end in rcx
.insert_path:
	dec	rcx	;decrease (to skip null byte)
	movzx	rax, byte[cwd_file+rcx]	;move previous byte into rax
	cmp	dword[r15+rbx], " "	;check if framebuffer char is a space
	jnz	.truncate_path	;if yes the truncate the path
	mov	dword[r15+rbx], eax	;otherwise move in the path byte
	sub	rbx, 4	;decrease framebuffer counter
	cmp	rcx, 0	;check if path byte counter is 0
	jz	.inserted_path	;if it is then finished
	jmp	.insert_path	;otherwise loop
.truncate_path:
	mov	dword[r15+rbx+4], " "	;move in some whitespace
	mov	dword[r15+rbx+8], " "
	mov	dword[r15+rbx+12], "."	;followed by ellipses
	mov	dword[r15+rbx+16], "."
	mov	dword[r15+rbx+20], "."
.inserted_path:
	mov	word[file_count], 0	;reset various things
	mov	qword[brk_len], 0	;prob not super important but its rarely called so who care
	mov	qword[previous_written], 0	;better be safe than sorry
	mov	word[current_scroll], 0
	mov	rax, 2	;open!!!!
	mov	rdi, cwd_file	;open the cwd
	xor	rsi, rsi	;some params important to xor them
	syscall
	mov	r14, rax	;save fd in r14
	mov	rax, 12	;call for sys_brk
	xor	rdi, rdi	;0 to get current program brk
	syscall
	mov	qword[brk], rax	;save this val
	mov	r13, rax	;in r13 also
.brk_memory:
	add	qword[brk_len], 1024	;initially 0
	mov	rax, 12	;sys_brk
	mov	rdi, qword[brk]	;base program end
	add	rdi, qword[brk_len]	;add the extension
	syscall
	mov	rax, 8	;lseek to file start in case of repeats
	mov	rdi, r14	;fd for dir
	xor	rsi, rsi	;offset 0
	xor	rdx, rdx	;from start
	syscall
	mov	rax, 217	;sys_getdents64
	mov	rdi, r14	;for this dir
	mov	rsi, r13	;put them in program brk space
	mov	rdx, qword[brk_len]	;length of current brk extension
	syscall
	cmp	rax, qword[previous_written]	;written val in rax from return
	jz	.brk_done	;if its the same then the buffer was big enough
	mov	qword[previous_written], rax	;otherwise store this guy
	jmp	.brk_memory	;and keep on going with brking woof
.brk_done:
	mov	qword[r13+rax], 0	;add empty qword at end of brk data just in case its not zeroed
	xor	rbx, rbx	;reset counters
	xor	r12, r12	;of sorts
.loop_get_files:
	cmp	qword[r13+rbx], 0	;check if at end of file data
	jz	.finished_files	;if yes u have finished this stuff
	movzx	r8, word[r13+rbx+16]	;otherwise store the d_reclen in r8
	push	rbx	;push	counter for record
.loop_str:
	movzx	rdx, byte[r13+rbx+19]	;save byte of file name
	cmp	rdx, 0	;check if its 0
	jz	.end_str	;if it is u have read the file name
	mov	byte[r13+r12], dl	;otherwise move it into the buffer start (save space ✨)
	inc	rbx	;next byte
	inc	r12	;fdspokmcv
	jmp	.loop_str	;keep go
.end_str:
	pop	rbx	;pop back record counter
	cmp	byte[r13+rbx+18], 10	;symlink
	jnz	.test_unknown	;if its not then skip
	jmp	.symlink	;and go to testing
.test_unknown:
	cmp	byte[r13+rbx+18], 0	;test if file type is unknown
	jnz	.not_unknown	;if its not skip again
.symlink:
	mov	rax, 80	;sys_chdir
	lea	rdi, [r13+rbx+19]	;use addr of filename
	syscall
	cmp	rax, -2	;this tests for broken symlinks (ENOENT)
	jz	.skip_dir	;if it is then dont show as dir
	cmp	rax, -20	;check if not a dir (ENOTDIR)
	jnz	.is_folder	;if it is a dir then go here
	jmp	.skip_dir	;otherwise the cwd isnt different so show as a file
.is_folder:
	mov	rax, 80	;sys_chdir again
	mov	rdi, up_dir	;this is just a .. so it goes back to prev dir
	syscall	;go!!
	jmp	.force_dir	;force directory showed
.not_unknown:
	cmp	byte[r13+rbx+18], 4	;check if file type is folder
	jnz	.skip_dir	;if no skip this bit
.force_dir:
	mov	byte[r13+r12], "/"	;if yes insert a forward slash
	inc	r12	;and increase byte counter
.skip_dir:
	mov	byte[r13+r12], 0	;move in null byte toterminate str
	inc	word[file_count]	;increase file counter
	inc	r12	;and file stream counter
	add	rbx, r8	;add reclen to get to next record
	jmp	.loop_get_files	;get more files
.finished_files:
	mov	qword[r13+r12], 0	;move in empty qword to separate processed stream from unprocessed
.new_round:	;bubble sort alphabet bit
	mov	byte[round_errors], 0	;reset round errors
	xor	rax, rax	;reset counters
	xor	rbx, rbx
.loop_sort:
	call	f_get_next_file	;get position of text file name in rbx
	cmp	rbx, r12	;check if its at end of data
	jz	.round_done	;if it is then round is done
	push	rax	;push counters
	push	rbx
	xor	r9, r9	;reset byte counter for comparisons
.compare_bytes:
	mov	sil, byte[r13+rbx]	;move byte of second file here
	mov	dil, byte[r13+rax]	;move in other file byte now
	call	f_ascii_lower	;and then raise both to lowercase
	cmp	dil, sil	;and compare with other byte
	ja	.swap	;if the lower bite is above swap
	jb	.no_swap	;if its higher dont
	inc	rax	;otherwise check next byte
	inc	rbx	;bc first ones arethe same
	cmp	dil, 0	;if one byte is 0 then so is the other
	jz	.no_swap	;dont swap in this case
	jmp	.compare_bytes	;and loop over
.swap:
	mov	byte[round_errors], 1	;error encountered !!
	pop	rbx	;get filename start offsets
	pop	rax
	xor	rcx, rcx	;reset this bc its used for loading
	push	rax	;push lower file offset
.load_buffer:
	mov	sil, byte[r13+rax]	;into sil
	mov	byte[file_swap_buffer+rcx], sil	;and into the file swap buffer
	cmp	sil, 0	;if 0 byte loaded
	jz	.buffer_loaded	;then,,,, its loaded wow
	inc	rcx	;next byte load
	inc	rax
	jmp	.load_buffer	;loop over
.buffer_loaded:
	pop	rax	;get back lower filename offset
.shift_lower:
	mov	sil, byte[r13+rbx]	;move the higher filename bytes
	mov	byte[r13+rax], sil	;to the lower filename bytes
	inc	rbx	;keep going with this
	inc	rax
	cmp	sil, 0	;check if its null byte
	jz	.insert_buffer	;if yes tadaa done
	jmp	.shift_lower	;keep go now
.insert_buffer:
	push	rax	;rax is now higher filename offset
	xor	rbx, rbx	;reset this now its a counter
.insert_loop:
	mov	sil, byte[file_swap_buffer+rbx]	;move in more bytes so many byte transfers
	mov	byte[r13+rax], sil	;put in higher place now
	cmp	sil, 0	;yk by now cmon
	jz	.swapped
	inc	rax
	inc	rbx
	jmp	.insert_loop	;loopy crazy wacky
.swapped:
	pop	rax	;get back lower filename counter
	mov	rbx, rax	;and move into rbx
	jmp	.loop_sort	;loop over
.no_swap:
	pop	rbx	;just pop back these values
	pop	rax
	mov	rax, rbx	;higher file becomes lower
	jmp	.loop_sort	;and go to the next one, so easy
.round_done:
	cmp	byte[round_errors], 0	;if 0 round errors its sorted
	jz	.sorted
	jmp	.new_round	;otherwise try again
.sorted:
	mov	rax, 3	;close
	mov	rdi, r14	;the dir
	syscall
	mov	ebx, dword[file_indexes]	;position of first file entry
	xor	rcx, rcx	;reset this file offset counter
	call	f_insert_files	;insert files !
	mov	ebx, dword[file_indexes]	;get back rdx val
	mov	dword[r15+rbx], ">"	;put in a arrow on first entry
	mov	word[selected_option], 0	;option is 0
.print_menu:
	mov	rax, 1	;print
	mov	rdi, 1	;same as the stuff ins start menu
	mov	rsi, qword[framebuf]
	mov	rdx, qword[print_length]
	syscall
	mov	rax, 0
	mov	rdi, 1
	mov	rsi, buf1
	mov	rdx, 4
	syscall
	cmp	byte[buf1], 10	;still the same,,,
	jz	.enter
	cmp	byte[buf1], 27
	jz	.test_escapes
	jmp	.print_menu
.enter:
	movzx	rax, word[current_scroll]	;get scroll val
	movzx	rbx, word[selected_option]	;and selected option
	shr	rbx, 2	;divide by4 to get normal index
	add	rax, rbx	;sum of them is index of selected file
	xor	rbx, rbx	;reset this counter
.loop_find_selected:
	cmp	rax, 0	;check if rax is 0
	jz	.found_selected	;if yes then the offset for filename hasbeen found!
.find_boundary:
	cmp	byte[r13+rbx], 0	;check if currently at 0 byte (new file entry)
	jz	.found_boundary	;if yes u found a file boundary well done
	inc	rbx	;increase counter
	jmp	.find_boundary	;looop
.found_boundary:
	dec	rax	;decrease counter for file index
	inc	rbx	;increase byte counter to skip null byte
	jmp	.loop_find_selected	;loop over
.found_selected:
	movzx	rax, word[cwd_end]	;move in the offset for end of cwd
	cmp	word[r13+rbx], "./"	;check if dir is ./ (same directory)
	jz	.file_appended	;if yeah then do nothing p much
	cmp	word[r13+rbx], ".."	;if its this however,,,
	jnz	.append_file	;(skip over if its not)
	cmp	byte[r13+rbx+2], "/"	;double check
	jnz	.append_file	;not this then skiiiiipp
	cmp	byte[cwd_file+1], 0	;check if ur at root directory (/)
	jz	.file_appended	;if yes, dontdo anything
	dec	rax	;if no, decrease cwd end to skip 0 byte
.remove_dir:
	mov	byte[cwd_file+rax], 0	;move in null byte
	dec	rax	;decrease counter
	cmp	byte[cwd_file+rax], "/"	;check if at / (went up a dir)
	jnz	.remove_dir	;if no, loop over
	inc	rax	;otherwise increase this guy
	jmp	.file_appended	;and now cwd processed
.append_file:
	mov	dl, byte[r13+rbx]	;normally just do a byte copy
	mov	byte[cwd_file+rax], dl
	cmp	dl, 0
	jz	.file_appended
	inc	rax
	inc	rbx
	jmp	.append_file
.file_appended:
	mov	word[cwd_end], ax	;save the offset
	movzx	rdx, word[selected_option]	;do the thing to reset uh
	mov	edx, dword[file_indexes+rdx]	;te arrow > thing
	mov	dword[r15+rdx], " "
	mov	byte[first_run], 1	;used to skip sys_getcwd call
	mov	rax, 12	;brk now
	mov	rdi, qword[brk]	;release memory
	syscall
	movzx	rax, word[cwd_end]
	cmp	byte[cwd_file+rax-1], "/"
	jz	.open_dir
	mov	word[selected_option], 0
	ret
.open_dir:
	lea	r14, [open_game_str]
	jmp	.open_directory	;and open cwd
.test_escapes:
	cmp	word[buf1+1], "[A"	;still the same as the start menu really
	jz	.cycle_options_up
	cmp	word[buf1+1], "[B"
	jz	.cycle_options_down
	cmp	word[buf1+1], "[C"
	jz	.enter
	jmp	.print_menu
.cycle_options_up:
	cmp	word[selected_option], 0	;at top of page?
	jnz	.skip_scroll_a	;if no then its all fun and normal like start menu
	cmp	word[current_scroll], 0	;check if current scroll is also 0
	jz	.print_menu	;if yes do nothing
	dec	word[current_scroll]	;otherwise decrease scroll num
	call	f_get_file_offset	;and get offset for this scroll (in rcx)
	mov	ebx, dword[file_indexes]	;start offset
	call	f_insert_files	;insert some files
	jmp	.print_menu	;and print menu again
.skip_scroll_a:
	movzx	rbx, word[selected_option]	;saaaame
	mov	eax, dword[file_indexes+rbx]	;as start
	mov	dword[r15+rax], " "
	sub	word[selected_option], 4
	movzx	rbx, word[selected_option]
	mov	eax, dword[file_indexes+rbx]
	mov	dword[r15+rax], ">"
	jmp	.print_menu
.cycle_options_down:
	movzx	rax, word[selected_option]	;load selected option
	shr	rax, 2	;get actual index
	inc	rax	;and add 1 so its not 0 index
	cmp	ax, word[file_count]	;compare to file count
	jz	.print_menu	;if its the same do nothing (dont scroll ur at end)
	cmp	word[selected_option], (FLOAD_HEIGHT-4)*4-4	;check if selected option is at window end
	jnz	.skip_scroll_b	;if no normal scroll down
	mov	ax, word[file_count]	;otherwise move in file count
	sub	ax, word[current_scroll]	;subtract the current scroll
	cmp	ax, FLOAD_HEIGHT-4	;compare against window available
	jz	.print_menu	;if its the same then dont scroll
	inc	word[current_scroll]	;scroll down thing
	call	f_get_file_offset	;get file offset into rcx
	mov	ebx, dword[file_indexes]	;and same as scroll up
	call	f_insert_files
	jmp	.print_menu
.skip_scroll_b:
	movzx	rbx, word[selected_option]	;again its the asme as start
	mov	eax, dword[file_indexes+rbx]	;its not that different underneath really
	mov	dword[r15+rax], " "
	add	word[selected_option], 4
	movzx	rbx, word[selected_option]
	mov	eax, dword[file_indexes+rbx]
	mov	dword[r15+rax], ">"
	jmp	.print_menu
f_ascii_lower:
	cmp	sil, "A"	;check if byte is A
	jb	.not_capital_sil	;if its loewr its not capital
	cmp	sil, "Z"	;check if byte is Z
	ja	.not_capital_sil	;if its above its lowercase
	add	sil, 32	;otherwise convert to lowercase
.not_capital_sil:
	cmp	dil, "A"	;same thing but with rdi
	jb	.not_capital_dil	;and not rsi
	cmp	dil, "Z"
	ja	.not_capital_dil
	add	dil, 32
.not_capital_dil:
	ret
f_get_next_file:
	cmp	byte[r13+rbx], 0	;offset in rbx
	jz	.end	;and it just checks bytes easy
	inc	rbx
	jmp	f_get_next_file
.end:
	inc	rbx	;return is in rbx
	ret
f_get_file_offset:
	xor	rcx, rcx	;counter
	movzx	rax, word[current_scroll]	;this gets file on offset
.loop:
	cmp	rax, 0	;if counter is 0 then found file offset
	jz	.end	;and end
.loop_single:
	cmp	byte[r13+rcx], 0	;check if at boundary
	jz	.end_single	;if yes, then stop looping this bit
	inc	rcx	;if no continue :dissappointed:
	jmp	.loop_single
.end_single:
	dec	rax	;decrease index counter now
	inc	rcx	;and increase byte counter
	jmp	.loop
.end:
	ret
f_insert_files:
	mov	byte[pad_row], 0	;initially u might not need to pad a row
	xor	rsi, rsi	;reset counters for stuff
	xor	rdi, rdi
.loop_all_files:
	cmp	rsi, FLOAD_HEIGHT-4	;check if finished listing files
	jz	.files_listed	;if yes go to end p much
	cmp	qword[r13+rcx], 0	;check if rows need to be padded (at end of stream)
	jnz	.dont_set_pad	;if no skip this
	mov	byte[pad_row], 1	;set a byte
.dont_set_pad:
	xor	r8, r8	;reset counter
.loop_insert:
	cmp	r8, FLOAD_WIDTH-5	;check if the file is at end & needs to be truncated
	jnz	.skip_truncate	;if no skip this
	mov	dword[r15+rbx+4], "."	;otherwise put some dots
	mov	dword[r15+rbx], "."
	mov	dword[r15+rbx-4], "."
.correct_rcx:
	cmp	byte[r13+rcx], 0	;and then loop rcx to correct the offset now
	jz	.finish_insert	;ye just go to next file name
	inc	rcx
	jmp	.correct_rcx
.skip_truncate:
	movzx	rdx, byte[r13+rcx]	;move in byte for filename
	cmp	rdx, 0	;check if at end
	jz	.pad_filename	;if yes, pad the rest
	mov	dword[r15+rbx+8], edx	;otherwise move in the byte
	cmp	byte[pad_row], 0	;check if the row needs to be padded
	jz	.no_pad	;if no then dont use a " " char
	mov	dword[r15+rbx+8], " "	;yep padding
.no_pad:
	inc	rcx	;increase the counters
	inc	r8
	add	rbx, 4
	jmp	.loop_insert	;and loop over
.pad_filename:
	cmp	r8, FLOAD_WIDTH-5	;check if at row end
	jz	.finish_insert	;if yes finished
	mov	dword[r15+rbx+8], " "	;but now move in a space to pad
	inc	r8
	add	rbx, 4	;same thingy
	jmp	.pad_filename
.finish_insert:
	inc	rcx	;increase counters to go to next file name
	inc	rsi
	add	rdi, 4
	mov	ebx, dword[file_indexes+rdi]	;get next file index offset for framebuf
	jmp	.loop_all_files
.files_listed:
	ret
f_alert:
	xor	rcx, rcx	;used for msg offset
	movzx	rax, word[alert_y_offset]	;y pos
	movzx	rbx, word[alert_x_offset]	;x pos also
	cmp	qword[alert_tick], 0	;check if ticker is 0
	jnz	.loop	;if its not procede as normal
	not	byte[alert_end]	;otherwise set end byte
	not	byte[alerted]	;and clear alerted byte
.loop:
	mov	r8w, word[message+rcx]	;move current 2 letters into r8
	call	f_draw_ui	;draw this
	add	rcx, 2	;increase letter counter
	inc	rbx	;and x pos counter
	cmp	byte[message+rcx], 0	;check if at end
	jnz	.loop	;if no, loop over
.end:
	dec	qword[alert_tick]	;decrease the ticks to show for
	ret
f_clear_alert:
	xor	rcx, rcx	;used for msg offset
	movzx	rax, word[alert_y_offset]	;y pos
	movzx	rbx, word[alert_x_offset]	;and x pos
.loop:
	mov	r8w, word[message_clear]	;move double space "  " into r8 to be drawn
	call	f_draw_ui	;same as above
	add	rcx, 2	;increase this so you know where the end of the string is
	inc	rbx	;increase rbx (x position, draw next space)
	cmp	byte[message+rcx], 0	;check if at end
	jnz	.loop	;if no loop over
.end:
	not	byte[alert_end]	;clear end byte to show that alert is gone
	ret
f_fix_cwd:
	movzx	rax, word[cwd_end]	;get cwd end
	xor	rcx, rcx	;and reset this counter for file label
.get_file_start:
	cmp	byte[cwd_file+rax-1], "/"	;byte search from end to last / char
	jz	.found_file_start	;basic
	dec	rax
	jmp	.get_file_start
.found_file_start:
	push	rax	;push rax to save position of byte after last /
.loop:
	mov	bl, byte[cwd_file+rax]	;move in current byte
	mov	byte[file+rcx], bl	;and transfer to the file label
	cmp	bl, 0	;check if current byte was 0
	jz	.end	;if yes, done
	inc	rax	;otherwise loop and increase
	inc	rcx
	jmp	.loop
.end:
	pop	rax	;pop back position of last / + 1
	mov	byte[cwd_file+rax], 0	;insert a 0
	mov	word[cwd_end], ax	;and store in cwd_end label
	ret
