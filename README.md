# pixelflow

A **click-through macOS overlay** that drifts soft animation across your whole desktop while you work — so static UI does not sit on the same subpixels for minutes at a time. Burn-in insurance you can leave running over a long prompt, a build, or a chat without losing the screen.

There is also a **browser-based fullscreen animation** (no install) for the cases where you want the whole display covered instead.

## The problem

OLED panels and other modern display tech are vulnerable to **burn-in** — the gradual, uneven aging of subpixels that have shown the same image for extended periods. The classic culprits are high-contrast static elements: a menu bar, the macOS dock, IDE chrome, a paused chat window mid-prompt, a paused video frame. Even short exposure adds up; over months the affected pixels age faster than their neighbours and a faint ghost of the static UI remains visible against any uniform background.

The scenarios I run into the most:

- I send a long prompt and walk away (or move to a different monitor) while the response generates — the input UI sits frozen on screen for minutes
- I work on an external monitor with the laptop open, and the laptop's screen sits showing the same desktop for hours
- A long meeting where the same window is in the foreground but I'm not interacting with it
- Anywhere the display is on but the content is effectively frozen

The standard macOS screensavers help a little, but most are designed to look pretty rather than to actually exercise every pixel — they tend to draw bright moving foregrounds against a dark background, which is precisely the *opposite* of what you want. The dark areas don't get exercised at all. They also kick the screen out entirely, which is no good when you actually want to *watch* what's happening.

## The overlay

A translucent, always-on-top, **click-through** window sits over your entire desktop with one of six animated styles drifting across it. Most of the screen stays visible, but every pixel gets briefly obscured as the animation passes over it.

- **Most of the screen is fully visible at any given moment** — you can keep watching a long response stream in, monitor a build, follow a chat, etc.
- **Every pixel gets fully obscured periodically** as elements drift over it, which is what actually refreshes the subpixel exposure
- **It's click-through.** Clicks and keystrokes pass straight through to whatever window is underneath. You can approve edits, switch apps with `⌘-Tab`, scroll, type — exactly as if the overlay weren't there.
- **It runs on every connected display.** Helpful when one display is the working one and another sits idle.

**Six styles** (menu bar ✦ → Style):

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

### Running the overlay

Requires the Swift toolchain that ships with Xcode Command Line Tools. If you don't already have it:

```
xcode-select --install
```

Then double-click `run-overlay.command`, or from a terminal:

```
./run-overlay.command
```

The launcher compiles `overlay.swift` to a cached binary on first run, kills any prior instance, and launches the overlay detached from the terminal. The terminal window is safe to close immediately.

A ✦ icon will appear in the menu bar — that's your control surface. Pause, adjust opacity/speed/density, or quit from there.

## Fullscreen in the browser

For times when obscuring the entire display is what you want — a long job you are walking away from, or a panel you are not using — open `index.html` in a modern browser (or use `run-fullscreen.command` for a chrome-less Chrome app window that starts in fullscreen). The same palette names and anchor colors as the overlay live in `js/palette.js` (kept in sync with the Swift `palettes` array). Five animation modes match the overlay styles except **Blobs**; there is an auto-cycle that rotates through all of them.

Move your mouse to reveal controls. Keyboard:

| Key | Action |
| --- | --- |
| `F` | Toggle fullscreen |
| `Space` | Pause / resume |
| `1`–`5` | Jump to a specific mode |
| `A` | Auto-cycle |
| `[` / `]` | Previous / next palette |
| `Esc` | Exit fullscreen |

No build step for this path — static HTML, CSS, and JavaScript.

## File structure

```
pixelflow/
├── README.md
│
├── overlay.swift             — menu-bar app + overlay window(s) + all six styles (Swift)
├── run-overlay.command       — launcher: compiles + runs detached
│
├── index.html                — browser entry point
├── styles.css                — on-screen controls
├── run-fullscreen.command    — opens the page in a Chrome app window, fullscreen
└── js/
    ├── palette.js            — palette definitions (mirror overlay.swift anchors)
    ├── app.js                — main loop, mode switching, input
    └── modes/
        ├── aurora.js
        ├── plasma.js
        ├── particles.js
        ├── pixelrain.js
        └── sweep.js
```

The overlay is one Swift file: borderless `.floating`-level windows per `NSScreen`, `ignoresMouseEvents = true` for click-through, and a 30 Hz timer driving the styles above.

The browser build splits each animation into `js/modes/*.js`; each mode exposes `init`, `resize`, `reset`, and `render(ctx, time, width, height, brightness, palette)`. Adding another mode means a new file under `js/modes/` plus registration in `app.js`.

## Why this exists

This is one of a series of small projects I'm building to **practice AI prompt engineering** — specifically, getting an entire usable MVP of a tool from a single well-formed prompt rather than building it incrementally over many turns. Then using prompts to as efficiently as possible refactor and iterate. The interesting work is mostly upstream of the code: figuring out which features are actually load-bearing, which trade-offs matter, what the smallest defensible scope looks like, and how to express that in a brief that produces something I'd actually keep using.

The overlay is the piece that maps cleanly onto the real problem: I want to *watch* a long-running prompt finish, not blank the screen entirely. A click-through overlay was the right shape — but only became obvious once a fullscreen-only prototype was sitting in front of me. That iteration loop, even within a single session, is the part of prompt engineering this project is trying to practice. The browser fullscreen view came later as a straightforward way to share the same visual language without Xcode.
