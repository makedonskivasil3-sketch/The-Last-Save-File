# Fonts

| File | Source | License | Changes |
|---|---|---|---|
| `Inter-Regular.otf`, `Inter-SemiBold.otf` | Inter 4.0, The Inter Project Authors (github.com/rsms/inter), via the Debian `fonts-inter` package | SIL Open Font License 1.1 (`OFL-Inter.txt`) | Subset to Latin, Latin-1, Latin Extended-A, general punctuation, arrows and geometric shapes (the glyphs the game's text uses) to keep the web build small |
| `DejaVuSansMono.ttf` | DejaVu fonts (Bitstream Vera derivative), via the Debian `fonts-dejavu-core` package | Bitstream Vera license; DejaVu changes public domain (`LICENSE-DejaVu.txt`) | Subset the same way, plus block elements (used for redacted text) |

Inter is the voice of the world and the interface. DejaVu Sans Mono is reserved for the owner's system: file names, slot labels, system-space signage and redactions.

To re-subset after adding text in a new script, run `tools/subset_fonts.sh`; `tests/test_fonts.gd` fails if game text uses a glyph the fonts lack.
