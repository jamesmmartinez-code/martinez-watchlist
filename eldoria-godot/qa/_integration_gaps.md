# Integration Gaps Log

last_run: 2026-05-06T13:55:51Z
canon_qa_status_at_run: PASS_WITH_DEBT
merged_this_cycle: auto/art (1 commit), auto/lore (2 commits)
skipped_this_cycle: auto/scale (merge conflict — needs manual resolution)
nothing_to_merge: auto/builder, auto/polisher, auto/qa, auto/scale-floorfix

## Gaps surfaced this run

[GAP: orphan asset] eldoria-godot/assets/icons/codex/the_sundering.png
  PNG present (auto/art @ 074b835) but no codex .md frontmatter has `icon_glyph: the_sundering`.
  Owner: @lorekeeper. Renderer falls back to legacy emoji, so non-blocking.

[GAP: orphan asset] eldoria-godot/assets/icons/codex/oath_of_thorns.png
  PNG present, no codex .md references it via `icon_glyph: oath_of_thorns`. Owner: @lorekeeper.

[GAP: orphan asset] eldoria-godot/assets/icons/codex/wyrmsong_winds.png
  PNG present, no codex .md references it via `icon_glyph: wyrmsong_winds`. Owner: @lorekeeper.

[GAP: orphan asset] eldoria-godot/assets/icons/codex/sunken_chord.png
  PNG present, no codex .md references it via `icon_glyph: sunken_chord`. Owner: @lorekeeper.

[GAP: skipped merge] auto/scale (1 commit ahead, 73 behind) — merge conflict
  Tip: 76bb428 "Scale: extend sweep to windmills/boulders/campfires/banner_poles/chests"
  Action: scale-engineer to rebase auto/scale onto main and re-push.

## Carry-over (from canon-qa _blocking_status.md)

PASS_WITH_DEBT: 7 S2 issues logged in eldoria-godot/qa/_blocking_status.md
(items_flavor entries, ITEMS dict drift, mossbound recipe, tree collision parity, AnimationLibrary batch).
These are owner-tracked S2 debt and do not block merge.

## Notes

- auto/art commit explicitly noted the codex frontmatter linkage is the Lore agent's
  responsibility on the next run; the four orphan-asset entries above are expected
  to clear when @lorekeeper ships icon_glyph: <name> frontmatter for matching codex
  fragments. They are logged here per integrator policy regardless of the planned
  follow-up.
