shader_type spatial;
// Realm of Eldoria — EnemyVariant.gdshader
//
// Lightweight per-instance tint + emissive for procedural enemy appearance.
// Applied when a GLB model is NOT available (fallback capsule enemies).
//
// Uniforms set once in _ready() per enemy instance:
//   variant_color  — base tint (set from Enemy.tint + random brightness)
//   emissive_color — eye / outline glow (subtle)
//   roughness      — surface feel (varies slightly per kind)
//
// On take_damage: caller pulses damage_flash to 1.0 then lerps back.

render_mode blend_mix, depth_draw_opaque, cull_back,
            diffuse_lambert, specular_schlick_ggx;

uniform vec4  variant_color  : source_color = vec4(0.45, 0.85, 0.30, 1.0);
uniform vec4  emissive_color : source_color = vec4(1.00, 0.40, 0.10, 1.0);
uniform float emissive_strength = 0.4;
uniform float roughness         = 0.75;
uniform float damage_flash      = 0.0;   // 0→1, lerped back to 0 each frame
uniform float time_offset       = 0.0;

void fragment() {
    float t   = TIME + time_offset;
    vec3  col = variant_color.rgb;

    // Damage flash
    col = mix(col, vec3(1.0, 0.15, 0.15), clamp(damage_flash, 0.0, 1.0));

    // Subtle eye-glow pulse — makes even placeholder capsules feel alive.
    // The glow is strongest at UV.y ≈ 0.85 (top of capsule = head area).
    float eye_zone = smoothstep(0.80, 0.92, UV.y);
    float eye_pulse = 0.5 + 0.5 * sin(t * 3.5 + time_offset);
    vec3  emissive  = emissive_color.rgb * emissive_strength * eye_zone * eye_pulse;

    ALBEDO    = col;
    EMISSION  = emissive;
    ROUGHNESS = roughness;
    METALLIC  = 0.0;
}
