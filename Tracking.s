.global playerTracker
.global draw_crosshair

.equ RED_LEDS, 0xFF200000
.equ TIMER, 0xff202000
.equ ADDR_VGA, 0x08000000
.equ ADDR_CHAR, 0x09000000
.equ VIDEO_ENABLE, 0xFF20306C
.equ EDGE_DETECTION, 0xFF203070
.equ PUSH_BUTTONS,	0xFF200050
.equ VIDEO_BUFFER, 0x03000000 #Change this later to reserve memory instead
.equ AIMING_SPEED, 25


.data
player_temp:
	.word 50
	.word 50

.text
playerTracker:

getVideoIn:
#saving calee registers onto stack
addi sp,sp,-16
stw ra,0(sp)
stw r16,4(sp)
stw r17,8(sp)
stw r20,12(sp)

call detect_Red
call update_player_Location
#call draw_crosshair

#remove loop and return here
ldw ra,0(sp)
ldw r16,4(sp)
ldw r17,8(sp)
ldw r20,12(sp)
addi sp,sp,16
ret

#Subroutine changes all pixels that are not red to black
detect_Red:
addi sp,sp,-32
stw ra,0(sp)
stw r16,4(sp)
stw r17,8(sp) 
stw r18,12(sp)
stw r19,16(sp)
stw r20,20(sp)
stw r21,24(sp)
stw r22,28(sp)

#Register 20 will be for the x average, register 21 will be for the y average, r22 will be for number of elements to divide by
mov r20,r0
mov r21,r0
mov r22,r0


#r12 is for the outer loop (y-pixels) r13 is for the inner loop (x-pixels)
movi r12, 0
movi r13, 0

#Dnested for loops, loop through all x and y pixels
y_red_loop:
#Reloading addresses and resseting x counter
movia r16, ADDR_VGA
movia r11, VIDEO_BUFFER
movi r13, 0

#Adding offset to base addresses depending on current y-pixel
movi r10, 1024 
mul r18, r10, r12
add r16, r16, r18
add r11, r11, r18

x_red_loop:
ldhio r9,0(r11)

#Checks if red pixel is higher than a threshold value
movi r10, 15 #Threshold for red pixel
srli r19, r9, 11 #Isolating red pixel intensity
andi r19,r19, 0b0011111
blt r19, r10, skip_pixel_change

#checks if green pixel is greater than threshold
movi r10, 30 #Threshold for green pixel
srli r19, r9, 5 #Isolating green pixel intensity
andi r19,r19, 0b00000111111
bgt r19, r10, skip_pixel_change

#checks if blue pixel is greater than threshold
movi r10, 10 #Threshold for blue pixel
 #Isolating blue pixel intensity
andi r19,r19, 0b0011111
bgt r19, r10, skip_pixel_change

#changes the colour of the pixel and calculates current average
Pixel_change:

#Isolating x (bits 1-8)
srli r19, r16, 1
andi r19, r19, 0b00111111111
add r20, r20, r19 #Storing current x

#Isolating y (bits 10-17)
srli r19, r16, 10
andi r19, r19, 0b0011111111
add r21, r21, r19 #Adding current y to sum of all ys for red pixels

addi r22, r22, 1 #Incrementing element counter

skip_pixel_change:
#While address is less than ending address. keep looping
addi r16, r16, 2
addi r11, r11, 2
addi r13, r13, 1
movi r18, 320 #x = 319 is the rightmost pixel
bltu r13, r18, x_red_loop

call play_sound

#Incrementing y counter, checking if less than max y
addi r12, r12, 1
movi r18, 240
bltu r12, r18, y_red_loop


#Calculating average location and storing it before returning
beq r22, r0, skip_average #If there are no red pixels, do not attempt to find the average (division by 0)

div r20, r20, r22 #Sum of x divided by number of elements
div r21, r21, r22 #Sum of y divided by number of elements

#Storing x and y at the appropriate memory location
movia r16, player_temp
subi r20, r20, 15
stw r20,0(r16)
subi r21, r21, 15
stw r21,4(r16)


skip_average:
ldw ra,0(sp)
ldw r16,4(sp)
ldw r17,8(sp)
ldw r18,12(sp)
ldw r19,16(sp)
ldw r20,20(sp)
ldw r21,24(sp)
ldw r22,28(sp)
addi sp,sp,32
ret

#Increments the players location by a fixed value to prevent random teleportation
update_player_Location:
addi sp,sp,-20
stw ra,0(sp)
stw r16,4(sp)
stw r17,8(sp)
stw r18,12(sp)
stw r20,16(sp)

#Loading current player position and new player position
movia r16, player_temp
ldw r17,0(r16)
movia r16, player
ldw r18,0(r16)

#Determining the difference between the two
blt r17, r18, reverse_subtraction_1
sub r17, r17, r18
movia r18, AIMING_SPEED
blt r17, r18, teleport_1
movia r16, player
ldw r20,0(r16)
add r20, r20, r18
stw r20,0(r16)
br skip_teleport_1

#For reversing the subtraction and moving the other way
reverse_subtraction_1:
sub r17, r18, r17
movia r18, AIMING_SPEED
blt r17, r18, teleport_1
ldw r20,0(r16)
sub r20, r20, r18
stw r20,0(r16)
br skip_teleport_1

#Difference is less than the aming speed (Pixels moved per call) therefore just teleport it to the right coordinates
teleport_1:
movia r16, player_temp
ldw r20,0(r16)
movia r16, player
stw r20,0(r16)

skip_teleport_1:

#Loading current player position and new player  (y-direction)
movia r16, player_temp
ldw r17,4(r16)
movia r16, player
ldw r18,4(r16)

#Determining the difference between the two
blt r17, r18, reverse_subtraction_2
sub r17, r17, r18
movia r18, AIMING_SPEED
blt r17, r18, teleport_2
movia r16, player
ldw r20,4(r16)
add r20, r20, r18
stw r20,4(r16)
br skip_teleport_2

#For reversing the subtraction and moving the other way
reverse_subtraction_2:
sub r17, r18, r17
movia r18, AIMING_SPEED
blt r17, r18, teleport_2
ldw r20,4(r16)
sub r20, r20, r18
stw r20,4(r16)
br skip_teleport_2

#Difference is less than the aming speed (Pixels moved per call) therefore just teleport it to the right coordinates
teleport_2:
movia r16, player_temp
ldw r20,4(r16)
movia r16, player
stw r20,4(r16)

skip_teleport_2:

ldw ra,0(sp)
ldw r16,4(sp)
ldw r17,8(sp)
ldw r18,12(sp)
ldw r20,16(sp)
addi sp,sp,20
ret

draw_crosshair:
addi sp,sp,-16
stw ra,0(sp)
stw r16,4(sp)
stw r17,8(sp)
stw r20,12(sp)


#Loading x and adding offset of 2
movia r20, player
ldw r17,0(r20)
movi r16, 2
mul r17, r17, r16

#loading y and adding offset of 1024
ldw r16,4(r20)
movi r20, 1024
mul r16, r20, r16

add r17, r16, r17

#Adding offset to base address
movia r20, ADDR_VGA
add r20, r20, r17

movui r17,0xF800
sthio r17,0(r20) 
addi r16, r20, 2
sthio r17,0(r16) 
addi r16, r20, 1024
sthio r17,0(r16) 
addi r16, r16, 2
sthio r17,0(r16) 

ldw ra,0(sp)
ldw r16,4(sp)
ldw r17,8(sp)
ldw r20,12(sp)
addi sp,sp,16
ret



