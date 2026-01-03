

# Mode-Based Input, Focus, and Active Minute Tracking

This document specifies required changes to extend the app with explicit modes for input capture and focus enforcement, add active-minute tracking during coding blocks, and emit a deterministic stdout summary when exiting active coding.

All existing behavior must be preserved by default.
### Requirements
- Mode switching must be idempotent
- No duplicated observers
- No behavior regressions
---

## 1. GlobalKeyboardCapture — Mode-Based Behavior

### Add modes

```swift
enum KeyboardCaptureMode {
    case observeOnly   // default
    case breakLogCapture
    case off
}
```

### Semantics

#### `.'observeOnly'` (default)
- Event tap is **listen-only**
- Events are not swallowed
- track a list of minutes where there was an active event. Don't bother tracking inactive minutes. list reset on start
- Used for:
  - activity tracking just to know whether a given minute had activity or not
  - normal coding blocks where the user can interact feely with any app

#### `.breakLogCapture`
- this is the current behavior

### Requirements
- Single event tap only
- Mode must be changeable at runtime
- Keep the current behavior unmodified, except to theck for the current mode being off before starting, and to rename to startBreakLogCapture and stopBreakLogCapture
- add a startObserveOnly / stopObserveOnly


---

## 2. FocusEnforcer — Mode-Based Behavior

### Add modes

```swift
enum FocusEnforcementMode {
    case onlyTrackActiveApp
    case enforceAppFocus   // current behavior
    case off
}
```

### Semantics


#### `.onlyTrackActiveApp`
- just log the changing active app events into a list of (app_name, timestamp)
    - make sure to use consistent app names (key-able)
- list reset every time we start this mode


#### `.enforceAppFocus`
- Preserve current behavior:


---
## 3. ActivityReviewer
### calculation phases:
1. sort join to list of (app, minute)
    * if a minute has two activities, just emit both of them
2. groupby and sum to (app, sum(minutes))
3. sort by app - this is the result


## 4. App State integration

The app’s implicit phases must be made **explicit and authoritative**.

### During active coding
- start KeyboardCaptureMode at observeOnly
- start FocusEnforcement onlyTrackActiveApp

### On exit from active coding
1. stop both
2. run activity reviewer 
3. Emit the stdout summary (see below)
4. Transition modes to their next appropriate state

Mode transitions must occur in app state or controller logic, **not SwiftUI views**.

---


## 5. Required Stdout Output (Exact Format)

When transitioning **out of active coding**, print:

```
active minutes: {total_active_minutes} / total minutes: {total_minutes}
```

Then print apps sorted by active minutes descending:

```
* app [{app_short_name}]: {app_active_minutes} active minutes
```

Rules:
- `{app_short_name}` must be human-readable
- Omit apps with zero active minutes
- Output must be deterministic and stable

---

## 7. Constraints

- Prefer composition over inheritance
- No third-party libraries
- No new event taps or workspace observers
- Show only new or modified Swift code
- Label changes clearly inside existing types
- Be explicit about threading and run loop assumptions

Target platform: macOS 13+, Swift 5.9.
