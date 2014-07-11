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

PPMImage* resizePPM (PPMImage* input){
    int adj_y = input->y - ((input->y)%OUTPUT_HEIGHT);    
    int adj_x = input->x - ((input->x)%OUTPUT_WIDTH);    

    int height_gap = adj_y / (OUTPUT_HEIGHT-1);
    int width_gap = adj_x / (OUTPUT_WIDTH-1);

    PPMPixel* data = (PPMPixel*) malloc(OUTPUT_HEIGHT*OUTPUT_WIDTH*sizeof(PPMPixel));   
 
    PPMImage* new = (PPMImage*) malloc(sizeof(PPMImage));
    new->x = OUTPUT_WIDTH;
    new->y = OUTPUT_HEIGHT;
    new->data = data;

    int i,j;
    for (i=0;i<adj_y;i+=height_gap){
        for (j=0;j<adj_x;j+=width_gap){
            (new->data)[((i/height_gap)*OUTPUT_WIDTH + (j/width_gap))].red = (input->data)[(i*(input->x) + j)].red;
            (new->data)[((i/height_gap)*OUTPUT_WIDTH + (j/width_gap))].green = (input->data)[(i*(input->x) + j)].green;
            (new->data)[((i/height_gap)*OUTPUT_WIDTH + (j/width_gap))].blue = (input->data)[(i*(input->x) + j)].blue;
        }
    }
    return new;
}







