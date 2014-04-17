int write_jpegfile(char * frame, unsigned short width, unsigned short height, FILE * fd, int quality);
int write_jpegmem(char * frame, unsigned short width, unsigned short height, unsigned short nbChannels, unsigned char **outbuffer, long unsigned int *outlen, int quality);
int read_jpeg_file( char *filename, unsigned char ** buffer);
