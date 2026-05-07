#!/usr/bin/env python3
# PX 2026-05-05: ensure the Godot canvas has keyboard focus.
# Browsers often deliver keystrokes to whichever element has focus, and the
# Godot canvas doesn't always grab it on load (especially after a refresh
# or when other UI elements are present). Without focus, WASD does nothing.
# This script runs after every Godot export and injects a focus manager
# + a visible "Click here to play" hint that activates if focus is lost.
import sys, pathlib

def main(html_path):
    p = pathlib.Path(html_path)
    src = p.read_text()
    if 'focus-hint' in src:
        print('already injected, skipping')
        return
    # 1. add tabindex to canvas
    src = src.replace(
        '<canvas id="canvas">',
        '<canvas id="canvas" tabindex="1" style="outline:none;">'
    )
    # 2. add focus manager + hint right before <script src="index.js">
    inject = '''
        <style>
            #canvas{transition:box-shadow 0.2s;}
            body.unfocused #canvas{box-shadow:0 0 0 6px #ff4444 inset !important;}
            body.focused   #canvas{box-shadow:0 0 0 4px #44ff44 inset !important;}
            #focus-hint{position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);
                background:rgba(255,80,80,0.97);color:#1a0e00;padding:24px 38px;
                border-radius:14px;font:bold 26px/1.3 system-ui,sans-serif;
                border:4px solid #1a0e00;cursor:pointer;z-index:9999;display:none;
                box-shadow:0 8px 28px rgba(0,0,0,0.7);text-align:center;
                animation:focus-pulse 1s ease-in-out infinite;}
            @keyframes focus-pulse{0%,100%{transform:translate(-50%,-50%) scale(1);}50%{transform:translate(-50%,-50%) scale(1.05);}}
            #focus-hint:hover{background:rgba(255,120,120,1);}
        </style>
        <div id="focus-hint">CLICK HERE TO PLAY<br><span style="font-size:16px;font-weight:normal;">(canvas needs keyboard focus for WASD)</span></div>
        <script>
        (function(){
            const c=document.getElementById('canvas');
            const hint=document.getElementById('focus-hint');
            let focused=false;
            function focusCanvas(){try{c.focus({preventScroll:true});}catch(e){}}
            function checkFocus(){
                const isFocused=(document.activeElement===c);
                if(isFocused!==focused){
                    focused=isFocused;
                    document.body.classList.toggle('focused',focused);
                    document.body.classList.toggle('unfocused',!focused);
                    hint.style.display=focused?'none':'block';
                    console.log('[Eldoria] focus state:',focused?'FOCUSED (WASD will work)':'NOT FOCUSED');
                }
            }
            // AGGRESSIVE: refocus every 100ms for first 5 seconds (covers Godot init reclaim)
            // 2026-05-07: gentler initial focus — was 100ms × 50 (5s of focus-stealing); now 250ms × 12 (3s)
            let aggressive_count=0;
            const aggressive=setInterval(()=>{
                if(document.activeElement!==c) focusCanvas();
                checkFocus();
                if(++aggressive_count>=12){clearInterval(aggressive);}
            },250);
            // After 5s, drop to gentle 1s polling
            setTimeout(()=>{setInterval(()=>{checkFocus();if(!focused)focusCanvas();},1000);},5000);
            // Click anywhere -> focus canvas
            // 2026-05-07: removed mousedown refocus — was fighting Godot's right-drag camera + click-handling.
            document.addEventListener('click',(e)=>{if(document.activeElement!==c){focusCanvas();checkFocus();}});
            hint.addEventListener('click',(e)=>{e.stopPropagation();focusCanvas();checkFocus();});
            window.addEventListener('focus',()=>{focusCanvas();checkFocus();});
            window.addEventListener('keydown',(e)=>{
                if(!focused){focusCanvas();checkFocus();}
                console.log('[Eldoria] keydown:',e.code,'focused:',document.activeElement===c);
            },true);
            console.log('[Eldoria] AGGRESSIVE focus manager v2 active');
        })();
        </script>
'''
    src = src.replace('<script src="index.js">', inject + '\n        <script src="index.js">')
    p.write_text(src)
    print('injected focus manager into', html_path)

if __name__ == '__main__':
    main(sys.argv[1])