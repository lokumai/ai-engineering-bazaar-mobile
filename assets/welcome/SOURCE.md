# Welcome art

The opening's and Welcome's pictures come from the web repo (lokumai/ai-engineering-bazaar, MIT licence), where the home page draws them as inline SVG under `src/components/home/street/art/`, at commit `7df302e` (2026-11-09):

| File | Source |
| --- | --- |
| `cast_mihri.webp`, `cast_dariush.webp`, `cast_bit.webp`, `cast_mei.webp`, `cast_piri.webp` | `cast-<id>-tile.html`, the front view of each person |

Each SVG was drawn with its `defs.html` in headless Chrome and saved as WebP, since the app's SVG renderer does not draw their patterns and clip paths: each person at 110 x 200 at scale 3, the lamps at 80 x 154 and 80 x 112 at scale 4.

The gate picture (`gate.html`, 1000 x 620 at scale 2) was drawn the same way until the full-screen opening replaced it (plan 1AA, 1AE). To redraw a picture, wrap the files in a page and take a screenshot, here a person:

```bash
art=<web clone>/src/components/home/street/art
printf '<!doctype html><style>html,body{margin:0;background:transparent}svg{display:block;width:110px;height:200px}svg.defs{position:absolute;width:0;height:0}</style>%s%s' "$(cat $art/defs.html)" "$(cat $art/cast-mei-tile.html)" > mei.html
google-chrome --headless=new --hide-scrollbars --default-background-color=00000000 --force-device-scale-factor=3 --window-size=110,200 --screenshot=cast_mei.png mei.html
```

then convert the PNG to WebP (Pillow `save(..., 'WEBP', quality=88, method=6)`).
