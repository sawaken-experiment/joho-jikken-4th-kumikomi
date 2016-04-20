/* include <string.h> to use memcpy() */
#include <string.h>

/* standardized value of bitmap image file */
#define HEADER_SIZE       54
#define FILE_SIZE_OFFSET   2
#define IMG_WIDTH_OFFSET  18
#define IMG_HEIGHT_OFFSET 22

/* duration for seeking next image file in mmc (byte) */
#define NEXT_SEEK_LENGTH (512*8)

typedef struct{
	MMC *mp;
	unsigned int size;
	unsigned int width;
	unsigned int height;
	unsigned int pointer;
}IMG;

/* prototype decration */
IMG iopen(MMC *mp);
int is_image_data(MMC *mp);
int readline(IMG *ip, Color img_buf[]);
int seek_next_img(IMG *ip);


/*
	open bmp file from specified mmc point
	arg: mmc pointer pointing head of bmp file
	return: structure of bmp image (includes header info,
	                                   points head of rgb data)
*/
IMG iopen(MMC *mp){
	unsigned char header[HEADER_SIZE];
	IMG img;

	mread(header, HEADER_SIZE, mp);

	img.mp = mp;
	memcpy(&img.size,   header + FILE_SIZE_OFFSET,  4);
	memcpy(&img.width,  header + IMG_WIDTH_OFFSET,  4);
	memcpy(&img.height, header + IMG_HEIGHT_OFFSET, 4);
	img.pointer = HEADER_SIZE;
	
	return img;
}

/*
	check whether specified mmc point head of bmp file or not
*/
int is_image_data(MMC *mp){
	unsigned char data_type[2];
	
	mread(data_type, 2, mp);
	mseek(mp, -2, SEEK_CUR);
	
	return data_type[0] == 'B' && data_type[1] == 'M';
}

/*
	read one-line color data from bmp file
	args: ref of image structure pointing head of rgb data in bmp file
*/
int readline(IMG *ip, Color img_buf[]){
	int i;

	for(i=0;i<ip->width;i++){
		unsigned char rgb[3];
		
		mread(rgb, 3, ip->mp);

		img_buf[i] = make_color_from24bit(rgb[2], rgb[1], rgb[0]);	
	}

	mseek(ip->mp, ip->width % 4, SEEK_CUR);
	ip->pointer += ip->width * 3 + ip->width % 4;

	return 1;
}

/*
	move image structure's pointer to  head of next image file
	(seeking at most NEXT_SEEK_LENGTH byte from end of now image file)
	return: found => 0, not found => 1
*/
int seek_next_img(IMG *ip){
	int i;

	if(ip->pointer < ip->size){
		mseek(ip->mp, ip->size - ip->pointer, SEEK_CUR);
		ip->pointer = ip->size;
	}
	
	for(i=0;i<NEXT_SEEK_LENGTH;i++){
		if(is_image_data(ip->mp)){
			(*ip) = iopen(ip->mp);
			return 0;
		}
		mseek(ip->mp, 1, SEEK_CUR);
	}

	return 1;
}
