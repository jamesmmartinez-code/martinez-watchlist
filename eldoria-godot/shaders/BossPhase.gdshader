shader_type spatial;
// Realm of Eldoria — BossPhase.gdshader
//
// Dynamic material applied to all boss core meshes.
// Driven entirely by uniforms — GDScript sets them per-frame, no texture
// swap or material duplication needed.
//
// Features:
//   • Phase-based colour progression (cool blue → threat orange → enrage red)
//   • Animated energy pulse on the emissive channel
//   • Damage-flash: white-out that decays back to phase colour
//   • Phase-2 glitch: horizontal scanline shimmer at high speed
//   • Works on any SpatialMaterial-compatible mesh (sphere, capsule, plane)
//
// Usage in GDScript:
//   var mat := ShaderMaterial.new()
//   mat.shader = preload("res://shaders/BossPhase.gdshader")
//   mesh_instance.material_override = mat
//   # Each frame:
//   mat.set_shader_parameter("phase", current_phase)
//   mat.set_shader_parameter("damage_flash", flash_value)  # lerp to 0.0 each frame
//   mat.set_shader_parameter("time_offset", randf())       # set once in _ready

render_mode blend_mix, depth_draw_opaque, cull_back,
            diffuse_lambert, specular_schlick_ggx;

// ── Uniforms ───────────────────────────────────────────────────────────────
uniform int   phase         = 0;            // 0 = observe, 1 = adapt, 2 = punish
uniform float damage_flash  = 0.0;          // 0.0 (none) → 1.0 (full white)  — decays each frame
uniform float time_offset   = 0.0;          // per-instance seed — prevents sync between bosses
uniform float energy_scale  = 1.0;          // allow external control of glow brightness

// Phase base colours — set these to match your boss's lore colour
uniform vec4 color_phase0 : source_color = vec4(0.40, 0.65, 1.00, 1.0);  // spectral blue
uniform vec4 color_phase1 : source_color = vec4(1.00, 0.55, 0.15, 1.0);  // threat orange
uniform vec4 color_phase2 : source_color = vec4(1.00, 0.12, 0.08, 1.0);  // enrage crimson

// ── Fragment ───────────────────────────────────────────────────────────────
void fragment() {
    float t = TIME + time_offset;

    // ── Phase colour selection ─────────────────────────────────────────────
    vec3 phase_col;
    if (phase == 0) {
        phase_col = color_phase0.rgb;
    } else if (phase == 1) {
        // Phase 0→1 blend with a sin-wave so the transition shimmers
        float blend = 0.70 + 0.30 * sin(t * 4.0);
        phase_col = mix(color_phase0.rgb, color_phase1.rgb, blend);
    } else {
        // Phase 2: deepening red with urgency pulse
        float pulse = 0.5 + 0.5 * sin(t * 9.0);
        phase_col = mix(color_phase1.rgb, color_phase2.rgb, 0.55 + 0.25 * pulse);
    }

    // ── Damage flash overlay ───────────────────────────────────────────────
    // Mix toward pure white; caller lerps damage_flash → 0.0 each physics frame.
    vec3 col = mix(phase_col, vec3(1.0), clamp(damage_flash, 0.0, 1.0));

    // ── Phase-2 glitch scanlines ───────────────────────────────────────────
    // Horizontal bands that flicker at high frequency — reads as digital stress.
    if (phase == 2) {
        float band_v  = sin(UV.y * 48.0 + t * 22.0);          // high-frequency bands
        float band_h  = sin(UV.x * 12.0 - t * 7.0) * 0.4;    // slower horizontal drift
        float glitch  = step(0.55, band_v) * step(0.3, band_h) * 0.18;
        col += vec3(glitch);
        // Chromatic aberration approximation — R channel lags UV slightly
        float aberr = step(0.75, sin(UV.y * 24.0 + t * 30.0)) * 0.10;
        col.r += aberr;
        col.b -= aberr * 0.5;
        // Instability flicker — binary on/off at 20 Hz, ±30% brightness.
        // Reads as "core about to explode": not smooth, not safe, not stable.
        float flicker = step(0.5, sin(t * 20.0));
        col *= mix(0.70, 1.30, flicker);
    }

    // ── Energy pulse on emissive ───────────────────────────────────────────
    // Primary: slow heart-beat.  Secondary: fast shimmer.
    // Energy scale in phase 2 is boosted so it almost feels unstable.
    float base_energy   = 1.8 + 0.6  * sin(t * 2.6 + time_offset);
    float shimmer       = 0.0 + 0.25 * sin(t * 11.0 + time_offset * 3.0);
    float phase2_boost  = (phase == 2) ? (1.5 + 0.5 * sin(t * 18.0)) : 1.0;
    float final_energy  = (base_energy + shimmer) * energy_scale * phase2_boost;

    EMISSION  = col * final_energy;
    ALBEDO    = col * 0.35;          // keep diffuse dark so emission dominates
    ROUGHNESS = (phase == 2) ? 0.05 : 0.12;   // enrage phase is more mirror-like
    METALLIC  = 0.0;
    SPECULAR  = 0.6;
}
