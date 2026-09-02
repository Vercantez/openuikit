#include <stdio.h>
#define P(f) do{ fprintf(stderr,"  %-16s ...\n", #f); fprintf(stderr,"  %-16s = %d\n", #f, f()); }while(0)
extern int p_plainclass(void), p_existential(void), p_arrayslice(void), p_string(void),
           p_anyobject(void), p_anyexistential(void), p_userarrayslice(void),
           p_genericclass(void), p_unowned(void), p_heapmetadata(void);
int main(void){
  P(p_plainclass); P(p_existential); P(p_arrayslice); P(p_string);
  P(p_anyobject); P(p_anyexistential); P(p_userarrayslice);
  P(p_genericclass); P(p_unowned); P(p_heapmetadata);
  fprintf(stderr,"ALL OK\n"); return 0;
}
