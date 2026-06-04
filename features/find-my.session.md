# Session — "Find my wife" in AppleBar, and the Find My automation reality

Faithful, not flattering. Audit trail for `find-my.feature`.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/e08dfd73-b702-44ad-9f8b-e58f14614d0f.jsonl`
- Session ID: `e08dfd73-b702-44ad-9f8b-e58f14614d0f`
- Resume: `claude --resume e08dfd73-b702-44ad-9f8b-e58f14614d0f`
- When: Thursday, 4 June 2026, ~15:00–16:30 EEST

## The request, and how it sharpened

Esa: add "Find My Wife" to AppleBar → Find My launched directly to <family member>. Then,
mid-build, he refined the routing: **"find" is ALWAYS the wife** ("wife" == "where's my
wife"); devices are rare — "find devices" boots Find My on the Devices tab; "find my
phone" means the iPhone 16 Pro. And he asked the real question: *do we really not have
any automation in Find My or any routes there?*

## What I found probing Find My (the honest map)

- **URL schemes**: Find My claims findmy / findmyfriends / fmf1 / fmip1 / grenada — but
  they only open the app; none deep-link a person or device.
- **AppleScript**: no .sdef — Find My is not natively scriptable.
- **Accessibility**: the sidebar tree is hostile. `entire contents` once returned 170
  elements, but per-element AND bulk title queries, the menu bar, and even toolbar-button
  queries all hit `-1712` AppleEvent timeouts. Names aren't in AXValue. Reliable
  AXPress-by-name is not practical.
- **THE route that works**: the **View menu** — `View ▸ People / Devices / Items`.
  Clicking those menu items via System Events switches tabs every time. That is the one
  dependable automation surface, and it's enough to always land on the right tab with the
  target listed.

So the split is honest: **tab = reliable (menu); specific row = best-effort (type-select).**

## Decisions

- **DRY**: one `bin/find-my <people|devices|items> [name]`, with `findwife` /
  `finddevices` / `findphone` as thin apple-do bindings pinning the tab + name. Esa raised
  DRY earlier this session; three near-copies would have contradicted it.
- **Selection** = list type-select, **frontmost-guarded** — if Find My isn't the active
  app, send NOTHING (the 2026-05-26 iMessage→iTerm keystroke-leak lesson). Hard-bounded
  (`timeout 8` + `with timeout 5`) so it can never hang.
- **Did NOT ship flaky AX traversal.** I chose the menu route over AXPress-by-name because
  the AX timeouts make the latter unreliable, and shipping something that hangs/misfires
  would betray both reliability and the no-UI-hijack rule.
- Wife's name (Olga) and phone model (iPhone 16 Pro) live in the apple-do bindings, not
  hardcoded in the tool — easy to change, reusable for other people/devices.

## Verified vs not

- **Routing — verified**: dry-run shows find/wife/where's-my-wife → findwife;
  find devices → finddevices; find my phone/iphone → findphone.
- **Tab landing — verified (screenshot)**: `apple-do findwife` opened Find My on People
  with "<family member>" listed (row 2).
- **Row highlight — @built, not guaranteed**: type-select fires when the list has focus;
  I could not confirm a consistent highlight (the list isn't always focused after the tab
  switch). Honest grade: the row is reliably *shown and one tap away*, not guaranteed
  auto-highlighted. I did not claim a selection I couldn't see.
- Process hygiene: every Find My / osascript probe was followed by an orphan check; all
  clean (the dns-sd/osascript timeout-orphan rule).

## Possible next turns
- If type-select proves to want focus: click the list region (AX or a known offset) before
  typing, or send one Down arrow to enter the list, then type-select.
- A `find-my items "<AirTag name>"` binding is already free (the tool supports `items`).
