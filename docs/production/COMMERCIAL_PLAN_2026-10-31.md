# Commercial plan (2026-10-31)

**Status:**
- A recommendation for the author. Nothing in it has been bought, published or signed.
- No player data exists yet. Every number below is either cited, with its source, or marked as an assumption.
- This plan builds on `PRODUCT_SPEC.md` (top page) and `docs/prompts/RELEASE_SPRINT_TO_CHRISTMAS_2026.md`.

## The facts that constrain the plan (checked 2026-10-31)

| Fact | Source |
|---|---|
| Steam Direct costs US$100 per app. Recoupment appears as a separate line in the monthly report. The often-quoted "returned after $1,000 of sales" threshold comes from 2017 press coverage and isn't stated on the current page, so treat it as unconfirmed | [Steamworks: app fee](https://partner.steamgames.com/doc/gettingstarted/appfee); [PC Gamer, 2017](https://www.pcgamer.com/uk/valve-reveals-steam-direct-fee-upcoming-changes-to-the-store) |
| A new product needs a Coming Soon page live for at least two weeks before release. Valve asks for review requests at least 7 business days before the page should go live | [Steamworks: Coming Soon](https://partner.steamgames.com/doc/store/coming_soon) |
| Steam Next Fest, February 2027: **22 Feb – 1 Mar 2027**. Registration closes **10 Jan 2027**. Required items due for review by 8 Feb. A game may take part in Next Fest only once. The next edition is 14–21 Jun 2027 | [Steamworks: Next Fest Feb 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027); [PC Gamer](https://www.pcgamer.com/games/steam-reveals-all-the-sale-dates-and-themed-events-for-the-first-half-of-2027/) |
| First-week sales relative to launch wishlists: GameDiscoverCo's median for 2024–25 titles with over 25k wishlists is about 0.15×, or 0.10× above $10. An earlier sample (700 games, at least 5k wishlists) gave about 0.2×. Studies differ in their samples, titles vary by 10–20× either way, and better-reviewed games convert more | [GameDiscoverCo via GameDevReports](https://gamedevreports.substack.com/p/gamediscoverco-the-state-of-steam); [GameDiscoverCo benchmarks](https://gamedevreports.substack.com/p/gamediscoverco-conversion-benchmarks) |

**What this means in practice:** launch sales scale with the wishlists gathered before launch. A page with few wishlists sells few copies, whatever the game's quality. That is arithmetic from the medians above, not a forecast for this game.

## Recommendation

**Route B: a store page with a free demo before Christmas, then Next Fest in February 2027, then launch in the weeks after.** Route A (release on 10 Dec 2026) remains possible but is the weaker commercial choice. The Christmas sprint brief explains the trade-off.

1. **Now to mid-November:**
   - Run the first playtest round (`playtest/RUN_A_ROUND.md`). It is still the most important missing evidence.
   - Measure the time to the first ending. **No price until this is measured.**
2. **By late November (author actions):**
   - Steamworks account, fee and tax forms.
   - Capsule art and key art, commissioned or licensed with a written assignment of rights.
   - The Coming Soon page with an honest description.
3. **December:**
   - A public demo build.
   - Choose between the two demo endpoints after the playtest. Both are in the code:
     - `?demo=1`: ends under the Archive's arch;
     - `?demo=workshop`: the candidate; it ends after the workshop repair and Wren noticing it.
   - Use the demo to collect wishlists and "Report a problem" feedback.
4. **Register for Next Fest by 10 Jan 2027.** Submit its items by 8 Feb. Take part on 22 Feb – 1 Mar.
5. **Launch:**
   - **When:** two to six weeks after Next Fest. The exact date is the author's call, checked against Steam's sale calendar.
   - **Price:** set from the measured length (bands in the Christmas sprint brief).

## Why the demo endpoint matters

- **The current demo** ends before any mission is finished (register: DM-1). It shows the premise and the threat, but not the game's third promise ("the people in the save matter").
- **The candidate** ends on a finished, remembered act:
  1. Rue repairs a light herself;
  2. she may sign the fifth lantern with her name;
  3. Wren notices.

  It still stops before the Archivist, the CHARACTER FILE, the Edge and every ending. Demo saves are kept apart from the full game (`OwnerMemory.DEMO_SAVE_PATH`).
- **Which converts better** is a playtest question, not something to assume. Two groups, one per endpoint, and one question: "would you buy the full game?"

## What must not happen

- **No spending, signing or publishing without the author.** This includes the Steam fee, art commissions and store pages.
- **No voices** without commercial rights and consent. No cloned voice of anyone.
- **No promised sales.** The medians above describe other games.
- **No "2–3 hours" claim** anywhere public until the length is measured.

## Revenue frame (assumption, to replace with data)

The arithmetic, as a template:

`launch wishlists × 0.10–0.20 (cited medians) × price × (1 − Steam's share, taxes, refunds)`

Fill it in only with real wishlist counts and a measured price.
