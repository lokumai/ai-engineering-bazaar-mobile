# Brand assets

`lokum_logo.webp` is the Lokum AI logo, the WebP image embedded in the web repo's `public/lokum-logo.svg` (lokumai/ai-engineering-bazaar, MIT licence), taken out of the SVG unchanged.

## App icon

Since 2026-11-14 (owner's choice) the app icons are the pocket model's robot, its head and hat as its round button draws them, one icon for each hat on its own screen and for each other head in its fez, on the dark (#1D1F27) or the cream (#FDFBF7) page colour (`lib/shared/app_icon/bazaar_icon.dart`). `tool/render_app_icons.dart` draws them all from the robot's painter: iOS `AppIcon.appiconset` (the fez on dark, the default) and `AppIcon<Name>.appiconset`, Android's `mipmap-*/ic_launcher*.png` layers and the default's monochrome layer, and the pictures Settings shows, `assets/app_icon/<name>.png`.

`app_icon/mark.svg` is the striped secret agent the opening animation draws (`welcome_sting.dart`), the app icon from 2026-11-13 to 2026-11-14: the fedora tilted forward and to the side, faceless, in a coat with its collar up and a brick tie, filled with the lattice band's teal, gold and brick stripes and the ground showing between them. It is not bundled.
