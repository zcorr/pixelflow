import Cocoa
import QuartzCore

// MARK: - Globals

let sRGB: CGColorSpace = CGColorSpaceCreateDeviceRGB()

// MARK: - Palette

struct PaletteAnchor {
    let h: CGFloat
    let s: CGFloat
    let b: CGFloat
}

struct Palette {
    let name: String
    let anchors: [PaletteAnchor]

    func hsb(at index: CGFloat) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        let n = CGFloat(anchors.count)
        var wrapped = index.truncatingRemainder(dividingBy: 1.0)
        if wrapped < 0 { wrapped += 1.0 }
        let pos = wrapped * n
        let i0 = Int(pos) % anchors.count
        let i1 = (i0 + 1) % anchors.count
        let f = pos - CGFloat(Int(pos))
        let a = anchors[i0]
        let b = anchors[i1]
        return (
            h: lerpHue(a.h, b.h, f),
            s: a.s + (b.s - a.s) * f,
            b: a.b + (b.b - a.b) * f
        )
    }

    func rgb(at index: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let v = hsb(at: index)
        let color = NSColor(hue: v.h, saturation: v.s, brightness: v.b, alpha: 1.0)
        guard let rgb = color.usingColorSpace(.deviceRGB) else {
            return (1, 1, 1)
        }
        return (rgb.redComponent, rgb.greenComponent, rgb.blueComponent)
    }
}

func lerpHue(_ h0: CGFloat, _ h1: CGFloat, _ f: CGFloat) -> CGFloat {
    var diff = h1 - h0
    if diff > 0.5 { diff -= 1 }
    if diff < -0.5 { diff += 1 }
    var result = h0 + diff * f
    while result < 0 { result += 1 }
    while result >= 1 { result -= 1 }
    return result
}

// Anchor values mirror `PALETTES` in js/palette.js (macOS overlay + web).
let palettes: [Palette] = [
    Palette(name: "Spectrum", anchors: [
        PaletteAnchor(h: 0.00, s: 0.7, b: 0.95),
        PaletteAnchor(h: 0.16, s: 0.7, b: 0.95),
        PaletteAnchor(h: 0.33, s: 0.7, b: 0.95),
        PaletteAnchor(h: 0.50, s: 0.7, b: 0.95),
        PaletteAnchor(h: 0.66, s: 0.7, b: 0.95),
        PaletteAnchor(h: 0.83, s: 0.7, b: 0.95)
    ]),
    Palette(name: "Aurora", anchors: [
        PaletteAnchor(h: 0.30, s: 0.70, b: 0.85),
        PaletteAnchor(h: 0.45, s: 0.65, b: 0.95),
        PaletteAnchor(h: 0.65, s: 0.70, b: 0.85),
        PaletteAnchor(h: 0.80, s: 0.60, b: 0.90)
    ]),
    Palette(name: "Sunset", anchors: [
        PaletteAnchor(h: 0.95, s: 0.85, b: 0.95),
        PaletteAnchor(h: 0.02, s: 0.90, b: 0.95),
        PaletteAnchor(h: 0.08, s: 0.85, b: 0.95),
        PaletteAnchor(h: 0.13, s: 0.70, b: 0.95)
    ]),
    Palette(name: "Ocean", anchors: [
        PaletteAnchor(h: 0.45, s: 0.70, b: 0.85),
        PaletteAnchor(h: 0.55, s: 0.75, b: 0.90),
        PaletteAnchor(h: 0.60, s: 0.70, b: 0.95),
        PaletteAnchor(h: 0.50, s: 0.60, b: 0.85)
    ]),
    Palette(name: "Cyberpunk", anchors: [
        PaletteAnchor(h: 0.83, s: 0.95, b: 0.95),
        PaletteAnchor(h: 0.50, s: 0.95, b: 0.95),
        PaletteAnchor(h: 0.13, s: 0.85, b: 0.95),
        PaletteAnchor(h: 0.95, s: 0.95, b: 0.85)
    ]),
    Palette(name: "Forest", anchors: [
        PaletteAnchor(h: 0.25, s: 0.70, b: 0.85),
        PaletteAnchor(h: 0.30, s: 0.75, b: 0.90),
        PaletteAnchor(h: 0.18, s: 0.65, b: 0.95),
        PaletteAnchor(h: 0.10, s: 0.60, b: 0.85)
    ])
]

// MARK: - Palette LUT (used by Plasma to avoid per-pixel NSColor allocations)

final class PaletteLUT {
    let size: Int
    var r: [UInt8]
    var g: [UInt8]
    var b: [UInt8]
    private var cachedPalette: Int = -1
    private var cachedOpacity: CGFloat = -1

    init(size: Int = 256) {
        self.size = size
        self.r = Array(repeating: 0, count: size)
        self.g = Array(repeating: 0, count: size)
        self.b = Array(repeating: 0, count: size)
    }

    func rebuildIfNeeded() {
        if cachedPalette == state.paletteIndex && cachedOpacity == state.opacity { return }
        cachedPalette = state.paletteIndex
        cachedOpacity = state.opacity
        let palette = state.palette
        let op = state.opacity
        for i in 0..<size {
            let rgb = palette.rgb(at: CGFloat(i) / CGFloat(size))
            r[i] = UInt8(max(0, min(255, rgb.r * 255 * op)))
            g[i] = UInt8(max(0, min(255, rgb.g * 255 * op)))
            b[i] = UInt8(max(0, min(255, rgb.b * 255 * op)))
        }
    }
}

// MARK: - Shared state

final class State {
    var styleIndex: Int = 0
    var paletteIndex: Int = 0
    var opacity: CGFloat = 0.85
    var speed: Double = 1.0
    var density: Int = 5
    var enabled: Bool = true
    var showMenuBarLabel: Bool = UserDefaults.standard.object(forKey: "showMenuBarLabel") as? Bool ?? true

    var palette: Palette { palettes[paletteIndex] }
}

let state = State()

// MARK: - Style protocol

protocol Style: AnyObject {
    var name: String { get }
    func resize(width: CGFloat, height: CGFloat)
    func populate()
    func update(dt: Double, time: Double)
    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat)
}

extension Style {
    func populate() {}
}

let styleNames = ["Blobs", "Aurora", "Plasma", "Particles", "Pixel rain", "Sweep"]

func makeStyle(at index: Int) -> Style {
    switch index {
    case 0: return BlobsStyle()
    case 1: return AuroraStyle()
    case 2: return PlasmaStyle()
    case 3: return ParticlesStyle()
    case 4: return PixelRainStyle()
    case 5: return SweepStyle()
    default: return BlobsStyle()
    }
}

// MARK: - Blobs

final class BlobsStyle: Style {
    let name = "Blobs"

    private struct Blob {
        var x, y, vx, vy, radius: CGFloat
        var hueIndex: CGFloat
        var hueSpeed: CGFloat
    }

    private var blobs: [Blob] = []
    private var width: CGFloat = 0
    private var height: CGFloat = 0

    func resize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        populate()
    }

    func populate() {
        guard width > 0, height > 0 else { return }
        let count = max(2, state.density)
        blobs.removeAll(keepingCapacity: true)
        blobs.reserveCapacity(count)
        let baseRadius = min(width, height) * 0.16
        for i in 0..<count {
            let angle = Double(i) / Double(count) * .pi * 2 + Double.random(in: -0.4...0.4)
            blobs.append(Blob(
                x: CGFloat.random(in: 0...width),
                y: CGFloat.random(in: 0...height),
                vx: CGFloat(cos(angle)) * 22 + CGFloat.random(in: -10...10),
                vy: CGFloat(sin(angle)) * 22 + CGFloat.random(in: -10...10),
                radius: baseRadius * CGFloat.random(in: 0.7...1.3),
                hueIndex: CGFloat(i) / CGFloat(count),
                hueSpeed: CGFloat.random(in: 0.04...0.10)
            ))
        }
    }

    func update(dt: Double, time: Double) {
        let dts = CGFloat(dt * state.speed)
        for i in 0..<blobs.count {
            blobs[i].x += blobs[i].vx * dts
            blobs[i].y += blobs[i].vy * dts
            blobs[i].hueIndex += blobs[i].hueSpeed * dts

            let r = blobs[i].radius
            if blobs[i].x < -r { blobs[i].x = width + r }
            if blobs[i].x > width + r { blobs[i].x = -r }
            if blobs[i].y < -r { blobs[i].y = height + r }
            if blobs[i].y > height + r { blobs[i].y = -r }
        }
    }

    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat) {
        for blob in blobs {
            let rgb = palette.rgb(at: blob.hueIndex)
            let inner = CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: opacity)
            let mid1  = CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: opacity * 0.85)
            let mid2  = CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: opacity * 0.30)
            let outer = CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 0)
            guard let gradient = CGGradient(
                colorsSpace: sRGB,
                colors: [inner, mid1, mid2, outer] as CFArray,
                locations: [0.0, 0.4, 0.75, 1.0]
            ) else { continue }
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: blob.x, y: blob.y),
                startRadius: 0,
                endCenter: CGPoint(x: blob.x, y: blob.y),
                endRadius: blob.radius,
                options: []
            )
        }
    }
}

// MARK: - Aurora

final class AuroraStyle: Style {
    let name = "Aurora"

    private struct Band {
        var yFrac: CGFloat
        var hueOffset: CGFloat
        var phase: CGFloat
        var bandSpeed: CGFloat
        var amplitude: CGFloat
    }

    private var bands: [Band] = []
    private var width: CGFloat = 0
    private var height: CGFloat = 0

    func resize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        populate()
    }

    func populate() {
        let count = max(2, min(8, state.density))
        bands.removeAll(keepingCapacity: true)
        bands.reserveCapacity(count)
        for i in 0..<count {
            bands.append(Band(
                yFrac: 0.1 + CGFloat(i) / max(1, CGFloat(count - 1)) * 0.8,
                hueOffset: CGFloat(i) / CGFloat(count),
                phase: CGFloat.random(in: 0...(.pi * 2)),
                bandSpeed: CGFloat.random(in: 0.30...0.70),
                amplitude: CGFloat.random(in: 0.18...0.36)
            ))
        }
    }

    func update(dt: Double, time: Double) {}  // time-driven

    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat) {
        let t = CGFloat(time)
        let speedF = CGFloat(state.speed)
        let step = max(CGFloat(4), width / 240)

        for band in bands {
            let yCenter = height * band.yFrac
            let amp = height * band.amplitude
            let lineHeight = height * 0.18

            let path = CGMutablePath()
            var first = true
            var x: CGFloat = 0
            while x <= width {
                let wave = sin(x * 0.0045 + t * band.bandSpeed * speedF + band.phase) * amp
                         + sin(x * 0.011 + t * band.bandSpeed * speedF * 1.4) * amp * 0.45
                let y = yCenter + wave
                if first {
                    path.move(to: CGPoint(x: x, y: y))
                    first = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                x += step
            }

            let rgb = palette.rgb(at: band.hueOffset + t * 0.05)

            // Outer glow (thick + low opacity)
            ctx.addPath(path)
            ctx.setStrokeColor(CGColor(red: rgb.r, green: rgb.g, blue: rgb.b,
                                       alpha: opacity * 0.18))
            ctx.setLineWidth(lineHeight * 1.6)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()

            // Core
            ctx.addPath(path)
            ctx.setStrokeColor(CGColor(red: rgb.r, green: rgb.g, blue: rgb.b,
                                       alpha: opacity * 0.50))
            ctx.setLineWidth(lineHeight * 0.55)
            ctx.strokePath()
        }
    }
}

// MARK: - Plasma

final class PlasmaStyle: Style {
    let name = "Plasma"

    private var width: CGFloat = 0
    private var height: CGFloat = 0
    private let scale: Int = 6
    private var lowW: Int = 0
    private var lowH: Int = 0
    private var bytesPerRow: Int = 0
    private var bufferSize: Int = 0
    private var buffer: UnsafeMutablePointer<UInt8>?
    private let lut = PaletteLUT()

    deinit {
        buffer?.deallocate()
        buffer = nil
    }

    func resize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        let nW = max(1, Int(width) / scale)
        let nH = max(1, Int(height) / scale)
        let nBPR = nW * 4
        let nSize = nBPR * nH
        if nSize != bufferSize {
            buffer?.deallocate()
            buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: nSize)
            bufferSize = nSize
        }
        lowW = nW
        lowH = nH
        bytesPerRow = nBPR
    }

    func update(dt: Double, time: Double) {}  // time-driven

    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat) {
        guard let buf = buffer, lowW > 0, lowH > 0 else { return }

        lut.rebuildIfNeeded()
        let alphaByte = UInt8(max(0, min(255, opacity * 255)))

        let tt = CGFloat(time * 0.6)
        let lutSize = lut.size
        let halfW = CGFloat(lowW) / 2
        let halfH = CGFloat(lowH) / 2
        var pixIdx = 0

        for y in 0..<lowH {
            let yf = CGFloat(y)
            let yPart = sin(yf * 0.045 + tt * 1.3)
            let dy = yf - halfH
            for x in 0..<lowW {
                let xf = CGFloat(x)
                let dx = xf - halfW
                let v = sin(xf * 0.04 + tt)
                      + yPart
                      + sin((xf + yf) * 0.03 + tt * 0.7)
                      + sin(sqrt(dx * dx + dy * dy) * 0.05 + tt * 1.1)
                let norm = (v + 4) / 8  // 0–1
                var lutIdx = Int(norm * CGFloat(lutSize) + tt * 30)
                lutIdx = ((lutIdx % lutSize) + lutSize) % lutSize

                buf[pixIdx]     = lut.r[lutIdx]
                buf[pixIdx + 1] = lut.g[lutIdx]
                buf[pixIdx + 2] = lut.b[lutIdx]
                buf[pixIdx + 3] = alphaByte
                pixIdx += 4
            }
        }

        // Wrap the buffer in a CGContext, snapshot to an image, draw scaled.
        // makeImage() copies the data so the buffer is free to be overwritten next frame.
        guard let bitmapCtx = CGContext(
            data: buf,
            width: lowW,
            height: lowH,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }
        guard let image = bitmapCtx.makeImage() else { return }

        ctx.interpolationQuality = .medium
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
}

// MARK: - Particles

final class ParticlesStyle: Style {
    let name = "Particles"

    private struct Particle {
        var x, y, vx, vy, size: CGFloat
        var hueIndex: CGFloat
        var hueSpeed: CGFloat
    }

    private var particles: [Particle] = []
    private var width: CGFloat = 0
    private var height: CGFloat = 0

    func resize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        populate()
    }

    func populate() {
        guard width > 0, height > 0 else { return }
        let count = max(20, state.density * 18)
        particles.removeAll(keepingCapacity: true)
        particles.reserveCapacity(count)
        for _ in 0..<count {
            particles.append(Particle(
                x: CGFloat.random(in: 0...width),
                y: CGFloat.random(in: 0...height),
                vx: CGFloat.random(in: -50...50),
                vy: CGFloat.random(in: -50...50),
                size: CGFloat.random(in: 30...90),
                hueIndex: CGFloat.random(in: 0...1),
                hueSpeed: CGFloat.random(in: 0.01...0.05)
            ))
        }
    }

    func update(dt: Double, time: Double) {
        let dts = CGFloat(dt * state.speed)
        for i in 0..<particles.count {
            particles[i].x += particles[i].vx * dts
            particles[i].y += particles[i].vy * dts
            particles[i].hueIndex += particles[i].hueSpeed * dts

            let s = particles[i].size
            if particles[i].x < -s { particles[i].x = width + s }
            if particles[i].x > width + s { particles[i].x = -s }
            if particles[i].y < -s { particles[i].y = height + s }
            if particles[i].y > height + s { particles[i].y = -s }
        }
    }

    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat) {
        for p in particles {
            let rgb = palette.rgb(at: p.hueIndex)
            let inner = CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: opacity * 0.55)
            let outer = CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 0)
            guard let gradient = CGGradient(
                colorsSpace: sRGB,
                colors: [inner, outer] as CFArray,
                locations: [0.0, 1.0]
            ) else { continue }
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: p.x, y: p.y),
                startRadius: 0,
                endCenter: CGPoint(x: p.x, y: p.y),
                endRadius: p.size,
                options: []
            )
        }
    }
}

// MARK: - Pixel rain

final class PixelRainStyle: Style {
    let name = "Pixel rain"

    private let pixelSize: CGFloat = 12

    private struct Drop {
        var col: Int
        var y: CGFloat
        var speed: CGFloat
        var hueIndex: CGFloat
        var hueSpeed: CGFloat
        var trail: Int
    }

    private var drops: [Drop] = []
    private var width: CGFloat = 0
    private var height: CGFloat = 0
    private var cols: Int = 0

    func resize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        cols = max(1, Int(width / pixelSize))
        populate()
    }

    func populate() {
        guard cols > 0 else { return }
        let count = min(cols, max(8, state.density * 8))
        drops.removeAll(keepingCapacity: true)
        drops.reserveCapacity(count)
        var available = Array(0..<cols)
        available.shuffle()
        for i in 0..<count {
            drops.append(Drop(
                col: available[i],
                y: CGFloat.random(in: 0...height),
                speed: CGFloat.random(in: 80...220),
                hueIndex: CGFloat.random(in: 0...1),
                hueSpeed: CGFloat.random(in: 0.05...0.15),
                trail: Int.random(in: 8...18)
            ))
        }
    }

    func update(dt: Double, time: Double) {
        let dts = CGFloat(dt * state.speed)
        for i in 0..<drops.count {
            drops[i].y += drops[i].speed * dts
            drops[i].hueIndex += drops[i].hueSpeed * dts

            if drops[i].y - CGFloat(drops[i].trail) * pixelSize > height {
                drops[i].y = -CGFloat(drops[i].trail) * pixelSize
                drops[i].speed = CGFloat.random(in: 80...220)
                drops[i].hueIndex = CGFloat.random(in: 0...1)
                drops[i].hueSpeed = CGFloat.random(in: 0.05...0.15)
                drops[i].trail = Int.random(in: 8...18)
            }
        }
    }

    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat) {
        let ps = pixelSize
        for drop in drops {
            let rgb = palette.rgb(at: drop.hueIndex)
            let x = CGFloat(drop.col) * ps
            for j in 0..<drop.trail {
                let y = drop.y - CGFloat(j) * ps
                if y < -ps || y > height { continue }
                let fade = 1.0 - CGFloat(j) / CGFloat(drop.trail)
                let alpha = fade * opacity * 0.85
                ctx.setFillColor(CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: alpha))
                ctx.fill(CGRect(x: x, y: y, width: ps, height: ps))
            }
        }
    }
}

// MARK: - Sweep

final class SweepStyle: Style {
    let name = "Sweep"

    private struct Sweep {
        var angle: CGFloat
        var speed: CGFloat
        var hueOffset: CGFloat
        var bandWidthFrac: CGFloat
    }

    private var sweeps: [Sweep] = []
    private var width: CGFloat = 0
    private var height: CGFloat = 0

    func resize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        populate()
    }

    func populate() {
        let count = max(2, min(8, state.density / 2 + 1))
        sweeps.removeAll(keepingCapacity: true)
        sweeps.reserveCapacity(count)
        for i in 0..<count {
            sweeps.append(Sweep(
                angle: CGFloat(i) * .pi / CGFloat(count) + CGFloat.random(in: -0.3...0.3),
                speed: CGFloat.random(in: 0.4...1.0),
                hueOffset: CGFloat(i) / CGFloat(count),
                bandWidthFrac: CGFloat.random(in: 0.15...0.30)
            ))
        }
    }

    func update(dt: Double, time: Double) {}  // time-driven

    func render(in ctx: CGContext, time: Double, width: CGFloat, height: CGFloat,
                palette: Palette, opacity: CGFloat) {
        let t = CGFloat(time)
        let speedF = CGFloat(state.speed)
        let diag = sqrt(width * width + height * height)
        let cx = width / 2
        let cy = height / 2

        for sweep in sweeps {
            let angle = sweep.angle + t * 0.04 * speedF
            let cosA = cos(angle)
            let sinA = sin(angle)
            let period = diag * 1.6
            let pos = (t * sweep.speed * 200 * speedF)
                .truncatingRemainder(dividingBy: period) - period / 2

            let px = cx + cosA * pos
            let py = cy + sinA * pos

            let bandWidth = diag * sweep.bandWidthFrac
            let gx0 = px - cosA * bandWidth / 2
            let gy0 = py - sinA * bandWidth / 2
            let gx1 = px + cosA * bandWidth / 2
            let gy1 = py + sinA * bandWidth / 2

            let rgb = palette.rgb(at: sweep.hueOffset + t * 0.05)
            guard let gradient = CGGradient(
                colorsSpace: sRGB,
                colors: [
                    CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 0),
                    CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: opacity * 0.55),
                    CGColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 0)
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            ) else { continue }
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: gx0, y: gy0),
                end: CGPoint(x: gx1, y: gy1),
                options: []
            )
        }
    }
}

// MARK: - Overlay view

final class OverlayView: NSView {
    var style: Style?
    private var lastStyleIndex: Int = -1
    private var lastDensity: Int = -1
    private var lastUpdate: TimeInterval = CACurrentMediaTime()
    private let startTime: TimeInterval = CACurrentMediaTime()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = CGColor(gray: 0, alpha: 0)
        layer?.isOpaque = false
        applyState()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override var isFlipped: Bool { true }

    func applyState() {
        if lastStyleIndex != state.styleIndex {
            style = makeStyle(at: state.styleIndex)  // ARC releases the previous one (frees Plasma's pixel buffer via deinit)
            style?.resize(width: bounds.width, height: bounds.height)
            lastStyleIndex = state.styleIndex
            lastDensity = state.density
        } else if lastDensity != state.density {
            style?.populate()
            lastDensity = state.density
        }
    }

    func update() {
        applyState()

        let now = CACurrentMediaTime()
        let dt = min(0.1, now - lastUpdate)
        lastUpdate = now

        guard state.enabled else { return }

        let t = now - startTime
        style?.update(dt: dt, time: t)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        guard state.enabled, let style = style else { return }
        let t = CACurrentMediaTime() - startTime
        style.render(in: ctx, time: t, width: bounds.width, height: bounds.height,
                     palette: state.palette, opacity: state.opacity)
    }
}

// MARK: - Window

final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        hasShadow = false
        isMovable = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [OverlayWindow] = []
    private var views: [OverlayView] = []
    private var statusItem: NSStatusItem!
    private var pauseItem: NSMenuItem!
    private var labelItem: NSMenuItem!
    private var styleParentItem: NSMenuItem!
    private var paletteParentItem: NSMenuItem!
    private var styleMenu: NSMenu!
    private var paletteMenu: NSMenu!
    private var opacityMenu: NSMenu!
    private var speedMenu: NSMenu!
    private var densityMenu: NSMenu!
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        rebuildWindows()
        setupStatusItem()
        startTimer()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
        for view in views { view.style = nil }   // triggers Plasma deinit → pixel buffer freed
        views.removeAll()
        for window in windows { window.orderOut(nil); window.close() }
        windows.removeAll()
    }

    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func rebuildWindows() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        for view in views { view.style = nil }
        views.removeAll()

        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
            window.contentView = view
            window.orderFrontRegardless()
            windows.append(window)
            views.append(view)
        }
    }

    @objc private func screensChanged() {
        rebuildWindows()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "pixelflow") {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageLeft
            }
            button.toolTip = "pixelflow overlay — click for controls"
        }
        statusItem.isVisible = true
        applyMenuBarLabel()

        let menu = NSMenu()

        pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        menu.addItem(NSMenuItem.separator())

        styleMenu = NSMenu()
        for (i, name) in styleNames.enumerated() {
            let item = NSMenuItem(title: name, action: #selector(setStyle(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            item.state = (i == state.styleIndex) ? .on : .off
            styleMenu.addItem(item)
        }
        styleParentItem = NSMenuItem(title: styleParentTitle(), action: nil, keyEquivalent: "")
        styleParentItem.submenu = styleMenu
        menu.addItem(styleParentItem)

        paletteMenu = NSMenu()
        for (i, palette) in palettes.enumerated() {
            let item = NSMenuItem(title: palette.name, action: #selector(setPalette(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            item.state = (i == state.paletteIndex) ? .on : .off
            paletteMenu.addItem(item)
        }
        paletteParentItem = NSMenuItem(title: paletteParentTitle(), action: nil, keyEquivalent: "")
        paletteParentItem.submenu = paletteMenu
        menu.addItem(paletteParentItem)

        menu.addItem(NSMenuItem.separator())

        opacityMenu = NSMenu()
        for value in [30, 50, 70, 85, 100] {
            let item = NSMenuItem(title: "\(value)%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.tag = value
            item.state = (value == Int(state.opacity * 100)) ? .on : .off
            opacityMenu.addItem(item)
        }
        let opacityParent = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        opacityParent.submenu = opacityMenu
        menu.addItem(opacityParent)

        speedMenu = NSMenu()
        for (label, value) in [("0.5×", 50), ("1.0×", 100), ("1.5×", 150), ("2.5×", 250)] {
            let item = NSMenuItem(title: label, action: #selector(setSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = value
            item.state = (value == Int(state.speed * 100)) ? .on : .off
            speedMenu.addItem(item)
        }
        let speedParent = NSMenuItem(title: "Speed", action: nil, keyEquivalent: "")
        speedParent.submenu = speedMenu
        menu.addItem(speedParent)

        densityMenu = NSMenu()
        for value in [2, 4, 6, 9, 12] {
            let item = NSMenuItem(title: "\(value)", action: #selector(setDensity(_:)), keyEquivalent: "")
            item.target = self
            item.tag = value
            item.state = (value == state.density) ? .on : .off
            densityMenu.addItem(item)
        }
        let densityParent = NSMenuItem(title: "Density", action: nil, keyEquivalent: "")
        densityParent.submenu = densityMenu
        menu.addItem(densityParent)

        menu.addItem(NSMenuItem.separator())
        labelItem = NSMenuItem(title: "Show label in menu bar",
                               action: #selector(toggleMenuBarLabel), keyEquivalent: "")
        labelItem.target = self
        labelItem.state = state.showMenuBarLabel ? .on : .off
        menu.addItem(labelItem)

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit pixelflow", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func styleParentTitle() -> String { "Style: \(styleNames[state.styleIndex])" }
    private func paletteParentTitle() -> String { "Palette: \(palettes[state.paletteIndex].name)" }

    private func tick() {
        for view in views { view.update() }
    }

    @objc private func togglePause() {
        state.enabled.toggle()
        pauseItem.title = state.enabled ? "Pause" : "Resume"
        for view in views { view.needsDisplay = true }
    }

    @objc private func setStyle(_ sender: NSMenuItem) {
        state.styleIndex = sender.tag
        updateMenuSelection(in: styleMenu, action: #selector(setStyle(_:)), tag: sender.tag)
        styleParentItem.title = styleParentTitle()
    }

    @objc private func setPalette(_ sender: NSMenuItem) {
        state.paletteIndex = sender.tag
        updateMenuSelection(in: paletteMenu, action: #selector(setPalette(_:)), tag: sender.tag)
        paletteParentItem.title = paletteParentTitle()
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        state.opacity = CGFloat(sender.tag) / 100.0
        updateMenuSelection(in: opacityMenu, action: #selector(setOpacity(_:)), tag: sender.tag)
    }

    @objc private func setSpeed(_ sender: NSMenuItem) {
        state.speed = Double(sender.tag) / 100.0
        updateMenuSelection(in: speedMenu, action: #selector(setSpeed(_:)), tag: sender.tag)
    }

    @objc private func setDensity(_ sender: NSMenuItem) {
        state.density = sender.tag
        updateMenuSelection(in: densityMenu, action: #selector(setDensity(_:)), tag: sender.tag)
    }

    private func updateMenuSelection(in menu: NSMenu, action: Selector, tag: Int) {
        for item in menu.items where item.action == action {
            item.state = (item.tag == tag) ? .on : .off
        }
    }

    @objc private func toggleMenuBarLabel() {
        state.showMenuBarLabel.toggle()
        UserDefaults.standard.set(state.showMenuBarLabel, forKey: "showMenuBarLabel")
        labelItem.state = state.showMenuBarLabel ? .on : .off
        applyMenuBarLabel()
    }

    private func applyMenuBarLabel() {
        guard let button = statusItem.button else { return }
        button.title = state.showMenuBarLabel ? " pixelflow" : ""
        button.imagePosition = state.showMenuBarLabel ? .imageLeft : .imageOnly
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Boot

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
