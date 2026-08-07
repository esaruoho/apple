---
description: Diagnose and recover a wedged USB-C / Thunderbolt port without rebooting
---

Run `bin/port-revive diagnose` and report the verdict. If the verdict is a
root-port wedge, remind the user to run `bin/port-revive sessions --save`
before trying `bin/port-revive fix --sleep`.
