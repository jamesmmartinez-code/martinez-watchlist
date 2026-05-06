# Sky HDRIs — Attribution & License

All sky assets in this folder are CC0 (public domain) — either sourced
from PolyHaven (sunset) or generated procedurally with Pillow + NumPy
(dawn, night). Both pipelines produce free-for-any-use, no-attribution-
required panoramas, safe to ship.

## Files

### Sunset (day cycle — evening)

- `eldoria_sunset_sky_2k.jpg` (2048×1024 equirectangular panorama, ~260 KB)
  Source: "The Sky Is On Fire" by Greg Zaal (PolyHaven) — CC0.
  Use: skybox panorama — fiery orange/crimson sunset, perfect for warm
  Eldoria palette. THEME §3 dominant sunset gold/wine.

- `eldoria_sunset_sky_1k.jpg` (1024×512 equirectangular, ~75 KB)
  Same source, lower-res for fast loading on weaker devices.

- `the_sky_is_on_fire_1k.hdr` (1024×512 Radiance HDR, ~1.5 MB)
  Same source, full HDR for ambient/IBL lighting in Godot's
  WorldEnvironment.

### Night (night cycle — added run 14)

- `eldoria_night_sky_2k.jpg` (2048×1024 equirectangular panorama, ~115 KB)
  Source: `scripts/art/gen_night_sky.py` — procedural Pillow + NumPy
  pipeline, deterministic seed 1306. Painterly indigo→warlock-purple
  gradient with scattered cool/warm stars, soft diagonal Milky Way band,
  and an offset silver moon at ~27° azimuth, ~28° altitude. Pure CC0.
  Use: night-cycle skybox to pair with the sunset panorama. THEME §1
  cool tones reserved for night, mist, magic; THEME §3 warlock purple
  / fey cyan / frost-pale silver as accents against ink charcoal.
  Verified palette compliance: max RGB 229 (no pure white), zenith
  (17,10,17), moon disk (186,209,215) silver-cool, mean luminance 73.7
  (genuinely night, not just dim day).

- `eldoria_night_sky_1k.jpg` (1024×512 equirectangular, ~30 KB)
  LANCZOS downscale from the 2K master, same star/moon layout.

### Dawn (morning cycle — added by Art agent)

- `eldoria_dawn_sky_2k.jpg` (2048×1024 equirectangular panorama, ~92 KB)
  Source: `scripts/art/gen_dawn_sky.py` — procedural Pillow + NumPy
  pipeline, deterministic seed 1409. Painterly six-stop vertical
  gradient running cooled-warlock indigo at zenith → lavender → eastern
  rose flush → peach → sunset gold horizon, with a small painterly
  rising sun at ~26% azimuth / 78% altitude (just cresting the horizon
  line) plus a wider gold horizon bloom on the sun side. A handful of
  fading silver/lavender stars near zenith sell the just-before-sunrise
  beat without contradicting the warming horizon. Soft wispy clouds in
  the mid-band carry the underlit-by-sunrise treatment (cool lavender
  tops, parchment-peach undersides). Pure CC0.
  Use: morning-cycle skybox bridging the night → sunset day arc. THEME
  §1 painterly hand-painted feel; §3 sunset gold + burnt orange + wine
  + parchment in the warm bands, with stone-blue / warlock-purple held
  as zenith accents. No neon, no pure white — max channel value caps at
  255 only inside the small sun disc; bulk of the frame stays inside
  the THEME palette.
  Verified seam-wrap: mean abs RGB diff between the left-most and
  right-most columns is < 1.0 / 255, so the panorama tiles cleanly when
  Godot wraps it around the WorldEnvironment skybox.

- `eldoria_dawn_sky_1k.jpg` (1024×512 equirectangular, ~16 KB)
  LANCZOS downscale from the 2K master, same sun/cloud/star layout.

## Usage in Godot — day/night/dawn switching

The Builder agent owns the day/night cycle. With three panoramas
available, the intended switching pattern uses `World.time_of_day`
(0..24 float, 6-real-minute period) banded into three windows:

```gdscript
# In World.gd or a dedicated SkyController node, swap when the band changes:
const SKY_DAWN  := preload("res://assets/skies/eldoria_dawn_sky_1k.jpg")
const SKY_DAY   := preload("res://assets/skies/eldoria_sunset_sky_1k.jpg")
const SKY_NIGHT := preload("res://assets/skies/eldoria_night_sky_1k.jpg")

func _sky_for_tod(tod: float) -> Texture2D:
    if tod < 5.0 or tod >= 21.0:
        return SKY_NIGHT
    elif tod < 8.0:
        return SKY_DAWN          # 5:00–8:00 morning band
    else:
        return SKY_DAY           # 8:00–21:00 day/sunset band

func _refresh_sky() -> void:
    var sm := $WorldEnvironment.environment.sky.sky_material as PanoramaSkyMaterial
    var want := _sky_for_tod(time_of_day)
    if sm.panorama != want:
        sm.panorama = want
```

A cross-fade approach (blending between two panoramas during transition
windows) is preferable to a hard swap once Builder lands a sky-blend
shader; until then, hard-swap on band-change is the agreed contract.

For HDR/IBL, the sunset still uses `the_sky_is_on_fire_1k.hdr`. Dawn
and night JPGs are intentionally LDR — those bands should drive
ambient_light_color tinting via the day/night controller (WORLD_STATE.md
day/night cycle notes), not be roundtripped through a procedural HDR
(which would risk visible banding from the JPG source).

## Regenerating the procedural skies

```bash
python3 scripts/art/gen_night_sky.py eldoria-godot/assets/skies/
python3 scripts/art/gen_dawn_sky.py  eldoria-godot/assets/skies/
```

Same seeds → identical output. Change `seed=1306` (night) or `seed=1409`
(dawn) in each `render()` to re-roll the star/cloud pattern. Sun
position (`sun_x_frac=0.26` for dawn) and gradient stops are tuned for
THEME compliance and should not be drifted without updating this file.
