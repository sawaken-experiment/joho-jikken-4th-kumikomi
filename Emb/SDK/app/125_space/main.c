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

#include "cfont.h" // include character & number font
#include "sin.h"
#include "cos.h"
#define D_WIDTH  128 // D_WIDTH
#define D_HEIGHT 128 // D_HEIGHT
#define VIEW_X 100
#define NUM_PLANET 100
#define INIT_DIST 1000
#define PLANET_SPEED 20

/**********************************************************************/
typedef struct {
    int r;
    int theta;
    int d;
} Planet;

Planet planets[NUM_PLANET];

volatile char vrambuf[128*128];

/**********************************************************************/
inline void mlcd_dot_buf(int x, int y){
    int color = (*e_gp1) ? 7 : 2;
    vrambuf[(y<<7) | x] = color;
}

/**********************************************************************/
void copy_buf(){
    int i;
    for(i = 0; i < 128*128; i++)
        e_vram[i] = vrambuf[i];
}

/**********************************************************************/
static unsigned int rand_seed = 1;

int my_rand(void){
    rand_seed = rand_seed*1103515245+12345;
    return (unsigned int)(rand_seed / 65536) % 32768;
}

/**********************************************************************/
void mylib_putc(int x, int y, char c, int color){
    int i, j;
    
    for(i=0; i<16; i++){
        for(j=0; j<8; j++){
            if(e_char[(int)(c-'A')][i][j]) 
                vrambuf[(x+j)+(y+i)*128] = color; // write to buffer
        }
    }
}
/**********************************************************************/
int spaceflight(void){
    int i;

    for (i = 0; i < NUM_PLANET; i++) {
        planets[i].d = 0;
        planets[i].r = 0;
        planets[i].theta = 0;
    }

    int index = 0;
    for(;;){
        
        for(i = 0; i < 128*128; i++) vrambuf[i] = 0;

        for (i = 0; i < NUM_PLANET; i++) {
            int d = planets[i].d;
            int r = planets[i].r;
            int theta = planets[i].theta;
            int x = -1;
            int y = -1;
            if (planets[i].d >= 0) {
                x = VIEW_X*r*e_cos[theta]/(1000*(d+VIEW_X)) + 64;
                y = VIEW_X*r*e_sin[theta]/(1000*(d+VIEW_X)) + 64;
            } 
            
            if (0 <= x && x <= D_WIDTH && 0 <= y && y <= D_HEIGHT) {
                if (d < 500) {
                    mlcd_dot_buf(x,   y  );
                    mlcd_dot_buf(x+1, y  );
                    mlcd_dot_buf(x,   y+1);
                    mlcd_dot_buf(x+1, y+1);
                } else {
                    mlcd_dot_buf(x,   y  );
                }
            }
            planets[i].d -= PLANET_SPEED;
        }
        
        {
            int x =0;
            mylib_putc(x, 0, 'S', 7); x=x+8;
            mylib_putc(x, 0, 'P', 7); x=x+8;
            mylib_putc(x, 0, 'A', 7); x=x+8;
            mylib_putc(x, 0, 'C', 7); x=x+8;
            mylib_putc(x, 0, 'E', 7); x=x+8;
            mylib_putc(x, 0, 'F', 7); x=x+8;
            mylib_putc(x, 0, 'L', 7); x=x+8;
            mylib_putc(x, 0, 'I', 7); x=x+8;
            mylib_putc(x, 0, 'G', 7); x=x+8;
            mylib_putc(x, 0, 'H', 7); x=x+8;
            mylib_putc(x, 0, 'T', 7); x=x+8;
        }
            
        copy_buf(); // update mini LCD 

        int rand = my_rand();
        planets[2*index+1].d = INIT_DIST;
        planets[2*index+1].r = rand % 1000;
        planets[2*index+1].theta = rand % 360;

        index = (index + 1) % (NUM_PLANET/2);
    }
    
    return 0;
}
/**********************************************************************/
int main(void){

    spaceflight();
    return 0;
}

/**********************************************************************/
