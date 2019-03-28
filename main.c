

static unsigned int bb;

unsigned int foo (int a) {
    switch (a) {
      case 40: bb += 6; asm volatile ("\n");
      case 50: bb -= 6; asm volatile ("\n");
      case 60: bb <<= 12; asm volatile ("\n");
      case 70: bb >>= 12; asm volatile ("\n");
      case 80: bb *= 49; asm volatile ("\n");
      case 90: bb /= 47;
    }
    return bb+1;
}

void main (void) {
    unsigned int b;
    unsigned int i;

    for (i = 2; i != 50; i++) {

        b = bb + foo(2);
    }

}
