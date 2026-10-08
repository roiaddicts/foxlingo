# Artwork provenance

The small leopard cub and matching app icon were generated with the built-in image tool on October 8, 2026. The supplied orange owl was a proportion and warmth reference. The mascot is an original golden leopard with rosettes, rounded ears, large eyes, a cream muzzle, tiny paws, and a green scarf. It uses a transparent background and appears at 70–140 points throughout the app. Reduce Motion disables its modest pose transitions.

- Mascot: `Assets.xcassets/Leopard.imageset/leopard.png`.
- App icon: `Assets.xcassets/AppIcon.appiconset/icon.png`.
- Downloaded badge and portrait URLs: `artwork-manifest.json`.
- Club badge source pages: `../../../content/club-artwork.json`.

Futbol11 portraits and UEFA badge URLs retain their source namespaces. Classic-squad portraits are joined by full name, never by colliding numeric IDs. Xolos’s badge comes from its official website; Riascos, Arce, and Saucedo portraits come from their named Wikipedia/Wikimedia images. Remaining club badges are obtained from the supplied seed, official club pages, or their Wikipedia infoboxes. These source images retain their original owners and licensing; the manifest records provenance rather than transferring image rights. Review source image terms when preparing public distribution.

Country flags are cached from the supplied Futbol11 nationality dataset (dataset 1), with explicit aliases for Czechia/Czech Republic and Türkiye/Turkey. Azerbaijan, absent from that dataset, uses FlagCDN. `content/country-artwork.json` records these name-to-source mappings. Cached image assets are used instead of flag emoji so the boards remain legible when emoji fonts are unavailable.

The explorer adds Di Stéfano's portrait from the supplied player record `player-1512`, explicitly mapped to canonical `entity-di-stefano` and cached offline. Match, two-leg tie, goal, city, and venue nodes use distinct system symbols; countries use their cached flags.
