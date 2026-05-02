class AuroraMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.bands = [];
        const bandCount = 6;
        for (let i = 0; i < bandCount; i++) {
            this.bands.push({
                yFrac: 0.1 + (i / (bandCount - 1)) * 0.8,
                hueOffset: (i / bandCount) * 360,
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

    render(ctx, t, w, h, brightness) {
        const baseHue = (t * 18) % 360;

        // Base full-screen gradient — covers every pixel and shifts color
        const baseGrad = ctx.createLinearGradient(0, 0, w, h);
        baseGrad.addColorStop(0, `hsl(${baseHue}, 70%, ${22 * brightness}%)`);
        baseGrad.addColorStop(0.5, `hsl(${(baseHue + 60) % 360}, 70%, ${30 * brightness}%)`);
        baseGrad.addColorStop(1, `hsl(${(baseHue + 140) % 360}, 70%, ${22 * brightness}%)`);
        ctx.fillStyle = baseGrad;
        ctx.fillRect(0, 0, w, h);

        // Aurora bands on top — additive so the whole base color shows through
        ctx.globalCompositeOperation = 'lighter';
        const step = Math.max(4, Math.round(w / 240));

        for (const band of this.bands) {
            const yCenter = h * band.yFrac;
            const amp = h * band.amplitude;
            const hue = (baseHue + band.hueOffset + t * 25) % 360;

            ctx.beginPath();
            for (let x = 0; x <= w; x += step) {
                const wave = Math.sin(x * 0.0045 + t * band.speed + band.phase) * amp
                           + Math.sin(x * 0.011 + t * band.speed * 1.4) * amp * 0.45;
                const y = yCenter + wave;
                if (x === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }

            const lineHeight = h * 0.18;
            const grad = ctx.createLinearGradient(0, yCenter - lineHeight, 0, yCenter + lineHeight);
            grad.addColorStop(0, `hsla(${hue}, 95%, 65%, 0)`);
            grad.addColorStop(0.5, `hsla(${hue}, 95%, 65%, ${0.55 * brightness})`);
            grad.addColorStop(1, `hsla(${hue}, 95%, 65%, 0)`);

            ctx.strokeStyle = grad;
            ctx.lineWidth = lineHeight * 1.4;
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            ctx.stroke();
        }

        ctx.globalCompositeOperation = 'source-over';
    }
}
