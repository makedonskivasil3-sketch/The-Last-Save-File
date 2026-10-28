# Movement acceptance route: results

Headless, scripted input, software rendering not involved (festival stepped at each frame length; the game in its real loop at the physics rate). Before: `b26aba0`. After: this commit.

## Before (b26aba0)

festival (custom movement, stepped):
| frame | moved after release | pointer arrival error | gate penetration | outside corner | inside corner | 0.5 stick | facing flips (±4° wobble, 1 s) | view bounds |
| 0.0069 s | 0.00 | 2.955 | 0.00 | 0.00 | 0.00 | 26 px/s, slide 4.32 | 144 | ok |
| 0.0167 s | 0.00 | 2.981 | 0.00 | 0.00 | 0.00 | 26 px/s, slide 4.29 | 60 | ok |
| 0.0333 s | 0.00 | 0.493 | 0.00 | 0.00 | 0.00 | 27 px/s, slide 4.43 | 30 | ok |
| 0.1000 s | 0.00 | 0.483 | 0.00 | 0.00 | 0.00 | 28 px/s, slide 4.71 | 10 | ok |
game (physics, 60 ticks/s): pushing into the crates 1 s: penetration 0.00 px; walking frames while blocked: 29; facing (0, -1); moved after release 0.07 px

## After

festival (custom movement, stepped):
| frame | moved after release | pointer arrival error | gate penetration | outside corner | inside corner | 0.5 stick | facing flips (±4° wobble, 1 s) | view bounds |
| 0.0069 s | 0.00 | 0.000 | 0.00 | 0.00 | 0.00 | 26 px/s, slide 0.00 | 0 | ok |
| 0.0167 s | 0.00 | 0.000 | 0.00 | 0.00 | 0.00 | 26 px/s, slide 0.00 | 0 | ok |
| 0.0333 s | 0.00 | 0.000 | 0.00 | 0.00 | 0.00 | 27 px/s, slide 0.00 | 0 | ok |
| 0.1000 s | 0.00 | 0.000 | 0.00 | 0.00 | 0.00 | 28 px/s, slide 0.00 | 0 | ok |
game (physics, 60 ticks/s): pushing into the crates 1 s: penetration 0.00 px; walking frames while blocked: 0; facing (0, -1); moved after release 0.07 px
