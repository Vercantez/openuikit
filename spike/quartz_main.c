#include <stdio.h>
extern int quartz_draw(const char *out);
int main(int argc, char **argv) {
    const char *out = argc > 1 ? argv[1] : "quartz_swift.png";
    return quartz_draw(out);
}
