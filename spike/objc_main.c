#include <stdio.h>
extern int objc_probe(void);
int main(void) { printf("objc_probe=%d\n", objc_probe()); return 0; }
