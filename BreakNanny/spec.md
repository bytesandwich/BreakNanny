# BreakNanny — Product Specification

## Overview

BreakNanny manages intentional periods of focused coding followed by enforced breaks.  
Each work period (“coding block”) is explicitly planned, executed, and then reflected upon.

The core loop is:

**Intention Write Down → Focused Work → Enforced Break and Reflection; Repeat**

The app ensures that breaks actually happen and that reflection is captured while the context is still fresh.

---

## Core Concepts

### Coding Block

A coding block represents one unit of focused work and its associated break.

Each coding block contains:

- **Intended Description**
  - The goal or intention before starting the coding block.
- **Actual Description**
  - A reflection written during the break about what actually happened.
- **Planned Coding Duration**
  - One of: 10, 15, 20 minutes (default: 15).
- **Planned Break Duration**
  - One of: 5, 10 minutes (default: 10).
- **Actual Coding Duration**
  - The elapsed time spent coding.
- **Actual Break Duration**
  - The elapsed time spent on break.

---

## App States

At any moment, the app is in exactly one of the following states:

1. **Idle (No Active Coding Block, but a new block form visible)**
2. **Active Coding**
3. **Active Break**

---

## Layout

The UI is divided vertically into two regions:

1. **History List** — completed coding blocks
2. **Primary Coding Block Area** — current focus (visually emphasized)

---

## Coding Block Visual Structure (Consistency Rule)

All coding blocks share the same visual structure in every state:

### Top Section — Coding Info
- Intended Description (a text field, or a static text)
- Coding duration (either a picker, an active countdown, or a static duration like "15m" )

### Bottom Section — Break Info
- Actual Description (the string "TBD", a text field that receives all key input during the break, or a static text)
- Break duration (either a picker, an active countdown, or a static duration like "15m" )


This structure is consistent across all places a block can be:
- Historical blocks
- The Active block
- The New block creation form

Only content and interactivity vary by state.

---

## History List

### Appearance
- Vertical list of rectangular coding block cards
- Each card displays:
  - top section
    - Intended Description
    - Actual Coding Duration
  - bottom section
    - Actual Description
    - Actual Break Duration
    
The description/duration should also be a consistent visual element between the two sections.

### Behavior
- Read-only
- No editing after completion
- Displays completed coding blocks only

---

## Primary Coding Block Area

The primary coding block area is visually distinct (higher contrast / emphasis / larger size) and represents the current focus - either a new form or the active ongoing coding block.

### State: Idle (New Coding Block Form)

Displayed when no coding block is active.

#### Fields
- **Intended Description**
  - Text input
  - Required
- **Coding Duration Picker**
  - Options: 10, 15, 20 minutes
  - Default: 15 minutes
- **Actual Descripion Info**
  - field name grayed out and text field shows text "fill this out during the break"
- **Break Duration Picker**
  - Options: 5, 10 minutes
  - Default: 10 minutes

#### Actions
- **Start Button**
  - Disabled until Intended Description is non-empty
  - Creates a new coding block
  - Transitions to *Active Coding*

---

### State: Active Coding

Displayed while the coding timer is running.

#### Display
- Intended Description (read-only)
- Countdown timer for remaining coding duration
- Actual Descripion Info
  - field name grayed out and text field shows text "fill this out during the break"
- Planned break duration (read-only)

#### Behavior
- Coding ends automatically when the timer reaches zero
- Keyboard and mouse input behave normally during coding. The app is not capturing or doing anything.

---

### State: Active Break

Displayed while the break timer is running.

#### Display
- Intended Description (read-only)
- Actual Coding Duration (read-only)
- Countdown timer for remaining break duration
- **Actual Description** field (editable)

#### Input Rules
During an active break:

- All keyboard input is intercepted system-wide (this feature is already developed)
- Keyboard input is routed exclusively to the *Actual Description* field (this feature is already developed)
- Mouse interaction is disabled (this feature is already developed)
- No other applications can receive keyboard or mouse input (this feature is already developed)

#### Completion
- When the break timer reaches zero:
  - The coding block is finalized
  - The block is added to the History List
  - The app transitions to the *Idle* state with the new block form visible

---

## Automatic Transitions

- **Coding → Break**
  - Occurs automatically when the coding timer expires
  - Also occurs immediately when the Done button is pressed
- **Break → Idle**
  - Occurs automatically when the break timer expires

---

## Non-Goals (Out of Scope)

The following are explicitly not part of this specification:

- Editing completed coding blocks
- Pausing or skipping timers
- Analytics, scoring, or streaks
- Sync or persistence details
- Custom durations beyond the provided presets
- Notifications
- Any widget capabilities

---

## Product Intent

BreakNanny is designed to:

- Enforce real breaks after focused work
- Preserve user intention before coding
- Capture reflection immediately after coding
- Reduce the temptation to continue coding during breaks

The app favors clarity, intentional friction, and enforcement over flexibility.
