---
description: Generate a Wi-Fi-join QR code (scan to join the network without typing the password). Apple-native. Usage `/qr-wifi <SSID> <password> [output.png] [auth] [hidden]`.
allowed-tools: Bash
argument-hint: <SSID> <password> [output.png] [WPA|WEP|nopass] [hidden]
---

Generate a Wi-Fi-join QR code via CoreImage (wraps `bin/sal-qr`). Default auth is WPA. Default output is `~/Desktop/wifi-<ssid-slug>.png`. Output is revealed in Finder.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/qr-wifi $ARGUMENTS
```

After the command completes, report only the output path and SSID. Do not echo the password.
