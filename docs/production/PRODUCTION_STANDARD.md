# One finished standard before more production (2026-10-28)

**The representative section is the village square on a first visit.** It has every kind of moment the game needs:
- **Ordinary exploration:** the stall, the board, the lane.
- **Dialogue:** Wren's game.
- **Movement:** the crossing, the awning.
- **Danger:** Arin's round, the lamp, a hunt.
- **A quiet emotional moment:** listening at the well.

Bring this one place to a consistent standard before producing assets for the rest.

## The standard, and where the square stands today

| Dimension | Standard | Today (`main` + this branch) | Status |
|---|---|---|---|
| **Characters (world)** | One illustrated figure per character at 34–42 logical px: a readable silhouette, planted feet, a facing that doesn't flicker | Code-drawn figures (`HeroFigure`, `IllustratedCharacter`). Contact fixed (0 px drift); facing stable | **Provisional**: code art, consistent, not hand-finished |
| **Portraits** | Expression set per speaker; no mouth movement for written or mute speech | Live-art resolver; Arin never speaks; Tobben's written state honoured | **Provisional** |
| **Objects** | Recognisable before interaction, and named when focused | The well, save crystal, note and memory redrawn; a name line on every prompt | **Improved; provisional art** |
| **Lighting** | Afternoon key light; the lamp and the lantern as practical lights; threat lighting distinct | Area lights, sun beam, lamp cone | Provisional |
| **Materials** | Cobbles, flags, grass, wood, stone each distinct at 2× | Code-drawn | Provisional |
| **Typography** | One family, sizes 8–13 logical, outlined for legibility; captions on a backing | `UiStyle`; text-size setting | **Approved in practice**; needs human legibility checks |
| **Effects** | Corruption only on purpose (the owner's actions); reduced flashing honoured | Glitch FX scaled by settings | Provisional |
| **Transitions** | Area changes with a short card; story holds freeze threats | Implemented | Approved in tests; feel unverified |
| **Sound hierarchy** | Warnings first, then dialogue, then world, then music; deliberate silence at the departure | Mix and ducking (`AUDIO_DIRECTION.md`); silence in the festival break | **Needs human listening** |

**"Final" means approved by the author after seeing it in play.** Nothing in the table is final. That code art renders reliably does not make it final.

## Asset briefs for the section (to quote, not to buy)

| Asset | Count | Brief | Source of truth |
|---|---|---|---|
| World figures: Rue (missing + restored states), Arin, Wren, Tobben, Mira | 5 figures × 4 facings × idle, walk (8), startle, crouch | Match the code figures' proportions and palette; the feet must plant (stance = one stride of floor) | `ART_BIBLE.md` §Proportions, §Palette; `CHARACTER_ART.md` |
| Portraits for the same five | 5 × about 6 expressions | Existing expression keys | `PORTRAIT_ASSETS.md` |
| Square props | Well (with winch), lantern post, stall, board, crates, awning, lamp, chalk marks | The current code drawings as layout reference | `village_square.gd` |
| Voice pilot | About 10 lines (below) | Direction column in the manifest | `audio/voice/manifest.csv` |

## Performance pilot: representative lines (stable IDs)

Recorded acting only, with consent and commercial rights. Rules:
- **Arin is never voiced** (mute).
- **The owner's notes stay written:** they are typed text.
- **System lines stay system TTS or text.**

| Quality | ID | Line |
|---|---|---|
| Ordinary warmth | `npc.wren.edd16c20` | "You hide like a lamp post. Everybody can see you." |
| Warmth (a joke) | `npc.wren.7e2f7543` | "You can borrow my chalk. Give it back. It's my only one." |
| Disagreement | `npc.wren.4a8e8674` | "Here? Out here? The lamp goes right over this. Every single time." |
| Correction, pride | `npc.wren.59d96355` | "I fixed your R. Under the awning. You're welcome." |
| Fear held down | `npc.wren.720633aa` | "If they find out I hid you, they'll take me out of the save. It's okay. Go." |
| Vulnerability | `npc.wren.c623b01e` | "...Is there one of me?" |
| Relief | `npc.wren.93e68d6b` | "...Now there's one of me. Even if it's only chalk." |
| Restraint (the owner, spoken once) | `boot.3bbe8008` | "...who's in my save?" |
| Grief, flat (Rue's memory) | `memory.delete.60058b43` | (Memory 5) |

**The pilot's gate:** a human listens to each take against its caption and direction before any more lines are commissioned. Captions must match the take word for word. Speech must stay continuous across caption pages, with time left to finish reading (`CAPTION_VOICE_CONTRACT.md`).

## Cost

**Structure, with quotes to fill in:** `COMMERCIAL_DIRECTION.md` §7.

**Quantities for those quotes:**
- 5 world figures;
- about 30 portraits;
- one set of square props;
- about 10 pilot lines, out of about 300 in the manifest.

**No prices are given here**, because none have been quoted. **Nothing has been purchased, commissioned or generated.**
