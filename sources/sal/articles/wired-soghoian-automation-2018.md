---
title: How One Apple Programmer Got Apps Talking to Each Other
author: Jordan McMahon
publication: WIRED
section: Gear
published: 2018-06-02 07:00 AM
source_url: https://www.wired.com/story/soghoian-automation/
archive_url: https://web.archive.org/web/20180602160148/https://www.wired.com/story/soghoian-automation/
local_html: wired-soghoian-automation-2018-wayback.html
local_pdf: ~/Downloads/How Apple Programmer Sal Soghoian Got Apps Talking to Each Other _ WIRED.pdf
photographer: Phuc Pham
tags: [wwdc, wwdc2018, apple, programming, automation]
---

# How One Apple Programmer Got Apps Talking to Each Other

*Jordan McMahon — WIRED, 2018-06-02*

> Sal Soghoian is known as "The Dean of Automation." — Photo caption (Phuc Pham for WIRED)

## Opening (the Jobs confrontation)

In July 1997, then-CEO Gil Amelio had just been ousted and Apple's stock was plummeting. To right the ship, Apple brought Steve Jobs back as interim CEO. Jobs went on a campaign to salvage Apple's remaining resources by hacking and slashing under-performing departments.

> "It used to be easy when we were 100 times better than Windows. But now that we're not, you don't know what to do." — Steve Jobs to the room

Two years earlier Jobs had quipped that Microsoft "had no taste."

Sal Soghoian, Apple's product manager of automation, didn't like that.

> "No, you're wrong," Soghoian told the notoriously brutal CEO.
>
> Jobs fired back: "And you are?"
>
> "I'm Sal Soghoian, and you're wrong. My technology is better than Windows."

Soghoian was the first in the room to challenge Jobs:

> "I sort of saw it as 'I might be this dog on my square yard of dirt, but I know every bit of that square yard and you're stepping on my yard,'" he says, "'I'm gonna bite your leg.'"

Jobs was gauging the room to see who was passionate enough to fight for their work. Those were the people he wanted to keep. Soghoian passed the test.

## Frame

Soghoian builds technology that lets users hand the tedium of repetitive grunt work off to their computers in creative ways. In the early 2000s he created the original Automator. A decade later, hungry iOS developers were inspired to hard-code a way for apps to share information between each other — building on Soghoian's work — making iOS more elegant and useful. Soghoian's Apple position was eliminated in 2016. He now works with The Omni Group.

## Follow the Script (AppleScript origins)

In 1993, Apple released AppleScript — a simplified language for controlling applications on the Mac. You couldn't build full applications with it, but you could write tiny bits of code that commanded programs to run repetitive tasks in the background.

Key to AppleScript's success: it didn't rely on esoteric syntax; you could write in something close to plain English. Typing `tell application "Microsoft Word" to quit` would shut Word down — no hiccups. You could turn emails into to-do list items, or find all files created on a given date and drop them into a specific folder.

> "[AppleScript] put incredible power in the hands of regular users without putting a lifetime of effort into this language." — Steve Wozniak

Same year as AppleScript released, Soghoian copped a used Macintosh from a friend and started fiddling. He used it alongside his favorite design applications to whip up menus for bars and restaurants. He even wrote a script for *Better Homes and Gardens* to format all of its recipes for easy printing.

Soghoian started sharing his scripting chops with businesses looking to knock inefficiency out of their workplaces.

> "It's very empowering to give somebody that ability to suddenly change the way they work and enable them to do great, complex things to grow their business." — Sal Soghoian

His presentations caught Apple's attention. **In 1997 he was hired as the company's product manager of automation technologies.**

> "[Sal is] a combination of geek with mature sophistication." — Steve Wozniak

## Demo Days (Automator origin, the hallway stakeout)

Seven years later (2004), Soghoian had a hunch about AppleScript's future. While simple, it still bore a complexity that kept it beyond the reach of casual Mac users. What it really needed was a simple graphical interface. Soghoian started building a tool on the Mac desktop to make scripts with a couple clicks of the mouse — much easier than writing out full phrases. He called the program **Automator**, and once it was built, started pitching it to anyone at Apple who would listen. Nobody was biting.

WWDC was coming up. Soghoian tried working his way into the office where Jobs's crew was meeting, hoping to give a demo, but couldn't get in. **So Soghoian camped out in the hallway from 10 am to 5 pm, vowing to stay put until he had a minute with Jobs.**

As the CEO left the office, he saw Soghoian lingering and asked what he wanted to talk about.

Game face on, Soghoian told Jobs: **"Automation, but for the rest of us."**

They scurried into the conference room for a private demo. Automator's window had a grid of applications in the upper-left — Finder, Alarm, Mail, Pictures, Internet, Music. Under each category was a list of all the functions Automator could make the apps complete. By selecting functions one by one, you could string together as many commands as you wanted to build a workflow. Anyone with a mouse could change the typefaces in a folder full of Word documents — or, in Soghoian's actual demo, take a Safari webpage of family-photo thumbnails, find the full-sized versions, load them in iPhoto, and burn them to a DVD.

> "Stop! I want robots for icons." — Steve Jobs

A few months later, before Soghoian hopped on stage at **WWDC 2004**, he and Jobs ran through rehearsal after rehearsal.

> "He'd tell me 'No, Saul, you want to do this.' He never quite got my name right." — Sal

That June, Jobs introduced Soghoian to the WWDC crowd:

> "I'd like to invite Saul up on the stage, whom you all know."

The next day, Soghoian found a new name tag on his office door: **"Saul, whom you all know."** Automator shipped on **April 29, 2005**, robot icon and all.

## Tiny Tasks (x-callback-url and iOS automation)

By 2011, much of computing had shifted to mobile. iOS apps had no way to share information with each other — even copy-paste between apps was a hassle. Greg Pierce, software developer (Agile Tortoise), was itching for a better way to get things done on iOS.

iOS didn't have a system dictionary, so to look up a word you had to highlight, copy, switch apps, paste into Google, then tap back. Pierce wanted other developers to pull definitions straight from his dictionary app **Terminology**.

After a few months of planning, he had a barebones language that allowed apps to share strings of text (word definitions, phone numbers) and tell another app what to do with that text. **His method, now called x-callback-url, worked just fine, but wasn't useful without other apps adopting it.** Marco Arment's read-it-later service **Instapaper** jumped at the opportunity. After x-callback-url was plugged into both apps, you could highlight a word in Instapaper, tap a menu item, and bounce into Terminology with the correct definition front and center.

Pierce was the first to develop a way to run multiple processes back-to-back, like relay runners passing a baton.

> "Without [opening x-callback-url to any developer], it would've just been a clever integration between Instapaper and Terminology. Instead, it became the de facto standard for getting apps — even big ones like Google Maps and Evernote — to share information with each other and process stuff in tandem." — Marco Arment

David Barnard, founder of Contrast, saw x-callback-url and wanted to make an app that took full advantage. In December 2011 he and Justin Youens released **Launch Center**, an app that lived in iOS's Notification Center and used x-callback-url as a central control panel for frequent actions (speed-dial, quick-schedule events). It wasn't an approved use of Notification Center. Barnard and Youens pushed through with **Launch Center Pro**, which moved those shortcuts to a grid inside the app — like a productivity-focused home screen.

In 2014, after Apple announced new app-collaboration tools in iOS 8, Barnard and Youens started brainstorming. **Their plan: run x-callback-urls in succession to create script-like actions. They had effectively dreamed up Automator for iOS, but their fear of being burned again by Apple's often convoluted and murky app approval process held them back from following through.** Looking back, Barnard says that was a strategic blunder.

The team behind **Workflow** didn't share those fears. In winter 2014 the app debuted. You'd select actions, drag-drop them together. Send an ETA based on your current location, download all pictures on a webpage, post photos to Instagram with hashtags pre-included.

Just over two years later, Apple acquired Workflow and its team for an undisclosed amount. Greg Pierce thinks it's promising for the future of automation.

> "Maybe we'll see something [in 2018] that gives people a platform to do more professional work." — Greg Pierce

Barnard hopes Apple takes the framework of Workflow and creates something like Automator for mobile.

> "As iPads and iPhones get used more and more for more and more things, it's inevitable that people will look for shortcuts." — David Barnard

## Detour Ahead (the dismissal and Omni)

> Soghoian knows people are looking for those shortcuts, so he's already working on the next iteration of user automation.

In **October 2016**, he was let go from Apple after a nearly 20-year stint. **No warning, no early signs. Apple just said his position didn't exist anymore.** It had been thirteen years since Automator debuted on the Mac, and Soghoian's biggest champion at Apple, Steve Jobs, was gone.

> "If anything, it's a change in something you've known for a long time. But I still have more work to do." — Sal

Despite vowing to take November 2016 to himself, he quickly got to work when **The Omni Group** reached out for his expertise.

Soghoian says x-callback-url was a great start, but the next step is finding better ways for our devices to talk to each other. Omni has crafted a way for its apps to read **JavaScript** so an automation script can run in Omni's macOS and iOS apps without any fuss. Since JavaScript's use is so widespread, Omni's approach is more flexible than x-callback-url. Installing an automation script in one of Omni's iOS apps is as simple as tapping a download link.

Example: making flowcharts for a presentation. Hop into **OmniGraffle**, draw each box manually, position, connect — or open OmniOutliner, run a script you found online that turns each main bullet point into a flowchart box in OmniGraffle, with sub-bullets becoming connected bubbles. Instantaneous.

> "Automation becomes more useful when it gets faster and can respond to more types of events. It's the difference between building a project in your house with either a screwdriver or hammer and using both a screwdriver and a hammer." — Ken Case, Omni Group CEO

> "I'd like to be an old guy, looking back at things, and say I did something that made people's lives better, that they were able to control their destiny to some degree because of the work that I and people that I worked with produced." — Sal Soghoian

> "He ate his own dog food, he lived amongst the community and championed them." — Paul Kent, founder of pKreative event consulting firm and former MacWorld show manager (calling Sal "the dean of automation")

## Article tags
#WWDC #WWDC2018 #APPLE #PROGRAMMING #AUTOMATION
