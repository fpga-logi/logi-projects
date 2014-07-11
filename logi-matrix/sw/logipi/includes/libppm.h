/**@file libppm.h
 * @author Xiaofan Li
 * @brief takes care of reading in and resizing ppm file
 */

#include <stdio.h>
#include <stdlib.h>


#ifndef __libppm_h_
#define __libppm_h_

#define RGB_COMPONENT_COLOR 255

//define display size
#define OUTPUT_HEIGHT 32
#define OUTPUT_WIDTH 32
typedef struct {       
    unsigned char red,green,blue;
} PPMPixel;

typedef struct {
    int x, y;
    PPMPixel *data;
} PPMImage;

/**!@brief read in a ppm file and output an array
 */
PPMImage* readPPM(const char* filename);

/**!@brief resize the given array to 32 * 32
 *         might be interesting to do seam carving 
 */
PPMImage* resize(PPMImage* input);

//more functionality?

#endif
