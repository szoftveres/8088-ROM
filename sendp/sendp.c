#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define BUFSIZE         (32)
#define BLOCKS          (16)
#define BLOCKSIZE       (65536 / (BLOCKS))

int
main (int argc, char** argv) {
    char    buf[BUFSIZE];
    int     n;
    int     g = 0;
    for (g = 0; g != BLOCKS; g++) {
        write(2, "_", 1);
    }
    write(2, "\n", 1);
    g = 0;
    while(n = read(0, buf, BUFSIZE)) {
        write(1, buf, n);
        g++;
        if (g == (BLOCKSIZE / BUFSIZE)) {
            write(2, "#", 1);
            g = 0;
        }
        usleep(10000); /* 7000 starts to be unreliable */
    }
    write(2, "\n", 1);
}


