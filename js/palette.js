/**
 * Palette definitions and sampling — kept in sync with `palettes` in overlay.swift.
 * HSB components use the same 0–1 range as NSColor (hue/saturation/brightness).
 */

const PALETTES = [
    {
        name: 'Spectrum',
        anchors: [
            { h: 0.0, s: 0.7, b: 0.95 },
            { h: 0.16, s: 0.7, b: 0.95 },
            { h: 0.33, s: 0.7, b: 0.95 },
            { h: 0.5, s: 0.7, b: 0.95 },
            { h: 0.66, s: 0.7, b: 0.95 },
            { h: 0.83, s: 0.7, b: 0.95 }
        ]
    },
    {
        name: 'Aurora',
        anchors: [
            { h: 0.3, s: 0.7, b: 0.85 },
            { h: 0.45, s: 0.65, b: 0.95 },
            { h: 0.65, s: 0.7, b: 0.85 },
            { h: 0.8, s: 0.6, b: 0.9 }
        ]
    },
    {
        name: 'Sunset',
        anchors: [
            { h: 0.95, s: 0.85, b: 0.95 },
            { h: 0.02, s: 0.9, b: 0.95 },
            { h: 0.08, s: 0.85, b: 0.95 },
            { h: 0.13, s: 0.7, b: 0.95 }
        ]
    },
    {
        name: 'Ocean',
        anchors: [
            { h: 0.45, s: 0.7, b: 0.85 },
            { h: 0.55, s: 0.75, b: 0.9 },
            { h: 0.6, s: 0.7, b: 0.95 },
            { h: 0.5, s: 0.6, b: 0.85 }
        ]
    },
    {
        name: 'Cyberpunk',
        anchors: [
            { h: 0.83, s: 0.95, b: 0.95 },
            { h: 0.5, s: 0.95, b: 0.95 },
            { h: 0.13, s: 0.85, b: 0.95 },
            { h: 0.95, s: 0.95, b: 0.85 }
        ]
    },
    {
        name: 'Forest',
        anchors: [
            { h: 0.25, s: 0.7, b: 0.85 },
            { h: 0.3, s: 0.75, b: 0.9 },
            { h: 0.18, s: 0.65, b: 0.95 },
            { h: 0.1, s: 0.6, b: 0.85 }
        ]
    }
];

function lerpHue(h0, h1, f) {
    let diff = h1 - h0;
    if (diff > 0.5) diff -= 1;
    if (diff < -0.5) diff += 1;
    let result = h0 + diff * f;
    while (result < 0) result += 1;
    while (result >= 1) result -= 1;
    return result;
}

function hsbAt(palette, index) {
    const anchors = palette.anchors;
    const n = anchors.length;
    let wrapped = index % 1;
    if (wrapped < 0) wrapped += 1;
    const pos = wrapped * n;
    const i0 = Math.floor(pos) % n;
    const i1 = (i0 + 1) % n;
    const f = pos - Math.floor(pos);
    const a = anchors[i0];
    const b = anchors[i1];
    return {
        h: lerpHue(a.h, b.h, f),
        s: a.s + (b.s - a.s) * f,
        br: a.b + (b.b - a.b) * f
    };
}

/** HSV (same convention as NSColor brightness) → linear RGB 0–1. */
function hsbToRgb(h, s, v) {
    h = ((h % 1) + 1) % 1;
    const i = Math.floor(h * 6) % 6;
    const f = h * 6 - i;
    const p = v * (1 - s);
    const q = v * (1 - f * s);
    const t = v * (1 - (1 - f) * s);
    let r1;
    let g1;
    let b1;
    switch (i) {
        case 0:
            r1 = v;
            g1 = t;
            b1 = p;
            break;
        case 1:
            r1 = q;
            g1 = v;
            b1 = p;
            break;
        case 2:
            r1 = p;
            g1 = v;
            b1 = t;
            break;
        case 3:
            r1 = p;
            g1 = q;
            b1 = v;
            break;
        case 4:
            r1 = t;
            g1 = p;
            b1 = v;
            break;
        default:
            r1 = v;
            g1 = p;
            b1 = q;
            break;
    }
    return { r: r1, g: g1, b: b1 };
}

function rgbAt(palette, index) {
    const { h, s, br } = hsbAt(palette, index);
    return hsbToRgb(h, s, br);
}

function rgbaString(rgb, alpha) {
    const r = Math.round(rgb.r * 255);
    const g = Math.round(rgb.g * 255);
    const b = Math.round(rgb.b * 255);
    return `rgba(${r},${g},${b},${alpha})`;
}

/**
 * Same role as `PaletteLUT` in overlay.swift: pre-multiplies palette samples by opacity
 * for fast plasma rendering.
 */
class PaletteLUT {
    constructor(size = 256) {
        this.size = size;
        this.r = new Uint8Array(size);
        this.g = new Uint8Array(size);
        this.b = new Uint8Array(size);
        this._cachePalette = null;
        this._cacheOpacity = -1;
    }

    rebuildIfNeeded(palette, opacity) {
        if (this._cachePalette === palette && this._cacheOpacity === opacity) return;
        this._cachePalette = palette;
        this._cacheOpacity = opacity;
        const op = opacity;
        const n = this.size;
        for (let i = 0; i < n; i++) {
            const rgb = rgbAt(palette, i / n);
            this.r[i] = Math.max(0, Math.min(255, rgb.r * 255 * op));
            this.g[i] = Math.max(0, Math.min(255, rgb.g * 255 * op));
            this.b[i] = Math.max(0, Math.min(255, rgb.b * 255 * op));
        }
    }
}
