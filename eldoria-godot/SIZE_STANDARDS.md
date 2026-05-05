# Realm of Eldoria — Size Standards

All measurements are **visible AABB height in meters** (model's `_global_scale_sweep` target).
Authority: this file. If a script disagrees, the script is wrong — fix the script.

---

## Characters

| Category               | Target | Tolerance | Notes |
|------------------------|--------|-----------|-------|
| **Player**             | 1.80m  | ±10%      | Lange / Hero / CesiumMan all normalize to this |
| **Adult NPC**          | 1.80m  | ±15%      | Edda, Bram, Mara, Maeve, Roan, Hala, Lyra |
| **Child / youth NPC**  | 1.40m  | ±15%      | Worker girl, apprentices |
| **Pet companion**      | 0.70m  | ±20%      | Fox, mushroom familiar |
| **Mount (horse)**      | 1.70m  | ±10%      | Measured at withers |

## Enemies

| Category               | Target | Tolerance | Notes |
|------------------------|--------|-----------|-------|
| **Enemy — small**      | 1.40m  | ±20%      | Goblin scout, wolf |
| **Enemy — medium**     | 1.80m  | ±15%      | Goblin warrior, bandit |
| **Enemy — elite**      | 2.60m  | ±15%      | Ogre, troll |
| **Boss**               | 3.20m  | ±20%      | Hard floor 2.6m, hard ceiling 4.5m |
| **Crystal Guardian**   | 3.40m  | ±10%      | Pillar-form, special-cased |

## Props

| Category               | Target | Tolerance | Examples |
|------------------------|--------|-----------|----------|
| **Tiny prop**          | 0.40m  | ±50%      | Mushroom, lantern, skull |
| **Small prop**         | 1.00m  | ±30%      | Barrel, chest, stool, well-rim |
| **Medium prop**        | 2.00m  | ±25%      | Stone well, market stall, cart |
| **Large prop**         | 5.00m  | ±40%      | Windmill body, large statue |

## Trees / vegetation

| Category               | Target | Notes |
|------------------------|--------|-------|
| **Bush**               | 0.90m  | |
| **Small tree (oak)**   | 4.00m  | |
| **Tall tree (pine)**   | 8.00m  | |
| **Dead tree**          | 5.00m  | |

## Buildings

| Category               | Target |
|------------------------|--------|
| **Hut / shed**         | 3.50m  |
| **House**              | 5.00m  |
| **Tavern / smithy**    | 6.50m  |
| **Tower / windmill**   | 10.0m  |

---

## Rules

1. **One scale source.** Per-NPC overrides go in `WorldBuilder.NPC_SCALES`. Per-class targets go in `WorldBuilder._expected_height_for()`. Don't bake scale into `.tscn` transforms unless the model genuinely needs an asymmetric stretch.
2. **Sweep is authoritative.** `_global_scale_sweep` runs 0.5s after `_ready` and re-checks every CharacterBody3D / StaticBody3D against this table. Anything outside tolerance gets rescaled.
3. **Player is included.** The `player` group is in the sweep — don't bypass it.
4. **No 1.2× tweaks in `Main.tscn`.** If a model lands too small, fix it in the GLB import settings or in `NPC_SCALES`, not by inflating the scene transform.
5. **Tolerance bands matter.** A model inside its band is left alone (preserves artistic variance). Outside the band, it's snapped to the target.

## When you add a new model

1. Drop the `.glb` into `assets/models/...`
2. Add it to a scene via instance — leave its scale at `(1, 1, 1)`
3. Run the build. Open the live page and look at the model.
4. If it's wrong-sized, **first** check whether the sweep caught it. If not, the body might not be in the right group — fix that. If yes but it still looks off, add a per-name entry to `NPC_SCALES` (a fine-tune ratio, not a giant multiplier).

