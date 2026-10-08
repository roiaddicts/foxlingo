# Artwork provenance

The small leopard cub and matching app icon were generated with the built-in image tool on October 8, 2026. The supplied orange owl was a proportion and warmth reference. The mascot is an original golden leopard with rosettes, rounded ears, large eyes, a cream muzzle, tiny paws, and a Fox navy scarf. It uses a transparent background and appears at 70–140 points throughout the app. Reduce Motion disables its modest pose transitions.

- Mascot: `Assets.xcassets/Leopard.imageset/leopard.png`.
- App icon: `Assets.xcassets/AppIcon.appiconset/icon.png`.
- Downloaded badge and portrait URLs: `artwork-manifest.json`.
- Club badge source pages: `../../../content/club-artwork.json`.

Futbol11 portraits and UEFA badge URLs retain their source namespaces. Classic-squad portraits are joined by full name, never by colliding numeric IDs. Xolos’s badge comes from its official website; Riascos, Arce, and Saucedo portraits come from their named Wikipedia/Wikimedia images. Remaining club badges are obtained from the supplied seed, official club pages, or their Wikipedia infoboxes. These source images retain their original owners and licensing; the manifest records provenance rather than transferring image rights. Review source image terms when preparing public distribution.

Country flags are cached from the supplied Futbol11 nationality dataset (dataset 1), with explicit aliases for Czechia/Czech Republic and Türkiye/Turkey. Azerbaijan, absent from that dataset, uses FlagCDN. `content/country-artwork.json` records these name-to-source mappings. Cached image assets are used instead of flag emoji so the boards remain legible when emoji fonts are unavailable.

The explorer adds Di Stéfano's portrait from the supplied player record `player-1512`, explicitly mapped to canonical `entity-di-stefano` and cached offline. Match, two-leg tie, goal, city, and venue nodes use distinct system symbols; countries use their cached flags.

## Fox color update — October 8, 2026

The existing mascot and icon were edited with the built-in image-generation tool. The app's primary sRGB color is Fox navy `#002D56` (0, 45, 86). Controls, headings, roadmaps and game cards share `Palette.brand`; light surfaces use `#F4F7FB` and muted text uses `#56677A`. Clubs, flags, player portraits, gold tiers and error feedback retain their semantic colors.

Saved outputs replace the requested mascot/icon assets at `Assets.xcassets/Leopard.imageset/leopard.png` and `Assets.xcassets/AppIcon.appiconset/icon.png`. The mascot retains real alpha transparency; the icon is an opaque 1024×1024 PNG packaged for iOS.

Prompts used:

- Mascot: “Change only the existing green scarf to Fox navy #002D56 with restrained darker folds and lighter blue highlights. Keep the golden cub, rosettes, eyes, expression, pose, proportions, tail, cream belly, positioning and illustration style. Preserve a truly transparent background; no new clothes, text or logos.”
- Icon: “Change only the cream background to flat solid Fox navy #002D56 (RGB 0,45,86) and the green scarf to the same navy with subtle fold shading. Preserve the golden cub's face, proportions, style, placement and close crop. Opaque square, no rounded mask, logos or added elements.”
- Icon refinement: “The background is too light/textured: replace only it, including corners, margins and the bottom strip, with one flat dark navy #002D56, no texture, gradients or highlights. Keep every foreground element unchanged.”

The refined icon foreground is preserved at `content/artwork/fox-icon-foreground.png`. A built-in background-extraction edit kept the navy-clad foreground and removed the generated blue field. `scripts/build_app_icon.swift` packages that cutout at 1024×1024 on an exact native sRGB `#002D56` fill, avoiding generated background color drift. It changes no illustration details and produces an opaque RGB PNG for the icon catalog.

Extraction prompt: “Remove only the blue background, including the bottom strip. Preserve the leopard foreground's cropped head/upper-body, golden colors, eyes, pattern, expression, navy scarf, outlines, scale, placement and square composition. Keep clean alpha edges and output a truly transparent PNG; no added elements.”

## Icon bottom-edge repair — October 8, 2026

The built-in image-generation tool extended the cub's shoulders and cream belly through the bottom of the square canvas, eliminating the background strip beneath the mascot. The transparent result replaces `content/artwork/fox-icon-foreground.png`; the native icon packager writes `Assets.xcassets/AppIcon.appiconset/icon.png` on exact Fox navy. The generated original is retained at `/Users/diego/.codex/generated_images/01a11a73-57f0-7f83-a65a-2a2c0d8daf70/exec-245646d1-9d3e-46f3-a807-807fa6d1c165.png`.

Edit prompt: “Preserve the leopard cub's exact face, large eyes, ears, spots, smile, illustration style, head size and position, and navy #002D56 scarf. Fix only the lower body: naturally extend the existing golden shoulders and cream belly all the way through the bottom edge of the square canvas, as a tightly cropped bust portrait. The torso must visibly continue beyond the bottom canvas edge, with no transparent horizontal gap below it. No feet, no extra objects, no border, no background. Keep true transparent background around the head and shoulders and clean alpha edges. Maintain square composition and the current character identity.”
