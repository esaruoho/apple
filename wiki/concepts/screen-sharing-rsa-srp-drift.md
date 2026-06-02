# Screen Sharing fails (window "shakes") but SSH works — RSA-SRP verifier drift

**Symptom (2026-06-02, cloudcitymacmini / Mac Mini, macOS 26.3):** SSH to the Mini
works fine, but Apple **Screen Sharing.app** rejects the *correct* login password —
the auth sheet just shakes. Same account, same password "that works for SSH".

## Why SSH success proves nothing about the password

`ssh cloudcity` authenticates with the **public key** `~/.ssh/id_rsa`
(`Authenticated ... using "publickey"`). The login password is **never checked** by
SSH. So "it's the same password and SSH works" is a false premise — SSH never tested it.

## The real cause: two password verifiers that drifted apart

macOS stores several password verifiers per account, listed in the
`AuthenticationAuthority` HASHLIST. On this account:

```
dscl . -read /Users/esaruoho AuthenticationAuthority
# ;ShadowHash;HASHLIST:<SALTED-SHA512-PBKDF2,SRP-RFC5054-4096-SHA512-PBKDF2> ;SecureToken; ;Kerberosv5;...
```

- `SALTED-SHA512-PBKDF2` — used by `dscl -authonly`, `sudo`, and the GUI login window.
  **Matched the current password** (`dscl . -authonly esaruoho` → AUTH-OK; sudo accepted it).
- `SRP-RFC5054-4096-SHA512-PBKDF2` — used by modern Screen Sharing
  (**`Type: RSA-SRP`** in the log). **Was generated from an older password.**

When those two verifiers are generated from different plaintexts, you get exactly this
split: directory password correct everywhere, but Screen Sharing's RSA-SRP handshake fails.
The drift happens when a password is reset via a path that updates the PBKDF2 ShadowHash
but **not** the SRP verifier — e.g. an Apple-ID / secure-token reset or MDM, rather than a
normal OpenDirectory password change. (Tell-tale: `sysadminctl -resetPasswordFor` fails with
"Operation is not permitted without secure token unlock".)

## Ground-truth log line (the thing that nailed it)

Capture on the Mini while attempting the connection:

```
log stream --predicate 'process CONTAINS[c] "screensharing"' --style compact > /tmp/ss.log &
# ... attempt Screen Sharing login ...
# screensharingd: Authentication: FAILED :: User Name: esaruoho :: Viewer Address: <ip> :: Type: RSA-SRP
```

`Type: RSA-SRP` + the password being provably correct = SRP verifier mismatch.

## Confirm without changing anything

The SRP verifier holds an **old** password, so connecting via Screen Sharing with a
*previous* password may succeed. If it does, drift is confirmed (and you're in).

## Fix: regenerate ALL verifiers from one plaintext via a proper OpenDirectory change

Run an interactive password change **as the user** (provides old password, so the secure
token stays in sync) over SSH — this regenerates every hash type in the HASHLIST,
including the SRP verifier:

```
ssh -t cloudcity passwd       # Old password (current), New password, Retype
```

`passwd` won't accept new == old, so set a genuinely new value. Afterwards, Screen
Sharing's RSA-SRP validates against the freshly-generated verifier and the shake stops.

**Risk note:** FileVault account on a headless Mac. The Mini has a Personal Recovery Key
and iCloud Recovery user (`diskutil apfs listUsers /`), so worst case is recoverable. At
the next reboot, FileVault unlock will want the **new** password — remember it.

## Alternative workaround (no password change): legacy VNC password

The Mini has `VNCLegacyConnectionsEnabled = 1` and a VNC password set
(`/Library/Preferences/com.apple.VNCSettings.txt`). A **third-party** VNC client
authenticates against that separate 8-char VNC password (not RSA-SRP, not the login
password). Apple's own Screen Sharing.app prefers RSA-SRP and does **not** fall back to
the VNC password, so this path needs a non-Apple VNC client. Reset the VNC password to a
known value with:

```
ssh cloudcity 'sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes -setvncpw -vncpw <8charpw>'
```

## Quick reference — services + auth are independent

| | Service | Port | Auth checked against |
|---|---|---|---|
| SSH | Remote Login (`sshd`) | 22 | publickey (password never checked here) |
| Screen Sharing | `screensharingd` | 5900 | RSA-SRP verifier (modern) **or** legacy 8-char VNC password |

Network was never the issue: port 5900 was open and reachable over Tailscale the whole time
(`nc -z cloudcitymacmini 5900` → succeeded). Always target the Tailscale name
`cloudcitymacmini` / IP, never `.local` (dead off-LAN).
