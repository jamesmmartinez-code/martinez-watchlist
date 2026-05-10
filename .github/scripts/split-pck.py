#!/usr/bin/env python3
"""Split eldoria/index.pck into <100 MB chunks and patch index.html to
fetch+reassemble them in the browser before Godot starts.

Why: GitHub blocks blobs >100 MB and Pages doesn't serve LFS, so we keep the
whole pipeline working over plain HTTP by splitting the PCK at build time and
reassembling it client-side. No Godot source changes required.

Idempotent: if index.pck is already <99 MB this is a no-op.
"""
import json
import os
import sys

CHUNK_SIZE = 90 * 1024 * 1024  # 90 MB, comfortably below the 100 MB limit

# Old block we expect in the Godot 4.6.x generated index.html (exact match).
OLD_BLOCK = """\t\tsetStatusMode('progress');
\t\tengine.startGame({
\t\t\t'onProgress': function (current, total) {
\t\t\t\tif (current > 0 && total > 0) {
\t\t\t\t\tstatusProgress.value = current;
\t\t\t\t\tstatusProgress.max = total;
\t\t\t\t} else {
\t\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t\t}
\t\t\t},
\t\t}).then(() => {
\t\t\tsetStatusMode('hidden');
\t\t}, displayFailureNotice);"""

NEW_BLOCK = """\t\tsetStatusMode('progress');
\t\t(async function loadChunkedPck() {
\t\t\tconst manifest = await (await fetch('pck-parts.json')).json();
\t\t\t// Download all chunks first, measure actual sizes before allocating.
\t\t\t// Prevents "offset out of bounds" if a chunk size differs from manifest
\t\t\t// (e.g. during the mid-deploy race between new chunks and old manifest).
\t\t\tconst buffers = [];
\t\t\tlet actualTotal = 0;
\t\t\tlet fetched = 0;
\t\t\tconst manifestTotal = manifest.totalSize || 1;
\t\t\tfor (const part of manifest.parts) {
\t\t\t\tconst r = await fetch(part.name);
\t\t\t\tif (!r.ok) throw new Error('Failed to fetch ' + part.name + ': ' + r.status);
\t\t\t\tconst buf = new Uint8Array(await r.arrayBuffer());
\t\t\t\tbuffers.push(buf);
\t\t\t\tactualTotal += buf.byteLength;
\t\t\t\tfetched += buf.byteLength;
\t\t\t\tstatusProgress.value = fetched;
\t\t\t\tstatusProgress.max = manifestTotal;
\t\t\t}
\t\t\t// Allocate using ACTUAL downloaded byte count, not manifest's totalSize.
\t\t\tconst merged = new Uint8Array(actualTotal);
\t\t\tlet offset = 0;
\t\t\tfor (const buf of buffers) {
\t\t\t\tmerged.set(buf, offset);
\t\t\t\toffset += buf.byteLength;
\t\t\t}
\t\t\t// Monkey-patch preloadFile so Engine.startGame uses our reassembled
\t\t\t// buffer instead of fetching a (non-existent) index.pck from the server.
\t\t\tconst origPreload = engine.preloadFile.bind(engine);
\t\t\tengine.preloadFile = function (file, path) {
\t\t\t\tif (file === 'index.pck') {
\t\t\t\t\treturn origPreload(merged.buffer, 'index.pck');
\t\t\t\t}
\t\t\t\treturn origPreload(file, path);
\t\t\t};
\t\t\tawait engine.startGame({
\t\t\t\t'onProgress': function (current, total) {
\t\t\t\t\tif (current > 0 && total > 0) {
\t\t\t\t\t\tstatusProgress.value = current;
\t\t\t\t\t\tstatusProgress.max = total;
\t\t\t\t\t} else {
\t\t\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t\t\t}
\t\t\t\t},
\t\t\t});
\t\t\tsetStatusMode('hidden');
\t\t})().catch(displayFailureNotice);"""


def main():
    eldoria = sys.argv[1] if len(sys.argv) > 1 else "eldoria"
    pck_path = os.path.join(eldoria, "index.pck")
    if not os.path.exists(pck_path):
        print(f"[split-pck] No {pck_path} — nothing to do.")
        return 0

    size = os.path.getsize(pck_path)
    threshold = 99 * 1024 * 1024
    if size <= threshold:
        print(f"[split-pck] {pck_path} is {size} bytes (<99 MB) — leaving intact.")
        # Make sure no stale parts/manifest linger
        for f in os.listdir(eldoria):
            if f.startswith("index.pck.") or f == "pck-parts.json":
                os.remove(os.path.join(eldoria, f))
                print(f"[split-pck] removed stale {f}")
        return 0

    parts = []
    with open(pck_path, "rb") as src:
        idx = 0
        while True:
            chunk = src.read(CHUNK_SIZE)
            if not chunk:
                break
            part_name = f"index.pck.{idx:03d}"
            with open(os.path.join(eldoria, part_name), "wb") as dst:
                dst.write(chunk)
            parts.append({"name": part_name, "size": len(chunk)})
            idx += 1

    os.remove(pck_path)
    manifest = {"totalSize": size, "parts": parts}
    with open(os.path.join(eldoria, "pck-parts.json"), "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"[split-pck] split {size} bytes into {len(parts)} chunks.")

    html_path = os.path.join(eldoria, "index.html")
    with open(html_path, "r") as f:
        html = f.read()

    if OLD_BLOCK not in html:
        print("[split-pck] ERROR: expected startGame block not found in index.html.")
        print("[split-pck] Godot's HTML template may have changed — patch needs updating.")
        return 1

    html = html.replace(OLD_BLOCK, NEW_BLOCK, 1)
    with open(html_path, "w") as f:
        f.write(html)
    print("[split-pck] patched index.html with chunked-PCK loader.")
    return 0


if __name__ == "__main__":
    sys.exit(main())