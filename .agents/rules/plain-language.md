---
paths:
  - "design/**"
  - "production/**"
  - "prototypes/**"
  - "docs/architecture/**"
---

# Plain Language Rules

The user directs this game and playtests it, but is not a game developer.
Everything they must read or approve is written for a non-developer: short
sentences, everyday words, no internal codes, no jargon without a five-word
explanation, no metaphors.

## The rules

- Anything put to the user for approval — a document, a decision, a question —
  opens with a section `## In plain words`, at most ten lines. It says what the
  player would see and feel on screen, what the user is being asked to choose,
  what happens if they say yes, and what happens if they say no.
- Numbers are shown as something a player can picture, next to the raw value.
  Example: "crosses the screen in about two seconds (speed 960)".
- Give one recommendation, stated first, with the reason in one sentence.
- Status words are always one of: done, in progress, planned, not planned,
  waiting on user.
- Feel values in a prototype are tuned by playing. The playtest verdict log
  (`production/playtests/VERDICTS.md`) outranks every design document; when
  they disagree, the verdict log wins and the document is corrected.
- Never ask the user to approve more than five items at once.

## Good example

> ## In plain words
> We recommend yes: this speed felt right in the last playtest.
> You press right and the heroine runs at full speed at once, and stops the
> moment you let go. We ask you to approve the run speed: 960, which crosses
> the screen in about two seconds. Say yes and v3 keeps this speed. Say no and
> we tune it again after your next playtest.

## Bad example

> ## In plain words
> We propose to raise the horizontal velocity constant from 480 to 960 px/s to
> match the acceleration curve in SYS-MOVE-01, pending TR-114 sign-off.
