/* OpenUIKitABI.h — the FUNCTIONS half of the OpenUIKit C ABI.
 *
 * Every symbol here is DEFINED in Swift with @_cdecl (Sources/OpenUIKitC).
 * Swift does not include this header — it would be a redeclaration of what it
 * is defining. The types the two halves share live in
 * Sources/COpenUIKitABI/include/openuikit_abi_types.h, which BOTH sides use.
 *
 * OWNERSHIP: the Core Foundation Create Rule.
 *   `*_create` -> +1, you must openuikit_release() it.
 *   everything else that returns an OUKHandle -> +0, borrowed.
 * See docs/OBJC_FACADE.md.
 */

#ifndef OPENUIKIT_ABI_H
#define OPENUIKIT_ABI_H

#include "openuikit_abi_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ---- memory --------------------------------------------------------- */
OUKHandle openuikit_retain(OUKHandle h);
void      openuikit_release(OUKHandle h);

/* ---- peering & callbacks -------------------------------------------- */
void openuikit_set_objc_hooks(const openuikit_objc_hooks *hooks);
int32_t openuikit_set_peer(OUKHandle h, OUKPeer peer);
OUKPeer openuikit_get_peer(OUKHandle h);
void    openuikit_clear_peer(OUKHandle h);
void    openuikit_set_strict(int32_t on);
int32_t openuikit_violation_count(void);
/* openuikit_abi_hooks_size() is declared by openuikit_abi_types.h. */

/* ---- creation (+1) --------------------------------------------------- */
OUKHandle openuikit_view_create(void);
OUKHandle openuikit_label_create(void);
OUKHandle openuikit_button_create(int32_t type);
OUKHandle openuikit_viewcontroller_create(void);
int32_t   openuikit_class_name(OUKHandle h, char *buf, int32_t cap);

/* ---- UIView ---------------------------------------------------------- */
void openuikit_view_set_frame(OUKHandle h, double x, double y, double w, double hh);
void openuikit_view_get_frame(OUKHandle h, double *out4);
void openuikit_view_set_bounds(OUKHandle h, double x, double y, double w, double hh);
void openuikit_view_get_bounds(OUKHandle h, double *out4);
void openuikit_view_set_center(OUKHandle h, double x, double y);

void openuikit_view_set_background_color(OUKHandle h, double r, double g, double b, double a);
void openuikit_view_clear_background_color(OUKHandle h);
void openuikit_view_set_alpha(OUKHandle h, double a);
void openuikit_view_set_hidden(OUKHandle h, int32_t hidden);
void openuikit_view_set_opaque(OUKHandle h, int32_t opaque);
void openuikit_view_set_clips_to_bounds(OUKHandle h, int32_t clips);
void openuikit_view_set_corner_radius(OUKHandle h, double r);
void openuikit_view_set_tag(OUKHandle h, int64_t tag);
int64_t openuikit_view_get_tag(OUKHandle h);

void      openuikit_view_add_subview(OUKHandle parent, OUKHandle child);
void      openuikit_view_insert_subview_at(OUKHandle parent, OUKHandle child, int32_t index);
void      openuikit_view_remove_from_superview(OUKHandle h);
OUKHandle openuikit_view_superview(OUKHandle h);          /* +0 */
int32_t   openuikit_view_subview_count(OUKHandle h);
OUKHandle openuikit_view_subview_at(OUKHandle h, int32_t i); /* +0 */

void openuikit_view_set_needs_layout(OUKHandle h);
void openuikit_view_layout_if_needed(OUKHandle h);
void openuikit_view_set_needs_display(OUKHandle h);
void openuikit_view_super_layout_subviews(OUKHandle h);
void openuikit_view_super_draw_rect(OUKHandle h, double x, double y, double w, double hh);
void openuikit_view_size_to_fit(OUKHandle h);
void openuikit_view_size_that_fits(OUKHandle h, double w, double hh, double *out2);

/* ---- UILabel --------------------------------------------------------- */
void    openuikit_label_set_text(OUKHandle h, const char *utf8);
int32_t openuikit_label_get_text(OUKHandle h, char *buf, int32_t cap);
void    openuikit_label_set_text_color(OUKHandle h, double r, double g, double b, double a);
void    openuikit_label_set_font(OUKHandle h, double size, int32_t weight);
void    openuikit_label_set_text_alignment(OUKHandle h, int32_t alignment);
void    openuikit_label_set_number_of_lines(OUKHandle h, int32_t n);

/* ---- UIButton -------------------------------------------------------- */
void      openuikit_button_set_title(OUKHandle h, const char *utf8, uint32_t state);
int32_t   openuikit_button_get_title(OUKHandle h, uint32_t state, char *buf, int32_t cap);
void      openuikit_button_set_title_color(OUKHandle h, double r, double g, double b,
                                           double a, uint32_t state);
OUKHandle openuikit_button_title_label(OUKHandle h);      /* +0 */

/* ---- UIControl ------------------------------------------------------- */
int64_t openuikit_control_add_target_action(OUKHandle h, OUKPeer target,
                                            const char *action, uint32_t events);
void    openuikit_control_remove_target(OUKHandle h, int64_t token);
void    openuikit_control_send_actions(OUKHandle h, uint32_t events);
void    openuikit_control_set_enabled(OUKHandle h, int32_t enabled);

/* ---- UIViewController ------------------------------------------------ */
OUKHandle openuikit_viewcontroller_view(OUKHandle h);            /* +0, loads */
OUKHandle openuikit_viewcontroller_view_if_loaded(OUKHandle h);  /* +0 */
void      openuikit_viewcontroller_set_view(OUKHandle h, OUKHandle view);
void      openuikit_viewcontroller_load_view_if_needed(OUKHandle h);
void      openuikit_viewcontroller_super_load_view(OUKHandle h);
void      openuikit_viewcontroller_super_view_did_load(OUKHandle h);
void      openuikit_viewcontroller_set_title(OUKHandle h, const char *utf8);
void      openuikit_viewcontroller_add_child(OUKHandle h, OUKHandle child);

/* ---- drawing (valid only inside a -drawRect: callback) ---------------- */
void openuikit_gc_set_fill_color(double r, double g, double b, double a);
void openuikit_gc_fill_rect_current(double x, double y, double w, double h);
void openuikit_gc_fill_rect(double x, double y, double w, double h,
                            double r, double g, double b, double a);
void openuikit_gc_fill_rounded_rect(double x, double y, double w, double h, double radius,
                                    double r, double g, double b, double a);
void openuikit_gc_stroke_rect(double x, double y, double w, double h, double lineWidth,
                              double r, double g, double b, double a);

/* ---- rendering / runtime knobs --------------------------------------- */
int32_t openuikit_render_png(OUKHandle root, double scale, const char *path);
void    openuikit_set_backend(int32_t backend);   /* 0 = swift, 1 = quartz */
void    openuikit_set_resource_root(const char *path);
void    openuikit_set_font_path(const char *key, const char *path);

#ifdef __cplusplus
}
#endif
#endif /* OPENUIKIT_ABI_H */
