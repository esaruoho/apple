# Session — screen-audio-record

Spawning conversation for `bin/screen-audio-record` (the report card is
`features/screen-audio-record.feature`). Faithful, not flattering.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/6d81d169-c28a-4913-9650-2716a635d7a5.jsonl`
- Session ID: `6d81d169-c28a-4913-9650-2716a635d7a5`
- Resume: `claude --resume 6d81d169-c28a-4913-9650-2716a635d7a5`
- When: 2026-07-02, ~00:45–00:54 EEST. Machine: macOS 15.6.1 (24G90).

## The exchange
1. Esa asked how to use QuickTime to record the screen AND an audio app's output at
   once — and explicitly rejected the fake-mic answer: *"the answer is not 'yeah let
   it play via speaker and go into microphone', that's junk!. do a proper apple
   solution for this, please."*
2. I verified the constraint rather than guessing: confirmed the Mac is on macOS
   15.6.1, and web-checked that the built-in ⌘⇧5 / QuickTime recorder exposes only a
   MICROPHONE picker — Apple omits system audio from the GUI on purpose. The genuinely
   Apple-native path is ScreenCaptureKit (`SCStreamConfiguration.capturesAudio`), which
   pulls audio off the system engine with no loopback driver, and an app-scoped
   `SCContentFilter` isolates a single app's sound.
3. Esa: *"please figure it out for me... build it... and i want a terminal command
   for this and it will start."* → build a compiled Swift CLI, no further questions.
4. I wrote `bin/screen-audio-record.swift`, compiled with swiftc (frameworks:
   ScreenCaptureKit/AVFoundation/CoreMedia/CoreGraphics/AppKit).

## Corrections / honesty notes
- First compile threw a real warning: `Recorder(opts).run()` created a temporary that
  ARC could deallocate out from under the async SCK callbacks (all `[weak self]`).
  Fixed by holding a global strong `let recorder`. Recompiled clean. This was a genuine
  lifetime bug, not cosmetic — left unfixed the callbacks could no-op.
- Did NOT stop at "it compiles." Ran a live 6s capture of Renoise, SIGINT'd it, then
  probed the output with AVFoundation: duration 5.48s, video avc1 3024×1964, audio
  'aac '. Both tracks real — verified, not asserted.
- Honest grades on the card: `--app` isolation, Ctrl-C finalize, and `--list` are
  `@hw-verified` (run live). `--system-audio` and `--also-mic` are `@built` — they
  compile and the logic is in place, but those specific branches were not exercised
  live this session. Sequoia's weekly screen-recording re-prompt is a `@note` boundary
  the code cannot suppress.

## Side effects surfaced
- Audio scope for `--app` relies on ScreenCaptureKit scoping capturesAudio to the
  filter's included application(s); with `excludesCurrentProcessAudio=true` the
  recorder's own process is excluded. If a future macOS changes filter→audio scoping,
  the isolation claim is the thing to re-test first.
