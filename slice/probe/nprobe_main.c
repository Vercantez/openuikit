#include <stdio.h>
extern int p_n(void);
int main(void){ int r = p_n(); fprintf(stderr, "p_n=%d\n", r); return 0; }
