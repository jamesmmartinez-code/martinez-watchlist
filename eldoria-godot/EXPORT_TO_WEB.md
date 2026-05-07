# How to publish Eldoria 3D to your live URL

End goal: kids visit **`https://jamesmmartinez-code.github.io/martinez-watchlist/`** → click the new "🌍 Realm of Eldoria · 3D" tile → enters the live Godot 3D world.

## One-time setup (5 min)

### 1. Install Godot Web export templates
- Open Godot, with the Eldoria project loaded.
- Top menu: **Editor → Manage Export Templates**.
- Click **Download and Install** (the recommended URL shows up in the dialog).
- Wait for the ~280 MB download. Once it says "Installed", close the dialog.

### 2. Add the Web export preset
- Top menu: **Project → Export...**
- Click **Add...** in the top-left of the Export window.
- Pick **Web** from the dropdown.
- A "Web" preset appears.

### 3. Configure the preset for GitHub Pages
- With the Web preset selected, on the right panel:
  - **Variant: Threads** → **Uncheck this**. (GitHub Pages doesn't set the COOP/COEP headers Godot's threaded mode needs. Single-threaded works fine for our scope.)
  - **Variant: Extensions Support** → leave checked (default is fine).
  - **Variant: Debug Info** → leave unchecked.
  - **HTML / Custom HTML Shell** → leave empty (default Godot shell is fine).
- Click **Export Project...** at the bottom.

### 4. Set the export path
- A file dialog appears. Navigate to:
  `outputs/eldoria-godot/web-export/`
- If the folder doesn't exist, create it (right-click → New Folder).
- Filename: **`index.html`**
- Click **Save**.

Godot will produce ~6-8 files in `web-export/`:
- `index.html`
- `index.pck` (the game data)
- `index.wasm` (the Godot engine compiled to WebAssembly)
- `index.audio.worklet.js`, `index.js`, `index.icon.png`, `index.apple-touch-icon.png`

## Pushing it live

Once you've exported successfully, run the existing deploy script from your outputs folder:

```bash
bash "$HOME/Library/Application Support/Claude/.../outputs/deploy.sh"
```

(Or just **`bash deploy.sh`** if you `cd` into the outputs folder first.)

It will:
1. Clone your `martinez-watchlist` repo
2. Copy the latest `family-watchlist.html` to `index.html`
3. Copy the contents of `eldoria-godot/web-export/` into the repo's `eldoria/` folder
4. Commit and push to GitHub

GitHub Pages auto-rebuilds within ~30 seconds. Then:

- **Watchlist + Games** → `https://jamesmmartinez-code.github.io/martinez-watchlist/`
- **Eldoria 3D** → `https://jamesmmartinez-code.github.io/martinez-watchlist/eldoria/` (also reachable from the games tile in the watchlist)

## Re-publishing after I make changes

Whenever I modify Godot code/scenes:
1. **In Godot:** Project → Export → Export Project (overwrites `web-export/`)
2. **In Terminal:** `bash deploy.sh`

The kids open the same URL, see the latest version.

## If something goes wrong

- **"Export templates not found"** → step 1 again, click Download and Install.
- **Browser shows blank page** → open browser DevTools → Console. Most common: the threads checkbox was left ON. Re-export with it OFF.
- **`gh auth login` errors** → the deploy script uses git over HTTPS. Make sure `gh` is authed: `gh auth status`. If not: `gh auth login`.
- **Big load time** → first load is ~30 MB (engine wasm + game pack). Subsequent loads are cached.
