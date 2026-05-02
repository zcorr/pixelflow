class SweepMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.sweeps = [
            { angle: 0, speed: 0.7, hueIndex: 0, width: 0.55 },
            { angle: Math.PI / 2, speed: 1.1, hueIndex: 110 / 360, width: 0.45 },
            { angle: Math.PI / 4, speed: 0.5, hueIndex: 230 / 360, width: 0.65 },
            { angle: -Math.PI / 4, speed: 0.9, hueIndex: 310 / 360, width: 0.4 }
        ];
    }

    resize(w, h) {
        this.w = w;
        this.h = h;
    }

    reset() {}

    render(ctx, t, w, h, brightness, palette) {
        const base = rgbAt(palette, t * 0.03);
        const base2 = rgbAt(palette, t * 0.03 + 0.17);
        const baseGrad = ctx.createLinearGradient(0, 0, w, h);
        baseGrad.addColorStop(0, rgbaString(base, 0.45 * brightness));
        baseGrad.addColorStop(1, rgbaString(base2, 0.55 * brightness));
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

            const period = diag * 1.6;
            const pos = ((t * sweep.speed * 200) % period) - period / 2;

            const px = cx + cos * pos;
            const py = cy + sin * pos;

            const bandWidth = diag * sweep.width;
            const gx0 = px - cos * bandWidth / 2;
            const gy0 = py - sin * bandWidth / 2;
            const gx1 = px + cos * bandWidth / 2;
            const gy1 = py + sin * bandWidth / 2;

            const rgb = rgbAt(palette, sweep.hueIndex + t * 0.05);
            const grad = ctx.createLinearGradient(gx0, gy0, gx1, gy1);
            grad.addColorStop(0, rgbaString(rgb, 0));
            grad.addColorStop(0.5, rgbaString(rgb, 0.55 * brightness));
            grad.addColorStop(1, rgbaString(rgb, 0));

            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, w, h);
        }

        ctx.globalCompositeOperation = 'source-over';
    }
}
