# About art

The five pictures of the About page come from the web repo (lokumai/ai-engineering-bazaar, MIT licence), where the About page draws them in code and moves them as the reader arrives (`src/components/about/scenes/`, web D115), at commit `8fbada3` (2026-11-10). Each is an animated WebP of the web's scene in motion from its own start, one per section of the story, in its order, with the web's still picture beside it (`scene_<n>_still.webp`):

| File | Scene | Length |
| --- | --- | --- |
| `scene_1.webp` | `TreatyScene`: the question, the treaty read page by page, "Page 412: in short, yes" | 13.5 s |
| `scene_2.webp` | `HaystackScene`: the whole stack, the straws flying off, the needle bared and glinting | 7.5 s |
| `scene_3.webp` | `SealScene`: the sheet, the reed writing, a line struck, the seal pressed | 11.5 s |
| `scene_4.webp` | `BrainrotScene`: the memes in turn | 10 s |
| `scene_5.webp` | `EngravingScene`: the engraving drawn line by line, then its caption and the light | 8 s |

They were recorded from the built site (`npm run build`, then `out/` served on a local port) in Playwright's Chromium at the web's phone width (592 x 1100, scale 1), with the page under reduced motion so the page's own motion (`motion.ts`) does nothing, the page's grounds and words hidden, and the page's clock paused and moved only by the recorder (`page.clock.pauseAt`, then `runFor`), 24 frames a second. Each scene's own module (`createTreaty`, `createHaystack`, `createSeal`, `createBrainrot`, `createEngraving`, bundled from the web's source with its Vite) was created and started at the first frame, as `motion.ts` starts it when its section arrives; the haystack's `progress.p`, which the web's scroll drives, went from 0 to 1 over 0.6 s to 4.6 s, eased. Each frame is the `figure.slot` with 6% around it, on a clear ground, cut to what the scene draws, then laid on its section's ground (web `palette.ts`). The frames were saved with Pillow (`save(..., 'WEBP', save_all=True, duration=42, quality=60, method=4)`), which joins a run of equal frames into one, about 5.4 MB for the five; the stills are each section's still picture under reduced motion, the same cut.

Each scene plays once and stays on its last frame. Its section moves on only once the scene has shown its last frame, so each tells its whole story on a slower device too; the memes have no end and hold nothing up. Under reduced motion the section shows the still.

`grain.png` is the ground's grain, the web's `.ground::before` (`src/app/about.css`: fractal noise in cream, `rgb(1, .97, .9)` at `.9` of the noise, the layer at `.075`) baked into one 256 px tile: Pillow's Gaussian noise, blurred by 0.6 px, its alpha `.9 * .075` of the noise. The film repeats it over the whole screen.

The words beside them are not here: they come from the content bundle (`api/v1/story/en.json`, web D125).
