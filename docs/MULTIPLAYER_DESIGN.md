# Multiplayer: design and tech plan (for approval)

**Status: proposal only. Nothing here is built.** The author asked on 2026-10-17 for a design plus a tech and cost plan *before* any building ("Look first, MP design").

## 1. The pitch

> Two to four intruders wake up in someone else's save. The owner wants all of you gone. There is one way out, and it might not fit everyone.

This is the single-player game's premise, widened. Each player is a character who shouldn't exist in Arin's save, and the owner hunts all of them at once. The tension the author asked for, "cooperate or turn against themselves", comes from three rules:

1. **Awareness is shared.** One meter for the whole group. Every glitch anyone uses raises it for everyone, so a reckless player endangers the rest.
2. **Help costs.** Hiding a friend, carrying them through a seam, or reviving them after the owner selects them always costs awareness or a turn of your own safety.
3. **Slot 2 has limited room.** The exit fits *N − 1* players by default. The group can find a way to fit everyone, but that path is harder and slower.

This keeps the single-player canon: Rue's story stays the solo campaign, and multiplayer is a separate mode set in "another save".

## 2. Modes

| Mode | Players | Summary | Build cost |
|---|---|---|---|
| **A. Co-op escape** (recommended first) | 2–4 | Everyone escapes or nobody does. Shared awareness, revives, split-up puzzles (one holds a door with PAUSE while another walks through). | Lowest: one team, no hidden roles |
| **B. Not enough room** | 2–4 | Co-op until the Edge; then Slot 2 takes N − 1 people. Players can vote, race, or betray (a glitch can push someone into the owner's light). The hard "everyone" ending exists. | Medium: needs the betrayal tools and their balance |
| **C. The owner's helper** (hidden traitor) | 4–6 | One player is secretly working for the owner: they can nudge awareness, mark players for the cursor, and lock a door once per act. The others win by escaping, or by unmasking the helper at a save point. | Highest: hidden information, voting UI, anti-griefing |

**Recommendation:** build **A** as the prototype, then add **B**'s Slot 2 rule as a toggle once A is fun. **C** only after real playtests of A and B.

## 3. How the single-player systems change

| System | Solo today | Multiplayer |
|---|---|---|
| Owner awareness | one meter, one target | shared meter. The owner *targets* whoever is most visible (Arin's cone, recent glitch) and says their name |
| Death | the run ends; the world remembers | you become a **ghost** for ~45 s: you can see the owner's cursor and warn others, but can't touch anything. Revive at a save point, or a teammate carries your "file" there |
| Persistent memory (`OwnerMemory`) | per player, across runs | **per lobby run only.** The owner remembers within the session ("you two always split up"), not across strangers' games. Each player keeps a personal Records/Journal |
| Glitches | yours | per player, with separate cooldowns; their awareness cost is shared |
| NPCs (Mira, Wren, Tobben) | quests | one escort at a time per group. Mira can only be walked by one player, and she remembers who |
| Quitting | counts as quitting (+purge) | dropping out turns you into a ghost; rejoining is allowed within 2 minutes |

## 4. Technical plan

### Networking model

- **Server-authoritative, host-based to start.** One player's game is the host and runs the owner AI, awareness and every threat. The others send inputs and receive state. This fits the code: `World`, `OwnerDirector` and `OwnerMoves` already run in one place.
- **Godot 4 high-level multiplayer:** `MultiplayerSpawner`/`MultiplayerSynchronizer`, plus RPCs for one-off events (death, glitch, dialogue).
- The work is large:
  - every `kill()`, `notice()`, `change_area()` and glitch call has to become host-only, with an RPC to clients;
  - the area loader must keep all players in **the same area** (the group moves through an exit together, the way the escort works now), or each area must exist on the host at once.

  **Recommendation: the same area, together.** It is much simpler and better for horror pacing.

### Transport (this is why a server is needed)

The live game is a **static site on GitHub Pages**. It can serve files, but it can't relay or match players. Browser players can only use **WebSocket** or **WebRTC**:

| Option | How | Pros | Cons |
|---|---|---|---|
| **WebRTC peer-to-peer + a small signalling server** (recommended) | Godot `WebRTCMultiplayerPeer`; a tiny WebSocket server only introduces players (room codes), then the traffic is direct | Cheap: the server only handles handshakes. Low latency. Works in browsers and desktop | Some networks block P2P, so a TURN relay is needed as a fallback (that costs bandwidth) |
| WebSocket relay server | `WebSocketMultiplayerPeer`; every packet goes through the server | Simplest to reason about; always connects | The server carries all traffic, so it costs more and adds a hop of latency |
| Desktop-only Steam / ENet | `ENetMultiplayerPeer` or Steam sockets | Robust, free relay via Steam | No browser play; needs a Steam release |

### Hosting and cost (estimates, to be confirmed with real prices before buying)

| Item | What | Rough monthly cost |
|---|---|---|
| Signalling server | A ~100-line Node or Godot headless WebSocket server on Fly.io, Railway or a $5 VPS | **$0–5** (free tiers often cover it) |
| TURN relay fallback | Managed TURN (for example Cloudflare Calls or Twilio) or self-hosted coturn on the same VPS | **$0–10** at prototype scale; it grows with players behind strict NAT |
| Domain + TLS | Optional (browsers need `wss://`; most hosts provide TLS) | $0–1 |
| **Prototype total** | | **about $0–15 / month** |

A WebSocket-relay design for all traffic would be roughly 10× the bandwidth cost at the same player count.

### Accounts, safety, moderation

- **No accounts in the prototype.** Room codes only; names are random intruder handles ("FILE_07"), so there's **no personal data** and no free-text chat.
- **Communication:** pings and emotes only (a "here", "danger" and "help" wheel), which fits the setting and avoids moderation.
- **Mode C** needs anti-griefing (vote-kick) before any public release.

## 5. Prototype scope (proposal)

The goal is to find out whether two people in Arin's room and the square are scary *and* fun together.

1. Lobby: host or join by a 5-letter room code (WebRTC + signalling server). 2 players.
2. Arin's room → the square → the archive only. Shared awareness, Arin and the cursor.
3. Two glitches (UNLOCK, PAUSE), ghost-on-death, revive at the save point.
4. One ending: both reach the archive desk.
5. Out of scope: the persistent owner, NPC quests, the Edge/Slot 2, modes B/C, gamepad split-screen.

**Effort estimate:** 3–5 focused build sessions for the prototype, plus server setup. Most of the work is making `World` host-authoritative without breaking the solo game. All solo tests must keep passing.

## 6. Risks

- **Horror gets weaker in groups.** Mitigation: split-up puzzles, limited pings, the owner speaking to *one* player at a time.
- **Refactor risk to the solo game.** Mitigation: multiplayer runs in a separate `NetWorld` subclass; the solo code path stays the default and the existing test suite guards it.
- **Web P2P reliability.** Mitigation: a TURN fallback, and a WebSocket relay as a last resort.
- **Running costs.** Small at prototype scale. Review before any public launch.

## 7. Decisions needed from the author

1. Approve **mode A** as the prototype (and B as the next step)?
2. **WebRTC + signalling server** (recommended) vs a WebSocket relay vs desktop/Steam only?
3. Which host for the signalling server (Fly.io / Railway / a VPS), and is a budget of up to ~$15/month OK?
4. Does multiplayer stay outside Rue's canon ("another save"), as proposed?
