class SweepMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.sweeps = [
            { angle: 0,             speed: 0.7, hueOffset: 0,   width: 0.55 },
            { angle: Math.PI / 2,   speed: 1.1, hueOffset: 110, width: 0.45 },
            { angle: Math.PI / 4,   speed: 0.5, hueOffset: 230, width: 0.65 },
            { angle: -Math.PI / 4,  speed: 0.9, hueOffset: 310, width: 0.4  }
        ];
    }

    resize(w, h) {
        this.w = w;
        this.h = h;
    }

    reset() {}

    render(ctx, t, w, h, brightness) {
        const baseHue = (t * 22) % 360;

        // Base color that itself shifts continuously
        const baseGrad = ctx.createLinearGradient(0, 0, w, h);
        baseGrad.addColorStop(0, `hsl(${baseHue}, 60%, ${22 * brightness}%)`);
        baseGrad.addColorStop(1, `hsl(${(baseHue + 80) % 360}, 60%, ${28 * brightness}%)`);
        ctx.fillStyle = baseGrad;
        ctx.fillRect(0, 0, w, h);

        ctx.globalCompositeOperation = 'lighter';

        const diag = Math.sqrt(w * w + h * h);
        const cx = w / 2;
        const cy = h / 2;

        for (const sweep of this.sweeps) {
            const angle = sweep.angle + t * 0.04;
            const cos = Math.cos(angle);
            const sin = Math.sin(angle);

            // Position along the angle-direction axis, oscillating across the diagonal
            const period = diag * 1.6;
            const pos = ((t * sweep.speed * 240) % period) - period / 2;

            const px = cx + cos * pos;
            const py = cy + sin * pos;

            const bandWidth = diag * sweep.width;
            const gx0 = px - cos * bandWidth / 2;
            const gy0 = py - sin * bandWidth / 2;
            const gx1 = px + cos * bandWidth / 2;
            const gy1 = py + sin * bandWidth / 2;

            const grad = ctx.createLinearGradient(gx0, gy0, gx1, gy1);
            const hue = (baseHue + sweep.hueOffset) % 360;
            grad.addColorStop(0, `hsla(${hue}, 85%, 55%, 0)`);
            grad.addColorStop(0.5, `hsla(${hue}, 95%, 62%, ${0.55 * brightness})`);
            grad.addColorStop(1, `hsla(${hue}, 85%, 55%, 0)`);

            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, w, h);
        }

        ctx.globalCompositeOperation = 'source-over';
    }
}
