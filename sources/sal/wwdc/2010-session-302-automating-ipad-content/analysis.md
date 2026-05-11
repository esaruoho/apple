# WWDC 2010 Session 302 — Automating the Creation of iPad Content (Analysis)

**Speakers:** Francois Jouaux (Senior Manager of System Tools / Engineering Manager of Automation; intro) + Sal Soghoian (main, the demo body)
**Subtitle:** *"Tools for the New Desktop Publishing Revolution"*
**Year:** 2010 (Snow Leopard era; iPad just shipped in April)
**Source:** https://nonstrict.eu/wwdcindex/wwdc2010/302/

## The historical position

This is **the iPad-launch automation talk**, delivered weeks after the original iPad shipped. Sal's job in this session is to answer the existential question facing the AppleScript community in April-June 2010: *if Apple's future is a sealed touch device with no scripting, where does automation fit?* His answer is the **content pipeline**: automation lives upstream of the device, on the Mac, producing the HTML/EPUB/Web-App bundles that the iPad consumes.

This is the **pivot to content-pipeline automation** — a vision Sal will keep refining through 2014 (Books/Markdown), 2019 (Tools Conference), and 2023 (CCATP). It is also where Francois Jouaux appears as Sal's engineering manager, which dates the org structure of the Automation Technologies group at Apple to 2010.

## Sal's framing — automation as the through-line of every content revolution

> *"This was a groundbreaking point when automation and publishing combined for the first time electronically… because what AppleScript and automation delivered was speed, accuracy, consistency and scalability."*

The **four whys** (consistency / accuracy / speed / scale) from 2003 return verbatim, but the rhetorical move is bigger: Sal narrates **three content revolutions** — desktop publishing (PostScript + Quark + early AppleScript, ~1990–1993), the commercial Internet (CSS/RSS/HTML, late 90s), and now iPad (HTML5 + CSS3 + JavaScript, 2010). In each one, automation was the load-bearing layer that made the pipeline economic. The argument: **content revolutions don't happen without automation**, and the iPad is the next one.

Biographical anchor: *"I am officially the Product Manager for Automation Technologies at Apple Computer for the last thirteen years."* 2010 − 13 = **1997**.

## What Sal covers (the substance)

### 1. The "I don't make iPad apps, I make iPad content" thesis

> *"By itself, it's just a really handsome well-designed tool. It doesn't have impact until you put something on it… It's a great device, but without the content that you produce and others produce it's just a device."*

Content vectors onto the iPad: native apps (out of scope), iWork productivity files, EPUB via iBooks, podcasts, and the headline — **HTML5 Web-Apps** served from a folder or hosted on MobileMe. The Web-App is the loophole: no App Store review, no Xcode. **The user-side automation path onto a sealed device.**

### 2. Three scenarios, demonstrated live

| Scenario | Tool stack | Deliverable |
|----------|-----------|-------------|
| **Contextual tools** | Automator service + `Encode Media` action | One-click "make this video iPad-sized" droplet, built live in 30 seconds |
| **HTML Template Publishing** | Single-page Web-App + Photo Carousel + EPUB Automator action | Filled-in HTML bundle on the desktop |
| **Interactive Web** | AppleScript app + Apache + Aperture + Smart Album | Round-trip image-approval workflow over the network |

### 3. The 30-second John Gruber droplet

Sal reproduces the workflow Gruber tweeted about — *"wish I had a droplet that could turn high-res H.264 into Apple TV-size H.264. Took thirty seconds to make one."* Sal opens Automator, picks "service", drops in `Encode Media`, ticks "Show When Run", saves it. The point: **the user is the automation author.** WWSD #1 operationalized for the iPad era.

### 4. The HTML Template Publishing pattern

> *"Once you understand it you can spend a lot of money on pre-done systems that do exactly the same thing that you can do yourself."*

Three-layer recipe:
- **HTML5** = structural frame (video/audio tags, web fonts, SVG, canvas, WebKit transitions)
- **CSS** = positional/visual layer (placeholders fed by the interface)
- **JavaScript** = the wiring (clicks trigger CSS transforms)

A Web-App is a **folder**: `index.html` + CSS + JS + media + a **cache manifest**. The cache manifest is the trick — once Alice loads the bundle once, she can read it offline. **No app store. No Xcode. No certificate. A folder.**

Development model:
1. Design/steal an HTML template; insert placeholders at key points
2. Build a Cocoa-bindings interface that gathers media + settings from the user
3. Add the code that replaces placeholders and scales media

**The 2010 version of the droplet-with-preferences pattern (WWSD #38),** lifted to HTML bundles.

### 5. The Alice in Wonderland demo arc

Sal runs three demos on his niece Alice's favorite book:
1. **Single-page Web-App** — Alice Goes to Tea, banner-image generator, LibriVox audio, Creative Commons license. Drag to MobileMe → full-screen on iPad with offline cache.
2. **EPUB book** — `Create and Sync Electronic Book` service. Select chapters in Finder, pick cover, click Continue. Service generates EPUB, adds to iTunes, syncs to iPad.
3. **Photo carousel Web-App** — Tropical Fish with bubble audio, caption from metadata, video integration.

Alice as anchor is deliberate: she's **his actual niece**. The content is **personal**, not corporate. *"I want to make sure that she can use that."*

### 6. The Publish-for-Approval round-trip — automation as a CGI

> *"In this scenario, the automation not only builds the website, turns it on on his computer and hosts it. But it also acts as a CGI intermediary, so that when the client responds it triggers something in Aperture."*

Pipeline:
1. Photographer in Cupertino selects images in Aperture
2. AppleScript app exports them, builds a mini-site, turns on Apache (`/etc/apache2/`), opens preview, mails link
3. Client in Paris taps the link, selects approved images, hits Submit
4. CGI flips an `Approved` metadata tag on each image back in Cupertino
5. Aperture Smart Album with `keyword:Approved` populates **live**

**The Mac is the server. The AppleScript is the CGI. Aperture is the database.** Built into 10.6 — Apache is one `apachectl start` away. **The LAMP-stack analog has been in macOS the whole time.**

## Verbatim Sal-voice signatures

- *"Sick, sick, sick. Anybody who gets up at 9:00 in the morning to hear me talk is insane."*
- *"How many times have you just wanted a quick tool, quick and easy tool for compressing video? Why do I have to open up an application to do that? I've got all of Core Video at my disposal."*
- *"This is what happens when you live on the bleeding edge. Ah! All right. Whoa, down the Rabbit Hole."*

## WWSD-relevant takeaways

- **WWSD #1 extended to sealed devices.** iPad is read-only at the app layer but wide open at the content layer. Web-App folders preserve the user-author principle even when Apple's own platform won't.
- **WWSD #2 (local-over-cloud) embodied** by the MobileMe + Apache + folder model. User owns the stack end-to-end.
- **Four whys reasserted verbatim** seven years after 2003. Vision-stability anchor confirmed.
- **HTML5 Web-App folder = 2010 droplet-with-preferences (WWSD #38).** Same shape, different output.
- **Candidate WWSD #41 — Content automation outlives the device.** Sealed devices don't kill automation; they relocate it upstream into the pipeline. The Mac becomes the **content factory** even when the consumer surface is locked down.

## Reusable for the apple repo

- **`bin/apple-html-bundle.py`** — port Sal's Web-App template. Inputs: title, subhead, author, image, audio, body text. Outputs: `index.html` + cache manifest + media folder.
- **`bin/apple-publish-for-approval.sh`** — Sal's live-Apache + AppleScript-CGI pattern is **directly reproducible in 2026** (Apache still in Sequoia via `apachectl`, Photos scriptable via Image Capture Core).
- **EPUB Automator action probe** — is `Create and Sync Electronic Book` still in `/System/Library/Automator/`? If retired, document the retirement.
- **Padilicious.com Wayback probe** — Sal stood up `padilicious.com` for this session. Wayback snapshots are primary-source Sal-authored HTML templates worth recovering.
- **Apache-as-personal-CGI generalization** — the Mac has always had a web server. Sal made it part of an automation pipeline 15 years before users knew. `painpoints/` candidate: *"why did Apple hide built-in Apache after Mountain Lion?"*
