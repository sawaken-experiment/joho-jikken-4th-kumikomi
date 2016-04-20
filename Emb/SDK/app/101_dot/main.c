/***** Sample Program for MieruEMB System v1.0                    *****/
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
int main(void){
    int x = 63;
    int y = 63;

    e_vram[x+y*128] = 7;

    while(1);
}
/**********************************************************************/

