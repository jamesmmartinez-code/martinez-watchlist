shader_type spatial;
// Realm of Eldoria — EnemyVariant.gdshader
//
// Lightweight per-instance tint + emissive for procedural enemy appearance.
// Applied when a GLB model is NOT available (fallback capsule enemies).
//
// Uniforms set once in _ready() per enemy instance:
//   variant_color   — base tint (set from Enemy.tint + random brightness)
//   emissive_color  — eye / outline glow (subtle)
//   roughness       — surface feel (varies slightly per kind)
//
// On take_damage: caller pulses damage_flash to 1.0 then lerps back.
// On _do_attack:  caller pulses attack_flash to 1.0 then lerps back.
// On _die:        caller animates dissolve from 0.0 → 1.0 over ~0.45s.

render_mode blend_mix, depth_draw_opaque, cull_back,
            diffuse_lambert, specular_schlick_ggx;

uniform vec4  variant_color  : source_color = vec4(0.45, 0.85, 0.30, 1.0);
uniform vec4  emissive_color : source_color = vec4(1.00, 0.40, 0.10, 1.0);
uniform float emissive_strength = 0.4;
uniform float roughness         = 0.75;
uniform float damage_flash      = 0.0;   // 0→1 red flash on hit
uniform float attack_flash      = 0.0;   // 0→1 orange pulse on swing
uniform float dissolve          = 0.0;   // 0 = solid, 1 = fully gone
uniform float time_offset       = 0.0;

void fragment() {
    float t   = TIME + time_offset;
    vec3  col = variant_color.rgb;

    // ── Dissolve (played on death) ─────────────────────────────────────────
    // Hash-based noise seeded on UV so the pattern is stable (not swimming).
    // Enemy "crumbles" from the bottom up: pattern biased toward UV.y.
    float nx    = UV.x * 14.7 + UV.y * 31.3;
    float noise = fract(sin(nx * 127.1 + nx * nx * 311.7) * 43758.5453);
    // Bottom-up: add UV.y bias so lower pixels dissolve first
    float dissolve_threshold = dissolve * 1.35 - UV.y * 0.35;
    if (dissolve > 0.001) {
        if (noise < dissolve_threshold) {
            discard;
        }
        // Ember glow at the dissolving edge (orange-red fire effect)
        float edge = dissolve_threshold + 0.12;
        if (noise < edge) {
            float t2 = 1.0 - (noise - dissolve_threshold) / 0.12;
            EMISSION += vec3(2.0, 0.5 + t2 * 0.3, 0.0) * t2 * 1.8;
        }
    }

    // ── Damage flash (red) ─────────────────────────────────────────────────
    col = mix(col, vec3(1.0, 0.15, 0.15), clamp(damage_flash, 0.0, 1.0));

    // ── Attack telegraph (orange-gold pulse) ───────────────────────────────
    // Reads as "this enemy is about to swing" — gives Alden/Owen a visual cue.
    col = mix(col, vec3(1.0, 0.65, 0.10), clamp(attack_flash, 0.0, 1.0) * 0.70);

    // ── Emissive eye-glow pulse ─────────────────────────────────────────────
    // Glow at UV.y ≈ 0.85 (head area) — even placeholders feel alive.
    float eye_zone  = smoothstep(0.80, 0.92, UV.y);
    float eye_pulse = 0.5 + 0.5 * sin(t * 3.5 + time_offset);
    vec3  emissive  = emissive_color.rgb * emissive_strength * eye_zone * eye_pulse;

    // Attack flash also boosts eye glow briefly for extra threat readability.
    emissive += emissive_color.rgb * attack_flash * 1.2 * eye_zone;

    ALBEDO    = col;
    EMISSION  = emissive;
    ROUGHNESS = roughness;
    METALLIC  = 0.0;
}
