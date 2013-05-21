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

int write_jpegmem_gray(char * frame, unsigned short width, unsigned short height, unsigned char **outbuffer, long unsigned int *outlen, int quality)
{
  JSAMPROW row_ptr[1];
  unsigned short nbChannels = 1 ;
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
  jpeg.in_color_space = JCS_GRAYSCALE;
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
    frame += line_width;
  }
  jpeg_finish_compress (&jpeg);
  jpeg_destroy_compress (&jpeg);
  free (line);
  return 1;
}



