# How Apple Became Apple × The Sal Vision

**Source:** "How Apple became Apple: The definitive oral history of the company's earliest days" — Harry McCracken, Fast Company, March 2026 (Apple's 50th anniversary)
**Analysis date:** 2026-03-30

---

## The Article in Brief

67-page oral history with first-person testimony from Wozniak, Ron Wayne, Bill Fernandez, Chris Espinosa, Mike Markkula, Dan Bricklin, Bob Frankston, Nolan Bushnell, Lee Felsenstein, Liza Loop, Regis McKenna, and others. Covers 1968–1979: the two Steves meeting, blue boxes, the Homebrew Computer Club, Apple-1, Apple II, VisiCalc, and the IPO.

## The Through-Line to Sal

This article is a **primary source document** for the philosophy that Sal Soghoian inherited and championed for 20 years at Apple. The DNA is the same. Here's how:

### 1. "The power of the computer should reside in the hands of the one using it."

That's Sal's credo. But look at where Apple *started*:

> **Wozniak:** "I told my dad when I was in high school, 'I'm going to own a computer someday.' My dad said, 'It costs as much as a house.' And I said, 'I'll live in an apartment.'"

> **Wozniak:** "The computer has to be fun, or else nobody would want it."

> **Felsenstein:** "It was very clear to me that what they were making was a media machine... They wanted something that would give the user the equivalent of television, and the ability to program for it."

Woz didn't just want a computer — he wanted a **programmable** computer in the hands of ordinary people. Not terminals connected to mainframes. Not locked-down appliances. A machine you could **write programs for**. That's exactly Sal's position: the user should be able to automate, script, and control the machine themselves.

### 2. The Homebrew Computer Club = The Automation Community

The Homebrew Computer Club was a group of hobbyists who shared designs openly, helped each other debug, and believed computing should be democratized. Sal's automation community — the AppleScript mailing lists, the macosxautomation.com resources, the CMD-D conference — is the direct descendant.

> **Wozniak:** "I was too shy to talk to people. The only way I could communicate was to design something cool. And people, other geeks, would talk to me about it."

Sal principle #9: **"Educate and share."** The automation community grows through generosity.

### 3. Expansion Slots = Scriptability

One of the most telling details in the article:

> **Baum:** "One of the things that made the Apple II compelling was you could plug boards into it, which Steve Jobs didn't want at all."

Jobs wanted a sealed box. Baum and Woz insisted on expansion slots. Those slots made the Apple II an **open platform** — third parties could extend it in ways Apple never anticipated. The floppy drive, VisiCalc, and the entire Apple II ecosystem depended on that openness.

This is the **exact same tension** that played out 40 years later with AppleScript vs. App Extensions. Sal's 2017 manifesto ("AND, Not OR") is the same argument Baum made in 1976: the machine must be extensible by users and third parties, not just by Apple.

**Expansion slots are to hardware what scripting dictionaries are to software.** Both are interfaces that let outsiders extend the platform in ways the creator never imagined.

### 4. VisiCalc = The Killer App Argument

> **Rotenberg:** "If Dan Bricklin had decided to develop VisiCalc for the Radio Shack TRS-80 or Commodore PET instead, it's not clear that Apple would have had enough critical mass to survive."

VisiCalc saved Apple. It was created by a third party who could build on the platform because the platform was open. This is the same argument Sal's community made in 2016: the publishing industry's AppleScript workflows kept the Mac alive during its darkest years. When Bill Cheeseman asked "Is there an analogous pitch today?" after Sal's firing — he was invoking VisiCalc logic. **Open platforms survive because outsiders build things the platform maker can't imagine.**

### 5. Liza Loop — The First "User Automation" Story

Liza Loop might be the most Sal-relevant figure in this article. She was Apple's first user — literally. She took the Apple-1 into schools. She was an educator using technology to empower learners.

> **Wozniak:** "I told my dad in sixth grade that first, I was going to be an electrical engineer, and second, I was going to be a fifth grade teacher."

Woz's two passions: engineering and education. Sal embodies both. The entire macosxautomation.com site is a teaching resource. Sal wrote *AppleScript 1-2-3* as a textbook. He created Dictation Commands for accessibility. Loop's story and Sal's career are the same thread: **technology in the service of empowerment, not dependency.**

### 6. Markkula's Three Principles

Chris Espinosa recounts Markkula's one-page marketing philosophy from 1978:

1. **Empathy** for the customer
2. **Ruthless focus** — do fewer things better
3. **Impute value** — do everything well, not just the product

Sal's 10 WWSD principles map directly:
- Empathy → "The user comes first" (WWSD #1)
- Ruthless focus → "Solve a real problem" (WWSD #2)
- Impute value → "Make it readable" (WWSD #4), "Think in workflows" (WWSD #7)

Markkula's memo is still alive at Apple, per Espinosa ("I bought a new iPad yesterday — unboxing it with the zip strips... that goes back to Markkula's original memo"). Sal's principles are the automation-layer expression of the same DNA.

### 7. The Garage ≠ Where It Started

> **Kottke:** "When the Apple-1 boards first arrived, they were all stacked in Patty's bedroom. So really, Apple started in her bedroom, not the garage."

> **Fernandez:** "They had to form a company. That kind of happened in Steve Jobs's bedroom."

The article debunks the garage myth. The real origin was bedrooms, living rooms, HP labs after hours, and the Homebrew Computer Club meeting room. **The work happened wherever curious people gathered to share what they'd built.** This is relevant to our project: the `esaruoho/apple` repo is a bedroom-and-garage operation continuing the same tradition. Sal would recognize it instantly.

---

## What Sal Would Say About This Article

Sal would point out that the article ends in 1979 — right when the Apple II became a business tool through VisiCalc. But the *next* chapter, which this article doesn't cover, is when Apple started building automation into the platform itself:

- **1993:** AppleScript ships with System 7.1.1
- **1997:** Sal joins Apple to champion it
- **2004:** Automator debuts (Sal demos it on stage for Jobs)
- **2016:** Apple eliminates Sal's position

The oral history shows Apple was *born* from the principle that users should control their machines. Sal spent 20 years keeping that principle alive inside the company. When Apple eliminated his position, they broke the through-line that goes all the way back to Woz soldering blue boxes and insisting on expansion slots.

**This article is the origin story of the philosophy that Sal embodied and that Apple abandoned.**

---

## The Closing Quote

> **Wozniak:** "When you're about to die, you have certain memories. And for me, it's not going to be Apple going public or Apple being huge. It's really going to be stories from the period when humble people spotted something that was interesting and followed it."

That's the Sal vision in one sentence. Humble people spotting something interesting and following it. That's what this repo is — the continuation.
