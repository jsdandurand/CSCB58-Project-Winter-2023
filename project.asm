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
.eqv AMOGUS_GLASS_COL 0x3AAFE2
.eqv JUMP_HEIGHT 6 # Jump height in pixels
.eqv GRAV_PERIOD 7 # Increase to lower gravity speed (set to 1 for maximum gravity speed) (ONLY SET TO PRIME NUMBERS)

.data
message: .asciiz "   "
xCord: .word 20
yCord: .word 20
jumpPixels: .word 0
gravityBoolean: .word 0 # Used to slow gravity speed, if equal to gravityFreq - 1, move down, jf not, do not move down
#registers: $t7 - keyboard input
#	    $t6 - keyboard input check
.text
.globl main
main:
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
	lw $t3, 0($sp)		# Store return result in $t0
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
	### SET jumpPixels to 4
	la $t0, jumpPixels	# $t0 = Address of jumpPixels
	li $t1, JUMP_HEIGHT	# $t1 = JUMP_HEIGHT = 4
	sw $t1, 0($t0)		# jumpPixels = 4
	
	
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
	### SLEEP
  	li $v0, 32       # syscall number for sleep 
  	li $a0, refreshrate    # argument for sleep (in milliseconds)
  	syscall          # call sleep syscall
  	
  	### Loop back to start of loop
	j GAMELOOP
	

UPDATECHAR:
	# Retrieving displacement from stack
	lw $t3, 0($sp)		# $t3 = xCord displacement (From Stack)
	addi $sp, $sp, 4	# Increment stack pointer position
	# Retrieving x and y coordinates
	lw $t0, xCord		# $t0 = xCord
	lw $t1, yCord		# $t1 = yCord
	
	# Check if gravityBoolean = gravityFreq
	lw $t4, gravityBoolean	# $t4 = gravityBoolean
	li $t5, GRAV_PERIOD	# $t5 = gravityFreq	
	addi $t5, $t5, -1	# $t5 -= 1
	li $t6, 0 		# used for jump
	li $t7, 0	
	bne $t4, $t5, POSTJUMP #do not apply gravity or jump (ie any vertical change) if gravityBoolean != gravityFreq - 1 (jump to POSTGRAVITY)
GRAVITY:# Apply gravity
	addi $t1, $t1, 1	# $t1 = $t1 + 1 (yCord down technically) this APPLIES GRAVITY
	addi $t3, $t3, -256	# update displacement to account for gravity
POSTGRAVITY:	
	# Update y coordinate and decrement jumpPixels if jumping
	lw $t5, jumpPixels
	ble $t5, $zero, POSTJUMP # if jumpPixels > 0, decrement jumpPixels	
JUMP:
	la $t9, jumpPixels
	addi $t5, $t5, -1	# decrement $t5
	sw $t5, 0($t9)		# jumpPixels -= 1
	addi $t1, $t1, -2 	# Since t1 is incremented, to decrement it properly, we subtract 2
	addi $t3, $t3, 512 	# update displacement to account for jump
	
POSTJUMP:
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






CHECKROOFCOLLISION:
	lw $t0, yCord
	addi $sp, $sp, -4
	li $t0, 0	#assume no collision
	bge $t0, 4, ROOFCOLLISIONFALSE
	li $t0, 1
ROOFCOLLISIONFALSE:	#skip set to true if no collision
	sw $t0, 0($sp)
	jr $ra	
ENDCHECKROOFCOLLISION:

END:
	li $v0, 10
	syscall
