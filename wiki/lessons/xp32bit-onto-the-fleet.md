# Bringing XP32Bit onto the Fleet — Morning Setup Runbook

**Goal:** make the Windows XP (32-bit) desktop reachable from CloudcityMacMini — so you can deliver files, browse its folders, run a compiler on it, and see its screen — **while keeping XP completely OFFLINE** and **without touching the DOS-PC ↔ XP connection.**

**The whole idea in one sentence:** XP plugs into the same hub as the Mini, gets a *local-only* address (no internet route at all), and the **Mini becomes XP's only door to the outside world** — you reach XP by going through the Mini over Tailscale.

**The golden rule you must not break:** when you set XP's network, the **Default Gateway field stays EMPTY**. That single empty field is what keeps XP on the LAN but off the internet. Everything else is just plumbing.

## Values cheat-sheet (write these on paper)

- XP static IP: `192.168.32.50`  (we verify it's free first; if taken use `.51`)
- Subnet mask: `255.255.255.0`
- Default gateway: **BLANK** — leave empty
- DNS servers: **BLANK** — leave empty
- CloudcityMacMini IP on the LAN: `192.168.32.101`
- SSH port: `22`   ·   VNC (screen) port: `5900`

## Part 0 — The night before (do this on RayMac or the Mini, NOT on XP)

XP cannot download anything itself — it's old and we're keeping it offline. So everything arrives by **USB stick**.

- **Get a USB stick.**
- **Download Bitvise SSH Server** (the current `9.64` or newer — it supports Windows XP SP3). From `https://bitvise.com/ssh-server-download`. This one app gives you file transfer (SFTP) **and** a remote command line (for compiling) in a single Windows service.
- **Download UltraVNC** `1.2.x` (the `1.2` line is one binary for XP through Win10). From `https://uvnc.com/downloads/ultravnc/`. This is for seeing XP's screen (the VIEW button).
- **Copy both installers onto the USB stick.** Also copy this document.
- **Confirm XP is Service Pack 3.** On XP: right-click *My Computer* → *Properties* → the *General* tab shows the version. Bitvise 9.64 needs **SP3**. If it's not SP3, tell me — we pick an older Bitvise build instead.

## Part A — Plug in and make XP local-only (do on XP, at the workspace)

- **A1.** Plug XP's ethernet into the **same hub** the Mini and HertsiMacPro use.
- **A2. Check the chosen IP is free.** On the Mini, run `ping 192.168.32.50`. If it says *Request timed out* / no reply → the address is free, use it. If something replies → use `192.168.32.51` instead (and update your paper).
- **A3. Set the static, gateway-less address on XP:** *Start* → *Control Panel* → *Network Connections* → right-click **Local Area Connection** → *Properties* → click **Internet Protocol (TCP/IP)** → *Properties* → choose **Use the following IP address** and enter:
- IP address: `192.168.32.50`
- Subnet mask: `255.255.255.0`
- Default gateway: **leave it EMPTY** ← the safety switch
- Preferred DNS server / Alternate: **leave them EMPTY**
- **A4.** Click *OK*, then *OK* again to close.
- **A5. Confirm XP is offline:** open Internet Explorer and try any website — it must **fail to load**. That failure is success: XP has no route to the internet.
- **A6. Confirm XP is on the LAN:** back on the Mini, run `ping 192.168.32.50` again — now it **should reply**. XP is reachable locally.
- **A7. Confirm DOS ↔ XP is intact:** open the shared folder / mapped drive the DOS PC uses, exactly as before. It still works — that link is purely local and the empty gateway never affected it.

## Part B — Install Bitvise SSH Server (files + remote command line + compiling)

- **B1.** From the USB stick, run the Bitvise SSH Server installer on XP. Accept the defaults. It installs as a **Windows service**, which means it **starts automatically every time XP powers on** — important, since you close XP most days.
- **B2.** Open **Bitvise SSH Server Control Panel** → click **Open easy settings**.
- **B3.** On the **Windows accounts** tab, add an entry for the Windows user you log in to XP with. Allow: **login**, **terminal shell**, and **SFTP / file transfer**. Make sure that Windows account has a **password** (Bitvise won't allow blank-password logins). Write the username + password on your paper.
- **B4.** On the **Server** tab, confirm the SSH port is `22`. Leave it.
- **B5.** Click **Save changes**. The little status light should show the server **running**.
- *(Minor note: on XP, Bitvise leaks ~1–2 KB per connection. Irrelevant for our trickle of connections; just don't leave hundreds of sessions open. A reboot clears it.)*

## Part C — Install UltraVNC (the screen / VIEW button)

- **C1.** From the USB stick, run the UltraVNC installer on XP. You only need the **Server** (you can untick the Viewer).
- **C2.** When asked, choose to **register UltraVNC Server as a system service** so it **auto-starts on boot** (same reason as Bitvise).
- **C3.** Open UltraVNC Server settings (*Admin Properties*) and set a **VNC password**. Write it on your paper. A VNC password is required.
- **C4.** Leave the port at `5900`.

## Part D — XP firewall: let only the Mini in

- **D1.** *Control Panel* → *Windows Firewall* → make sure it's **On**.
- **D2.** *Exceptions* tab → **Add Port** twice:
- name `SSH`, port `22`, TCP
- name `VNC`, port `5900`, TCP
- **D3.** For each, click **Change scope** → **Custom list** → enter just the Mini's IP `192.168.32.101`. That way only the Mini can knock on those doors. *(If the scope box is fiddly, it's acceptable to leave the two ports open — XP is offline and behind the router's NAT, so the LAN is the only thing that can reach it anyway.)*

## Part E — Hook XP into the fleet (the Mini side)

This is the part I can do **for** you, remotely, once XP answers — just tell me the **XP username** and confirm the **IP** you used. I'll then:

- add `Host XP32Bit` to the Mini/RayMac SSH config (through `ProxyJump cloudcity`),
- add `xp32bit` to `fleet-files` so the **VIEW** button and `fleet-files screen xp` work,
- and teach the Mini's prober to publish an XP Machine Card (so it shows in Fleet like the others).

If you'd rather do it yourself, the SSH config block is: host `XP32Bit`, HostName `192.168.32.50`, User *your-XP-username*, ProxyJump `cloudcity`.

## Part F — Prove it works (from RayMac, from anywhere)

- `ssh XP32Bit` → you land at an XP `cmd.exe` prompt. Type `ver` → it prints the Windows version. **This is your remote command line — run your compiler/assembler here.**
- `sftp XP32Bit` → `put somefile.txt` → check it appears in XP's folder. **This is file delivery.**
- Drop a build artifact into the **DOS-shared folder** over SFTP → the DOS PC sees it on its mapped drive. **This is how you feed the DOS machine.**
- `fleet-files screen xp` (or the **VIEW** button in Fleet / the 🖥 Screen Share menu) → UltraVNC opens XP's screen.

## Compile-and-hand-to-DOS workflow (what you're really after)

- `ssh XP32Bit`, then run your assembler/compiler at the `cmd.exe` prompt — or `sftp` the source in first, build, and `sftp` the result out.
- Drop the finished binary into the folder the DOS PC maps as a drive. Next time the DOS PC reads that drive, your build is there. XP is the compile box; the shared drive is the hand-off; the DOS PC just picks it up.

## Golden rules (the careful bits — re-read before you start)

- **Default gateway stays EMPTY.** Never fill it in. That empty field is the entire reason XP is safe — no internet route in or out.
- **Everything installs from USB.** XP downloads nothing itself.
- **Both services must auto-start (run as services).** Because you close XP daily, they have to come up by themselves on power-on so the Mini can reach XP without you logging in or clicking anything.
- **Never enable UPnP or port-forwarding for XP on the router.** That's the only way a no-gateway machine could accidentally become reachable from the internet.
- **The DOS ↔ XP link is local and untouched.** Removing the gateway does not affect same-network traffic, so the DOS drive keeps working exactly as today.
- **The Mini is XP's only uplink.** XP talks to the LAN; the Mini talks to the world; you ride in through the Mini over Tailscale.

## If something doesn't work

- *Mini can't `ping 192.168.32.50`* → re-check XP's IP/subnet; make sure the cable is in the same hub; check XP's firewall isn't blocking everything.
- *`ssh XP32Bit` refused* → Bitvise service not running (open its Control Panel), or firewall port 22 not open to the Mini, or the Windows account isn't allowed terminal login.
- *VIEW / VNC blank or refused* → UltraVNC service not running, no VNC password set, or port 5900 not open to the Mini.
- *Website still loads on XP* → the gateway field wasn't left empty. Go back to A3 and clear it.

You've got this. Plug them in together, work top to bottom, and ping me the XP username when it answers — I'll wire the Mini side and we'll VIEW it together.
