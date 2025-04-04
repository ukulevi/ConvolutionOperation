#-------------------CO2008_CC06_LE HOANG CHI VI_2353336_assignment-------------------------#
.data
    inputFile: .asciiz "input_matrix.txt"
    outputFile: .asciiz "output_matrix.txt"
    .align 2
    
    # Used float numbers
    negative_one: .float -1.0
    ten: .float 10.0
    zero: .float 0.0
    one: .float 1.0
	
    image: .word 0:100      # Max size: 7x7
    kernel: .word 0:100     # Max size: 4x4
    paddedImage: .word 2
    N: .word 2
    M: .word 2
    p: .word 2
    s: .word 2
    buffer: .word 100
    
    output: .word 0:100     # Maximum output size: 7x7
    newline: .asciiz "\n"
    space: .asciiz " "
    error_msg: .asciiz "Error: size not match"
    invalid_image_size: .asciiz   "Error:  The size of the image matrix. (3 <= N <= 7)"
    invalid_kernel_size: .asciiz  "Error: The size of the kernel matrix. (2 <= M <= 4)"
    invalid_parameter_padding_input: .asciiz "Error: The value of padding. (0 <= p <= 4)"
    invalid_parameter_stride_input: .asciiz  "Error: The value of stride. (1 <= s <= 3)"
	

.text
.globl main

main:
    # Open file for reading
    li   $v0, 13          # System call for open file
    la   $a0, inputFile      
    li   $a1, 0           # Reading-only mode
    syscall               # Open a file, file descriptor return in $v0
    move $s0, $v0         # Save file descriptor
    
#-------------------N, M, P, S-------------------------#
    # Read input file
    li   $v0, 14          # System call for read from file
    move $a0, $s0         # Input file descriptor
    la   $a1, buffer      # Address of buffer
    li   $a2, 100          # Maximum number of bytes to read
    syscall
    
    # Input conditions check
    la $t4, buffer              
    jal parse_parameters        
    jal input_parameters_check
    jal input_size_check
    
    # Read the image matrix
    jal read_image
    
    j close_input
    
#-----------------N, M, P, S-----------------------#    
    # Parse the line to extract N, M, p, s
    parse_parameters:	 
    	lb $t3, 0($t4)              
    	subi $t3, $t3, 48           
    	sw $t3, N                   
    	addi $t4, $t4, 4 # Add 4 bytes to get the address of the next value          

    	lb $t3, 0($t4)
    	subi $t3, $t3, 48
    	sw $t3, M
    	addi $t4, $t4, 4

    	lb $t3, 0($t4)
    	subi $t3, $t3, 48
    	sw $t3, p
    	addi $t4, $t4, 4

    	lb $t3, 0($t4)
    	subi $t3, $t3, 48
    	sw $t3, s
    	addi $t4, $t4, 5 # Last byte for end of line	
    	
    	jr $ra             

#-----------------Image & kernel matrix & padded image-----------------------#
    
    # Read the image matrix
    read_image:
    	addi $sp, $sp, -16       # Expand space on stacking
    	sw $ra, 12($sp)          # Save return address
    	sw $t3, 0($sp)
    	sw $t2, 4($sp)
    	sw $t1, 8($sp)

   	# Initialize variables and pointers
    	la $t3, image            # Image matrix(array) pointer $t1
    	lw $t2, N               
    	mul $t2, $t2, $t2        #t4: Total no. of eles to read (N*N)
    	li $t1, 0                # Index   	
    	li $t8, 0                # Negative flag
    	li $t7, 0                # Fraction flag
    	l.s $f0, zero            # Accumulated value (float)
    	l.s $f4, one             # Fraction multiplier (float)
    	l.s $f5, ten             # Const 10.0
    	
    	jr $ra
    
    loop_image_num:
    	beq $t2, $t0, image_end
    	lb $t6, 0($t4)          
    	beqz $t6, image_end  
    	
    	li $t5, 10              # Newline '\n'
    	beq $t6, $t5, image_converted_num
    	#Check for carriage return
    	li $t5, 13              # Carriage return '\r'
    	beq $t6, $t5, image_converted_num
    	#Check for space
    	li $t5, 32              # Space ' '
    	beq $t6, $t5, image_converted_num
    	#Check for negative sign '-'
    	li $t5, 45              # Negative symbol '-'
    	beq $t6, $t5, image_set_negative

    	#Check for decimal point '.'
    	li $t5, 46              # Decimal point '.'
    	beq $t6, $t5, image_dot

    	#Check if elementacter is digit
    	li $t5, 48              # Value zero '0'
    	blt $t6, $t5, image_skip
    	li $t5, 57              # Value nine '9'
    	bgt $t6, $t5, image_skip

    	# Convert ASCII to integer if character is digit
    	li $t5, 48
    	sub $t9, $t6, $t5       # $t9 stores the digit value
    	mtc1 $t9, $f2
    	cvt.s.w $f2, $f2        
    	
    	beqz $t7, image_integer_part
    	j image_fractional_part

    image_integer_part:
    	jal int_part_calc	
    	j image_next_num

    image_fractional_part:
    	jal frac_part_calc	
    	j image_next_num
    
    image_converted_num:
    	beqz $t5, image_store
    	l.s $f6, negative_one     
    	mul.s $f0, $f0, $f6   

    image_set_negative:
    	jal set_negative               
    	j image_next_num
    
    image_dot:
    	jal dot_product			
    	j image_next_num
    
    image_skip:
    	j image_next_num

    image_store:
    	s.s $f0, 0($t1)
    	addi $t3, $t3, 4        
    	addi $t2, $t2, 1        
    	
	jal reset_for_next		
    	j image_next_num

    image_next_num:
    	addi $t4, $t4, 1       
    	j loop_image_num

    # Read the kernel matrix  
    
   
    # Pad the image matrix
   
     
    close_input:
        # Close the input file
        li   $v0, 16
        move $a0, $s0
        syscall     
        j exit
        
#-----------------Output Matrix & Convolution-----------------------#
    
        
#-----------------Output File-----------------------#
    

#-----------------Calculations-----------------------#
    int_part_calc:
	# Accumulate integer part: value = 10*value + digit
    	mul.s $f0, $f0, $f5 #f0 = f0*10.0
    	add.s $f0, $f0, $f2
	jr $ra
    frac_part_calc:

    	div.s $f2, $f2, $f4     
    	add.s $f0, $f0, $f2     
    	mul.s $f4, $f4, $f5     
	jr $ra
	
    set_negative:
	li $t5, 1               
	jr $ra
	
    dot_product:
	li $t6, 1               
    	l.s $f4, ten           
	jr $ra
	
    reset_for_next:
	# Reset variables for next number
    	l.s $f0, zero           
    	li $t5, 0            
    	li $t6, 0              
    	l.s $f4, one           
    	jr $ra
    
    image_end:	
	# Restore saved registers
    	lw $ra, 12($sp)
    	lw $t3, 0($sp)
    	lw $t2, 4($sp)
    	lw $t1, 8($sp)
    	addi $sp, $sp, 16
    	jr $ra        
                            
#-----------------Input error check-----------------------#
    # Check the first line of input file
    input_parameters_check:
    	# Check N (3 <= N <= 7)
    	lw $t4, N                 
    	li $t3, 3                 
    	li $t2, 7                 
    	blt $t4, $t3, invalid_parameter_N     
    	bgt $t4, $t2, invalid_parameter_N    

    	# Check M (2 <= M <= 4)
    	lw $t4, M                 
    	li $t3, 2                 
    	li $t2, 4                 
    	blt $t4, $t3, invalid_parameter_M     
    	bgt $t4, $t2, invalid_parameter_M     

    	# Check p (0 <= p <= 4)
    	lw $t4, p                 
    	li $t3, 0                
    	li $t2, 4                 
    	blt $t4, $t3, invalid_parameter_p     
    	bgt $t4, $t2, invalid_parameter_p     

    	# Check s (1 <= s <= 3)
    	lw $t4, s                 
    	li $t3, 1                 
    	li $t2, 3                 
    	blt $t4, $t3, invalid_parameter_s     
    	bgt $t4, $t2, invalid_parameter_s     

    	jr $ra                  

    # Invalid input parameters
    invalid_parameter_N:
    	# Open the output file
    	li $v0, 13                 
    	la $a0, outputFile     
    	li $a1, 1                   
    	li $a2, 0                   
    	syscall
    	move $s1, $v0              
    	
    	
    	# Write error message to file
    	move $a0, $s1              
    	la $a1, invalid_image_size    
    	li $a2, 50                  
    	li $v0, 15                  
    	syscall

    	# Close the output file
    	li $v0, 16                  
    	move $a0, $s1               
    	syscall	
    	j exit

    invalid_parameter_M:
    	# Open the output file
    	li $v0, 13                 
    	la $a0, outputFile     
    	li $a1, 1                   
    	li $a2, 0                   
    	syscall
    	move $s1, $v0              
    	
    	
    	# Write error message to file
    	move $a0, $s1              
    	la $a1, invalid_kernel_size    
    	li $a2, 47                  
    	li $v0, 15                  
    	syscall

    	# Close the output file
    	li $v0, 16                  
    	move $a0, $s1               
    	syscall   	
    	j exit

    invalid_parameter_p:
    	# Open the output file
    	li $v0, 13                 
    	la $a0, outputFile     
    	li $a1, 1                   
    	li $a2, 0                   
    	syscall
    	move $s1, $v0              
    	
    	
    	# Write error message to file
    	move $a0, $s1              
    	la $a1, invalid_parameter_padding_input    
    	li $a2, 49                  
    	li $v0, 15                  
    	syscall

    	# Close the output file
    	li $v0, 16                  
    	move $a0, $s1               
    	syscall   	
    	j exit

    invalid_parameter_s:
    	# Open the output file
    	li $v0, 13                 
    	la $a0, outputFile     
    	li $a1, 1                   
    	li $a2, 0                   
    	syscall
    	move $s1, $v0              
    	
    	
    	# Write error message to file
    	move $a0, $s1              
    	la $a1, invalid_parameter_stride_input     
    	li $a2, 49                  
    	li $v0, 15                  
    	syscall

    	# Close the output file
    	li $v0, 16                  
    	move $a0, $s1               
    	syscall  	
        j exit
  
    input_size_check:
    	# Calc the padded size
    	lw $t4, M  
    	lw $t3, N                 
    	lw $t2, p                 
    	add $t1, $t2, $t2  
    	add $t1, $t3, $t1       
    	sw $t1, paddedImage # paddedImage = 2*p + N                 
    	bgt $t4, $t1, error_size  

    	jr $ra                    

    error_size:
    	# Open the output file
    	li $v0, 13                 
    	la $a0, outputFile     
    	li $a1, 1                   
    	li $a2, 0                   
    	syscall
    	move $s1, $v0              
    	
    	# Write error message to file
    	move $a0, $s1              
    	la $a1, error_msg      
    	li $a2, 21                  
    	li $v0, 15                  
    	syscall

    	# Close the output file
    	li $v0, 16                  
    	move $a0, $s1               
    	syscall    	
    	j exit
    	
#-----------------EXIT PROGRAM-----------------------#
    exit:
        li $v0, 10               
    	syscall
