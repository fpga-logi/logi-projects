/*******************************************
* cheapscope.c
*
* A simple character mode interface for my
* CheapScope Virtual Logic Analyser
*
* I've put this together for my personal use. You are welcome to use it however
* your like. Just because it fits my needs it may not fit yours, if so, bad luck.
*
*******************************************/
#include <stdio.h>
#include <unistd.h>
#include <ncurses.h>
#include <malloc.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <fcntl.h>
#include <memory.h>
#include <termios.h>

#define CHANNELS 16
#define MAXVALUES 2048
struct Samples {
    int pos;
    int cursor;
    int nSamples;
    int trigger;
    unsigned int values[MAXVALUES];
};
int max_width, max_height;
struct Samples *samplesNext, *samples = NULL;
char lineBuffer[8192];          /* 4 bits per ASCII character, total of 4Kb */
int lineBufferUsed = 0;
int serialPort;

/********************************************************************/
static void displayChannel(int channel, struct Samples *s)
{
    unsigned int mask = (1 << channel);
    int i;
    move(2 * (CHANNELS - channel) - 1, 4);
    attron(COLOR_PAIR(2));
    for (i = 0; i < max_width - 4; i++)
    {
        if (s != NULL && s->pos + i == s->cursor)
            attron(COLOR_PAIR(5));

        if (s != NULL && s->pos + i == s->trigger - 1)
            addch('>');
        else if (s != NULL && s->pos + i == s->trigger)
            addch('<');
        else
            addch(' ');

        if (s != NULL && s->pos + i == s->cursor)
            attron(COLOR_PAIR(2));
    }
    move(2 * (CHANNELS - channel), 4);
    for (i = 0; i < max_width - 4; i++)
    {
        if (s == NULL || s->pos + i >= s->nSamples)
        {
            attron(COLOR_PAIR(2));
            addch(' ');
        }
        else
        {
            if (s->values[s->pos + i] & mask)
            {
                attron(COLOR_PAIR(3));
                addch(' ');
            }
            else
            {
                if (s->pos + i == s->cursor)
                    attron(COLOR_PAIR(5));
                else
                    attron(COLOR_PAIR(2));
                addch('_');
            }
        }
    }
}


/********************************************************************/
static void displayScreenStatic(void)
{
    int channel;
    clear();
    attron(COLOR_PAIR(4));
    move(0, 0);
    printw("%*.*s", -max_width, max_width,
           "Cheapscope virtual logic analyser");
    for (channel = 0; channel < CHANNELS; channel++)
    {
        move(2 * (CHANNELS - channel), 0);
        attron(COLOR_PAIR(1));
        printw("%2i:", channel);
    }
}


/********************************************************************/
static void updateScreen(struct Samples *s)
{
    int channel;
    if (s != NULL)
    {
        attron(COLOR_PAIR(4));
        move(0, max_width - 6);
        printw("%6i", s->cursor - s->trigger);
        if (s->cursor < s->pos)
            s->pos = s->cursor - 5;
        if (s->cursor >= s->pos + max_width - 4)
            s->pos = s->cursor - max_width + 10;

        /* Clap the display position */
        if (s->pos < 0)
            s->pos = 0;
        if (s->pos > s->nSamples - (max_width - 4))
            s->pos = s->nSamples - (max_width - 4);
    }
    for (channel = 0; channel < CHANNELS; channel++)
        displayChannel(channel, s);
    refresh();
    attron(COLOR_PAIR(4));
    move(max_height - 1, 0);
    if (samplesNext == NULL)
        printw("%*.*s", -max_width, max_width,
               "Use arrows to scroll, 'Q' to quit");

    else
        printw("%*.*s", -max_width, max_width,
               "Use arrows to scroll, 'Q' to quit, 'N' to get move to next capture");
}


/********************************************************************/
static int openSerialPort(char *fname)
{
    int f, flags;
    struct termios cf;
    f = open(fname, O_RDWR);
    if (f == -1)
    {
        fprintf(stderr, "Unable to open '%s'\n", fname);
        return -1;
    }
    if (tcgetattr(f, &cf) == -1)
    {
        fprintf(stderr, "Unable to get termios details\n");
        close(f);
        return -1;
    }
    if (cfsetispeed(&cf, B19200) == -1 || cfsetospeed(&cf, B19200) == -1)
    {
        fprintf(stderr, "Unable to set speed\n");
        close(f);
        return -1;
    }

    /* Make it a raw stream and turn off software flow control */
    cfmakeraw(&cf);
    cf.c_iflag &= ~(IXON | IXOFF | IXANY);
    if (tcsetattr(f, TCSANOW, &cf) == -1)
    {
        fprintf(stderr, "Unable to set termios details\n");
        close(f);
        return -1;
    }
    if (-1 == (flags = fcntl(f, F_GETFL, 0)))
        flags = 0;
    if (-1 == fcntl(f, F_SETFL, flags | O_NONBLOCK))
    {
        fprintf(stderr, "Unable to set non-blocking\n");
        close(f);
        return -1;
    }
    return f;
}


/********************************************************************/
static int hexchar2bin(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    return 0;
}


/********************************************************************/
static int processSerialData(int serialPort)
{
    char bytes[128];
    int bytesRead;
    int i, redraw = 0;
    for (;;)
    {
        bytesRead = read(serialPort, bytes, sizeof(bytes));
        if (bytesRead == 0 || bytesRead == -1)
            break;
        for (i = 0; i < bytesRead; i++)
        {
            if ((bytes[i] >= '0' && bytes[i] <= '9') || (bytes[i] >= 'A' && bytes[i] <= 'F'))
            {
                if (lineBufferUsed < sizeof(lineBuffer))
                    lineBuffer[lineBufferUsed++] = bytes[i];
            }
            else if (bytes[i] == '\n')
            {
              if(lineBufferUsed == 4096)
              {
                if (samplesNext == NULL)
                    samplesNext = malloc(sizeof(struct Samples));
                if (samplesNext != NULL)
                {
                    memset(samplesNext, 0, sizeof(struct Samples));
                    for (i = 0; i < MAXVALUES && i < lineBufferUsed / 4; i++)
                    {
                        int ll = 0, lh = 0, hl = 0, hh = 0;
                        hh = hexchar2bin(lineBuffer[i * 4 + 0]);
                        hl = hexchar2bin(lineBuffer[i * 4 + 1]);
                        lh = hexchar2bin(lineBuffer[i * 4 + 2]);
                        ll = hexchar2bin(lineBuffer[i * 4 + 3]);
                        samplesNext->values[i] = (hh << 12) + (hl << 8) + (lh << 4) + ll;
                    } samplesNext->nSamples = i;
                    samplesNext->trigger = 512;
                    samplesNext->cursor = 512;
                    samplesNext->pos = 512 - (max_width - 4) / 2;
                }
                redraw = 1;
              }
              lineBufferUsed = 0;
            }
        }
    }
    return redraw;
}


/********************************************************************/
int main(int argc, char *argv[])
{
    int redraw;
    int loop;
    int serialPort;
    WINDOW *win;
    if (argc != 2)
    {
        fprintf(stderr,
                "CheapScope Virtual Logic Analyser\n\nusage: %s serial_port\n",
                argv[0]);
        return 0;
    }
    serialPort = openSerialPort(argv[1]);
    if (serialPort == -1)
        return 1;
    win = initscr();
    cbreak();
    noecho();
    nonl();
    intrflush(stdscr, FALSE);
    keypad(stdscr, TRUE);
    if (has_colors())
    {
        start_color();
        init_pair(1, COLOR_WHITE, COLOR_BLACK);
        init_pair(2, COLOR_GREEN, COLOR_BLACK);
        init_pair(3, COLOR_BLACK, COLOR_GREEN);
        init_pair(4, COLOR_WHITE, COLOR_RED);
        init_pair(5, COLOR_GREEN, COLOR_BLUE);
    }
    getmaxyx(win, max_height, max_width);
    if (max_height < 34)
    {
        clear();
        printw("Resize your window to 34 lines to see all channels\n");
        refresh();
        sleep(5);
    }
    timeout(1);
    displayScreenStatic();
    redraw = 1;
    loop = 1;
    while (loop)
    {
        int k;
        if (samples == NULL && samplesNext != NULL)
        {
            samples = samplesNext;
            samplesNext = NULL;
            redraw = 1;
        }
        if (processSerialData(serialPort))
            redraw = 1;
        if (redraw)
        {
            updateScreen(samples);
            redraw = 0;
        }
        k = getch();
        switch (k)
        {
        case KEY_LEFT:
            if (samples && samples->cursor > 0)
            {
                samples->cursor--;
                redraw = 1;
            }
            break;
        case KEY_RIGHT:
            if (samples && samples->cursor < samples->nSamples - 1)
            {
                samples->cursor++;
                redraw = 1;
            }
            break;
        case KEY_NPAGE:
            if (samples && samples->cursor > 0)
            {
                samples->cursor -= (max_width - 4) / 2;
                if(samples->cursor < 0) samples->cursor = 0;
                redraw = 1;
            }
            break;
        case KEY_PPAGE:
            if (samples && samples->cursor < samples->nSamples - 1)
            {
                samples->cursor += (max_width - 4) / 2;
                if(samples->cursor >=  samples->nSamples - 1)
                  samples->cursor =  samples->nSamples - 1;
                redraw = 1;
            }
            break;
        case 'N':
        case 'n':
            if (samples != NULL && samplesNext != NULL)
            {
                free(samples);
                samples = samplesNext;
                samplesNext = NULL;
                redraw = 1;
            }
            break;
        case 'Q':
        case 'q':
        case '\027':
            loop = 0;
            break;
        case KEY_RESIZE:
            getmaxyx(win, max_height, max_width);
            displayScreenStatic();
            redraw = 1;
        }
    }
    endwin();
    return 0;
}