# HOME-001: HomeKit Has No CLI and No AppleScript

**App:** Home.app
**Intent:** Control HomeKit devices programmatically — lights, sensors, locks, thermostats — from scripts and the command line
**Severity:** Automation bottleneck — device control requires manual Shortcut creation in Shortcuts.app first, then CLI invocation second
**Status:** Open
**Filed:** 2026-03-07

---

## The Friction

Home.app has **4 App Intents** and **zero AppleScript support**. To control a HomeKit device from the command line, you must:

| Step | Action | Automated? |
|------|--------|:----------:|
| 1 | Open Shortcuts.app | Manual |
| 2 | Create a new Shortcut | Manual |
| 3 | Add a "Control [device]" Home action | Manual |
| 4 | Configure the action (which device, which state) | Manual |
| 5 | Name and save the Shortcut | Manual |
| 6 | Now run `shortcuts run "Name"` from CLI | **Automated** |

**5 manual steps before you get 1 automated step.** And you must repeat this for every device and every state. "Turn on kitchen lights" is one Shortcut. "Turn off kitchen lights" is another. "Set kitchen lights to 50%" is a third.

A home with 20 devices and 3 states each needs **60 manually-created Shortcuts** before CLI automation is possible.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

The user bought HomeKit devices. The user set them up. The user owns the home, the devices, and the Mac. But the Mac cannot talk to those devices without first hand-crafting a Shortcut for every single action.

Sal's Principle #2: **Solve a real problem.** "Turn off all the lights when I leave" is a real problem. "Read the temperature sensor and log it" is a real problem. Both require the user to become a Shortcut factory first.

Sal's Principle #7: **Think in workflows.** Home automation IS workflows. Trigger, condition, action. But Apple's Home automation can only be configured in the Home app GUI or via manually-created Shortcuts. There is no scriptable layer.

---

## The Automation Surface (from our probe)

From the probe data: Home.app has **4 App Intents** but **no AppleScript dictionary**, **no URL scheme** for device control, and **no CLI tool**.

The 4 App Intents are basic — they exist in Shortcuts but cannot be parameterized dynamically. You cannot say "control device X with value Y" where X and Y are variables from a script. Each Shortcut is hardcoded to a specific device and action at creation time.

HomeKit has a full framework (HomeKit.framework) available to native apps. But no bridge exists from AppleScript, Shortcuts parameters, or CLI to that framework.

---

## What It Should Be

```applescript
-- Control any HomeKit device by name
tell application "Home"
    set brightness of device "Kitchen Lights" to 50
    turn off device "Living Room Lamp"
    set temperature of device "Thermostat" to 21
    get current value of device "Bedroom Sensor"
end tell
```

```bash
# Or a proper CLI
homekit set "Kitchen Lights" brightness 50
homekit get "Bedroom Sensor" temperature
homekit list devices
homekit list scenes
homekit run scene "Good Night"
```

The user names the device, states the action. The computer does it. No intermediate Shortcut creation. No GUI.

---

## Fix Paths

1. **Apple (ideal):** Add an AppleScript dictionary to Home.app or ship a `homekit` CLI tool. Expose devices as scriptable objects with readable/writable properties. Gate behind existing HomeKit privacy permissions.
2. **Shortcuts (improvement):** Make the Home Shortcuts actions accept **dynamic parameters** — device name and value as input variables rather than hardcoded at Shortcut creation time. One generic "Control Device" Shortcut could replace 60 specific ones.
3. **HomeControl via Shortcuts workaround (today):** Create individual Shortcuts per device per action, then call them with `shortcuts run`. Works but does not scale. This is what the `homepod/` climate sensor setup in this repo does for temperature reading.
4. **`homebridge` / `HomeBridge` (third-party):** Open-source HomeKit bridge that exposes an HTTP API. Not Apple-supported, requires a separate server process, and duplicates device management outside of Home.app.
5. **Siri (limited):** "Hey Siri, turn off the kitchen lights" works but is voice-only, cannot be scripted, and cannot return values.

---

## Real-World Impact

This painpoint is not theoretical. The `homepod/` directory in this very repo demonstrates the workaround cost:

- Reading HomePod temperature requires a **manually-created Shortcut** ("HomePod Sensors")
- That Shortcut was created by hand in Shortcuts.app
- Only then can `shortcuts run "HomePod Sensors"` be called from bash
- The entire `homepod-climate.sh` pipeline depends on that one manual step

If Home.app had a CLI or AppleScript dictionary, the entire HomePod climate monitor could be built without touching Shortcuts.app once.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.