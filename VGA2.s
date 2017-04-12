.global main
.global player
.global play_sound
.equ BUFFER_CTRL, 0xFF203020
.equ TIMER1_CTRL, 0xFF202000
.equ VIDEO_ENABLE, 0xFF20306C
.equ EDGE_DETECTION, 0xFF203070
.equ PUSH_BUTTONS,	0xFF200050
.equ VIDEO_BUFFER, 0x03000000 #Change this later to reserve memory instead
.equ AUDIO_CODEC, 0xFF203040
.equ SWITCHES, 0xFF200040

.data
rocket_sound:
	.incbin "D:/Ece243/Final/rocket16.wav"
level_up_sound:
	.incbin "D:/Ece243/Final/levelup.wav"
evolve_sound:
	.incbin "D:/Ece243/Final/evolve.wav"	
sound_end:
	.word 0x00000000
current_sound_address:
	.word 0x00000000	
bg_novice:
	.incbin "BG_Novice.bmp"
bg_master:
	.incbin "BG_Master.bmp"
# bg_leader:
	# .incbin "BG_Leader.bmp"
# bg_champ:
	# .incbin "BG_Champ.bmp"
# bg_elite:
	# .incbin "BG_Elite.bmp"
squirtle:
	.incbin "Squirtle.bmp"
ponyta:
	.incbin "Ponyta.bmp"
sandshrew:
	.incbin "Sandshrew.bmp"
pikachu:
	.incbin "Pikachu.bmp"
charmander:
	.incbin "Charmander.bmp"
pokeball:
	.incbin "pokeball.bmp"
rocket:
	.incbin "rocket.bmp"
refresh:
	.word 1
score:
	.word 0
player:
	.word 50
	.word -120
target1:
	.word 30 #x
	.word -30 #y
target2:
	.word 70 #x
	.word -90 #y
target3:
	.word 80 #x
	.word -180 #y
target4:
	.word 150 #x
	.word -50 #y
target5:
	.word 170 #x
	.word -230 #y
target6:
	.word 200 #x
	.word -140 #y
target7:
	.word 220 #x
	.word -200 #y
target8:
	.word 270 #x
	.word -65 #y
bomb1:
	.word 40 #x
	.word -200 #y
bomb2:
	.word 220 #x
	.word -100 #y
sound_enable:
	.word 0x00000000
update_player:
	.word 0x00000000
previous_title:
	.word 0x00000000

.text
main:
	#Changing location of video input
	movia r20, VIDEO_BUFFER
	movia r17, 0xff203060 
	stw r20,0(r17)
	movia r17, 0xff203064
	stw r20,0(r17)

	#Enabling video output
	movia r16, VIDEO_ENABLE
	movi r17, 0b00100
	stwio r17,0(r16)

	#SETUP TIMER1
	movia r8, TIMER1_CTRL
	movia r9, 6000000 #0.03 second
	sthio r9, 8(r8) #period - lower 16 bits
	srli r9, r9, 16
	sthio r9, 12(r8) #period - higher 16 bits
	addi r9, r0, 0b0111
	stwio r9, 4(r8) #start, cont, enable interrupt for timer1
	call seed_random #SRAND

	#ENABLE INTERRUPTS
	addi r9, r0, 0x1
	wrctl ctl3, r9 #Unmask IRQ0 - Timer1
	wrctl ctl0, r9 #Enable CPU interrupt
#------------------------------------------------------
BG_RESET:
	movia r4, bg_novice
	call callersave
	call initialize
	call callerrestore

DRAW_LOOP:
	call callersave
	call draw_full_Screen
	call callerrestore
	
	call callersave
	call update_sound
	call callerrestore

	movia r8, SWITCHES
	ldw r9,0(r8)
	beq r9, r0, DRAW_LOOP
	
Pause_loop:
wrctl ctl0, r0
movia r8, SWITCHES
ldw r9,0(r8)
beq r9, r0, DRAW_LOOP
br Pause_loop

	
callersave:
	#SAVE LISTED CALLER SAVED REGISTERS
	#Disable interrupt
	wrctl ctl0, r0 #Enable CPU interrupt
	subi sp, sp, 32
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw r10, 8(sp)
	stw r11, 12(sp)
	stw r12, 16(sp)
	stw r13, 20(sp)
	stw r14, 24(sp)
	stw r15, 28(sp)
	ret

callerrestore:
	#RESTORE LISTED CALLER SAVED REGISTERS
	ldw r8, 0(sp)
	ldw r9, 4(sp)
	ldw r10, 8(sp)
	ldw r11, 12(sp)
	ldw r12, 16(sp)
	ldw r13, 20(sp)
	ldw r14, 24(sp)
	ldw r15, 28(sp)
	addi sp, sp, 32
	#Enable CPU interrupt
	addi r16, r0, 0x1
	wrctl ctl0, r16
	ret
	
callerrestore_No_Interrupts:
	#RESTORE LISTED CALLER SAVED REGISTERS
	ldw r8, 0(sp)
	ldw r9, 4(sp)
	ldw r10, 8(sp)
	ldw r11, 12(sp)
	ldw r12, 16(sp)
	ldw r13, 20(sp)
	ldw r14, 24(sp)
	ldw r15, 28(sp)
	addi sp, sp, 32
	wrctl ctl0, r0
	ret	

update_sound:
movia r8, sound_enable
ldw r9,0(r8)
beq r9, r0, skip_sound_enable:
movia r10, 1
beq r9, r10, play_team_rocket
movia r10, 2
beq r9, r10, play_level_up
movia r10, 3
beq r9, r10, play_evolve

#Getting appropriate sound address and ending address
play_team_rocket:
movia r10, current_sound_address
movia r11, rocket_sound
stw r11,0(r10)
movia r10, sound_end
movia r11, level_up_sound
stw r11,0(r10)
br continue_sound_update

play_level_up:
movia r10, current_sound_address
movia r11, level_up_sound
stw r11,0(r10)
movia r10, sound_end
movia r11, evolve_sound
stw r11,0(r10)
br continue_sound_update

play_evolve:
movia r10, current_sound_address
movia r11, evolve_sound
stw r11,0(r10)
movia r10, sound_end
movia r11, sound_end
stw r11,0(r10)


continue_sound_update:
#Enabling write interrupts and clearing FIFO
movia r11, AUDIO_CODEC
movia r10, 0b01110
stwio r10,0(r11)
stwio r10,8(r11)
stwio r10,12(r11)
movia r10, 0b00110
stwio r10,0(r11)
ldw r10, 4(r11)

movia r10,0x0041
wrctl ctl3,r10   # Enable bit 1 and bit 6
movia r8, sound_enable
stw r0,0(r8)
skip_sound_enable:
ret	

play_sound:
	
	
	rdctl r8, ctl4
	andi r8, r8, 0x040
	beq r8, r0, return_to_ISR

	movia r9, current_sound_address
	ldw r8,0(r9)
	ldh r10,0(r8)
	addi r8, r8, 4
	stw r8,0(r9)
	#Left shifting sound to make it 32 bits, mirroring to 
	slli r10, r10, 16
	movia r9, AUDIO_CODEC
	stwio r10,8(r9)
	stwio r10,12(r9)
	movia r9, sound_end
	ldw r11,0(r9)
	blt r8, r11, play_sound
	movia r9,0x0001
	wrctl ctl3,r9   # Disable audio interrupts
	movia r9, sound_enable
	stw r0,0(r9)
	return_to_ISR:
	
ret	

.section .exceptions, "ax"
handler:
	addi sp, sp, -4
	stw ra,0(sp)
	
	call play_sound
	
	check_timer_interrupt:	
	#SELECT INTERRUPT I/O
	rdctl r16, ctl4 #red ipending
	andi r17, r16, 0x1
	bne r17, r0, timer1_inter #timer interrupt
	br handler_end

timer1_inter:
	#TIMER1 INTERRUPT
	#ACKNOWLEDGE TIMEOUT
	movia r16, TIMER1_CTRL
	ldwio r17, 0(r16)
	movia r18, 0xFFFFFFFE
	and r17, r17, r18
	stwio r17, 0(r16)

MOVE_ALL_TARGETS:
	#INITIALIZE SCREEN
	movia r4, bg_novice
	movia r5, player
	call callersave
	call update_background
	call play_sound
	call callerrestore_No_Interrupts
	
	#CALL PLAYER COORD UPDATE
	call callersave
	call playerTracker
	call play_sound
	call callerrestore_No_Interrupts
	
	movia r4, target1
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target2
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target3
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target4
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target5
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target6
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target7
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, target8
	movia r5, player
	movia r6, score
	call callersave
	call move_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, bomb1
	movia r5, player
	movia r6, score
	movia r7, sound_enable
	call callersave
	call move_bomb
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, bomb2
	movia r5, player
	movia r6, score
	movia r7, sound_enable
	call callersave
	call move_bomb
	call play_sound
	call callerrestore_No_Interrupts
	
	draw_all_targets:
	movia r6, target1
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, squirtle
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target2
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, ponyta
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target3
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, sandshrew
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target4
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, pikachu
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target5
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, charmander
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target6
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, pikachu
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target7
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, ponyta
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, target8
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, squirtle
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, bomb1
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, rocket
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, bomb2
 	ldw r4, 0(r6) #startx
	ldw r5, 4(r6) #starty
	movia r6, rocket
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r6, player
 	ldw r4, 0(r6) #xcen
	ldw r5, 4(r6) #ycen
	movia r6, pokeball
	call callersave
	call draw_target
	call play_sound
	call callerrestore_No_Interrupts

	movia r4, score
	ldw r4, 0(r4)
	movia r5, previous_title
	movia r6, sound_enable
	call callersave
	call write_score
	call play_sound
	call callerrestore_No_Interrupts
	

	
handler_end:
	#RETURN
	ldw ra,0(sp)
	addi sp, sp, 4
	subi ea, ea, 4
	eret
	

