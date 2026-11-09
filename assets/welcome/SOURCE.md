# Welcome art

The Welcome screen's pictures come from the web repo (lokumai/ai-engineering-bazaar, MIT licence), where the home page draws them as inline SVG under `src/components/home/street/art/`, at commit `7df302e` (2026-11-09):

| File | Source |
| --- | --- |
| `gate.webp` | `gate.html`, the gate with the vaulted street and its lamps |
| `cast_mihri.webp`, `cast_dariush.webp`, `cast_bit.webp`, `cast_mei.webp`, `cast_piri.webp` | `cast-<id>-tile.html`, the front view of each person |

| `lamp_left.webp`, `lamp_right.webp` | the two hanging lamps of the team's mobile mockup, [Bazaar Mobil Taslak](https://claude.ai/artifact/4YZcwzuafAdcpsfGwWryp4), its Welcome screen |

Each SVG was drawn with its `defs.html` in headless Chrome and saved as WebP, since the app's SVG renderer does not draw their patterns and clip paths: the gate at 1000 x 620 at scale 2, each person at 110 x 200 at scale 3, the lamps at 80 x 154 and 80 x 112 at scale 4.

To redraw one, wrap the files in a page and take a screenshot:

```bash
art=<web clone>/src/components/home/street/art
printf '<!doctype html><style>html,body{margin:0;background:transparent}svg{display:block;width:1000px;height:620px}svg.defs{position:absolute;width:0;height:0}</style>%s%s' "$(cat $art/defs.html)" "$(cat $art/gate.html)" > gate.html
google-chrome --headless=new --hide-scrollbars --default-background-color=00000000 --force-device-scale-factor=2 --window-size=1000,620 --screenshot=gate.png gate.html
```

then convert the PNG to WebP (Pillow `save(..., 'WEBP', quality=88, method=6)`).
