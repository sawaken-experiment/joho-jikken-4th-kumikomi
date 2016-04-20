/* include character font data */
#include "cfont.h"

/* memory address to access mmc */
volatile char *e_vram = (char*)0x900000;

/* data-type of LCD color (express 16bit color) */
typedef struct{
	unsigned char r, g, b;
}Color;

/* prototype decration */
Color make_color(unsigned char r, unsigned char g, unsigned char b);
Color make_color_from24bit(unsigned char r, unsigned char g, unsigned char b);
int draw_dot(int x, int y, Color *color);
int draw_char(int x, int y, char c, Color *color);
void draw_byte_hex(int x, int y, unsigned char c, Color *color);
int draw_int(int x, int y, unsigned int val, Color *color);
int draw_str(int x, int y, char str[], Color *color);
void draw_fill(int x, int y, int width, int height, Color *color);
void draw_fill_line(int y, int line_width, Color *color);
void draw_clear(Color *color);
int is_out_of_range(int x, int y);
int is_upper(char c);
int is_lower(char c);
int is_digit(char c);

/*
	make and return structure of Color (express 16bit color)
	args: red (5bit, 0-31), green (6bit, 0-63), blue (5bit, 0-31)
*/
Color make_color(unsigned char r, unsigned char g, unsigned char b){
  Color color;
	color.r = r;
	color.g = g;
	color.b = b;
	return color;
}

/*
	convert 24bit-color to 16bit-color and make structure of Color
	args: red, green, blue (each 8bit, 0-255)
*/
Color make_color_from24bit(unsigned char r, unsigned char g, unsigned char b){
	return make_color(r >> 3, g >> 2, b >> 3);
}

/*
	draw one dot on display
	return: draw point (x, y) is out of range => 1, in range => 0
*/
int draw_dot(int x, int y, Color *color){	
	if(is_out_of_range(x, y)) return 1;

	e_vram[x + y * 128] =       (color->r & 63);
	e_vram[x + y * 128] =  64 | (color->g & 63);
	e_vram[x + y * 128] = 128 | (color->b & 63);
	return 0;
}

/*
	draw one character on display
	only 0..9, a..z and A..Z are supported
	(a..z are automatically converted to A..Z)
	args: left_position, top_position, print_charcter, print_color
	return: character is supported => 0, not supported => 1
*/
int draw_char(int x, int y, char c, Color *color){ 
	if(is_digit(c)){

		int i, j;
		for(i=0;i<8;i++){
			for(j=0;j<16;j++){
				if(e_number[c - '0'][j][i]) draw_dot(x+i, y+j, color);
			}
		}
		return 0;

	}else if(is_upper(c) || is_lower(c)){
		
		int i, j;
		if(is_lower(c)) c = 'A' + (c - 'a');
		for(i=0;i<8;i++){
			for(j=0;j<16;j++){
				if(e_char[c - 'A'][j][i]) draw_dot(x+i, y+j, color);
			}
		}
		return 0;

	}

	return 1;
}

/*
	dump byte data as two hex value
*/
void draw_byte_hex(int x, int y, unsigned char c, Color *color){
	int d[] = {0, 0};
  int i, j;
	
	for(i=0;i<2;i++){
		char hexchar;
		for(j=1;j<16;j*=2){
			d[i] += (1 & c) * j;
			c = c >> 1;
		}
		hexchar = (d[i] < 10 ? '0' + d[i] : 'A' + (d[i] - 10));
		draw_char(x + (1-i) * 8, y, hexchar, color);
	}
}


/*
	draw integer value on display
	args: left_position, top_position, print_value, print_color
	return: length of value
*/
int draw_int(int x, int y, unsigned int val, Color *color){
	int length, i;
	char digits[10];

	if(val == 0){
		draw_char(x, y, '0', color);
		return 1;
	}
	
	length = 0;
	while(val > 0){
		digits[length++] = '0' + (val % 10);
		val /= 10;
	}
	for(i=0;i<length;i++){
		draw_char(x + (i*8), y, digits[length - 1 - i], color);
	}
	return length;
}

/*
	draw string (array of char) on display
	return: lenght of string
*/
int draw_str(int x, int y, char str[], Color *color){
	int i;

	for(i=0;str[i]!='\0';i++){
		draw_char(x + (i*8), y, str[i], color);
	}

	return i;
}

/*
	fill in rectangle area
*/
void draw_fill(int x, int y, int width, int height, Color *color){
	int i, j;
	for(i=0;i<width;i++){
		for(j=0;j<height;j++){
			draw_dot(x + i, y + j, color);
    }
	}
}

/*
	fill in lines by specifying top-position and line-width
*/
void draw_fill_line(int y, int line_width, Color *color){
	draw_fill(0, y, 128, line_width, color);
}

/*
	fill in the whole of display by specified color
*/
void draw_clear(Color *color){
	draw_fill(0, 0, 128, 128, color);
}

/*
	check point (x, y) is in display range?
	returns: in range => 1, out of range => 0
*/
int is_out_of_range(int x, int y){
  return (x < 0 || x > 127 || y < 0 || y > 127);
}

/*
	functions for distinction of character type
	(similar to functions in the c standard library <ctype.h>)
*/
int is_upper(char c){
	return 'A' <= c && c <= 'Z';
}

int is_lower(char c){
	return 'a' <= c && c <= 'z';
}

int is_digit(char c){
	return '0' <= c && c <= '9';
}

