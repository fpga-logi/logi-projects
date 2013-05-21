int write_jpegfile(char * frame, unsigned short width, unsigned short height, FILE * fd, int quality);
int write_jpegmem_gray(char * frame, unsigned short width, unsigned short height, unsigned char **outbuffer, long unsigned int *outlen, int quality);
