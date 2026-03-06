# US 7,428,535 B1 — Automatic Relevance Filtering

## The Automator Patent

**Title:** Automatic Relevance Filtering
**Filed:** June 25, 2004
**Granted:** September 23, 2008
**Assignee:** Apple Inc., Cupertino, CA
**Inventors:** Eric S. Peyton, Tim W. Bumgarner, Todd R. Fernandez, **David H. Soghoian**

### Related Patents (Same Filing Date)

- **10/877,292** — "Visual Programming Tool" (the Automator UI)
- **10/876,940** — "Automatic Execution Flow Ordering" (runtime flow logic)
- **10/876,931** — "Automatic Conversion for Disparate Data Types" (data type bridging)

Together, these four patents form the **complete intellectual foundation of Automator**.

---

## What It Does

This patent describes the **intelligence behind Automator's action filtering** — the system that makes building workflows intuitive by only showing you relevant next steps.

### The Core Problem

When building a visual workflow, the list of available actions is massive. On a powerful platform, hundreds of candidate actions exist. Most are irrelevant at any given step. Showing everything would be overwhelming and error-prone.

### The Solution: Context-Aware Relevance Filtering

The patent describes a method that:

1. **Determines context and data requirements** — When a user selects an action in a workflow, the system examines what data type the action outputs
2. **Filters candidate actions for relevance** — The next actions presented are filtered based on whether they can accept the previous action's output as input
3. **Ranks by data type conversion cost** — Actions are ranked by how much data conversion would be needed:
   - **Highest relevance**: Actions that accept the exact output type (no conversion needed)
   - **Medium relevance**: Actions that need some data type conversion
   - **Lowest relevance**: Actions whose input type can't be converted from the output at all

### Key Innovations

**Automatic Data Type Conversion (Fig. 11-12):**
When two actions in a workflow produce/consume incompatible data types, the system automatically inserts invisible "bridge" actions that convert between types — transparently to the user. Uses a breadth-first search through a **Data Conversion Engine** to find the shortest conversion path.

**Universal Type Interface (UTI):**
Uses Apple's reverse-DNS naming convention (e.g., `com.apple.iphoto.photo`, `public.alias`) to identify data types. This is the same UTI system still used across macOS/iOS today.

**Dynamic Execution Flow (Fig. 9-10):**
The workflow doesn't have to execute in the order actions were added. The system determines execution flow at runtime based on which actions need input from which — it traces directed relationships between actions and finds actions that need no input as starting points, then flows forward.

**Extensible Action Architecture:**
Actions are modular, self-contained, parametric. They can be imported from third parties. The user arranges building blocks and sets parameters — the application generates the actual script in the background (as XML).

---

## Why This Matters for Our AppleScript Work

This patent embodies Sal's core philosophy: **"The power of the computer should reside in the hands of the one using it."**

The key insight is that **the system should be smart so the user doesn't have to be**. Applied to our automation work:

1. **Data flows between scripts** — think about what each script produces/consumes
2. **Type awareness** — when chaining actions, consider data type compatibility
3. **Filter for relevance** — don't overwhelm with options; present what's useful in context
4. **Invisible bridging** — handle conversions and edge cases transparently
5. **Modular, self-contained actions** — each script does one thing perfectly (one trigger = one action)

Whether the trigger is a hardware controller button, a keyboard shortcut, a Siri phrase, or an automator bot — the principle is the same. This is the engineering philosophy behind everything we build here.
