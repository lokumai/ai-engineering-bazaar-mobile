# Brand assets

`lokum_logo.webp` is the Lokum AI logo, the WebP image embedded in the web repo's `public/lokum-logo.svg` (lokumai/ai-engineering-bazaar, MIT licence), taken out of the SVG unchanged.

## App icon

`app_icon/` holds the app icon's sources: since 2026-11-13 (owner's choice) a secret agent, the fedora tilted forward and to the side, faceless, in a coat with its collar up and a brick tie, filled with the lattice band's teal, gold and brick stripes and the ground showing between them (`mark.svg`); before that, the bazaar gate holding the same stripes. They are not bundled; each is drawn at 1024 x 1024 in headless Chrome and scaled:

- `icon.svg`, the mark on the dark page colour (#1D1F27), one icon for every phone theme (owner, 2026-11-13): iOS `AppIcon.png` and Android's `mipmap-*/ic_launcher.png`;
- `adaptive_foreground.svg` and `adaptive_monochrome.svg`, the layers of Android's adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`, on the dark `ic_launcher_background` colour), scaled to 108 dp in each `mipmap-*` folder; the monochrome layer is the themed icon that Android 13 and later tint after the wallpaper.
