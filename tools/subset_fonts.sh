#!/bin/sh
# Rebuild the subset fonts in assets/fonts from the system copies (needs fonttools: pip install fonttools).
set -e
U="U+0020-007E,U+00A0-00FF,U+0100-017F,U+2010-2027,U+2030-203A,U+2190-2195,U+2022,U+2026,U+2212,U+25A0-25FF,U+2713,U+2717"
for f in Inter-Regular Inter-SemiBold; do
	pyftsubset /usr/share/fonts/opentype/inter/$f.otf --unicodes="$U" --layout-features='kern,liga,calt,tnum' --output-file=assets/fonts/$f.otf
done
pyftsubset /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf --unicodes="$U,U+2580-259F" --output-file=assets/fonts/DejaVuSansMono.ttf
