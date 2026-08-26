/*
 * vendor/objc4-priv/os/feature_private.h
 *
 * Darwin's runtime feature flags come from objc4.plist through os_feature.
 * There is no such service under machorun, so every feature takes the value
 * Apple ships as the default -- which is what the macro's `default_value`
 * argument already is. Evaluating to it directly means no symbol, no
 * environment override, and no divergence from a stock macOS boot in the
 * default configuration.
 */
#ifndef _OBJC4_PRIV_OS_FEATURE_PRIVATE_H
#define _OBJC4_PRIV_OS_FEATURE_PRIVATE_H

#define os_feature_enabled_simple(subsystem, feature, default_value) (default_value)

#endif
