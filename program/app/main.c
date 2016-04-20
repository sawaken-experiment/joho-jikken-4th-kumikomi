/***************************
 Image Viewer Program on MieruEMB System
 since       2013/11/16
 last update 2013/11/18
****************************/
#include "mmc.h"
#include "lcd.h"
#include "switch.h"
#include "bmp.h"

#define PROGRAM_SIZE (512*1024)


void draw_img(IMG *ip){
	Color img_buf[128];
	int i, j;
	
	for(i = 0; i < ip->height; i++){
		readline(ip, img_buf);
		for(j = 0; j < ip->width; j++){
			draw_dot(j, 127-i, &img_buf[j]);
		}
	}
}

int main(){
	Color black = make_color(0, 0, 0);
	MMC mmc, *mp;
	IMG img, *ip;

	while(1){
		mmc = mopen(), mp = &mmc;
		mseek(mp, PROGRAM_SIZE, SEEK_CUR);
		
		img = iopen(mp), ip = &img;
		
		draw_clear(&black);
		draw_img(ip);

		while(1){
			if(check_switch(SWITCH1, ON)){

				if(seek_next_img(ip)){
					mclose(mp);
					break;
				}

				draw_img(ip);
			}
		}
	}
}

