# MUMUMONG V2 sky key visual generator (DESIGN_V2.md §3.3).
# Procedural, deterministic and license-free: no photo or AI image service.
# Usage: python3 -I tool/v2/gen_sky_key.py out.ppm 7
#        ffmpeg -i out.ppm -q:v 3 assets/v2/sky_key.jpg
import numpy as np, sys
from scipy import ndimage as ndi

W, H = 900, 1600
rng = np.random.default_rng(int(sys.argv[2]) if len(sys.argv) > 2 else 7)

def value_noise(w, h, cell, rng):
    gw, gh = int(np.ceil(w / cell)) + 3, int(np.ceil(h / cell)) + 3
    g = rng.random((gh, gw))
    z = ndi.zoom(g, cell, order=3, mode='wrap')
    return z[:h, :w]

def fbm(w, h, base, octaves, rng, aniso=1.0):
    out = np.zeros((h, w)); amp = 1.0; tot = 0
    for o in range(octaves):
        cell = max(2, base / (2 ** o))
        n = value_noise(int(w), int(h), cell, rng)
        out += amp * n; tot += amp; amp *= 0.52
    return out / tot

y, x = np.mgrid[0:H, 0:W].astype(np.float64)
v = y / (H - 1)

# warm sky gradient: deep warm sky -> soft sky -> hazy warm white
def hexrgb(h):
    h = h.lstrip('#'); return np.array([int(h[i:i+2], 16) for i in (0, 2, 4)]) / 255.0
stops = [(0.00, hexrgb('#6AA5DB')), (0.30, hexrgb('#97C5EB')), (0.58, hexrgb('#BFDAF1')),
         (0.80, hexrgb('#E6EEF4')), (1.00, hexrgb('#F6F1EA'))]
sky = np.zeros((H, W, 3))
for i in range(len(stops) - 1):
    a, ca = stops[i]; b, cb = stops[i + 1]
    m = (v >= a) & (v <= b)
    t = ((v - a) / (b - a))[m][:, None]
    t = t * t * (3 - 2 * t)
    sky[m] = ca * (1 - t) + cb * t

# domain-warped fbm clouds, stretched horizontally
warp1 = fbm(W, H, 420, 3, rng); warp2 = fbm(W, H, 420, 3, rng)
base = fbm(W, H, 260, 6, rng)
coords = np.array([y + (warp1 - .5) * 140, x + (warp2 - .5) * 260])
dens = ndi.map_coordinates(base, coords, order=1, mode='reflect')
detail = fbm(W, H, 60, 4, rng)
dens = dens * .82 + detail * .18
# coverage: sparse at the top, fuller mid/low, thinning into haze at the bottom
cov = .36 + .20 * np.clip(1 - np.abs(v - .55) / .45, 0, 1)
cloud = np.clip((dens - (1 - cov) * .92) / .24, 0, 1)
cloud = cloud * cloud * (3 - 2 * cloud)
cloud *= np.clip((v - .05) / .25, 0, 1)
# lighting from the upper left
shift = ndi.shift(dens, (-10, -14), order=1, mode='nearest')
light = np.clip((dens - shift) * 6 + .5, 0, 1)
cloud_col = (hexrgb('#FFFFFF')[None, None, :] * light[..., None] +
             hexrgb('#C7D5E4')[None, None, :] * (1 - light[..., None]))
cloud_col = cloud_col * .92 + hexrgb('#FFF6E8') * .08
img = sky * (1 - cloud[..., None] * .93) + cloud_col * cloud[..., None] * .93
# warm diffused light (no sun disc): a broad bloom high on the left
bloom = np.exp(-(((x - W * .18) / (W * .55)) ** 2 + ((y - H * .10) / (H * .32)) ** 2))
img = img * (1 - bloom[..., None] * .22) + hexrgb('#FFF3DC') * bloom[..., None] * .22
# soft photographic blur and a little grain
for c in range(3):
    img[..., c] = ndi.gaussian_filter(img[..., c], 3.2)
img += (rng.random((H, W, 1)) - .5) * .018
img = np.clip(img, 0, 1)
out = (img * 255 + .5).astype(np.uint8)
with open(sys.argv[1], 'wb') as f:
    f.write(b'P6 %d %d 255\n' % (W, H)); f.write(out.tobytes())
print('ok')
