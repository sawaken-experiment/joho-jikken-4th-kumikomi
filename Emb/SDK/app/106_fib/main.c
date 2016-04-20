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
void mylib_putuint(int x, int y, int num, int color){
    x = x - 7;

    if (x >= 128 || x <= -8 || y >= 128 || y <= -16)
        return;

    if (num < 0)
        return;
    else if (num == 0)
        mylib_putnum(x, y, num, color);

    for(; (num/10 != 0) || (num%10 != 0);){
        mylib_putnum(x, y, num % 10, color);
        x = x - 8;
        num = num / 10;
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
unsigned int fib(int n){
    if(n<=2) return 1;
    else return (fib(n-1) + fib(n-2));
}
/**********************************************************************/
int main(){
    int i, answer;

    i = 1;
    while(1){
        answer = fib(i);

        mylib_clear(7);
        mylib_putc( 0, 0, 'F', 1);
        mylib_putc( 8, 0, 'I', 1);
        mylib_putc(16, 0, 'B', 1);
        mylib_putc(24, 0, 'O', 1);

        mylib_putuint(120, 40, i,      0);
        mylib_putuint(120, 70, answer, 0);

        mylib_msleep(1000);
        i++;
    }
}
/**********************************************************************/
