# Dollard *Common Language*: why it showed as defective, plus Adams square-wave torque and VR3 (2026-11-24)

## Why a full-text book showed up as "defective OCR"
- The book is **born-digital**: produced in OpenOffice 3.3, 82 pages, with embedded Cambria and Arial text. It never needed OCR.
- It was sent to OCR on 2026-07-06 anyway, as part of a Dollard batch. The vision model then **looped on equation pages** 7, 10, 25 and 35, producing 130,881 characters of repeats. That looped copy is what the quality gate flagged.
- The worker's "skip if it already has text" check (`_skip-already-has-text/`) only started on 2026-08-11. A copy submitted on 07-06 would be skipped today.
- **The archive was never affected.** It has always used the real text layer (`lone-pine-common-language-2015/_pdftotext-raw.txt`). The looped OCR result (`.txt`, `.pdfws`, `_ocr.pdf`) is junk and can be deleted from the queue.

## Coverage so far
- **DOLLARD-QUOTE-LEDGER:** 101 rows from this book, marked "✅ FULL — every prose line read; short lines checked 2026-11-18".
- **Deep-read:** one whole-book senior deep-read (2026-05-14, 17 KB). Its sections cover four primary dimensions, two-volts/two-amps duality, counterspace, Parameter Variation (Transmission 9, pp. 60–67, aimed at the VR papers), the missing machine and Class K, and eighth-root versors (Transmission 10).
- **Not done:** a chapter-by-chapter (Transmission-by-Transmission) deep-read set like the Adams and Dollard-1985 sets. The **equations** in particular have not been read: pdftotext mangles them, and the ledger only quotes prose.

## Tesla and "common language"
Searching the archive turned up no Tesla letter about Dollard's booklet. The one Tesla hit is his 1905 essay *"The Transmission of Electrical Energy Without Wires as a Means for Furthering Peace"*. In it he argues that *"by adopting one common language the onward march of man would be prodigiously quickened"*. He rejects artificial tongues like Volapük and expects a return to Latin or Greek "mother tongues" by Spencer's law of rhythm. The essay ends with the "annihilation of distance". That is the same impulse as Dollard's title, which proposes one shared language for electrical engineering. Dollard's own Letters 001 and 002 don't mention the book.

## What "square-wave torque" means (Adams Manual p. 35)
*"By using square wave current switching high order motor efficiencies can be attained. Over a wide range of speeds the machine exhibits a constant current and therefore constant torque characteristic."*
- **Conventional DC motor:** I = (V − E_back)/R, and the back-EMF rises with speed. So the current falls as speed rises, and torque falls with it. The speed–torque line slopes down.
- **Adams:** current is switched in short square pulses with a low duty cycle, placed just past pole alignment. At that point the rotor magnet's rate of flux change through the coil is near its minimum, so the back-EMF that opposes the supply during the pulse is small. The current in each pulse is then set by V/R and the pulse width, not by speed. So it stays **constant over a wide speed range, and torque per pulse stays constant**. The collapse after clip-off then supplies a second push of the same sign.
- **What it means for the VR3 paper:** it is a **testable signature of Class E timing**. If the reaction really has been moved in time, the speed–torque (or speed–current) curve should be flat, not drooping.

## Should it go in the VR3 paper?
VR3 v11 §2.5 (Class E) already has a full Adams paragraph: the 1980 clip-off drawing, GB 2,282,708, Low's 1993 simulation, and capture into the battery. It does **not** have the constant-current, constant-torque claim. **Recommendation:** add one sentence and one bench prediction to that paragraph, citing Manual p. 35. Proposed text:

> Adams further reports that with square-wave switching "over a wide range of speeds the machine exhibits a constant current and therefore constant torque characteristic" [5a, p.35] — the opposite of a conventional DC machine, whose current and torque fall as speed-proportional back-EMF rises; a flat speed–current curve under fixed pulse width is therefore a second, cheaper discriminator for Class E placement than per-pulse torque.

Not yet edited into the draft. It needs Esa's OK.
