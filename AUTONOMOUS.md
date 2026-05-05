# Autonomous build pipeline

This repo contains both the source (`eldoria-godot/`) and the built artifacts
(`eldoria/`) for the Realm of Eldoria game.

**On every push to `eldoria-godot/**`:**
1. `.github/workflows/build-eldoria.yml` triggers
2. Installs Godot 4.6.2 headless + Web export templates
3. Runs `--import` then `--export-release "Web"` into `eldoria-godot/web-export/`
4. Copies the build into `/eldoria/` at the repo root
5. Commits the build back so GitHub Pages serves the new version

**Scheduled autonomous agents** clone this repo, edit GDScript files in
`eldoria-godot/scripts/`, then commit + push using a fine-grained PAT stored
in their session prompt. GitHub Actions does the rest.

See `CHANGES.md` for the running build ledger.
