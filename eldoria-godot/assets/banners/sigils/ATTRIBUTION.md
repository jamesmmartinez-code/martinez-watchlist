# Faction Crest Sigils — Attribution & License

All sigils in this folder are **CC0** (public domain) — generated procedurally
with Pillow + NumPy from `scripts/art/gen_sigils.py`. Free for any use, no
attribution required.

## Files

Each crest is **256×256 RGBA PNG** with transparent background, drawn as a
painterly heater-shield escutcheon over a faction-flavored field, with a
hand-painted sigil and weathered trim per THEME.md §3.

| File | Faction | Sigil | Palette |
|------|---------|-------|---------|
| `briarwood_crest.png` | Briarwood Village | oak leaf over crossed axe | moss + bronze |
| `goldhaven_crest.png` | Goldhaven (capital) | five-point royal crown w/ jewel | crimson + sunset gold |
| `ironhold_crest.png` | Ironhold (forge city) | hammer striking anvil w/ sparks | ember + iron |
| `silverleaf_crest.png` | Silverleaf (elven grove) | almond elven leaf, silver veins | jade + silver |
| `stormwatch_crest.png` | Stormwatch Port (coast) | ringed ship's anchor w/ rope | slate + bronze |
| `embergrove_crest.png` | Embergrove (desert oasis) | layered rising flame | sienna + magma |
| `frostpeak_crest.png` | Frostpeak Keep (north) | six-point snowflake | ice + steel |

## Pipeline

`scripts/art/gen_sigils.py` — deterministic seed `13130 + i*17` per faction.
Pure Pillow + NumPy. No external assets, no AI generators, no Adobe Stock
royalty fees.

The script:
1. Builds an irregular shield mask (small per-vertex jitter for hand-painted edge).
2. Paints a faction-color field (vertical sunset gradient + ~320 brushstrokes).
3. Adds parchment fiber grain noise.
4. Strokes a heraldic trim outline + thin inner accent band.
5. Renders the faction-specific sigil with painterly drop-shadow.
6. Drops weathering scratches (ink + parchment specks).
7. Top-edge sunset-warmth lightcatch (per THEME §3, sunset 70% dominance).

## Use in world-builder

Suggested wiring:
- Mount as `Sprite3D` billboards above each town gate.
- Embed inline in NPC dialogue panels for the town's trade NPC (e.g. Goldhaven
  banker dialogue gets a small `goldhaven_crest.png` icon next to the speaker
  name).
- Use as inventory-tab dividers when the player has gear from multiple factions.
- Pair with the existing town signposts (`banners/sign_to_<town>.png`) — the
  signpost is the highway marker, the crest is the formal heraldry.

## Re-rendering

```bash
python3 scripts/art/gen_sigils.py eldoria-godot/assets/banners/sigils/
```

Deterministic — same seeds → same output.

---

*Generated: art-agent run, branch `auto/art`. Bound by THEME.md.*
