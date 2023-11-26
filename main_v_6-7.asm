
# data section
.data
# eqv
.eqv FILE_NAME_SIZE 256
.eqv TEXT_SIZE 512

# some buffers
file_name: .space FILE_NAME_SIZE
buffer: .space TEXT_SIZE
buffer_1: .space TEXT_SIZE
buffer_2: .space TEXT_SIZE
out_line_1: .space TEXT_SIZE
out_line_2: .space TEXT_SIZE
out_file_name: .space FILE_NAME_SIZE
enter: .space 2

# messages
error_msg1: .asciz "ERROR open file!"
error_msg2: .asciz "ERROR read file!"
error_msg3: .asciz "ERROR create file!"
msg1: .asciz "Hello! Enter input file name: "
msg2: .asciz "Enter output file name: "
msg3: .asciz "Do you want to show answers? (Y / N)"



.text

# Some help macro 

# Allocate additive memory
.macro allocate(%size)
    li a7, 9
    li a0, %size
    ecall
.end_macro

# Read part of buffer size
.macro read_part(%file_descriptor, %reg, %size)
    li   a7, 63
    mv   a0, %file_descriptor
    mv   a1, %reg
    li   a2, %size
    ecall
.end_macro

# s4 - allocated buffer
# s2 - allocated buffer size

la a3, file_name                    # Enter file name
sw a3, (sp)			    # call {enter_program_name}
jal enter_program_name              # a3 - actual parametr (file name buffer)

sw a3, (sp)                         # Open current file
jal open_file                       # Call {open_file}
mv s0, a0                           # a3 - actual parametr (file name buffer)

allocate(TEXT_SIZE)                 # Start allocate
mv s4, a0                           # Read strings from file
sw s0, (sp)
addi sp, sp, -4                     # Call {read_from_file}
sw s4, (sp)                         # s0 - actual parametr (destriptor)
jal read_from_file                  # s4 - actual parametr (addres of save buffer)
mv s4, a0

li a7, 57                           # Simple close file
mv a0, s0
ecall


la t0, buffer_1                     # Divide file content into two strings
la t1, buffer_2                     # Call {divide_string}
sw s4, (sp)                         # s4 - actual parametr (file content)
addi sp, sp, -4                     # t0 - actual parametr (buffer 1)
sw t0, (sp)                         # t1 - actual parametr (buffer 2)
addi sp, sp, -4
sw t1, (sp)
jal divide_string
mv s1, t5
mv s3, t6

la a4, buffer_1                     # Create new line
la a5, out_line_2                   # Call {inverse_line}
sw a4, (sp)                         # a4 - actual parametr (buffer 1)
addi sp, sp, -4                     # a5 - actual parametr (new line 1)
sw a5, (sp)                         # s1 - actual parametr (size of byffer 1)
addi sp, sp, -4 
sw s1, (sp)
jal inverse_line
mv s8, a0


la a4, buffer_2                       # Create new line
la a5, out_line_1                     # Call {inverse_line}
sw a4, (sp)                           # a4 - actual parametr (buffer 2)
addi sp, sp, -4                       # a5 - actual parametr (new line 2)               
sw a5, (sp)                           # s3 - actual parametr (size of byffer 2)
addi sp, sp, -4
sw s3, (sp)
jal inverse_line
mv s7, a0

li a7, 57                            # Simple close file
mv a0, s0 
ecall

la a3, enter                         # Create enter string
li a4, '\n'
sb a4, (a3)

la a3, out_file_name                   # Enter output file name
sw a3, (sp)			       # Call {enter_output_file_name}
jal enter_output_name		       # a3 - actual parametr (buffer of string)

la a3, out_file_name                    # Open file
sw a3, (sp)			        # Call {open_output_file}
jal open_output_file			# a3 - actual parametr (buffer of string)
mv s6, a0

la a3, out_line_1			# Write first line in file
sw a3, (sp)				# Call {write_file}
addi sp, sp, -4				# a3 - actual parametr (buffer of string)
sw s7, (sp)
jal write_file

li t0, 1
la a3, enter				# Same as the last
sw a3, (sp)
addi sp, sp, -4
sw t0, (sp)
jal write_file

la a3, out_line_2
sw a3, (sp)				# Same as the last
addi sp, sp, -4
sw s8, (sp)
jal write_file

li a7, 57				# Simple close
mv a0, s6
ecall

li a7, 4                                # Enter message to enter reault in console
la a0, msg3
ecall

li a7, 12				# Get char - Y(yes) or N(no)
ecall

li a1, 'N'

beq a1, a0, no_show

# If show

la a1, enter
li a0, 1                          # Print string from buffer
sw a1, (sp)		          # Call {print_string}
addi sp, sp, -4			  # a1 - actual parametr (string)
sw a0, (sp)                       # a0 - actual parametr (size)
jal print_string

la a1, out_line_1
sw a1, (sp)                       # Same as the last
addi sp, sp, -4
sw s7, (sp)
jal print_string

la a1, enter
li a0, 1
sw a1, (sp)                          # Same as the last
addi sp, sp, -4
sw a0, (sp)
jal print_string

la a1, out_line_2
sw a1, (sp)                         # Same as the last
addi sp, sp, -4
sw s8, (sp)
jal print_string

no_show:

j end                               # End program

.text
#========================================================================
enter_program_name:                 # void enter_program_name(link_to_save_buffer)

#t0 - link to file name string

	addi sp, sp, -4              # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t0, (sp)
	
	li a7, 4                      # Call help message
	la a0, msg1
	ecall

	li a7, 8
	mv a0, t0
	li a1, FILE_NAME_SIZE
	ecall

	li t4, '\n'
	mv t5, t0

	loop_enter_program_name:                     # While don't meet enter - read letters
		lb t6, (t5)
		beq t4, t6, change_program_name
		addi t5, t5, 1
		b loop_enter_program_name

	change_program_name:
	sb zero, (t5)

	addi sp, sp, -4                     # Return
	lw ra, (sp)
	ret

#===========================================================
open_file:                                   # int open_file(link_to_save_buffer)

#t0 - link to file name string

	addi sp, sp, -4                       # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t0, (sp)

	li a7, 1024                             # Open file
	mv a0, t0
	li a1 0
	ecall
	
	li s1, -1                               # Check correct open
	beq a0, s1, ERROR_OPEN_FILE

	addi sp, sp, -4                           # Return
	lw ra, (sp)
	ret

#========================================================
read_from_file:                          #(int, string) read_from_file(destriptor, save_buffer)

# t0 - destriptor
# t1 - addres of saved buffer

# t3 - address of buffer
# t5 - changed addres
# t4 - constant text size
# t6 - size

	addi sp, sp, -4                        # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t1, (sp)
	addi sp, sp, 4
	lw t0, (sp)
	addi sp, sp, -8
	
	mv t3, t1                            # Init
	mv t5, t1
	li t4, TEXT_SIZE
	mv t6, zero
	li s1, -1
	
	read_from_file_loop:                   # While buffer if full - read parts 
		read_part(t0, t5, TEXT_SIZE)
		beq a0, s1, ERROR_READ_FILE
		mv t2, a0
		add t6, t6, t2
		
		bne t2 t4 end_read_from_file_loop
		allocate(TEXT_SIZE)
		add t5 t5 t2
		b read_from_file_loop	
	
	end_read_from_file_loop:
	mv t2, zero                         # Set '\0' in the end
	addi t5, t5, 1
	lb t2, (t5)
	
	mv s2, t6
	mv a0, t3

	lw ra, (sp)                         # Return
	ret

#===============================================================
divide_string:                               # (int, int) divide_string (string, new_string1, new_string2)

#t0 - string
#t3 - out_string_1
#t4 - out_string_2

#t1 - current_letter
#t2 - '\n' (enter)
#t5 - out_string_1_size
#t6 - out_string_2_size

	addi sp, sp, -4                   # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t4, (sp)
	addi sp, sp, 4
	lw t3, (sp)
	addi sp, sp, 4
	lw, t0, (sp)
	addi sp, sp, -12


	li t2, '\n'
	li t5, 0
	li t6, 0

	loop_divide_1:                        # Before meet '\n' read to first line
		lb t1, (t0)
		beq t1, t2, end_loop_divide_1
		sb t1, (t3)
		addi t5, t5, 1
		addi t0, t0, 1
		addi t3, t3, 1
		j loop_divide_1

	end_loop_divide_1:
	addi t0, t0, 1
	
	loop_divide_2:                         # After '\n' read to second line
		lb t1, (t0)
		beqz t1, end_loop_divide_2
		sb t1, (t4)
		addi t6, t6, 1
		addi t4, t4, 1
		addi t0, t0, 1
		j loop_divide_2

	end_loop_divide_2:
	mv a0, t5
	mv a1, t6

	lw ra, (sp)                              # Return
	ret


#=====================================================================
inverse_line:                                         # int inverse_line(string, new_string, strig_size)

# sp - input string
# -4(sp) - strng to save
# -8(sp) - string size

# t2 - 0-127
# t3 - current letter
# t6 - input string iterator
# t1 - size string iterator
# t4 - string to save iterator
# t5 - size of save string
# s11 - 0x7f

	addi sp, sp, -4
	sw ra, (sp)
	addi sp, sp, 12

	li t2, 0x41                       # Init
	lw t4, -4(sp)
	li t5, 0
	li s11, 0x7f

	for_i_in_all_letters:              # Loop for all letters
		lw t6, (sp)
		lw t1, -8(sp) 
		for_j_in_string:                  # Loop for all string
			lb t3, (t6)
			beq t3, t2, inverse_is_equal    # If meet current letter - skip
			addi t1, t1, -1
			addi t6, t6, 1
			bgtz t1, for_j_in_string
		
		sb t2, (t4)                      # Add letter
		addi t4, t4, 1
		addi t5, t5, 1
		
		
		inverse_is_equal:
		addi t2, t2, 1
		bne t2, s11, for_i_in_all_letters

	mv a0, t5
	addi sp, sp, -12
	lw ra, (sp)                               # Return
	ret
	
#===================================================================
print_string:                           # void print_string(string, size)
# t0 - string
# t1 - size
	addi sp, sp, -4
	sw ra, (sp)

	addi sp, sp, 4                      # Get parametrs
	lw t1, (sp)
	addi sp, sp, 4
	lw t0, (sp)

	loop_print_string:                         # For all chars - print
		li a7, 11
		lb a0, (t0)
		ecall
		addi t0, t0, 1
		addi t1, t1, -1
		bgtz t1, loop_print_string

	addi sp, sp, -8
	lw ra, (sp)                             # Return
	ret

#===============================================================
enter_output_name:                             # void enter_output_file_name (buffer of string)

# t0 - enter
# t1 - buffer to file name
# t2 - pointer to start file name buffer

	addi sp, sp, -4                         # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t1, (sp)
	
	li a7, 4                                    # Help message
	la a0, msg2
	ecall

	mv a0, t1                                # Read file name
	li a1 FILE_NAME_SIZE
	li a7 8
	ecall

	li t0, '\n'
	mv t2, t1

	read_out_file_name:                           # While meet '\n' - read letters
		lb t3, (t1)
		beq t3, t0, stop_read_out_file_name
		addi t1, t1, 1
		b read_out_file_name

	stop_read_out_file_name:
	beq t2, t1, ERROR_CREATE_FILE
	sb zero, (t1)
	mv a0, t3

	addi sp, sp, -4
	lw ra, (sp)                     # Return
	ret

#==========================================================
open_output_file:                         # void open_output_file (file_name)

#t0 - file name

	addi sp, sp, -4                     # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t0, (sp)

	mv a0, t0                             # Open
	li a7, 1024
	li a1, 1
	ecall

	li s1, -1
	beq s1, a0, ERROR_CREATE_FILE                # If error

	addi sp, sp, -4
	lw ra, (sp)                                  # Return
	ret

#==========================================================
write_file:                                        # void write_file(string, size)
# t0 - buffer_to_write
# t1 - size of buffer

	addi sp, sp, -4                             # Get parametrs
	sw ra, (sp)
	addi sp, sp, 4
	lw t1, (sp)
	addi sp, sp, 4
	lw t0, (sp)

	li a7, 64                                    # Write
	mv a0, s6
	mv a1, t0
	mv a2, t1
	ecall

	addi sp, sp, -8
	lw ra, (sp)                                  # Return
	ret


# Errors

ERROR_OPEN_FILE:
la a0, error_msg1
li a7, 4
ecall
j end

ERROR_READ_FILE:
la a0, error_msg2
li a7, 4
ecall
j end

ERROR_CREATE_FILE:
la a0, error_msg3
li a7, 4
ecall
j end

end:
