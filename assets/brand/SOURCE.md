# Brand assets

`lokum_logo.webp` is the Lokum AI logo, the WebP image embedded in the web repo's `public/lokum-logo.svg` (lokumai/ai-engineering-bazaar, MIT licence), taken out of the SVG unchanged.

## App icon

`app_icon/` holds the app icon's sources (owner's choice, 2026-11-10): the bazaar gate's silhouette holding the lattice band, its navy ground and its teal, gold and brick stripes (`mark.svg`). They are not bundled; each is drawn at 1024 x 1024 in headless Chrome and scaled:

- `icon_light.svg`, the mark on white: iOS `AppIcon.png` and Android's `mipmap-*/ic_launcher.png`;
- `icon_dark.svg` and `icon_tinted.svg`, the mark on no ground and in white: iOS `AppIcon-Dark.png` and `AppIcon-Tinted.png`, which iOS 18 and later show in the dark and tinted home screens;
- `adaptive_foreground.svg` and `adaptive_monochrome.svg`, the layers of Android's adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`, on the white `ic_launcher_background` colour), scaled to 108 dp in each `mipmap-*` folder; the monochrome layer is the themed icon that Android 13 and later tint after the wallpaper.
