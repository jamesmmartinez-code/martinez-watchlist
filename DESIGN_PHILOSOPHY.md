# Design Philosophy — Realm of Eldoria

This file is the *operational distillation* of the world-engine research. Every
autonomous run consults this before deciding what to build. The 6 rules below
override any backlog item that conflicts with them.

## Audience
- Alden, age 9. Plays as the frog — explores, befriends, collects, lingers on
  details. Prefers companions, nature, low-pressure systems, surprise.
- Owen, age 11. Plays as the racer — pushes speed, mounts, gadgets, challenge.
  Prefers tactical wins, escalation, visible mastery.
- They play together. Co-op > PvP. Local-first, no accounts, no monetization.

## The 6 Rules

### 1. Compound, don't sprawl
Endless content production is a trap. The world gets richer when new mechanics
*recombine existing primitives* (NPCs × time-of-day × faction state × player
impact = NPC schedules that remember you). A new system must either (a)
recombine what's already there, or (b) introduce ONE new primitive AND wire it
into AT LEAST TWO existing systems on the same run. Standalone novelty is
forbidden.

### 2. Five outputs per feature
A feature isn't done unless it leaves behind:
  i.   Updated world state (WORLD_STATE.md)
  ii.  Updated schema if new (SYSTEM_REGISTRY.md)
  iii. Player-facing feedback (toast / popup / SFX / UI)
  iv.  An evaluation check (test contract or runtime assert)
  v.   At least 2 future hooks for downstream runs to build on
If any of i–v is missing, do not commit. Refactor or descope.

### 3. Persistent memory beats CHANGES.md alone
CHANGES.md is a journal — it's append-only and great for humans, but Claude
needs *queryable* state to make consistent decisions across runs. The five
ledger files together form long-term memory. Read all five before planning.
Update all that are touched as part of the same commit as the feature.

### 4. Planner → Builder → Verifier → Historian
Every run is four phases, in order. The phases are non-skippable. If verify
fails, roll the build back; do not commit half-broken state.

### 5. Endless ≠ infinite map
The world feels endless because it *remembers* and *reacts*. Faction state
changes. NPCs greet differently after you save them. Roads get safer when
defended, riskier when abandoned. Quests emerge from world events, not
template churn. One reactive system beats ten content additions.

### 6. Child-centered design is a hard constraint
NEVER ship: FOMO loops, dark patterns, manipulative UI, monetization, gated
progression that pressures purchases, social-pressure mechanics. ALWAYS prefer:
forgiving failure, readable telegraphs, large hit-feedback, short text, low
friction, strong solo and co-op play, the kids feeling smart.

## Reference
The full research document on emergent world design lives outside this repo
on James Martinez's machine. This file is the durable distillation. When in
doubt, re-read these 6 rules.
