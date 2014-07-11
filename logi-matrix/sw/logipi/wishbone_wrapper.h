/*!@brief The header file for the wishbone wrapper
 *        Wishbone interfaces with the SPI interface and handles 
 *        the communication btw the rpi and the FPGA
 * @author Jonathan Piat, Xiaofan Li 
 * @date July 8th 2014
 */


/*!@brief initializes wishbone interface
 * @param void 
 * @return 0 on success, 1 if fd exists, -1 on error 
 */
int wishbone_init(void);


/*!@brief set max speed with ioctl
 * @param speed in Hz
 * @return 0 on success, -1 on error
 */
int set_speed(unsigned long speed_arg);


/*!@brief Write a buffer to specified address
 *        Write 4096 bytes at a time
 * @param buffer: the buffer to write
 *        length: the length of the buffer
 *        address: the address to write to
 * @return the number of bytes written 
 */
unsigned int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address);

/*!@brief Read a buffer at specified address
 *        Read 4096 bytes at a time
 * @param buffer: the buffer read into
 *        length: the length of the buffer
 *        address: the address to read from
 * @return the number of bytes read 
 */
unsigned int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address);
