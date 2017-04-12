#include <time.h>
#include <stdio.h>
#include <stdlib.h>



void draw_full_Screen(){
	unsigned x;
	unsigned y;

	for(y = 0; y < 240; y++){
		for(x = 0; x < 320; x++){
			volatile short *addr=(volatile short*)(0x08000000 + ((y)<<10) + ((x) <<1));
			volatile short *buffer=(volatile short*)(0x08400000 + ((y)<<10) + ((x) <<1));
			*addr=*buffer;
		}
	play_sound();	
	}
}



//Set entire pixel buffer to <color>

void initialize(short* background){
	unsigned x;
	unsigned y;
	background += 34;//34 header size

	for(y = 0; y < 240; y++){
		for(x = 0; x < 320; x++){
			volatile short *addr=(volatile short*)(0x08400000 + ((y)<<10) + ((x) <<1));
			*addr=*background;
			background++;
		}
	}
}

void update_background(short* background, int* targets){
	unsigned x;
	unsigned y;
	short* bg_start = background + 34;
	int* limit = targets + 20;

	for(targets = targets; targets <= limit; targets += 2){
		int startx, starty;
		startx = *targets;
		starty = *(targets+1);
		
		for(y = 0; y < 30; y++){
			for(x = 0; x < 30; x++){
				volatile short *addr=(volatile short*)(0x08400000 + ((starty + y)<<10) + ((startx + x) <<1));
				if(addr >= (short*)0x08400000){
					background = bg_start + (320*(starty + y) + (startx + x));
					*addr = *background;
				}
			}
		}
	}
}

//Draw target

void draw_target(int startx, int starty, short* image){
	unsigned x;
	unsigned y;
	image += 34;

	for(y = 0; y < 30; y++){
		for(x = 0; x < 30; x++){
			volatile short *addr=(volatile short*)(0x08400000 + ((starty + y)<<10) + ((startx + x) <<1));
			if(addr >= (short*)0x08400000) if(*image != 0x0000) *addr=*image;
			image++;
		}
	}
}

void seed_random(){
	srand(time(NULL));
}

//Move target

void move_target(int* target, int* player, int* score){
	int startx = *target;
	int starty = *(target + 1);
	int playerx = *player;
	int playery = *(player + 1);
	if((playerx + 15 > startx - 10 && playerx + 15 < startx + 40) && (playery + 15 > starty - 10 && playery + 15 < starty + 40)){
		*(target + 1) = -30 - (rand() % 210);
		*target = 20 + rand() % 280;
		(*score)++;
	} else if (starty > 240){
		*(target + 1) = - 30 - (rand() % 60);;
		if (startx + 50 > 280){
			*target = rand() % 50 + 5;
		} else {
			*target += rand() % 60 + 20;
		}

	} else {
		*(target + 1) += 4;
	}
}

//Move bomb

void move_bomb(int* target, int* player, int* score, int* sound){
	int* startx = target;
	int* starty = target + 1;
	if((*player > *startx && *player < *startx + 30) && (*(player+1) > *starty && *(player+1) < *starty + 30)){
		*starty = -30 - (rand() % 210);
		*startx = *player - 40 + (rand() % 80);
		*score = 0;
		*sound = 1;
	} else if (*starty > 240){
		*starty = -30 - (rand() % 60);;
		*startx = *player - 40 + (rand() % 80);
	} else {
		if (*score < 6) *starty += 8;
		else if (*score < 12) *starty += 10;
		else if (*score < 24) *starty += 14;
		else if (*score < 48) *starty += 18;
		else *starty += 28;
	}
}

//Type score

void write_score(int score, int *previous_title, int* sound){
	char score_str[5];
	int new_title = 0;
	sprintf(score_str, "%d", score);
	char* score_strp = &score_str[0];
	char* prompt = "POKEMON CAUGHT: ";
	char* title = " - NOVICE TRAINER";
	if (score < 6){
		new_title = 0;
		title = " - NOVICE TRAINER";
	} 
	else if (score < 12){
		new_title = 1;
		title = " - MASTER TRAINER";
	} 
	else if (score < 24){
		new_title = 2;
		title = " - GYM LEADER";
	}
	else if (score < 48){
		new_title = 3;
		title = " - LEAGUE CHAMPION";
	} 
	else{
		new_title = 4;
		title = " - ELITE FOUR";
	} 

	if(new_title != *previous_title && new_title != 0){
		*previous_title = new_title;
		*sound = 2;
		if(new_title == 4) *sound = 3;
	}
	
	unsigned i;
	for(i=0; i<100; i++){
		volatile char * character_buffer = (char *) (0x09000000 + (1<<7) + i);
		*character_buffer = ' ';
	}

	unsigned x_coord = 1;
	while(*prompt){
		volatile char * character_buffer = (char *) (0x09000000 + (1<<7) + x_coord);
		*character_buffer = *prompt;
		x_coord++;
		prompt++;
	}

	while(*score_strp){
		volatile char * character_buffer = (char *) (0x09000000 + (1<<7) + x_coord);
		*character_buffer = *score_strp;
		x_coord++;
		score_strp++;
	}
	
	while(*title){
		volatile char * character_buffer = (char *) (0x09000000 + (1<<7) + x_coord);
		*character_buffer = *title;
		x_coord++;
		title++;
	}
}