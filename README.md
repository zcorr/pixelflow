# pixelflow

Two complementary tools for protecting modern displays from burn-in — one for when you're actively at the computer, one for when you've stepped away.

## The problem

OLED panels and other modern display tech are vulnerable to **burn-in** — the gradual, uneven aging of subpixels that have shown the same image for extended periods. The classic culprits are high-contrast static elements: a menu bar, the macOS dock, IDE chrome, a paused chat window mid-prompt, a paused video frame. Even short exposure adds up; over months the affected pixels age faster than their neighbours and a faint ghost of the static UI remains visible against any uniform background.

The scenarios I run into the most:

- I send a long prompt to Claude and walk away (or move to a different monitor) while the response generates — the input UI sits frozen on screen for minutes
- I work on an external monitor with the laptop open, and the laptop's screen sits showing the same desktop for hours
- A long meeting where the same window is in the foreground but I'm not interacting with it
- Anywhere the display is on but the content is effectively frozen

The standard macOS screensavers help a little, but most are designed to look pretty rather than to actually exercise every pixel — they tend to draw bright moving foregrounds against a dark background, which is precisely the *opposite* of what you want. The dark areas don't get exercised at all. They also kick the screen out entirely, which is no good when you actually want to *watch* what's happening.

## What this does

There are two modes, designed for different situations.

### Overlay mode — the primary tool

A translucent, always-on-top, **click-through** window that sits over your entire desktop with one of six animated styles drifting across it. Most of the screen is visible at any given moment, but every pixel gets briefly obscured as the animation passes over it.

- **Most of the screen is fully visible at any given moment** — you can keep watching Claude generate, monitor a long build, follow a chat, etc.
- **Every pixel gets fully obscured periodically** as elements drift over it, which is what actually refreshes the subpixel exposure
- **It's click-through.** Clicks and keystrokes pass straight through to whatever window is underneath. You can approve edits, switch apps with `⌘-Tab`, scroll, type — exactly as if the overlay weren't there.
- **It runs on every connected display.** Helpful when one display is the working one and another sits idle.

**Six styles** (selectable from the menu bar):

| Style | What it does |
| --- | --- |
| **Blobs** | A handful of large soft circles drifting slowly across the screen |
| **Aurora** | Wide, glowing wavy bands flowing horizontally |
| **Plasma** | Classic full-coverage plasma at adjustable opacity — every pixel cycles colors continuously |
| **Particles** | Many smaller drifting glow-spots, like dust motes |
| **Pixel rain** | Cascading colored squares falling down through scattered columns |
| **Sweep** | Wide gradient bands sweeping across at different angles |

**Six color palettes** (combine with any style):

Spectrum (full rainbow), Aurora (greens / teals / violets), Sunset (pinks / oranges / yellows), Ocean (cyans / blues / sea-green), Cyberpunk (magenta / cyan / yellow), Forest (greens / yellow-greens / amber).

Controls live in the ✦ icon in the menu bar: pause/resume, style picker, palette picker, opacity (30–100%), speed (0.5×–2.5×), density (2–12 elements), quit.

If you want to reclaim a bit of menu-bar real estate (especially helpful on a notched MacBook), the menu has a **Show label in menu bar** toggle. Turning it off collapses the indicator to just the ✦ icon. The choice persists across restarts via `UserDefaults`.

**Memory and efficiency.** The overlay is built to stay small and not leak. There is one 30 Hz `Timer` (no per-frame allocations from the run loop). Each style owns its own state and, when you switch styles, the previous instance is released by ARC — Plasma's `deinit` deallocates its pixel buffer at that point. Plasma renders to a single pre-allocated `UnsafeMutablePointer<UInt8>` at 1/6 resolution and uses a 256-entry palette LUT (rebuilt only when palette or opacity changes), so its inner loop has no `NSColor` allocations. All other styles bound their work by element count (≤12 blobs, ≤8 bands, etc), never by pixel count. Pausing skips both `update` and `setNeedsDisplay`, dropping CPU to near-zero.

Typical resident memory after warm-up is around **90 MB** including the Swift / AppKit runtime, with no growth over time.

### Fullscreen mode — for when you're stepping away

A fullscreen browser-based animation, intended for when you actually want to obscure the whole display (a long task you're walking away from, or a second monitor you're not using). Five animation modes plus an auto-cycle that rotates through all of them. Calm motion, full-spectrum colors, every pixel exercised continuously.

| Mode | What it does |
| --- | --- |
| **Aurora** | Slow flowing color gradient with bright bands sweeping across the whole screen |
| **Plasma** | Classic mathematical plasma — every pixel cycles through the full hue spectrum |
| **Particles** | Drifting blobs of light over a slowly-shifting base color, covering all regions |
| **Pixel rain** | Cascading colored pixels that hit every column over and over |
| **Sweep** | Wide gradient bands sweeping across the screen at different angles |

## Running it

### Overlay mode

Requires the Swift toolchain that ships with Xcode Command Line Tools. If you don't already have it:

```
xcode-select --install
```

Then double-click `run-overlay.command`, or from a terminal:

```
./run-overlay.command
```

The launcher compiles `overlay.swift` to a cached binary on first run, kills any prior instance, and launches the overlay detached from the terminal. The terminal window is safe to close immediately.

A ✦ icon will appear in the menu bar — that's your control surface. Pause, adjust opacity/speed/blob-count, or quit from there.

### Fullscreen mode

No build step. Either open `index.html` directly in any modern browser and press `F` for fullscreen, or double-click `run-fullscreen.command` for a chrome-less Chrome app window that starts in fullscreen.

Move your mouse to reveal controls. Keyboard:

| Key | Action |
| --- | --- |
| `F` | Toggle fullscreen |
| `Space` | Pause / resume |
| `1`–`5` | Jump to a specific mode |
| `A` | Auto-cycle |
| `Esc` | Exit fullscreen |

## File structure

```
pixelflow/
├── README.md
│
├── overlay.swift             — translucent always-on-top overlay (single Swift file)
├── run-overlay.command       — launcher: compiles + runs detached
│
├── index.html                — fullscreen mode entry point
├── styles.css                — fullscreen-mode controls overlay
├── run-fullscreen.command    — opens fullscreen mode in a Chrome app window
└── js/
    ├── app.js                — main loop, mode switching, fullscreen + input handling
    └── modes/
        ├── aurora.js
        ├── plasma.js
        ├── particles.js
        ├── pixelrain.js
        └── sweep.js
```

The fullscreen mode's animation modes are each a class with `init`, `resize`, `reset`, and `render(ctx, time, width, height, brightness)`. Adding another mode is a matter of dropping a file into `js/modes/` and registering it in `app.js`.

The overlay mode is one Swift file that creates a borderless `.floating`-level window per `NSScreen`, sets `ignoresMouseEvents = true` for click-through, and drives a small set of drifting radial-gradient blobs from a 30 Hz timer. The status-bar item is the entire UI surface.

## Why this exists

This is one of a series of small projects I'm building to **practice AI prompt engineering** — specifically, getting an entire usable tool from a single well-formed prompt rather than building it incrementally over many turns. The interesting work is mostly upstream of the code: figuring out which features are actually load-bearing, which trade-offs matter, what the smallest defensible scope looks like, and how to express that in a brief that produces something I'd actually keep using.

The overlay mode in particular is a good example of how the *exact* framing of the problem matters. The first version of pixelflow shipped a fullscreen burn-in animation, which technically solves "burn-in protection" but doesn't fit the actual situation that motivated it: I want to *watch* a long-running prompt finish, not blank the screen entirely. A click-through overlay was the right shape — but only became obvious once the wrong one was sitting in front of me. That iteration loop, even within a single session, is the part of prompt engineering this project is trying to practice.
