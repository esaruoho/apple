# WWDC 2010 #302 — Automating the Creation of iPad Content

**Speakers:** Francois Jouaux + Sal Soghoian · **53:07** · Track: Developer Tools (iOS, OS X)
**Subtitle:** "Tools for the New Desktop Publishing Revolution"
**nonstrict:** https://nonstrict.eu/wwdcindex/wwdc2010/302/

## The pitch — the iPad pivot

iPad shipped April 2010. Two months later, Sal is on WWDC stage answering: *if Apple's future is a sealed touch device, where does AppleScript live?* His answer: **the content pipeline. Automation lives upstream on the Mac, producing the HTML/EPUB/Web-App bundles the iPad consumes.**

This is the **pivot to content-pipeline automation** — vision Sal will keep refining through 2014, 2019, 2023.

## The "three content revolutions" framing

1. **Desktop publishing** (PostScript + Quark + AppleScript, ~1990-1993)
2. **The commercial Internet** (CSS/RSS/HTML, late 90s)
3. **iPad** (HTML5 + CSS3 + JavaScript, 2010)

**Each revolution had automation as the load-bearing layer.** The argument: content revolutions don't happen without automation.

## Three demos, escalating in ambition

### Demo 1 — The 30-second John Gruber droplet

John Gruber tweeted: *"wish I had a droplet that could turn high-res H.264 into Apple TV-size H.264."* Sal builds it live in 30 seconds:

1. Open Automator → Service template
2. Drop in `Encode Media` action
3. Tick "Show When Run"
4. Save as `Movie Bullet Encode Media`
5. Done

**The user is the automation author.** WWSD #1 operationalized for the iPad era.

### Demo 2 — HTML Template Publishing

The Web-App is a **folder**: `index.html` + CSS + JS + media + **cache manifest**. The cache manifest is the key — once loaded once, the iPad reads it **offline**. No App Store. No Xcode. No certificate. **A folder.**

Three-layer recipe:
- **HTML5** = structural frame (video/audio tags, web fonts, SVG, canvas)
- **CSS** = positional/visual (placeholders fed by interface)
- **JavaScript** = the wiring (clicks → CSS transforms)

Sal's Alice in Wonderland demos:
1. **Alice Goes to Tea** — single-page Web-App, custom banner, Lewis Carroll attribution, LibriVox audio. Drag to MobileMe → full-screen iPad with offline cache.
2. **EPUB book** — `Create and Sync Electronic Book` service. Select chapters in Finder, pick cover, click Continue. EPUB → iTunes → iPad.
3. **Photo carousel** — Tropical Fish, bubble audio, caption from image metadata, video integration.

### Demo 3 — Publish-for-Approval round-trip (the showstopper)

> *"In this scenario, the automation not only builds the website, turns it on on his computer and hosts it. But it also acts as a CGI intermediary, so that when the client responds it triggers something in Aperture."*

Pipeline:
1. Photographer in Cupertino selects images in Aperture
2. AppleScript app exports them, builds a mini-site, **turns on Apache (`apachectl start`)**, opens preview, mails link
3. Client in Paris taps link, selects approved images, hits Submit
4. CGI flips an `Approved` keyword on each image back in Cupertino
5. Aperture Smart Album with `keyword:Approved` populates **live**

**The Mac is the server. AppleScript is the CGI. Aperture is the database.** All in macOS 10.6.

## Power features delivered

- **Cache-manifest Web-Apps** — folder-on-MobileMe → offline iPad reading
- **`Create and Sync Electronic Book` Automator action** — EPUB generation built in
- **AppleScript as CGI** via built-in Apache (`/etc/apache2/`)
- **Round-trip image approval workflow** — local server + remote client + metadata writeback
- **Padilicious.com** — Sal stood up the companion site for this session with downloadable templates

## Sal's voice

> *"By itself, it's just a really handsome well-designed tool. It doesn't have impact until you put something on it."*

> *"This is what happens when you live on the bleeding edge. Ah! All right. Whoa, down the Rabbit Hole."*

Biographical anchor: *"Product Manager for Automation Technologies at Apple Computer for the last thirteen years."* 2010 - 13 = **1997**.

## Marketing copy version

**Headline:** The iPad is a sealed device. Your Mac is wide open. Build the content pipeline on the Mac — HTML5 Web-Apps, EPUBs, Photo Carousels — and ship them to the iPad as folders. No App Store. No Xcode. Just a folder.

**Audience takeaway:** if iPad shipping has you worried about AppleScript's relevance, this session is the architectural answer. Automation moves upstream into content production. The Mac becomes the content factory; the iPad is just the surface where the content gets consumed.
