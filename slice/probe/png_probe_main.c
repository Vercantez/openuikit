#include <stdio.h>
extern int p_plainclass(void), p_existential(void);
int main(void){
  fprintf(stderr,"plainclass...\n");  fprintf(stderr,"plainclass=%d\n", p_plainclass());
  fprintf(stderr,"existential...\n");  fprintf(stderr,"existential=%d\n", p_existential());
  fprintf(stderr,"ALL OK\n"); return 0;
}
