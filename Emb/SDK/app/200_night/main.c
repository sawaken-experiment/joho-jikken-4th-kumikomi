/***** Sample Program for MieruEMB System v1.1                    *****/
/**********************************************************************/
volatile char *e_vram = (char*)0x900000;
volatile int  *e_time = (int *)0x80010c;
volatile char *e_gp1  = (char*)0x8001f0;
volatile char *e_gp2  = (char*)0x8001f1;
volatile char *e_sw1  = (char*)0x8001fc;
volatile char *e_sw2  = (char*)0x8001fd;
volatile char *e_sw3  = (char*)0x8001fe;
volatile char *e_gin  = (char*)0x8001ff;

/**********************************************************************/
#include "sin.h"
#include "cos.h"
#define P_WIDTH  7
#define P_HEIGHT 7

const unsigned int pic_data[P_HEIGHT][P_WIDTH] = {
  {0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0}, 
  {0, 0, 0, 6, 0, 0, 0},
  {0, 0, 6, 6, 6, 0, 0},
  {0, 0, 0, 6, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0}
};

/**********************************************************************/
void mylib_putpic(int x, int y, int width, int height,  
                  const unsigned int data[][width]){
    int i,j;
    for(i=0; i<height; i++){
      for(j=0; j<width; j++){
	int draw_x = x + j - (width / 2);
	int draw_y = y + i - (height / 2);
	if(is_out_of_range(draw_x, draw_y))continue;
	e_vram[draw_x + draw_y*128] =  data[i][j];
      }
    }
}

/**********************************************************************/
int is_out_of_range(unsigned int x, unsigned int y){
  return (x < 0 || x > 127 || y < 0 || y > 127);
}

/**********************************************************************/
void mylib_msleep(unsigned int tm){
    unsigned int end = (unsigned int) *e_time + tm;
    while (*e_time < end);
}

/**********************************************************************/
void mylib_clear(int color){
    int i;
    for(i=0; i<128*128; i++) e_vram[i] = color;
}

/**********************************************************************/
int main(){
    int x = 0;
    int y = 63;
    int direct = 1;
    int satellite_arg = 0;
    int satellite_x, satellite_y;

    mylib_clear(0);

    while(1){
      x += direct;
      if(is_out_of_range(x, y)){
	direct *= -1;
	x += direct;
      }
      satellite_arg = (satellite_arg + 2) % 360;
      satellite_x   = 10 * e_cos[satellite_arg] / 1000 + x;
      satellite_y   = 10 * e_sin[satellite_arg] / 1000 + y;
	
      mylib_putpic(x, y, P_WIDTH, P_HEIGHT, pic_data);
      mylib_putpic(satellite_x, satellite_y, P_WIDTH, P_HEIGHT, pic_data);
      mylib_msleep(10);
    }
}
/**********************************************************************/
