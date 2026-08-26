// slice_main.c -- runs the vendored OpenUIKit slice render and writes the PNG.
#include <stdio.h>
#include <stdlib.h>

extern int slice_probe(void);
extern int slice_probe_uint8arr(void);
extern int slice_probe_pointarr(void);
extern int slice_probe_pathelem(void);
extern int slice_probe_unowned(void);
extern int slice_probe_existential(void);
extern int slice_probe_unowned_self(void);
extern int slice_probe_bitmap(void);
extern int slice_probe_canvas(void);
extern int slice_probe_fill(void);
extern int slice_probe_view(void);
extern int slice_probe_canvas_swift(void);
extern unsigned char *slice_render_boxes_png(long *outLen);

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s out.png\n", argv[0]); return 2; }
    fprintf(stderr, "[main] slice_probe = %d\n", slice_probe());
    fprintf(stderr, "[main] uint8arr...\n");  fprintf(stderr, "[main] uint8arr = %d\n", slice_probe_uint8arr());
    fprintf(stderr, "[main] view (build UIView tree: UIView/CALayer/UIColor)...\n");
    fprintf(stderr, "[main] view = %d\n", slice_probe_view());
    fprintf(stderr, "[main] pointarr (Array<CGPoint> metadata)...\n");  fprintf(stderr, "[main] pointarr = %d\n", slice_probe_pointarr());
    fprintf(stderr, "[main] pathelem...\n");  fprintf(stderr, "[main] pathelem = %d\n", slice_probe_pathelem());
    fprintf(stderr, "[main] bitmap...\n");   fprintf(stderr, "[main] bitmap = %d\n", slice_probe_bitmap());
    fprintf(stderr, "[main] unowned...\n"); fprintf(stderr, "[main] unowned = %d\n", slice_probe_unowned());
    fprintf(stderr, "[main] existential...\n"); fprintf(stderr, "[main] existential = %d\n", slice_probe_existential());
    fprintf(stderr, "[main] unowned_self...\n"); fprintf(stderr, "[main] unowned_self = %d\n", slice_probe_unowned_self());
    fprintf(stderr, "[main] canvas_swift (pure-Swift rasterizer fill)...\n"); fprintf(stderr, "[main] canvas_swift = %d\n", slice_probe_canvas_swift());
    fprintf(stderr, "[main] canvas (quartz backend)...\n");   fprintf(stderr, "[main] canvas = %d\n", slice_probe_canvas());
    fprintf(stderr, "[main] render...\n");
    long n = 0;
    unsigned char *png = slice_render_boxes_png(&n);
    if (!png || n <= 0) { fprintf(stderr, "render produced no bytes\n"); return 1; }
    FILE *f = fopen(argv[1], "wb");
    if (!f) { perror("fopen"); return 1; }
    fwrite(png, 1, (size_t)n, f);
    fclose(f);
    free(png);
    fprintf(stderr, "[main] wrote %ld bytes to %s\n", n, argv[1]);
    return 0;
}
