"""Fit the bar-button platter shadow to the golden's measured falloff.

The golden (real iOS 26, white backdrop, white platter) shows the platter's
drop shadow only OUTSIDE the capsule. Model it as UIKit does: the capsule's
alpha mask, offset by (0, dy), Gaussian-blurred with sigma = shadowRadius,
scaled by shadowOpacity, composited black-over-white. Fit (opacity, sigma,
dy) by least squares over the ring around the platter.
"""
from PIL import Image
import numpy as np

SCALE = 2
g = np.array(Image.open('golden/navitem_buttons.png').convert('RGB')).astype(float)[:, :, 0]

# "Back" platter, scene points: x 16..86.667, y 10..54 (bar zone at y=10).
PX, PY, PW, PH = 16.0, 10.0, 70.667, 44.0
R = PH / 2

# Sample window around it, avoiding the hairline (y=64) and the content card
# (y>=72) and the label ink inside the platter.
ys = np.arange(int((PY - 9) * SCALE), int(63.5 * SCALE))
xs = np.arange(0, int(110 * SCALE))
Y, X = np.meshgrid(ys / SCALE, xs / SCALE, indexing='ij')


def capsule_mask(dy, oversample=4):
    """Alpha of the platter capsule, offset by dy, at sub-pixel resolution."""
    yy = (np.arange(len(ys) * oversample) / (SCALE * oversample)
          + ys[0] / SCALE) - dy
    xx = np.arange(len(xs) * oversample) / (SCALE * oversample) + xs[0] / SCALE
    YY, XX = np.meshgrid(yy, xx, indexing='ij')
    cx0, cx1 = PX + R, PX + PW - R
    cyc = PY + R
    inside = ((YY >= PY) & (YY <= PY + PH) & (XX >= cx0) & (XX <= cx1))
    d0 = np.hypot(XX - cx0, YY - cyc)
    d1 = np.hypot(XX - cx1, YY - cyc)
    inside |= (d0 <= R) | (d1 <= R)
    return inside.astype(float), oversample


def blur(a, sigma_px):
    n = max(1, min(int(sigma_px * 3), min(a.shape) // 2 - 1))
    k = np.exp(-0.5 * (np.arange(-n, n + 1) / sigma_px) ** 2)
    k /= k.sum()
    out = np.apply_along_axis(lambda m: np.convolve(m, k, mode='same'), 0, a)
    return np.apply_along_axis(lambda m: np.convolve(m, k, mode='same'), 1, out)


# Region the fit runs on: outside the platter (the shadow is clipped by the
# opaque platter itself), inside the sample window.
solid, os_ = capsule_mask(0.0, oversample=1)
outside = solid < 0.5

best = None
for dy in [0.0, 1.0, 2.0, 3.0, 4.0]:
    m, ov = capsule_mask(dy, oversample=2)
    for sigma in [4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20]:
        b = blur(m, sigma * SCALE * ov)
        # downsample back to pixel grid
        b = b.reshape(len(ys), ov, len(xs), ov).mean(axis=(1, 3))
        obs = (255.0 - g[np.ix_(ys, xs)]) / 255.0     # observed shadow alpha
        mask = outside & (b > 1e-4)
        # least-squares opacity for this (sigma, dy)
        num = (obs[mask] * b[mask]).sum()
        den = (b[mask] * b[mask]).sum()
        op = num / den
        resid = np.sqrt((((obs - op * b) ** 2)[mask]).mean()) * 255
        if best is None or resid < best[0]:
            best = (resid, op, sigma, dy)
        print('dy=%.1f sigma=%2d -> opacity=%.4f rms=%.3f counts' % (dy, sigma, op, resid))

print('\nBEST: rms=%.3f counts  opacity=%.4f  sigma=%g  dy=%g' % best)
