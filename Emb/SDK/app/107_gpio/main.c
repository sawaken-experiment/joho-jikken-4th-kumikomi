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
void mylib_msleep(unsigned int tm){
    unsigned int end = (unsigned int) *e_time + tm;
    while (*e_time < end);
}

/**********************************************************************/
int main(void){
    int i=0;

    while(1) {
        *e_gp2 = i;
        mylib_msleep(100);
        i++;
    }
}
/**********************************************************************/

