# Sky HDRIs — Attribution & License

All sky assets in this folder are CC0 (public domain) sourced from PolyHaven.
PolyHaven assets are released under the Creative Commons Zero (CC0) license:
free for any use, commercial or otherwise, no attribution required.

## Files

- `eldoria_sunset_sky_2k.jpg` (2048×1024 equirectangular panorama, ~260 KB)
  Source: "The Sky Is On Fire" by Greg Zaal (PolyHaven)
  Use: skybox panorama — fiery orange/crimson sunset, perfect for warm Eldoria palette.

- `eldoria_sunset_sky_1k.jpg` (1024×512 equirectangular, ~75 KB)
  Same source, lower-res for fast loading on weaker devices.

- `the_sky_is_on_fire_1k.hdr` (1024×512 Radiance HDR, ~1.5 MB)
  Same source, full HDR for ambient/IBL lighting in Godot's WorldEnvironment.
  Use as `sky_material -> PanoramaSkyMaterial.panorama` for proper IBL.

## Usage in Godot

```gdscript
# In your World scene's WorldEnvironment node, set Sky -> Panorama Sky Material
# and load the HDR for proper energy/IBL response:
var sky := PanoramaSkyMaterial.new()
sky.panorama = preload("res://assets/skies/the_sky_is_on_fire_1k.hdr")
$WorldEnvironment.environment.sky.sky_material = sky
$WorldEnvironment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
```

For a non-HDR pipeline (mobile/web), use the JPG instead:
`sky.panorama = preload("res://assets/skies/eldoria_sunset_sky_1k.jpg")`
