# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
.eqv refreshrate 40 #40 default
.eqv BASE_ADDRESS 0x10008000
.eqv IO_CHECK 0xffff0000
.eqv IO_INPUT 0xffff0004
.eqv RED 0xff0000
.eqv GREEN 0x00ff00
.eqv BLUE 0x0000ff
.eqv BLACK 0x000000
.eqv GREY 0xB3BAB5
.eqv AMOGUS_GLASS_COL 0x3AAFE2
.eqv JUMP_HEIGHT 10 # Jump height in pixels
.eqv GRAV_PERIOD 2 # Increase to lower gravity speed (set to 1 for maximum gravity speed)

.data
level: .word 1
xCord: .word 20	#Character xCord
yCord: .word 20	#Character yCord 
onPlatform: .word 0
jumpPixels: .word 0
gravityBoolean: .word 0 # Used to slow gravity speed, if equal to gravityFreq - 1, move down, jf not, do not move down
platforms_xCord: .space 20 #Space for numPlatforms platform x coordinates (should always equal numPlatforms * 4)
platforms_yCord: .space 20 #Space for numPlatforms platform y coordinates (should always equal numPlatforms * 4)
platformLength: .word 12 #Length of platforms
numPlatforms: .word 5 #Number of platforms

.text
.globl main
main:
createLevel:
	lw $t0, level				# $t0 = level
	li $t1, 1				# $t1 = 1
	beq $t0, $t1, generate_level_one	# if level = 1, generate level 1	
	li $t1, 2				# $t1 = 2
	beq $t0, $t1, generate_level_two	# if level = 2, generate level 2
	li $t1, 3				# $t1 = 3
	beq $t0, $t1, generate_level_three	# if level = 3, generate level 3
generate_level_one:
lv1_setPlatforms:
	la $t1, platforms_xCord # $t1 = platforms_xCord[0]
	la $t2, platforms_yCord # $t2 = platforms_yCord[0]
	#Platform 1
	li $t0, 2		# $t0 = 2
	sw $t0, 0($t1)		# platforms_xCord[0] = 2
	li $t0, 30		# $t0 = 30
	sw $t0, 0($t2)		# platforms_yCord[0] = 30
	#Platform 2
	li $t0, 15		# $t0 = 2
	sw $t0, 4($t1)		# platforms_xCord[4] = 2
	li $t0, 40		# $t0 = 30
	sw $t0, 4($t2)		# platforms_yCord[4] = 30
	#Platform 3
	li $t0, 30		# $t0 = 2
	sw $t0, 8($t1)		# platforms_xCord[8] = 2
	li $t0, 25		# $t0 = 30
	sw $t0, 8($t2)		# platforms_yCord[8] = 30
	#Platform 4
	li $t0, 35		# $t0 = 2
	sw $t0, 12($t1)		# platforms_xCord[12] = 2
	li $t0, 50		# $t0 = 30
	sw $t0, 12($t2)		# platforms_yCord[12] = 30
	#Platform 5
	li $t0, 50		# $t0 = 2
	sw $t0, 16($t1)		# platforms_xCord[12] = 2
	li $t0, 20		# $t0 = 30
	sw $t0, 16($t2)		# platforms_yCord[12] = 30
	
	#Generate platforms
	jal PAINT_PLATFORMS
	
	j spawnCharacter	# branch to spawnCharacter
generate_level_two:
generate_level_three:


spawnCharacter:
	lw $t0, xCord		# $t0 = xCord
	lw $t1, yCord		# $t1 = yCord
	addi $t2, $zero, 64	# $t2 = 64
	mult $t1, $t2		# yCord * 64
	mflo $t1 		# $t1 = yCord * 64
	add $t0, $t0, $t1	# $t0 = xCord + 64 * yCord
	addi $t2, $zero, 4	# $t2 = 4
	mult $t0, $t2		# (xCord + 64 * yCord) * 4
	mflo $t0		# $t0 = (xCord + 64 * yCord) * 4
	li $t2, BASE_ADDRESS	# $t2 = Base Adress of Framebuffer
	add $t0, $t0, $t2	# $t0 = (xCord + 64 * yCord) * 4 + BASE_ADDRESS
	li $t1, RED
	sw $t1, 0($t0)

	
GAMELOOP:
	jal PAINT_PLATFORMS
	jal CHECK_PLATFORM_COLLISION
	lw $t6, IO_CHECK	# $t8 = Boolean of whether there was a keyboard input
	beq $t6, 1, PRESS 	# if no key press, branch to MOVEDONE
	j NOMOVE
PRESS:	lw $t7, IO_INPUT	# $t9 = Keyboard input	
	beq $t7, 100, GORIGHT	# if key press = 'd' branch to moveright
	beq $t7, 97, GOLEFT	# else if key press = 'a' branch to moveLeft	
	beq $t7, 119, GOJUMP	# else if key press = 'w' branch to moveJump	
	beq $t7, 112, END	# else if key pres = 'p' branch to end and stop the game

	
GORIGHT:
	jal CHECK_BOR_COL_RIGHT # Check for Border collision
	lw $t3, 0($sp) 		# Store return result in $t3
	addi $sp, $sp, 4	# Increment $sp
	li $t2, 1		# $t2 = 1
	
  	lw $t0, xCord		# $t0 = xCord
  	li $t1, -4		# t1 = xCord displacement	
	addi $t0, $t0, 1	# ($t0 = xCord) += 1
	
	bne $t3, $t2, nocolright	# if $t3 = 1 (collision)
	addi $t0, $t0, -1	# fix xCord so there is no change
	li $t1, 0		# set displacement to 0
nocolright:
  	addi $sp, $sp, -4	# Increment stack pointer position
  	sw $t1, 0($sp)      	# Store xCord displacement in Stack

  	
	### UPDATE xCord
	la $t1, xCord		# $t1 = Address of xCord
	sw $t0, 0($t1)		# Store new xCord in xCord
	jal UPDATECHAR
	j MOVEDONE
GOLEFT:
	jal CHECK_BOR_COL_LEFT  # Check for Border collision
	lw $t3, 0($sp)		# Store return result in $t3
	addi $sp, $sp, 4	# Increment $sp
	li $t2, 1		# $t1 = 1
	
  	lw $t0, xCord		# $t0 = xCord
  	li $t1, 4		# t1 = xCord displacement	
	addi $t0, $t0, -1	# ($t0 = xCord) += 1
	
	bne $t3, $t2, nocolleft	# if $t0 = 1 (collision)
	addi $t0, $t0, 1	# fix xCord so there is no change
	li $t1, 0		# set displacement to 0
nocolleft:
  	addi $sp, $sp, -4	# Increment stack pointer position
  	sw $t1, 0($sp)      	# Store xCord displacement in Stack

  	
	### UPDATE xCord
	la $t1, xCord		# $t1 = Address of xCord
	sw $t0, 0($t1)		# Store new xCord in xCord
	jal UPDATECHAR
	j MOVEDONE

GOJUMP:

	la $t0, jumpPixels	# $t0 = Address of jumpPixels	
	lw $t2, onPlatform	# $t2 = onPlatform
	beq $t2, $zero, no_jump # if not on platform, do not perform jump
	
	### SET jumpPixels to JUMP_HEIGHT
	li $t1, JUMP_HEIGHT	# $t1 = JUMP_HEIGHT 
	sw $t1, 0($t0)		# jumpPixels = JUMP_HEIGHT
	
no_jump:	
	addi $sp, $sp, -4	# Increment stack pointer position
  	sw $zero, 0($sp)      	# Store xCord displacement in Stack
	jal UPDATECHAR
	j MOVEDONE
NOMOVE:	
	addi $sp, $sp, -4	# Increment stack pointer position
  	sw $zero, 0($sp)      	# Store xCord displacement in Stack
	jal UPDATECHAR
	j MOVEDONE
MOVEDONE:
	### Reset values needed to be reset (UNCOMMENT WHEN PLATFORM COLLISION ADDED)
	la $t0, onPlatform	# $t0 = address of onPlatform
	sw $zero, 0($t0)		# reset onPlatform to 0 default
	### SLEEP
  	li $v0, 32       # syscall number for sleep 
  	li $a0, refreshrate    # argument for sleep (in milliseconds)
  	syscall          # call sleep syscall
  	
  	### Loop back to start of loop
	j GAMELOOP
	

UPDATECHAR:
### Handle possible roof collision
	addi $sp, $sp, -4	# Save $ra in stack
	sw $ra, 0($sp)	
	jal CHECK_ROOF_COL	# Check for roof collision
	lw $t3, 0($sp)		# Store result in $t3
	addi $sp, $sp, 4	# Increment stack 
	li $t2, 1		# $t2 = 1
	bne $t3, $t2, no_jp_update # Do not update jumpPixels if no collision
	la $t0, jumpPixels	# $t0 = address of jumpPixels
	sw $zero, 0($t0)	# jumpPixels = 0
no_jp_update:	
	lw $ra, 0($sp)		# Restore $ra of UPDATECHAR function call 
	addi $sp, $sp, 4	# Increment $sp


	# Retrieving displacement from stack
	lw $t3, 0($sp)		# $t3 = xCord displacement (From Stack)
	addi $sp, $sp, 4	# Increment stack pointer position
	# Retrieving x and y coordinates
	lw $t0, xCord		# $t0 = xCord
	lw $t1, yCord		# $t1 = yCord

### Handle Gravity && Jump movements	
	# Check if gravityBoolean = gravityFreq
	lw $t4, gravityBoolean	# $t4 = gravityBoolean
	li $t5, GRAV_PERIOD	# $t5 = gravityFreq	
	addi $t5, $t5, -1	# $t5 -= 1
	li $t6, 0 		# used for jump
	bne $t4, $t5, POSTJUMP #do not apply gravity or jump (ie any vertical change) if gravityBoolean != gravityFreq - 1 (jump to POSTGRAVITY)
	lw $t8, onPlatform	# $t8 = onPlatform
	bne $t8, $zero, POSTGRAVITY # If on platform, do not apply gravity
GRAVITY:# Apply gravity
	addi $t1, $t1, 1	# $t1 = $t1 + 1 (yCord down technically) this APPLIES GRAVITY
	addi $t3, $t3, -256	# update displacement to account for gravity
	li $t6, 1		# Used incase of jump
POSTGRAVITY:	
	# Update y coordinate and decrement jumpPixels if jumping
	lw $t5, jumpPixels
	ble $t5, $zero, POSTJUMP # if jumpPixels > 0, decrement jumpPixels	
JUMP:
	la $t9, jumpPixels
	addi $t5, $t5, -1	# decrement $t5
	sw $t5, 0($t9)		# jumpPixels -= 1
	addi $t1, $t1, -1 	# Since t1 is incremented, to decrement it properly, we subtract 2
	sub $t1, $t1, $t6	# Decrement t1 an extra time since gravity was applied
	li $t7, 256
	mult $t6, $t7
	mflo $t6
	addi $t3, $t3, 256 	# update displacement to account for jump
	add $t3, $t3, $t6
	
POSTJUMP:

## Handel Erase and Redraw of Character
	# Update gravityBoolean
	addi $t4, $t4, 1	# $t4 += 1
	li $t5, GRAV_PERIOD
	div $t4, $t5		# $t4/$t5
	mfhi $t4		# $t4 = $t4 mod $t5
	la $t8, gravityBoolean
	sw $t4, 0($t8)


	la $t2, yCord		# $t2 = Address of yCord
	sw $t1, 0($t2)		# update yCord	
	# Calculating position in array
	addi $t2, $zero, 64	# $t2 = 64
	mult $t1, $t2		# yCord * 64
	mflo $t1 		# $t1 = yCord * 64
	add $t0, $t0, $t1	# $t0 = xCord + 64 * yCord
	addi $t2, $zero, 4	# $t2 = 4
	mult $t0, $t2		# (xCord + 64 * yCord) * 4
	mflo $t0		# $t0 = (xCord + 64 * yCord) * 4
	li $t2, BASE_ADDRESS	# $t2 = Base Adress of Framebuffer
	add $t0, $t0, $t2	# $t0 = (xCord + 64 * yCord) * 4 + BASE_ADDRESS

ERASEOLDCHAR:
	# Drawing new pixel and erasing old pixel
	li $t1, BLACK		# $t1 = Black Hexadecimal value
	add $t0, $t0, $t3	# $t0 = (xCord + displacement + 64 * yCord)*4 + BASE_ADDRESS	
	sw $t1, 0($t0)		# paint Old Character position black
	sw $t1, -256($t0)
	sw $t1, -260($t0)
	sw $t1, -252($t0)
	sw $t1, -248($t0)
	sw $t1, 8($t0)
	sw $t1, -512($t0)
	sw $t1, -516($t0)
	sw $t1, -768($t0)
	sw $t1, -764($t0)
	sw $t1, -760($t0)
	sw $t1, -508($t0)
	sw $t1, -504($t0)
PAINTNEWCHAR:
	sub $t0, $t0, $t3	# $t0 = (xCord + 64 * yCord)*4 + BASE_ADDRESS	
	li $t1, RED		# $t1 = Red Hexadecimal Value
	sw $t1, 0($t0)		# paint New Character position red\
	sw $t1, -256($t0)
	sw $t1, -260($t0)
	sw $t1, -252($t0)
	sw $t1, -248($t0)
	sw $t1, 8($t0)
	sw $t1, -512($t0)
	sw $t1, -516($t0)
	sw $t1, -768($t0)
	sw $t1, -764($t0)
	sw $t1, -760($t0)
	li $t1, AMOGUS_GLASS_COL
	sw $t1, -508($t0)
	sw $t1, -504($t0)
	
	jr $ra
ENDUPDATECHAR:

CHECK_BOR_COL_LEFT:
	lw $t0, xCord
	addi $sp, $sp, -4
	li $t1, 0	#assume no collision
	li $t2, 2
	ble $t0, $t2, left_col_true
	j left_col_false
left_col_true:
	li $t1, 1
left_col_false:	#skip set to true if no collision
	sw $t1, 0($sp)
	jr $ra
end_left_bor_check:


CHECK_BOR_COL_RIGHT:
	lw $t0, xCord
	addi $sp, $sp, -4
	li $t1, 0	#assume no collision
	li $t2, 61
	bge $t0, $t2, right_col_true
	j right_col_false
right_col_true:
	li $t1, 1
right_col_false:	#skip set to true if no collision
	sw $t1, 0($sp)
	jr $ra
end_right_bor_check:

CHECK_ROOF_COL:
	lw $t0, yCord
	addi $sp, $sp, -4
	li $t1, 0	#assume no collision
	li $t2, 4
	blt $t0, $t2, roof_col_true
	j roof_col_false
roof_col_true:
	li $t1, 1
roof_col_false:	#skip set to true if no collision
	sw $t1, 0($sp)
	jr $ra
end_check_roof_col:

CHECK_FLOOR_COL:
	lw $t0, yCord
	addi $sp, $sp, -4
	li $t1, 0
	li $t2, 63
	bgt $t0, $t2, floor_col_true
	j floor_col_false
floor_col_true:
	li $t1, 1
floor_col_false:
	sw $t1, 0($sp)
	jr $ra
end_check_floor_col:


PAINT_PLATFORMS:
	lw $t0, numPlatforms			# Iterator for outside loop (i)
	addi $t0, $t0, -1			# Decrement for loop
	li $t7, 4				# $t1 = 4
	mult $t0, $t7				# $t0 * 4
	mflo $t0				# $t0 = 4 * numPlatforms
	lw $t1, platformLength			# reset $t1 to platformLength
	addi $t1, $t1, -1			# $t1 = platformLength -1
	mult $t1, $t7				# (platformLength -1) * 4
	mflo $t1				# $t1 = (platformLength - 1) * 4
	la $t2, platforms_xCord	 		# $t2 = address of platforms_xCord
	la $t3, platforms_yCord			# $t3 = address of platforms_yCord
numPlatforms_loop: blt $t0, $zero, numPlatforms_end # for(int i = 4 * numPlatforms-1; i>=0; i -= 4)
	add $t4, $t2, $t0			# $t4 = address of platforms_xCord[i]
	add $t5, $t3, $t0			# $t5 = address of platforms_yCord[i]
	lw $t4, 0($t4)				# $t4 = platforms_xCord[i]
	lw $t5, 0($t5)				# $t5 = platforms_yCord[i]
	addi $sp, $sp, -12			# Decrement $sp 3 words to store xCord and yCord
	sw $t4, 0($sp)				# Store xCord in stack
	sw $t5, 4($sp)				# Store yCord in stack
	sw $ra, 8($sp)				# Store original $ra in stack
	jal ARRAY_POS_X_Y			# Paint platform pixel at (x, y) = ($t5, $t6)
	lw $t6, 0($sp)				# $t6 = (xCord + 64 * yCord) * 4 + BASE_ADDRESS
	lw $ra, 4($sp)				# restore original address to $ra
	addi $sp, $sp, 8				# Increment stack pointer
platformLen_loop: blt $t1, $zero, platform_Len_end # for(int j = platformLength-1; i>=0; i--)
	add $t6, $t6, $t1			# $t6 = (xCord + 64 * yCord) * 4 + BASE_ADDRESS + 4i
	li $t7, GREY
	sw $t7, 0($t6)
	sub $t6, $t6, $t1			# subtract old $t1 to readd incremented $t1
	addi $t1, $t1, -4			# Decrement $t1
	j platformLen_loop
platform_Len_end: 
	li $t7, 4				# $t7 = 4
	lw $t1, platformLength			# reset $t1 to platformLength
	addi $t1, $t1, -1			# $t1 = platformLength -1
	mult $t1, $t7				# (platformLength - 1) * 4
	mflo $t1				# $t1 = (platformLength - 1) * 4
	addi  $t0, $t0, -4			# Decrement $t0
	j numPlatforms_loop
numPlatforms_end:
	jr $ra
end_paint_platforms:

ARRAY_POS_X_Y:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	addi $s2, $zero, 64	# $s2 = 64
	mult $s1, $s2		# yCord * 64
	mflo $s1 		# $s1 = yCord * 64
	add $s0, $s0, $s1	# $s0 = xCord + 64 * yCord
	addi $s2, $zero, 4	# $s2 = 4
	mult $s0, $s2		# (xCord + 64 * yCord) * 4
	mflo $s0		# $s0 = (xCord + 64 * yCord) * 4
	li $s2, BASE_ADDRESS	# $s2 = Base Adress of Framebuffer
	add $s0, $s0, $s2	# $s0 = (xCord + 64 * yCord) * 4 + BASE_ADDRESS
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	jr $ra
end_paint_pixel:

CHECK_PLATFORM_COLLISION:
	lw $t0, numPlatforms			# Iterator for outside loop (i)
	addi $t0, $t0, -1			# Decrement for loop
	li $t1, 4				# $t1 = 4
	mult $t0, $t1				# $t0 * 4
	mflo $t0				# $t0 = 4 * numPlatforms
	lw $t1, platformLength			# Iterator for inside loop (j)
	addi $t1, $t1, -1			# Decrement for loop
	la $t2, platforms_xCord	 		# $t2 = address of platforms_xCord
	la $t3, platforms_yCord			# $t3 = address of platforms_yCord
numPlatforms_loop2: blt $t0, $zero, numPlatforms_end2 # for(int i = numPlatforms-1; i>=0; i--)
	add $t4, $t2, $t0			# $t4 = address of platforms_xCord[i]
	add $t5, $t3, $t0			# $t5 = address of platforms_yCord[i]
	lw $t4, 0($t4)				# $t4 = platforms_xCord[i]
	lw $t5, 0($t5)				# $t5 = platforms_yCord[i]
platformLen_loop2: blt $t1, $zero, platform_Len_end2 # for(int j = platformLength-1; i>=0; i--)
	add $t6, $t1, $t4			# $t6 = platforms_xCord[i] + j
	lw $t7, xCord				# $t7 = xCord
	lw $t8, yCord				# $t8 = yCord
	beq $t7, $t6, maybe_on_platform		# if left foot on platform, check y coordinate
	addi $t7, $t7, 2			# $t7 = xCord + 2 (right foot)
	beq $t7, $t6, maybe_on_platform		# if rightt foot on platform, check y coordinate
	j not_on_platform
maybe_on_platform:
	addi $t8, $t8, 1
	beq $t8, $t5, on_platform
	j not_on_platform
on_platform:
	la $t9, onPlatform			# $t9 = address of onPlatform
	li $t7, 1				# $t7 = 1
	sw $t7, 0($t9)				# onPlatform = 1
not_on_platform:
	addi $t1, $t1, -1			# Decrement $t1
	j platformLen_loop2
platform_Len_end2: lw $t1, platformLength	# reset $t1 to platformLength
	addi $t1, $t1, -1
	addi  $t0, $t0, -4			# Decrement $t0
	j numPlatforms_loop2
numPlatforms_end2:
	jr $ra
end_check_pf_col:

END:
	li $v0, 10
	syscall
