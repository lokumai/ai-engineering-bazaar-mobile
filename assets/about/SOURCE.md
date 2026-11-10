# About art

The five pictures of the About page come from the web repo (lokumai/ai-engineering-bazaar, MIT licence), where the About page draws them in code (`src/components/about/scenes/`, web D115), at commit `8fbada3` (2026-11-10). Each is the still the page shows under reduced motion, one per section of the story, in its order:

| File | Scene |
| --- | --- |
| `scene_1.webp` | `TreatyScene`, down the table |
| `scene_2.webp` | `HaystackScene`, the needle in the haystack |
| `scene_3.webp` | `SealScene`, the seal |
| `scene_4.webp` | `BrainrotScene`, brainrot |
| `scene_5.webp` | `EngravingScene`, Nietzsche engraved |

They were taken from the built site (`npm run build`, then `out/` served on a local port) in Playwright's Chromium at 1440 x 1000, scale 2, with reduced motion and the page's words hidden: each `#stall-<n> figure.slot` as a screenshot, the treaty widened 150 px to the left, since its table runs past its slot. Each PNG was scaled to 800 px high and saved as WebP (Pillow `save(..., 'WEBP', quality=86, method=6)`).

The words beside them are not here: they come from the content bundle (`api/v1/story/en.json`, web D125).
