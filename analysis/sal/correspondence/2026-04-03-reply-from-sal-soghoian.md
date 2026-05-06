# Reply from Sal Soghoian

Date received: 2026-04-03 (Sal replied within ~24 hours of Esa's email)
Date processed into archive: 2026-05-06
In reply to: 2026-04-02-email-to-sal-soghoian.md

## Sal's message (verbatim)

> Greetings! Thank you for contacting me. I'll provide what I can. I'll check my backup drives.
>
> 1. Do you happen to have local copies of any of the 6 missing files above?
>
> 2. Do you have surviving installer/app/package material for Dictation Commands?
>
> I believe so. Will check.
>
> 3. Are there offline backups, conference kits, CMD-D materials, demo bundles, or old archive folders that might contain the missing payload layer?
>
> Possibly. WIll check.
>
> 4. Is there any preservation or attribution preference you would like us to follow as this work continues?
>
> I'm humbled by your efforts. Thank you for your dedication.
>
> Will reply soon.
>
> Sal

## Attachments / direct deliveries (received with this message)

| Item | Path / URL | Notes from Sal |
|------|-----------|----------------|
| `Photos-to-Keynote.mp4` | `/Users/esaruoho/Downloads/Photos-to-Keynote.mp4` | One of the 6 missing files (photosautomation.com video). Direct file send. |
| `ASClass Materials/` | `/Users/esaruoho/Downloads/ASClass Materials/` | "This may contain the Presidents Database example and others" — AppleScript Class teaching bundle, 9 files dated 2006-01-12. |
| `installer.zip` | `/Users/esaruoho/Downloads/installer.zip` | "This might be the one. Photos Automation Installer" — directly addresses the missing `photosautomation.com/installer.zip` target. |
| `movies-from-dictations-comannds.zip` (1.4 GB) | `https://macosxautomation.com/movies-from-dictations-comannds.zip` | "Every movie from Dictation Commands" — primary video corpus for the Dictation Commands site. (Note: filename has typo "comannds" — preserved as-is per Sal's URL.) |
| Hidden Dictation Commands subsite | `https://macosxautomation.com/dictationcommands/` | "I 'hidden hosted' Dictation Commands .COM here" — Sal's own redirect-only mirror of the original dictationcommands.com. |
| Hidden last installer reference | `https://macosxautomation.com/dictationcommands/index.html` | "The 'hidden' dictation commands website should also contain the last installer I did." — confirms a final Dictation Commands installer is reachable from the hidden subsite. |

## Significance

This single message addresses **three of the six known missing artifacts** plus the largest conceptual gap (Dictation Commands corpus):

- ✅ `photosautomation.com/installer.zip` — delivered as `installer.zip`
- ✅ `photosautomation.com/Photos-to-Keynote.mp4` — delivered directly
- ✅ `iworkautomation.com/numbers/PresidentsSQLiteDB.zip` — likely inside `ASClass Materials/DB Publishing.zip` (pending extraction confirmation)
- ✅ Dictation Commands video corpus — full 1.4 GB bundle now accessible at the URL Sal provided
- ✅ Dictation Commands installer + site contents — accessible via the hidden subsite at `macosxautomation.com/dictationcommands/`

Still missing after this message:

- `macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip`
- `macosxautomation.com/applescript/apps/Script_Geek.zip`
- `macosxautomation.com/applescript/apps/Script_Geek_old.zip`

Sal indicated he will check his backup drives, so further recoveries are possible in a follow-up message.

## Preservation/attribution

Sal expressed gratitude rather than naming a specific preservation directive. Default policy — keep all material attributed to him, preserved verbatim, with provenance (original URL and date) recorded — continues to apply.

## Action plan

1. Save and inventory all directly-sent files into `sources/sal/<site>/downloads/` with `.failed` markers cleared.
2. Extract `ASClass Materials/*.zip` and confirm whether `DB Publishing.zip` is the Presidents SQLite database example.
3. Download `movies-from-dictations-comannds.zip` (1.4 GB) into `sources/sal/dictationcommands.com/downloads/`.
4. Mirror the hidden `macosxautomation.com/dictationcommands/` subsite into `sources/sal/macosxautomation.com/dictationcommands/`.
5. Update `indexes/sal-download-targets.yaml` to reflect newly recovered status.
6. Re-run `bin/sal-archive-status.py --write analysis/sal/current-status.md` to confirm the missing-package count drops.
7. Compose a follow-up reply thanking Sal, confirming receipt, and listing the three Script_Geek / aperturepdfworkflows targets that remain.
