# About art

The five pictures of the About page come from the web repo (lokumai/ai-engineering-bazaar, MIT licence), where the About page draws them in code and moves them under the scroll (`src/components/about/scenes/`, web D115), at commit `8fbada3` (2026-11-10). Each is an animated WebP: a loop of the web's scene in motion, one per section of the story, in its order:

| File | Scene | Loop |
| --- | --- | --- |
| `scene_1.webp` | `TreatyScene`, down the table | 16.25 s, one cycle of its own clock |
| `scene_2.webp` | `HaystackScene`, the needle in the haystack | the scroll from the whole stack to the bare needle, 8 s, then held 2.5 s |
| `scene_3.webp` | `SealScene`, the seal | 13.25 s, one cycle |
| `scene_4.webp` | `BrainrotScene`, brainrot | 7.6 s, one cycle of the memes |
| `scene_5.webp` | `EngravingScene`, Nietzsche engraved | the engraving drawn, then one sweep of the light, starting on the drawn plate |

They were recorded from the built site (`npm run build`, then `out/` served on a local port) in Playwright's Chromium at 1440 x 900, scale 1, with the page's words hidden and the page's clock under Playwright's control (`page.clock`), 8 frames a second: each `#stall-<n> figure.slot` as a screenshot every 125 ms of page time, the treaty widened 150 px to the left, since its table runs past its slot. A loop is cut where the scene's frame matches the frame one cycle earlier. The frames were saved with Pillow (`save(..., 'WEBP', save_all=True, duration=125, loop=0, quality=72, method=6)`), about 2.4 MB for the five.

Under reduced motion Flutter's `Image` holds each one on its first frame, which is why each loop starts on a full picture.

`grain.png` is the ground's grain, the web's `.ground::before` (`src/app/about.css`: fractal noise in cream, `rgb(1, .97, .9)` at `.9` of the noise, the layer at `.075`) baked into one 256 px tile: Pillow's Gaussian noise, blurred by 0.6 px, its alpha `.9 * .075` of the noise. The film repeats it over the whole screen.

The words beside them are not here: they come from the content bundle (`api/v1/story/en.json`, web D125).
