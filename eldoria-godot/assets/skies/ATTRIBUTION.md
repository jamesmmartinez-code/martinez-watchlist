# Sky HDRIs — Attribution & License

All sky assets in this folder are CC0 (public domain) — either sourced
from PolyHaven (sunset) or generated procedurally with Pillow + NumPy
(night). Both pipelines produce free-for-any-use, no-attribution-required
panoramas, safe to ship.

## Files

### Sunset (day cycle)

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

## Usage in Godot — day/night switching

The Builder agent owns the day/night cycle. The intended pattern is to
swap the panorama between sunset and night based on `time_of_day`:

```gdscript
# In World.gd or a dedicated SkyController node, called when day flips:
const SKY_DAY := preload("res://assets/skies/eldoria_sunset_sky_1k.jpg")
const SKY_NIGHT := preload("res://assets/skies/eldoria_night_sky_1k.jpg")

func _set_sky(is_night: bool) -> void:
    var sm := $WorldEnvironment.environment.sky.sky_material as PanoramaSkyMaterial
    sm.panorama = SKY_NIGHT if is_night else SKY_DAY
```

For HDR/IBL, the sunset still uses `the_sky_is_on_fire_1k.hdr`. The
night JPG is intentionally LDR — night-time IBL should fall back to the
ambient_light_color drop the Builder already controls (WORLD_STATE.md
day/night cycle notes), not to a procedural HDR (which would risk
visible banding from the JPG roundtrip).

## Regenerating the night sky

```bash
python3 scripts/art/gen_night_sky.py eldoria-godot/assets/skies/
```

Same seed → identical output. Change the `seed=1306` in `render()` to
re-roll the star pattern. The moon position (0.27 × W, 0.28 × H) and
gradient stops are tuned for THEME compliance and should not be drifted
without updating this file.
