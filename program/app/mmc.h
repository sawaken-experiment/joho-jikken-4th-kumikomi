/* define seek origin symbol */
#define SEEK_SET 0
#define SEEK_CUR 1

/* memory address to access mmc */
volatile char *e_mmc  = (char*)0x800200;
volatile char *e_mcc  = (char*)0x800108;

/* data-type of MMC access pointer */
typedef struct{
	int byte_pointer;
	int block_pointer;
	int closed;
	int block_changed_flag;
}MMC;

/* type of size */
typedef unsigned int size_t;

/* prototype decration */
MMC mopen();
int mclose(MMC *mp);
size_t mread(void *buf, size_t size, MMC *mp);
int mseek(MMC *mp, int offset, int origin);
int control_mmc_pointing_block(MMC *mp);


/* 
	 open mmc descriptor (mmc structure)
 */
MMC mopen(){
	MMC mp;

	mp.byte_pointer  = 0;
	mp.block_pointer = 0;
	mp.closed = 0;
	mp.block_changed_flag = 0;
	return mp;
}

/*
	close mmc descriptor (mmc structure)
	(in fact, because of not using OS resource, you need not close mmc descriptor)
	closed mmc descriptor can not be used any more
*/
int mclose(MMC *mp){
	if(mp->closed) return 1;

	mp->closed = 1;
	
	return 0;
}

/*
	read data from mmc and write on specified buffer
	be used like fread (in C standard library)
*/
size_t mread(void *buf, size_t size, MMC *mp){
	int i;
	
	if(mp->closed) return 0;

	control_mmc_pointing_block(mp);

	for(i=0;i<size;i++){
		unsigned char mmc_data;

		if(mp->block_changed_flag){
			control_mmc_pointing_block(mp);
		}

		mmc_data = e_mmc[mp->byte_pointer];
		mmc_data = e_mmc[mp->byte_pointer];
		*((unsigned char *) buf + i) = mmc_data;

		mseek(mp, 1, SEEK_CUR);
	}
	return size;
}

/*
	seek mmc descriptor (mmc structure)
	be used like fseek (in C standard library)
	return: seek is succeeded => 0, not => 1
*/
int mseek(MMC *mp, int offset, int origin){
	int block_added;

	if(mp->closed) return 1;

	if(origin == SEEK_SET){
		mp->byte_pointer = 0;
		mp->block_pointer = 0;
	}

	block_added = (mp->byte_pointer + offset) / 512;
	if(block_added != 0) mp->block_changed_flag = 1;

	mp->block_pointer += block_added;
	mp->byte_pointer   = (mp->byte_pointer + offset) % 512;

	return 0;
}

/*
	send signal to mmc and instruct to change mmc's (hardware) block point
	normaly, be not used from out (means private function)
*/
int control_mmc_pointing_block(MMC *mp){

	if(mp->closed) return 1;

	int block = (mp->block_pointer + 81) * 2;
	e_mcc[1] = block;
	e_mcc[2] = block >> 8;
	e_mcc[3] = block >> 16;
	while(e_mcc[0] != 1);

	mp->block_changed_flag = 0;

	return 0;
}
