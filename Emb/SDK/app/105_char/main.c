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

/**********************************************************************/
#define P_WIDTH  14
#define P_HEIGHT 18

const unsigned int pic_data[P_HEIGHT][P_WIDTH] = {
    {7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7},
    {7, 7, 7, 7, 4, 4, 4, 4, 4, 7, 7, 7, 7, 7},
    {7, 7, 7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7, 7},
    {7, 7, 7, 0, 0, 0, 6, 6, 0, 6, 7, 7, 7, 7},
    {7, 7, 0, 6, 0, 6, 6, 0, 0, 0, 0, 0, 7, 7},
    {7, 7, 0, 6, 0, 0, 6, 0, 0, 0, 0, 0, 6, 7},
    {7, 7, 0, 0, 6, 6, 6, 0, 0, 0, 0, 0, 7, 7},
    {7, 7, 7, 7, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7},
    {7, 7, 7, 1, 1, 4, 1, 1, 4, 1, 1, 7, 7, 7},
    {7, 7, 1, 1, 1, 4, 1, 1, 4, 1, 1, 1, 7, 7},
    {7, 1, 1, 1, 1, 4, 4, 4, 4, 1, 1, 1, 1, 7},
    {7, 6, 6, 1, 4, 6, 4, 4, 6, 4, 1, 6, 6, 7},
    {7, 6, 6, 6, 4, 4, 4, 4, 4, 4, 6, 6, 6, 7},
    {7, 6, 6, 4, 4, 4, 4, 4, 4, 4, 4, 6, 6, 7},
    {7, 7, 7, 4, 4, 4, 7, 7, 4, 4, 4, 7, 7, 7},
    {7, 7, 0, 0, 0, 7, 7, 7, 7, 0, 0, 0, 7, 7},
    {7, 0, 0, 0, 0, 7, 7, 7, 7, 0, 0, 0, 0, 7},
    {7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7}
};

/**********************************************************************/
void mylib_putpic(int x, int y, int width, int height,  
                  const unsigned int data[][width]){
    int i,j;

    for(i=0; i<height; i++)
        for(j=0; j<width; j++)
            e_vram[(x+j) + (y+i)*128] =  data[i][j];
}

/**********************************************************************/
void mylib_putc(int x, int y, char c, int color){
    int i, j;
    
    for(i=0; i<16; i++){
        for(j=0; j<8; j++){
            if(e_char[(int)(c-'A')][i][j]) 
                e_vram[(x+j)+(y+i)*128] = color;
        }
    }
}
/**********************************************************************/
void mylib_putnum(int x, int y, int num, int color){
    int i, j;
    
    for(i=0; i<16; i++){
        for(j=0; j<8; j++){
            if(e_number[num][i][j]) e_vram[(x+j)+(y+i)*128] = color;
        }
    }
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
    int x = 57;
    int y = 55;
    
    mylib_clear(7);

    mylib_putc( 0, 0, 'M', 1);
    mylib_putc( 8, 0, 'I', 1);
    mylib_putc(16, 0, 'E', 1);
    mylib_putc(24, 0, 'R', 1);
    mylib_putc(32, 0, 'U', 1);
    mylib_putc(40, 0, 'E', 1);
    mylib_putc(48, 0, 'M', 1);
    mylib_putc(56, 0, 'B', 1);

    mylib_putnum(80, 0, 1, 1);
    mylib_putnum(88, 0, 0, 1);
    mylib_putnum(96, 0, 0, 1);

    while(1){
        if(*e_sw1==0 && x>10)  x--;
        if(*e_sw2==0 && y>17)  y--;
        if(*e_sw3==0 && x<107) x++;
        if(*e_sw1==0 && *e_sw3==0 && y<108)  y++;

        mylib_putpic(x, y, P_WIDTH, P_HEIGHT, pic_data);
        mylib_msleep(10); // sleep 10 msec
    }
}
/**********************************************************************/
