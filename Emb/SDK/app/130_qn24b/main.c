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

/**********************************************************/
typedef struct array_t{
    unsigned int cdt; /* candidates        */
    unsigned int col; /* column            */
    unsigned int pos; /* positive diagonal */
    unsigned int neg; /* negative diagonal */
} array;

/**********************************************************/
long long qn(int n, int h, int r, array *a){
    long long answers = 0;

    for(;;){
        if(r){
            int lsb = (-r) & r;
            a[h+1].cdt = (       r & ~lsb);
            a[h+1].col = (a[h].col & ~lsb);
            a[h+1].pos = (a[h].pos |  lsb) << 1;
            a[h+1].neg = (a[h].neg |  lsb) >> 1;
      
            r = a[h+1].col & ~(a[h+1].pos | a[h+1].neg);
            h++;
        }
        else{
            r = a[h].cdt;
            h--;

            if(h==0) break;
            if(h==n) answers++;
        }
    }
    return answers;
}


/** main function                                        **/
/**********************************************************/
int main(int argc, char *argv[]){
    int i;
    int n    = 13;
    array a[30];
    long long answers = 0;
    unsigned int time = *e_time;
    
    mylib_clear(7);

    mylib_putc( 0, 0, 'Q', 1);
    mylib_putc( 8, 0, 'N', 1);

    mylib_putuint(120, 40, n, 0);
  
    for(i=0; i<(n/2+n%2); i++){
        long long ret;
        int h = 1;      /* height or level  */
        int r = 1 << i; /* candidate vector */
        a[h].col = (1<<n)-1;
        a[h].pos = 0;
        a[h].neg = 0;

        ret = qn(n, h, r, a); /* kernel loop */

        answers += ret;
        if(i!=n/2) answers += ret;
    }

    time = *e_time - time;
    mylib_putuint(120, 60, answers, 0);
    mylib_putuint(120, 90, time, 0);

    while(1);

    return 0;
}
/**********************************************************/
