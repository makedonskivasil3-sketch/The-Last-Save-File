# Presentation and gameplay pass

This pass strengthens the existing identity: a warm remembered afternoon, cold unloaded
space, a fragile memory melody, and an intruder learning how to survive.

## Bugs and usability

- **Frame-dependent title corruption:** glitch and recovery probabilities now use elapsed
  time, preserving the intended 60 Hz pacing on displays with other refresh rates.
- **Unstable interaction prompts:** the current valid target stays selected until a second
  object is at least six pixels closer. Leaving interaction range still clears the target;
  Pip retains the existing lower priority.
- **Misleading tutorial context:** tips dismiss when their area is left. Only the opening
  room's door can trigger its seam-puzzle lesson; the house door no longer triggers it.
- **Large-text settings overflow:** the settings controls scroll and follow focus, while
  Back stays outside the scroll region. Reviewed at the game's 640×360 logical viewport.
- **Story text ignored text speed:** cinematic typing now respects Slow, Normal, Fast,
  and Instant, matching dialogue.
- **Order-sensitive music regression:** the cold-start test now examines title setup
  before background processing, rather than assuming synthesis cannot finish in two frames.
  It also checks that setup did not synchronously populate the music cache.

## Visuals and sound

- Procedural title skyline with warm window light, drifting dust, and a cold wire grid.
  The menu has a dark centre to preserve text contrast.
- Area-specific dust uses deterministic positions, leaving gameplay randomness alone.
- Village and house sunlight use the existing awareness-reactive SunBeam system. The
  empty Player 2 room remains cold, following the art direction.
- The existing memory melody now also plays quietly in the village and Archive. It
  recedes during dialogue and danger, and builds through the existing background job budget.
- Optional spoken dialogue and story scenes use English system voices. Narration is off
  by default and follows Master/Voices levels. It pauses with play, stops on dialogue close
  and scene exit, and replaces synthetic dialogue syllables when available. Story scenes
  allow speech to complete while retaining manual advance.

## Validation

- Full Godot 4.3 suite: **245 passed, 0 failed**, exit 0, in 792.0 seconds.

- Five new functional tests cover stable focus, range, actual interaction, adaptive music,
  narration settings/captions, tutorial context, and dialogue narration handoff.
- Reviewed screenshots of the title, normal/large-text settings, village, house and Archive.
- Exported the Linux game pack and launched it from outside the checkout with Godot 4.3.
- The message-ending playthrough bot passed at its supported 3× speed: one session,
  all five memories, Pip found, zero deaths and zero stalls (80.6 real seconds).
- Live narration passed dialogue, pause/resume, close-to-stop, cinematic completion and
  clean exit checks using English eSpeak voices through Speech Dispatcher. Tested both
  0.11 and 0.12 clients. Audio was routed to a null device, so audible quality was not judged.

## Limits

Narration uses system speech, not recorded voice acting. It requires a compatible system
speech service and English voice; Linux needs Speech Dispatcher. Voice availability is
checked once per game process, so restart after installing a voice. Platforms without a voice
retain captions and procedural character sounds. Windows, macOS, browser narration, real
controllers and physical mobile devices were not tested in this cloud pass. Godot still emits
its pre-existing ObjectDB cleanup warning on some test exits.
