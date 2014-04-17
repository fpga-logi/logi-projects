#include <stdio.h>
#include <stdlib.h>
#include <jpeglib.h>
#include <jerror.h>
#include "jpeg_func.h"



int write_jpegfile(char * frame, unsigned short width, unsigned short height, FILE * fd, int quality)
{
  JSAMPROW row_ptr[1];
  struct jpeg_compress_struct jpeg;
  struct jpeg_error_mgr jerr;
  char *line, *image;
  int y, x, line_width;
  line =(char *) malloc((width) * sizeof(char));
  if (!line)
    return 0;
  jpeg.err = jpeg_std_error (&jerr);
  jpeg_create_compress (&jpeg);
  jpeg.image_width = width;
  jpeg.image_height= height;
  jpeg.input_components = 1;
  jpeg.in_color_space = JCS_GRAYSCALE;
  jpeg_set_defaults (&jpeg);
  jpeg_set_quality (&jpeg, quality, TRUE);
  jpeg.dct_method = JDCT_FASTEST;
  jpeg_stdio_dest(&jpeg, fd);
  jpeg_start_compress (&jpeg, TRUE);
  row_ptr[0] = (JSAMPROW) line;
  line_width = width ;
  image = (char *) frame ;
  for (y = 0; y < height; y++) {
    for (x = 0; x < line_width; x++) {
      line[x]   = image[x];
    }
    if (!jpeg_write_scanlines (&jpeg, row_ptr, 1)) {
      jpeg_destroy_compress (&jpeg);
      free(line);
      return 0;
    }
    image += line_width;
  }
  jpeg_finish_compress (&jpeg);
  jpeg_destroy_compress (&jpeg);
  free (line);
  return 1;
}

int write_jpegmem(char * frame, unsigned short width, unsigned short height, unsigned short nbChannels, unsigned char **outbuffer, long unsigned int *outlen, int quality)
{
  JSAMPROW row_ptr[1];
  struct jpeg_compress_struct jpeg;
  struct jpeg_error_mgr jerr;
  char *line, *image;
  int y, x, line_width;
  *outbuffer = NULL;
  *outlen = 0;
  line =(char *) malloc((width * nbChannels) * sizeof(char));
  if (!line)
    return 0;
  jpeg.err = jpeg_std_error (&jerr);
  jpeg_create_compress (&jpeg);
  jpeg.image_width = width;
  jpeg.image_height= height;
  jpeg.input_components = nbChannels;
  jpeg.in_color_space = JCS_RGB;
  jpeg_set_defaults (&jpeg);
  jpeg_set_quality (&jpeg, quality, TRUE);
  jpeg.dct_method = JDCT_FASTEST;
  jpeg_mem_dest(&jpeg, outbuffer, outlen);
  jpeg_start_compress (&jpeg, TRUE);
  row_ptr[0] = (JSAMPROW) line;
  line_width = width * nbChannels;
  for (y = 0; y < height; y++) {
    for (x = 0; x < line_width; x++) {
      line[x]   = frame[x];
    }
    if (!jpeg_write_scanlines (&jpeg, row_ptr, 1)) {
      jpeg_destroy_compress (&jpeg);
      free (line);
      return 0;
    }
    image += line_width;
  }
  jpeg_finish_compress (&jpeg);
  jpeg_destroy_compress (&jpeg);
  free (line);
  return 1;
}

int read_jpeg_file( char *filename, unsigned char ** buffer)
{
	/* these are standard libjpeg structures for reading(decompression) */
	struct jpeg_decompress_struct cinfo;
	struct jpeg_error_mgr jerr;
	/* libjpeg data structure for storing one row, that is, scanline of an image */
	JSAMPROW row_pointer[1];
	
	FILE *infile = fopen( filename, "rb" );
	unsigned long location = 0;
	int i = 0;
	
	if ( !infile )
	{
		printf("Error opening jpeg file %s\n!", filename );
		return -1;
	}
	printf("input file opened \n");
	/* here we set up the standard libjpeg error handler */
	cinfo.err = jpeg_std_error( &jerr );
	/* setup decompression process and source, then read JPEG header */
	jpeg_create_decompress( &cinfo );
	/* this makes the library read from infile */
	jpeg_stdio_src( &cinfo, infile );
	/* reading the image header which contains image information */
	jpeg_read_header( &cinfo, TRUE );
	/* Uncomment the following to output image information, if needed. */
	
	printf( "JPEG File Information: \n" );
	printf( "Image width and height: %d pixels and %d pixels.\n", cinfo.image_width, cinfo.image_height );
	printf( "Color components per pixel: %d.\n", cinfo.num_components );
	printf( "Color space: %d.\n", cinfo.jpeg_color_space );
	
	/* Start decompression jpeg here */
	jpeg_start_decompress( &cinfo );

	/* allocate memory to hold the uncompressed image */
	buffer[0] = (unsigned char*) malloc( 
cinfo.output_width*cinfo.output_height*cinfo.num_components );
	/* now actually read the jpeg into the raw buffer */
	row_pointer[0] = (unsigned char *)malloc( cinfo.output_width*cinfo.num_components );
	/* read one scan line at a time */
	printf("starting decompression \n");
	while( cinfo.output_scanline < cinfo.image_height )
	{
		jpeg_read_scanlines( &cinfo, row_pointer, 1 );
		for( i=0; i<cinfo.image_width*cinfo.num_components;i++) 
			buffer[0][location++] = row_pointer[0][i];
	}
	/* wrap up decompression, destroy objects, free pointers and close open files */
	jpeg_finish_decompress( &cinfo );
	jpeg_destroy_decompress( &cinfo );
	free( row_pointer[0] );
	fclose( infile );
	/* yup, we succeeded! */
	return 1;
}



