class ParticlesMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.lastT = -1;
        this.spawn();
    }

    spawn() {
        const count = Math.max(120, Math.round((this.w * this.h) / 14000));
        this.particles = [];
        for (let i = 0; i < count; i++) {
            this.particles.push({
                x: Math.random() * this.w,
                y: Math.random() * this.h,
                vx: (Math.random() - 0.5) * 90,
                vy: (Math.random() - 0.5) * 90,
                size: 40 + Math.random() * 110,
                hueIndex: Math.random(),
                hueSpeed: 0.01 + Math.random() * 0.04
            });
        }
    }

    resize(w, h) {
        this.w = w;
        this.h = h;
        this.spawn();
    }

    reset() {
        this.spawn();
    }

    render(ctx, t, w, h, brightness, palette) {
        const dt = this.lastT < 0 ? 1 / 60 : Math.min(0.1, t - this.lastT);
        this.lastT = t;

        const bg = rgbAt(palette, t * 0.04);
        ctx.fillStyle = rgbaString(bg, Math.min(1, 0.35 * brightness));
        ctx.fillRect(0, 0, w, h);

        ctx.globalCompositeOperation = 'lighter';

        for (const p of this.particles) {
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.hueIndex = (p.hueIndex + p.hueSpeed * dt) % 1;
            if (p.hueIndex < 0) p.hueIndex += 1;

            if (p.x < -p.size) p.x = w + p.size;
            else if (p.x > w + p.size) p.x = -p.size;
            if (p.y < -p.size) p.y = h + p.size;
            else if (p.y > h + p.size) p.y = -p.size;

            const rgb = rgbAt(palette, p.hueIndex);
            const grad = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size);
            grad.addColorStop(0, rgbaString(rgb, 0.55 * brightness));
            grad.addColorStop(1, rgbaString(rgb, 0));
            ctx.fillStyle = grad;
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fill();
        }

        ctx.globalCompositeOperation = 'source-over';
    }
}
