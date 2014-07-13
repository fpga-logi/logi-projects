/**@file libppm.c
 * @author Xiaofan Li
 * @brief takes care of reading in and resizing ppm file
 */

#include <stdio.h>
#include <stdlib.h>

#include "includes/libppm.h"


/** start of the ppm library **/
PPMImage *readPPM(const char *filename)
{
    char buff[16];
    PPMImage *img;
    FILE *fp;
    int c, rgb_comp_color;
    
    //open PPM file for reading
    fp = fopen(filename, "rb");
    if (!fp) {
        fprintf(stderr, "Unable to open file '%s'\n", filename);
        exit(1);
    }

    //read image format
    if (!fgets(buff, sizeof(buff), fp)) {
        perror(filename);
        exit(1);
    }

    //check the image format
    if (buff[0] != 'P' || buff[1] != '6') {
        fprintf(stderr, "Invalid image format (must be 'P6')\n");
        exit(1);
    }

    //alloc memory form image
    img = (PPMImage *)malloc(sizeof(PPMImage));
    if (!img) {
        fprintf(stderr, "Unable to allocate memory\n");
        exit(1);
    }

    //check for comments
    c = getc(fp);
    while (c == '#') {
    while (getc(fp) != '\n') ;
        c = getc(fp);
    }

    ungetc(c, fp);
    //read image size information
    if (fscanf(fp, "%d %d", &img->x, &img->y) != 2) {
        fprintf(stderr, "Invalid image size (error loading '%s')\n", filename);
        exit(1);
    }

    //read rgb component
    if (fscanf(fp, "%d", &rgb_comp_color) != 1) {
        fprintf(stderr, "Invalid rgb component (error loading '%s')\n", filename);
        exit(1);
    }

    //check rgb component depth
    if (rgb_comp_color!= RGB_COMPONENT_COLOR) {
        fprintf(stderr, "'%s' does not have 8-bits components\n", filename);
        exit(1);
    }

    while (fgetc(fp) != '\n') ;
    //memory allocation for pixel data
    img->data = (PPMPixel*)malloc(img->x * img->y * sizeof(PPMPixel));

    if (!img) {
        fprintf(stderr, "Unable to allocate memory\n");
        exit(1);
    }

    //read pixel data from file
    if (fread(img->data, 3 * img->x, img->y, fp) != img->y) {
        fprintf(stderr, "Error loading image '%s'\n", filename);
        exit(1);
    }

    fclose(fp);
    return img;
}

PPMImage* handle_shrink(PPMImage* input){
    int height = input->y;
    int width = input->x;
    if ((height%OUTPUT_HEIGHT!=0) || (width%OUTPUT_WIDTH!=0)){
	fprintf(stderr,"the original size needs to be multiple of %d and %d",OUTPUT_HEIGHT,OUTPUT_WIDTH);
	exit(1);
    }
    int height_gap = input->y / OUTPUT_HEIGHT;
    int width_gap = input->x / OUTPUT_WIDTH;

    PPMPixel* data = (PPMPixel*) malloc(OUTPUT_HEIGHT*OUTPUT_WIDTH*sizeof(PPMPixel));   
 
    PPMImage* new = (PPMImage*) malloc(sizeof(PPMImage));
    new->x = OUTPUT_WIDTH;
    new->y = OUTPUT_HEIGHT;
    new->data = data;

    int i,j;
    for (i=0;i<OUTPUT_HEIGHT;i++){
        for (j=0;j<OUTPUT_WIDTH;j++){
            (new->data)[(i*OUTPUT_WIDTH + j)].red = (input->data)[(i*height_gap*(input->x) + j*width_gap)].red;
            (new->data)[(i*OUTPUT_WIDTH + j)].green = (input->data)[(i*height_gap*(input->x) + j*width_gap)].green;
            (new->data)[(i*OUTPUT_WIDTH + j)].blue = (input->data)[(i*height_gap*(input->x) + j*width_gap)].blue;
        }
    }
    return new;
}


PPMImage* handle_center(PPMImage* input){
    int adj_y = ((input->y)-OUTPUT_HEIGHT) / 2;
    int adj_x = ((input->x)-OUTPUT_WIDTH) / 2 ;

    PPMPixel* data = (PPMPixel*) malloc(OUTPUT_HEIGHT*OUTPUT_WIDTH*sizeof(PPMPixel));   
 
    PPMImage* new = (PPMImage*) malloc(sizeof(PPMImage));
    new->x = OUTPUT_WIDTH;
    new->y = OUTPUT_HEIGHT;
    new->data = data;

    int i,j;
    for (i=adj_y;i<OUTPUT_HEIGHT+adj_y;i++){
        for (j=adj_x;j<OUTPUT_WIDTH+adj_x;j++){
            (new->data)[((i-adj_y)*OUTPUT_WIDTH + (j-adj_x))].red = (input->data)[(i*(input->x) + j)].red;
            (new->data)[((i-adj_y)*OUTPUT_WIDTH + (j-adj_x))].green = (input->data)[(i*(input->x) + j)].green;
            (new->data)[((i-adj_y)*OUTPUT_WIDTH + (j-adj_x))].blue = (input->data)[(i*(input->x) + j)].blue;
        }
    }
    return new;
}



PPMImage* resizePPM (PPMImage* input, int modes){
    switch (modes){
	case RESIZE_CENTER: return handle_center(input);
	case RESIZE_SHRINK: return handle_shrink(input);
	case RESIZE_SEAMCARVING: return input;
	default: 
	    fprintf(stderr,"error: undefined resizing mode");
	    exit(1);
    }	
}
