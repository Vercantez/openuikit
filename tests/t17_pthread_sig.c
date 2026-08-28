/* T17 -- isolate T16's wall from CoreFoundation entirely.
 * Hypothesis: machorun accepts Darwin's DEFAULT static mutex signature
 * (0x32AAABA7) and rejects the ERRORCHECK one (0x32AAABA1), which is what
 * CF's CFLockInit uses on TARGET_OS_MAC. Two mutexes, one line apart. */
#include <pthread.h>
extern long write(int, const void *, unsigned long);
extern int snprintf(char *, unsigned long, const char *, ...);
static void say(const char *s){unsigned long n=0;while(s[n])n++;(void)!write(2,s,n);}

static pthread_mutex_t plain = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t errck = PTHREAD_ERRORCHECK_MUTEX_INITIALIZER;
static pthread_mutex_t recur = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

int main(void){
  char b[160];
  snprintf(b,sizeof b,"signatures as compiled into the guest:\n  plain      0x%08lX\n  errorcheck 0x%08lX\n  recursive  0x%08lX\n",
           *(long*)&plain, *(long*)&errck, *(long*)&recur);
  say(b);
  say("\nlocking the PLAIN mutex (machorun knows 0x32AAABA7)...\n");
  pthread_mutex_lock(&plain); pthread_mutex_unlock(&plain);
  say("  ok -- plain mutex locks and unlocks\n");
  say("\nlocking the ERRORCHECK mutex (this is CF's CFLockInit)...\n");
  pthread_mutex_lock(&errck); pthread_mutex_unlock(&errck);
  say("  ok -- errorcheck mutex locks and unlocks\n");
  say("\nlocking the RECURSIVE mutex...\n");
  pthread_mutex_lock(&recur); pthread_mutex_unlock(&recur);
  say("  ok -- recursive mutex locks and unlocks\n");
  say("\nT17: all three static initialisers work.\n");
  return 0;
}
