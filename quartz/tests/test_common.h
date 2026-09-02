#pragma once
#include "quartz/quartz.h"
#include <CoreGraphics/CoreGraphics.h>
#include <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>

static inline int qz_fail(const char *msg) {
    fprintf(stderr, "FAIL %s\n", msg);
    return 1;
}
static inline void qz_pass(const char *pkg) {
    printf("PASS %s\n", pkg);
}
