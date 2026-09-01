---
description: A Homebrew cask that ships a bare Mach-O CLI (codex, and friends) gets com.apple.quarantine on install, and the first exec raises a hard "Not Opened / Move to Bin" Gatekeeper dialog with no Open Anyway path. Diagnosis, one-off fix, and the durable HOMEBREW_CASK_OPTS setting.
---

# Homebrew casks quarantine bare CLI binaries

## Symptom

Right after a `brew upgrade`, launching a cask-installed command-line tool raises:

> **"codex" Not Opened** — Apple could not verify "codex" is free of malware that may harm your
> Mac or compromise your privacy.  ·  **Done**  |  **Move to Bin**

Two buttons. No **Open Anyway**. No obvious way forward. The tool is untouched on disk and
perfectly valid.

## Why it happens

Homebrew applies `com.apple.quarantine` to **every cask** it installs, by design. For a normal
`.app` bundle that is fine: Gatekeeper's first-launch flow offers "Open Anyway", or you approve it
in **System Settings ▸ Privacy & Security**.

**A cask that installs a bare Mach-O executable instead of a bundle gets the hard-refuse dialog.**
There is no bundle for Launch Services to hang an approval on, so the friendly path never appears.
`codex` (the OpenAI CLI) is the case that surfaced this — `/opt/homebrew/bin/codex` is a symlink
into `/opt/homebrew/Caskroom/codex/<ver>/bin/codex`, a 217 MB arm64 executable, no `.app` anywhere.

The dialog wording is **misleading**: it reads as "this failed notarization." It usually has not.
Verify before you believe it.

## Diagnose — always check the signature BEFORE stripping anything

```bash
B=/opt/homebrew/Caskroom/codex/0.152.0/bin/codex
xattr -l "$B"                     # is com.apple.quarantine present?
codesign -dv --verbose=4 "$B"     # who signed it?
spctl -a -vv -t install "$B"      # is it actually notarized?
```

A genuine tool answers like this:

```
com.apple.quarantine: 0381;6a969350;;B6760EB9-...
Authority=Developer ID Application: OpenAI OpCo, LLC (2DC432GLL2)
accepted
source=Notarized Developer ID
```

`accepted` + `Notarized Developer ID` means the binary is fine and the dialog was purely the
quarantine bit. **If `spctl` says `rejected` / `no usable signature`, stop — do not strip the
attribute.** That is the case the dialog exists for.

Note `spctl -a -t exec` on a non-bundle returns `rejected (the code is valid but does not seem to
be an app)`. That is not a failure verdict; it means "this isn't an app". Read the `source=` line,
not the first word. Use `-t install` for bare executables.

## One-off fix

```bash
xattr -d com.apple.quarantine /opt/homebrew/Caskroom/codex/<ver>/bin/codex
xattr -d com.apple.quarantine /opt/homebrew/Caskroom/codex/<ver>/bin/codex-code-mode-host
```

Strip it from **every** executable the cask ships, not just the one named in the dialog — helper
binaries raise their own dialog later, under their own name.

This does not weaken anything structural: `codesign` and `spctl` still enforce signature and
notarization at exec time. Only the first-launch prompt goes away.

## Durable fix

In `~/.bash_profile`, right after the `brew shellenv` eval:

```bash
export HOMEBREW_CASK_OPTS="--no-quarantine"
```

Installed 2026-09-01 at line ~1066. Applies to future cask installs only — anything already on
disk still needs the one-off `xattr -d`. It is a **global** setting: every cask from then on skips
quarantine, so it trades the prompt for trusting Homebrew's tap sources. Worth knowing, and worth
keeping the `spctl` check as a habit for anything unfamiliar.

## Where it bit

`bin/sessions` resolves agents through `find_bin(name)`, which walks a fixed candidate list:
`~/.claude/local/` → `~/.local/bin/` → `/opt/homebrew/bin/` → `/usr/local/bin/` → `shutil.which()`.
Pressing `x` (new codex session) or resuming a codex row therefore execs
`/opt/homebrew/bin/codex` — the cask copy — and inherited its quarantine flag on the first run
after every upgrade.

**Duplicate-install trap:** an npm `@openai/codex` under
`~/.nvm/versions/node/<ver>/bin/codex` can coexist and is *never* selected, because
`/opt/homebrew/bin` is earlier in `find_bin`'s list. When debugging "which codex is this", resolve
the symlink rather than trusting `which`. The npm package's own vendored binaries are notarized,
with one exception worth remembering: its bundled
`codex-resources/zsh/bin/zsh` is signed by OpenAI but **unnotarized** (`source=Unnotarized
Developer ID`), so it would raise this same dialog under the name `zsh` if that path ever became
the active one.

## Related

- [`asobjc.md`](asobjc.md) — default tool order
- [`macos-app-icon-sizing.md`](macos-app-icon-sizing.md) — the other "shipped it wrong first" page
- Project memory `feedback_lsregister_after_app_bundle_changes.md` — the sibling Launch Services
  caching trap for `.app` bundles
