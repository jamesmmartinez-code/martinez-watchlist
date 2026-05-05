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
            #focus-hint{position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);
                background:rgba(255,195,60,0.95);color:#1a0e00;padding:18px 32px;
                border-radius:12px;font:bold 22px/1.3 system-ui,sans-serif;
                border:3px solid #1a0e00;cursor:pointer;z-index:9999;display:none;
                box-shadow:0 6px 20px rgba(0,0,0,0.6);text-align:center;}
            #focus-hint:hover{background:rgba(255,215,100,1);}
        </style>
        <div id="focus-hint">CLICK HERE TO PLAY<br><span style="font-size:14px;font-weight:normal;">(WASD won't work until you click on the game)</span></div>
        <script>
        (function(){
            const c=document.getElementById('canvas');
            const hint=document.getElementById('focus-hint');
            function focusCanvas(){try{c.focus();}catch(e){}}
            function checkFocus(){if(document.activeElement!==c){hint.style.display='block';}else{hint.style.display='none';}}
            window.addEventListener('load',()=>{setTimeout(focusCanvas,300);setTimeout(checkFocus,800);});
            document.addEventListener('mousedown',()=>{setTimeout(focusCanvas,0);setTimeout(checkFocus,50);});
            document.addEventListener('click',()=>{setTimeout(focusCanvas,0);setTimeout(checkFocus,50);});
            hint.addEventListener('click',()=>{focusCanvas();checkFocus();});
            setInterval(checkFocus,2000);
            window.addEventListener('focus',()=>{focusCanvas();checkFocus();});
            console.log('[Eldoria] focus manager active — canvas tabindex=1');
        })();
        </script>
'''
    src = src.replace('<script src="index.js">', inject + '\n        <script src="index.js">')
    p.write_text(src)
    print('injected focus manager into', html_path)

if __name__ == '__main__':
    main(sys.argv[1])
