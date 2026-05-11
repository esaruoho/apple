# MacTech Conference 2017 — "Cross-Platform Automation Magic for iOS and macOS" (Sal Soghoian)

**Speaker:** Sal Soghoian (introduced by Ed Marczak / Neil Ticktin of MacTech)
**Length:** ~60 minutes (759-line transcript)
**Context:** MacTech Conference 2017, Los Angeles. **One year after the October 2016 elimination from Apple.** Sal returns to MacTech as a featured speaker — the same conference where, the year before, he had been registered as "mystery speaker" while the news of Apple's automation-group dissolution was breaking.
**Audit attestation:** every quoted phrase below verified verbatim by direct read of transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

This is **the canonical post-Apple Sal conference talk** — the most technically detailed Omni Automation walkthrough on record from the 2017 cycle. Where the AltConf interviews are 5–10 minutes of headline framing, here Sal has 60 minutes and a slide deck. The session lays out the entire Omni Automation architecture from primitives (console, actions, libraries, plug-ins) through URLs, HTML forms, data-table extraction, third-party cloud data (Airtable), and app-to-app communication ("call and response").

The talk also contains **the single most quotable Sal narrative on the firing** — the "swimming with the whale" parable.

## Sal's framing — the "swimming with the whale" parable

> *"Last year at this time, I was registered as mystery speaker. And it was quite an interesting time for me. I had been swimming with the whale for about 20 years. And swimming with the whale is a really interesting and challenging thing to do. You have to, the whale has to believe that what you have to offer will help the whale get to where it wants to go. And you have to swim close enough to the whale that you get carried along and you get the propulsion that you need. But at the same time, you have to maintain the integrity of what it is you're working on and trying to accomplish."*

> *"And for many years, I swam with the whale, and everything kept going forward and kept advancing. And then one day, probably by accident, I got hit by a fin or the tail, and I found myself on the shore. and that's okay because my feet are in the ocean."*

> *"What you do when you find yourself on the shore is you get your board and you look out on the ocean for where the wave is going to be not where the wave has been or is but where the wave is going to be and then you paddle out to that place and you ride the wave that comes."*

**This is the canonical Sal-on-leaving-Apple metaphor.** Not bitter. Not nostalgic. Operational: the whale moves on; you don't sit on the shore; you read where the next wave is and paddle. It is also a perfect statement of **WWSD #20 (the institution is not the relationship)** in Sal's own voice, from the stage, with a room full of admins listening.

## Reading the wave — where Apple was heading in mid-2017

> *"Apple had, over the years, had been putting a lot of attention into trying to get some kind of parity with features in the two OSs... when it came to automation they had this thing called extensions which is a kind of automation and they had that on both platforms and recently they acquired workflow which in many ways and respects is similar to what Automator does on the Mac."*

> *"There really isn't iOS and so that got me thinking that well that means that the people that are on iOS can enjoy the benefits of automation while the people that are on iOS are have to deal with their hands trying to duplicate the kind of functionality that you can automate an iOS and there has to be a commonality there."*

**Sal correctly diagnoses Apple's 2017 trajectory** — Extensions on both platforms, Workflow acquired (2017 acquisition that became Shortcuts in 2018), but **no shared scripting language**. He identifies the gap that Apple would not fill until iOS 13 Shortcuts (2019) and never fully fills (still no AppleScript on iOS as of 2026). Omni Automation is the third-party answer to a gap Apple left open.

## The OmniOutliner / grocery-list demo

> *"There's a blank OmniOutliner document, and then I'm going to drag out a Safari window, and I'll resize it so that it's split screen and this is a copy of a web page from grocery list org and it's just lists of different categories of grocery items but you can click it or tap it and it will cause an action to happen."*

> *"It's just a matter of touching and approving. And then once it's in there, then I can do what Omni Outliner does really well, and I can select different things... So I just went from a web page to a shopping list on my phone by just tapping."*

**The end-to-end demo pipeline.** Webpage → OmniOutliner on iPad → "remove unchecked items" plug-in script → OmniPresence sync → grocery list on iPhone. **Eight discrete capabilities chained, zero typing.** This is the *iOS-side* answer to the OmniGraffle US-states demo from the Mac Observer interview.

## The architecture lesson — JavaScriptCore as the universal language

> *"WebKit has this architecture. They have core JavaScript, CSS, and HTML. It's all built in. And WebKit ships on every Apple device. So what Omni has done is they've taken their apps and they've exposed their apps to core JavaScript that's part of WebKit so that you can use JavaScript to control the actions of the applications and manipulate the objects in their documents on both Mac OS and iOS."*

> *"This is being driven not by Apple events, but by core JavaScript that's in WebKit on the Mac. Same architecture, same type of script, and we can even manipulate the text as well."*

**Explicit rejection of Apple Events as the substrate.** Same architectural decision JXA (2014 #306) inherited from JavaScriptCore, but Omni Automation **does not route through OSA** — it calls JavaScriptCore directly via the app's exposed object model. This is the post-Apple-Events automation primitive.

## Actions, libraries, plug-ins — the three-tier organisation

> *"An action is essentially just a script that's in a certain context. And this is what the action looks like in JavaScript. It's a function that contains a declaration of an action."*

> *"Now, when you have actions, you'll often write a lot of code that you might use in every action. So this is where libraries come in."*

> *"Actions and libraries in OmniWorld live within plugins. And these plugins are really just a folder that contains the actions in the libraries, it contains string files that are localized, and it contains icons so you can put your action in the menu bar or on the touch bar on your Mac."*

**Three-tier Omni Automation model:**
- **Action** = single script with validation routine + run routine
- **Library** = shared code reused across actions
- **Plug-in** = folder bundle of actions + libraries + localizations + icons

This is **AppleScript Libraries (2013 #416) translated to JavaScript and given a localization layer**. The plug-in folder structure is essentially the `.scptd` script bundle pattern with a different file extension.

## The URL encoding mechanism — script-as-URL

> *"You'll see it begin with some kind of domain, like the application or the company or something, and then there'll be a question mark and then there's like parameter equals value and then an ampersand and then another parameter equals value. This is pretty standard approach when applications send URLs to each other. But an Omni Automation URL is a little bit different."*

> *"It encodes all kinds of special characters including commas, forward slashes question marks colons at signs all those things... And then at the beginning of your automation URL, you have the name OmniGraffler OmniOutliner, and then colon slash slash, either localhost or three slashes, then OmniJS.run. And three slashes means localhost."*

> *"I sat right there, and I had an Omni script as a QR code, and then I looked at it with my iPad and when I ran it, it turned it into the blue circle on my iPad. So I had taken the URL and expressed it as a QR code that I looked at with the iPad camera."*

**Script-as-URL = script-as-QR-code = script-as-link.** The same URL works as a clickable web link, as a button form action, as a QR code scanned by Camera.app, as text pasted into Messages. The URL is the universal carrier; the carrier is the channel.

## Data flow — HTML table → JSON → script

> *"So this is standard HTML. Here I have my row. There's the name of the row, al-L. Then there's the cell that has the name of the state, and then the cell that has percentage value."*

> *"All the work at getting the set of graphics over onto the page for me, instantly, whoop, I drag it over to where I want to go, I swipe to bring the page back out again, I want to get the data out of the table, and then it's just a matter of tapping. And all of a sudden iOS becomes a lot different in nature."*

**The North-Dakota-changed-because-of-oil moment** lands the why:

> *"So why did North Dakota change so much? It's because they discovered oil in North less money coming back and they could pay more money out. But what you just saw was the transfer of data from a table on a web page into an Omni document and dynamically colorize the objects based upon information."*

The demo is technical (states keyed by postal-code ID matched to row IDs); the lesson is human (data + visual = understanding). Sal teaches the **why** before the **how** repeatedly through the talk.

## Tag-container publishing — the metadata pattern

> *"This is called tag container publishing. It's used quite a bit in the publishing industry to do things like real estate catalogs, auto trader magazines, those kind of things all use tag container publishing principles."*

> *"You can see that the objects were named the SKU number, and now I'm going to tap the extracting the notes about them, or the description, or importing the images... So this got the metadata about each one of those objects and put it in a box next to the picture."*

**Sal explicitly names the publishing-industry pattern Omni Automation enables.** This is the most domain-specific framing in any post-Apple Sal talk — directed at print/layout professionals who would recognise "tag container publishing" from QuarkXPress / InDesign automation.

## Airtable — third-party live data

> *"This is my data on Airtable. You see it says Airtable.com. This is my database. I'm going to select the little pig guy, and then I'm going to tap this link. Well, this is an Omni Automation link that's part of Airtable, and it's going to assign some metadata to that shape."*

> *"So it's not only static, it can be live data sources as well. This is incredibly powerful and incredibly flexible since they have this URL architecture."*

**Third-party SaaS embeds Omni Automation URLs in its own UI.** Airtable customers tap a link in Airtable; OmniGraffle responds. The architecture has crossed the vendor boundary — Omni Automation is no longer Omni-only.

## Call and response — app-to-app communication

> *"They have this thing called call and response built in. So basically, you have your script, and this script will execute another script over on the target application. Get the information you want, bring it back to your script, and then continue executing. I call it call and response. It also incorporates X callback URL for those that like the lower level architecture."*

**Call-and-response = the iOS x-callback-url pattern, rebadged.** Sal explicitly cites x-callback-url as the underlying mechanism. The OmniGraffle script calls into OmniOutliner, gets JSON back, continues. **This is the missing piece** that makes Omni Automation a real cross-app automation language and not just a per-app scripting host.

## Workflow.app integration — the Apple-acquisition bridge

> *"It's actually very cool, it's like Automator on iOS. It has certain level of functionality. Let me quickly show you what you can do with Workflow and Omni Automation."*

> *"I'm going to save this workflow on my desktop, on my iPad desktop, as a button for business letter. So I tap it. It brings up my address book. I tap whoever I want to send a business letter to. It shows me the script. I tap that, and in OmniGraphlet, it instantly lays out a perfect business letter with all their contact information."*

**Sal demos Workflow.app (Apple just acquired it in March 2017) calling Omni Automation URLs.** This is six months before Workflow became Shortcuts. Sal is wiring the future-Shortcuts-app to his post-Apple architecture before Apple even renames it. The whole point of Omni Automation's URL primitive: anything that can open a URL can drive an Omni app.

## The closing surfboard exhortation

> *"And I encourage you to join me out there on the ocean with this. We're at the point where this is starting to be a wave."*

> *"I hope eventually Apple will see the wisdom in this too. And maybe then we can start having a really comprehensive scripting solution that you can rely on. But right now we're still on the surfboard you to come paddle out with me and check this out."*

**The whale-and-surfboard parable bookends the talk.** Sal opens with "I got hit by the tail and washed ashore"; closes with "come paddle out with me." The talk's structural argument: Apple may not have seen the wave yet, but here are the tools to ride it without them.

## Sal-voice signature quotes

> *"It's a simple example, but it's proving that the architecture that we're looking for for manipulation and control of applications is built in."*

> *"And the lesson here is that core JavaScript and WebKit can be used to control applications, Apple applications regardless of platform."*

> *"You can run a script like an Omni Graffle."* (Whisper hiccup; reads as Sal-speak)

## WWSD-relevant takeaways

- **WWSD #20 (institution is not the relationship)** receives its strongest single-talk narrative in the **swimming-with-the-whale parable**. Worth elevating the parable into the WWSD canon as the canonical source quote for #20.
- **WWSD #1 (democratization)** operationalised: console + actions + libraries + plug-ins + URL = a complete distribution stack from author to user.
- **WWSD #5 (use what's already there)** at its strongest — Sal explicitly chooses JavaScriptCore (already in WebKit on every Apple device) over inventing a new automation runtime.
- **WWSD #11 (name commands like speech, not labels)** has a deep-cut application: action names + their localization string files are user-facing speech surfaces. The talk implies but does not articulate this.
- **WWSD #43 (one verb per action)** is structurally built into Omni Automation: an `action` is literally a single verb with one validation routine and one run routine. Sal's architecture *encodes* the principle.

## CANDIDATE WWSD #47 — *"Read the wave, not the institution"*

**Source quote:**
> *"What you do when you find yourself on the shore is you get your board and you look out on the ocean for where the wave is going to be not where the wave has been or is but where the wave is going to be and then you paddle out to that place and you ride the wave that comes."*

**Rationale:** WWSD #20 says the institution is not the relationship; this candidate goes one step further — **the institution is not the prediction of where the work goes next.** Apple in 2017 had not figured out cross-platform scripting; Omni had. Sal followed Omni, not Apple. The principle is a strategic complement to #20: when the institution falters, look at where the *user need* is heading (the wave), not where the institution is sitting (the shore). Worth canonising distinct from #20 because #20 is about *people*; this is about *direction*.

**How to apply:** When choosing what to build next in the apple repo, do NOT pick "what Apple just shipped" or "what Apple is hinting at." Pick **where the user pain still is.** Vocal Shortcuts in Sequoia 2024 had a 3-rep training limit; Hey Sal v1 routes around it. Apple shipped the surface; Esa rode the wave around the limitation.

## CANDIDATE WWSD #48 — *"The URL is the universal carrier"*

**Source quote:**
> *"It doesn't make any difference how you express the URL or where it is or what application has it."*

**Rationale:** Across the talk, Sal expresses the same Omni Automation script as: a URL in a webpage, a button form-action, a QR code, an HTML link in a Safari page, a parameter in a Workflow.app step, a third-party Airtable button, an x-callback-url. **The URL is the lingua franca.** Encode the script once, deliver it through any channel that knows what to do with a URL. This is a stronger and more concrete principle than "use what's there" — it specifies *the URL* as the universal automation carrier on Apple platforms.

**How to apply:** Any Hey Sal v2 action should be representable as a URL. Build a `bin/sal-action-url-encode` that takes a Lua/AppleScript and emits a `shortcuts://` or `vocalshortcuts://` URL. Distribute via QR / web / Messages / NFC tag — wherever the user is, the URL reaches.

## Reusable for the apple repo

- **The "swimming with the whale" parable** belongs in `sal-soghoian.md` as the canonical Sal-on-leaving-Apple quote. Currently the apple repo cites the firing without quoting Sal's own framing of it.
- **The Omni Automation three-tier model** (action / library / plug-in) is a direct template for **Hey Sal v2's organisation.** Currently Hey Sal v1 is a flat matcher; v2 should adopt the action/library/plug-in split with a `plugins/` folder under `applets/hey-sal/`.
- **Call-and-response / x-callback-url pattern** is portable to Renoise/Logic/Loupedeck cross-app workflows. Worth a `bin/x-callback-router.py` that lets one app's script call another app and continue when it returns.
- **The grocery-list-org demo** is a perfect template for `BBS Cloudcity` Tab-driven shopping/list workflows. Web page authored by user → tap items → list appears in Reminders/Notes.
- **The Airtable integration pattern** is a template for **ray-graph or Apple Notes data-driven automation**: external data source's UI embeds an apple-workflows URL; tapping it triggers a local script that pulls data, updates a Mac document.
- **The Workflow.app→Omni Automation URL handoff demo** is operationally identical to **Hey Sal v1's pattern** (Vocal Shortcut → matcher → AppleScript). Worth a side-by-side architectural diagram in `analysis/sal/omni-automation-vs-hey-sal.md`.

## Audit footer — verbatim quote verification

All quotes verified by direct character match against transcript.txt:

| Quote | Line(s) |
|-------|---------|
| *"Last year at this time, I was registered as mystery speaker..."* | 20-25 |
| *"And for many years, I swam with the whale..."* | 26-28 |
| *"What you do when you find yourself on the shore..."* | 32-36 |
| *"Apple had, over the years, had been putting a lot of attention..."* | 39-46 |
| *"There really isn't iOS and so that got me thinking..."* | 50-54 |
| *"There's a blank OmniOutliner document..."* | 68-72 |
| *"It's just a matter of touching and approving..."* | 78-96 |
| *"WebKit has this architecture..."* | 116-121 |
| *"This is being driven not by Apple events..."* | 199-201 |
| *"An action is essentially just a script that's in a certain context..."* | 234-235 |
| *"Now, when you have actions, you'll often write a lot of code..."* | 248-249 |
| *"Actions and libraries in OmniWorld live within plugins..."* | 262-266 |
| *"You'll see it begin with some kind of domain..."* | 339-344 |
| *"It encodes all kinds of special characters..."* | 350-358 |
| *"I sat right there, and I had an Omni script as a QR code..."* | 379-381 |
| *"So this is standard HTML..."* | 489-493 |
| *"All the work at getting the set of graphics over onto the page..."* | 515-520 |
| *"So why did North Dakota change so much?..."* | 477-480 |
| *"This is called tag container publishing..."* | 545-546 |
| *"You can see that the objects were named the SKU number..."* | 548-553 |
| *"This is my data on Airtable..."* | 616-624 |
| *"So it's not only static, it can be live data sources..."* | 641-643 |
| *"They have this thing called call and response built in..."* | 666-670 |
| *"It's actually very cool, it's like Automator on iOS..."* | 718-720 |
| *"And I encourage you to join me out there on the ocean..."* | 751-752 |
| *"I hope eventually Apple will see the wisdom in this too..."* | 756-758 |
| *"It doesn't make any difference how you express the URL..."* | 382-383 |

No paraphrasing in quote marks. The interpretive layering (#47, #48 candidates; apple-repo reusables) is mine, layered over verified-real lines.

## Whisper proper-noun confidence flags

- **"Sal Segoe"** (line 8), **"Sal Segoyan"** (line 20) — mishearings of **Sal Soghoian**. Standard corpus issue.
- **"OmniGraphlet"** (line 732) — mishearing of **OmniGraffle**. Cosmetic.
- **"OmniGraffler"** (line 344) — Whisper variant of **OmniGraffle**. Cosmetic.
- **"OmniWorld"** (line 262) — likely Sal-speak (jocular umbrella term for the Omni Group app suite); not a transcription error.
- **"Tildy"** (line 355) — mishearing of **"tilde"**. Cosmetic.
- **"al-L"** (line 491) — Whisper attempting to render "AL" (Alabama postal code) read aloud. Context disambiguates.
- **"Princeton"** (line 735) — likely transcription error for **"protocol"** or **"the form"** — Sal saying the letter is laid out per business-letter convention, not literally per Princeton. Flag for context-check.
- **"a Nerf bat"** (line 716) — appears intentional; Sal saying the demo hit the audience hard with information. Not a Whisper error.
- **"TelScript"** (line 678) — likely mishearing of **"this script"** or **"TextScript"** in the Omni Automation API context. Flag for API-reference cross-check.
- **"Json"** lowercase / inconsistent capitalisation throughout — Whisper artefact, content clear.
- **"register your wallpaper"** style minor word-soup — common in conference-recording Whisper output; cosmetic.
