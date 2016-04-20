/* define switching symbol */
#define SWITCH1 0
#define SWITCH2 1
#define SWITCH3 2
#define ON  0
#define OFF 1

/* memory address to access mmc */
volatile char *switches[] = {(char*)0x8001fc, (char*)0x8001fd, (char*)0x8001fe};


/* prototype decration */
int check_switch(int switch_name, int condition);


/*
	check specified switch is on specified condition (0 or 1)
*/
int check_switch(int switch_name, int condition){
	return *switches[switch_name] == condition;
}
