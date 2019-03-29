

struct __attribute__((packed, aligned(4))) ghi {
    char         aa;
    unsigned int a;
    char         ab;
    unsigned int b;
};


/* .bss */
static unsigned int bb;
static unsigned char bchar1; /* 1 byte, padded out*/
static unsigned char bchar2; /* 1 byte, padded out*/
static unsigned int bint;
static unsigned long int blong;

static float fa;
static double fb;

/* .data */
char test_str[] = "test_string1";
int test_int = 0xFFFF;

/* .text */
foo_deref (unsigned int* n, struct ghi* f) {
    f->a = *n;
    f->b = *n + 1;
    return;
}



void bbbbfunc (void) {
     bchar1 += 3;
     bchar2 += 3;
     bint += 4;
     blong += 5;
}

void div1 (void) {
    bb /= 47;
}
void mul1 (void) {
    bb *= 47;
}
void shl1 (void) {
    bb <<= 12;
}
void shr1 (void) {
    bb >>= 12;
}

void floatcode (void) {
    fa /= 0.34f;
    fb /= 0.34;
}

unsigned int foo (int a) {
    struct ghi gg;
    switch (a) {
      case 40: bb += 6; asm volatile ("\n");
      case 50: bb -= 6; asm volatile ("\n");
    }

    if (bb > 43) {
        return bb;
    }

    foo_deref(&a, &gg);

    return bb+1;
}

void main (void) {
    unsigned int b;
    unsigned int i;

    for (i = 2; i != 50; i++) {

        b = bb + foo(2);
    }

}
