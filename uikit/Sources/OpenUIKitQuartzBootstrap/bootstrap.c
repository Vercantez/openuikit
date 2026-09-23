// cg-unify phase 3 (docs/agent_reports/cg-unify.md): on Apple toolchains
// OpenUIKit's Core Animation is QuartzCore's, with a few CALayer /
// CATransaction methods interposed so the port's renderer keeps its model
// (OpenUIKit/QuartzCoreUnification.swift). Install them when the image
// loads, so a layer or transaction made before the first view (a unit test,
// an app's early setup) is covered. Only linked on Apple platforms.
#include "openuikit_quartz_bootstrap.h"

extern void _openuikit_install_quartzcore_bridge(void);

__attribute__((constructor))
static void openuikit_quartz_bootstrap(void) {
    _openuikit_install_quartzcore_bridge();
}
