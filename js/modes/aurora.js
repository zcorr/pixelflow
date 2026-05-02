class AuroraMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.bands = [];
        const bandCount = 6;
        for (let i = 0; i < bandCount; i++) {
            this.bands.push({
                yFrac: 0.1 + (i / (bandCount - 1)) * 0.8,
                hueIndex: i / bandCount,
                phase: Math.random() * Math.PI * 2,
                speed: 0.25 + Math.random() * 0.4,
                amplitude: 0.18 + Math.random() * 0.18
            });
        }
    }

    resize(w, h) {
        this.w = w;
        this.h = h;
    }

    reset() {}

    render(ctx, t, w, h, brightness, palette) {
        const bg = rgbAt(palette, t * 0.02);
        ctx.fillStyle = rgbaString(bg, Math.min(1, 0.14 * brightness));
        ctx.fillRect(0, 0, w, h);

        const step = Math.max(4, Math.round(w / 240));
        const time = t;

        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';

        for (const band of this.bands) {
            const yCenter = h * band.yFrac;
            const amp = h * band.amplitude;
            const lineHeight = h * 0.18;
            const rgb = rgbAt(palette, band.hueIndex + time * 0.05);

            ctx.beginPath();
            for (let x = 0; x <= w; x += step) {
                const wave = Math.sin(x * 0.0045 + time * band.speed + band.phase) * amp
                           + Math.sin(x * 0.011 + time * band.speed * 1.4) * amp * 0.45;
                const y = yCenter + wave;
                if (x === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }

            ctx.strokeStyle = rgbaString(rgb, brightness * 0.18);
            ctx.lineWidth = lineHeight * 1.6;
            ctx.stroke();

            ctx.strokeStyle = rgbaString(rgb, brightness * 0.5);
            ctx.lineWidth = lineHeight * 0.55;
            ctx.stroke();
        }
    }
}
