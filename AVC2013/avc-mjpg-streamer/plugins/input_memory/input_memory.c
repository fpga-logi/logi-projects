/*******************************************************************************
#                                                                              #
#      MJPG-streamer allows to stream JPG frames from an input-plugin          #
#      to several output plugins                                               #
#                                                                              #
#      Copyright (C) 2007 Tom Stöveken                                         #
#                                                                              #
# This program is free software; you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation; version 2 of the License.                      #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA    #
#                                                                              #
*******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <signal.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <getopt.h>
#include <pthread.h>
#include <syslog.h>
#include <fcntl.h>
#include <fcntl.h>
#include <math.h>


#include "../../mjpg_streamer.h"
#include "../../utils.h"
#include "jpeg_func.h"
#include "fifolib.h"


#define INPUT_PLUGIN_NAME "MEMORY input plugin"


#define WIDTH 160
#define HEIGHT 120
#define NB_CHAN 2
#define COLOR_MODE
#define FIFO_ID 1

/* private functions and variables to this plugin */
static pthread_t   worker;
static globals     *pglobal;
static pthread_mutex_t controls_mutex;
static int plugin_number;
unsigned char grab_buffer[WIDTH*HEIGHT*3*2] ; 
unsigned char rgb_buffer[WIDTH*HEIGHT*3] ;

void *worker_thread(void *);
void worker_cleanup(void *);
void help(void);



int min(int a, int b){
	if(a > b ){
		return b ;	
	}
	return a ;
}

/*** plugin interface functions ***/

/******************************************************************************
Description.: parse input parameters
Input Value.: param contains the command line string and a pointer to globals
Return Value: 0 if everything is ok
******************************************************************************/
int input_init(input_parameter *param)
{
    int i;

    if(pthread_mutex_init(&controls_mutex, NULL) != 0) {
        IPRINT("could not initialize mutex variable\n");
        exit(EXIT_FAILURE);
    }
    
    pglobal = param->global;

    return 0;
}

/******************************************************************************
Description.: stops the execution of the worker thread
Input Value.: -
Return Value: 0
******************************************************************************/
int input_stop(void)
{
    DBG("will cancel input thread\n");
    pthread_cancel(worker);
    fifo_close(1);
    return 0;
}

/******************************************************************************
Description.: starts the worker thread and allocates memory
Input Value.: -
Return Value: 0
******************************************************************************/
int input_run(void)
{
    pglobal->buf = malloc(512 * 1024);
    if(pglobal->buf == NULL) {
        fprintf(stderr, "could not allocate memory\n");
        exit(EXIT_FAILURE);
    }
    if( fifo_open(FIFO_ID) < 0){
    	fprintf(stderr, "could not open fifo !  (try sudo ...)\n");
	exit(EXIT_FAILURE);
    }

    if(pthread_create(&worker, 0, worker_thread, NULL) != 0) {
        free(pglobal->buf);
        fprintf(stderr, "could not start worker thread\n");
        exit(EXIT_FAILURE);
    }
    pthread_detach(worker);

    return 0;
}

/******************************************************************************
Description.: print help message
Input Value.: -
Return Value: -
******************************************************************************/
void help(void)
{
    fprintf(stderr, " ---------------------------------------------------------------\n" \
    " Help for input plugin..: "INPUT_PLUGIN_NAME"\n" \
    " ---------------------------------------------------------------\n" \
    " There is no parameters for this plugin:\n\n" \
    " ---------------------------------------------------------------\n");
}

/******************************************************************************
Description.: copy a picture from testpictures.h and signal this to all output
              plugins, afterwards switch to the next frame of the animation.
Input Value.: arg is not used
Return Value: NULL
******************************************************************************/
void *worker_thread(void *arg)
{
    int i = 0;
    float y, u, v ;
    float r, g, b ;
    int remaining ; 
    char * fPointer ;
    int outlen = 0;
    int vsync = 0 ;
    unsigned short vsync1, vsync2 ;
    unsigned char * start_buffer, * end_ptr;
    /* set cleanup handler to cleanup allocated ressources */
    pthread_cleanup_push(worker_cleanup, NULL);

    while(!pglobal->stop) {
	pthread_mutex_lock(&pglobal->db);
	//TODO: need to iterate to get the vsync signal and then grab a full frame
	fifo_reset(FIFO_ID);	
	fifo_read(FIFO_ID, grab_buffer, WIDTH*HEIGHT*3*NB_CHAN);
	i = 0 ;
	vsync = 0 ;
	start_buffer = grab_buffer ;
	end_ptr = &start_buffer[WIDTH*HEIGHT*NB_CHAN*3];
	vsync1 = *((unsigned short *) start_buffer) ;
	vsync2 = *((unsigned short *) &start_buffer[(WIDTH*HEIGHT*NB_CHAN)+2]) ;
	while(vsync1 != 0x55AA && vsync2 != 0x55AA && start_buffer < end_ptr){
			start_buffer+=2 ;
			vsync1 = *((unsigned short *) start_buffer) ;
			vsync2 = *((unsigned short *) &start_buffer[(WIDTH*HEIGHT*NB_CHAN)+2]) ;
	}
	if(vsync1 == 0x55AA && vsync2 == 0x55AA){
			vsync = 1 ;
			fPointer = start_buffer ;
	}
	if(vsync){
		DBG("Vsync found !\n");
		#ifdef COLOR_MODE
		for(i = 0 ; i < WIDTH*HEIGHT ; i ++){
			y = (float) fPointer[(i*2)] ;
			if(i%2 == 1){
				u = (float) fPointer[(i*2)+1];
				v = (float) fPointer[(i*2)+3];
			}else{
				u = (float) fPointer[(i*2)-1];
        	        	v = (float) fPointer[(i*2)+1];
			}
			r =  y + (1.4075 * (v - 128.0));
			g =  y - (0.3455 * (u - 128.0)) - (0.7169 * (v - 128.0));
			b =  y + (1.7790 * (u - 128.0)) ;
			rgb_buffer[(i*3)] = (unsigned char) abs(min(r, 255)) ;
			rgb_buffer[(i*3)+1] = (unsigned char) abs(min(g, 255)) ;
			rgb_buffer[(i*3)+2] = (unsigned char) abs(min(b, 255)) ;
		} 
		
		if(!write_jpegmem_rgb(rgb_buffer, WIDTH, HEIGHT, &pglobal->buf, &outlen, 100)){
			printf("compression error !\n");	
			exit(EXIT_FAILURE);
		}
		#else
		if(!write_jpegmem_gray(fPointer, WIDTH, HEIGHT, &pglobal->buf, &outlen, 100)){
			printf("compression error !\n");	
			exit(EXIT_FAILURE);
		}
		#endif
		pglobal->size = outlen ;

		/* signal fresh_frame */
		pthread_cond_broadcast(&pglobal->db_update);
		
	}
	pthread_mutex_unlock(&pglobal->db);
    }

    IPRINT("leaving input thread, calling cleanup function now\n");
    pthread_cleanup_pop(1);

    return NULL;
}

/******************************************************************************
Description.: this functions cleans up allocated ressources
Input Value.: arg is unused
Return Value: -
******************************************************************************/
void worker_cleanup(void *arg)
{
    static unsigned char first_run = 1;

    if(!first_run) {
        DBG("already cleaned up ressources\n");
        return;
    }

    first_run = 0;
    DBG("cleaning up ressources allocated by input thread\n");

    if(pglobal->buf != NULL) free(pglobal->buf);
}




