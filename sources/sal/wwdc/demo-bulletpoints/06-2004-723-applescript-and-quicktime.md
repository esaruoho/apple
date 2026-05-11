# WWDC 2004 #723 — A Powerful Combination: AppleScript and QuickTime (Tiger sequel)

**Speakers:** Stephen Tonna, Sal Soghoian, Ryan Lynch · **49:11** · Track: QuickTime
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2004/723/

> Continuation of WWDC 2003 #718. Tiger-era preview. **Headline addition: Automator + QuickTime integration.** See `01-QUICKTIME-PRO-AUTOMATION.md` for the QT Pro deep-dive.

## What's new since 2003 #718

### Frame-level scripting

Demo: **Typewriter Text Movie** — AppleScript creates a movie from scratch by adding frames one at a time:

```applescript
tell application "QuickTime Player"
    set newMovie to make new movie
    set textTrack to make new text track at end of tracks of newMovie
    repeat with i from 1 to count of words in "Hello World This Is A Test"
        make new text frame at end of frames of textTrack with properties ¬
            {text: (item i of words), duration: 60, ¬
             foreground color: {65535, 0, 0}, background color: {0, 0, 0}, ¬
             default font: "Helvetica", default size: 36}
    end repeat
end tell
```

You control: text content, duration, foreground/background color, font, size, justification, anti-aliasing. **Every property of a text frame is gettable + settable.** This is full per-frame programmatic control.

### Script templates folder

In the QuickTime Scripts collection's `script templates/` directory, Apple ships pre-written droplet skeletons. Add your 3-line action, save, drop in the menu. Templates for: working with the player, tracks, text tracks, movie templates, video tracks.

> *"All you have to do is open up this template, put your particular lines of AppleScript in there, save it, and then it will become a droplet that you can use just like the other QuickTime applets and droplets."*

## Automator + QuickTime (the Tiger headline)

### Workflow 1 — Batch playback property setter
1. **Get Specified Files** (drag movies in)
2. **Set Movie Playback Properties** (auto-play, auto-close, auto-quit, auto-present, presentation size)
3. Run

Result: movies self-present full-screen and close themselves on a customer's machine. Double-click, watch, done — no QuickTime UI touched.

### Workflow 2 — Batch annotate + browse
1. **Get Specified Files**
2. **Add Movie Annotations** (artist, copyright, performers — delete existing first if you want)
3. **Browse the Movies** — opens each in a web-style preview
4. Run

### Workflow 3 — Remote QuickTime Broadcaster control (★ the showpiece)

Ryan Lynch's two-machine demo:

- **Local machine workflow:**
  1. *Create Broadcast Settings* (256/192/standard/20fps, key frames, server URL)
  2. *Write to Text File* OR *Initiate Remote Broadcast* (the nifty one)
- **Remote machine:** has Remote Apple Events enabled in Sharing prefs + user account configured
- Local sends the .bsc file + start command via Apple Events over Wi-Fi
- Remote QT Broadcaster configures itself, starts broadcasting
- Local receives the stream

**Marketing:** Drag a workflow → broadcast video from a Mac across the room without touching it.

## Sal's pitch language

> *"The meeting of AppleScript and QuickTime has always been an incredibly fertile ground for creating very productive tools. Back in QuickTime 4, was the first time we had a scriptable dictionary in the QuickTime Player. And since then, the dictionary within QuickTime has grown and grown and grown."*

> *"The last thing you should have to do is some repetitive thing over and over again, like setting annotations to movies. It should always be an easy process. And now, with the introduction of Automator, it's going to be even easier."*

> *"Anybody can use this."* — said while showing Automator workflow editor

## Power features delivered

- **Frame-level AppleScript control** of text tracks (content, font, color, justification, anti-aliasing)
- **Script templates** — pre-built droplet skeletons in the QT Scripts collection
- **Automator workflows** with movie actions (Set Properties, Add Annotations, Browse, Encode)
- **Remote Apple Events for QT Broadcaster** — two-machine workflows over Wi-Fi
- **Tiger flakiness workaround:** Sal explicitly recommends copying the QT Player from Panther onto your Tiger machine because the bundled Tiger one was preview-buggy. (Period detail.)

## Marketing copy version

**Headline:** AppleScript ↔ QuickTime got even tighter in Tiger. Frame-level control. Pre-built templates. And Automator drag-and-drop workflows for batch video work — without writing a line of code.

**Audience takeaway:** if you missed the 2003 session, this brings you fully up to speed for Tiger. If you saw 2003, you came back for two things: Automator integration + Ryan's remote-broadcast demo. Both deliver.
