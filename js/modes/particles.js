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
                hue: Math.random() * 360,
                hueSpeed: 8 + Math.random() * 30
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

    render(ctx, t, w, h, brightness) {
        const dt = this.lastT < 0 ? 1 / 60 : Math.min(0.1, t - this.lastT);
        this.lastT = t;

        // Slowly-shifting base color so background pixels also change
        const bgHue = (t * 14) % 360;
        ctx.fillStyle = `hsl(${bgHue}, 35%, ${12 * brightness}%)`;
        ctx.fillRect(0, 0, w, h);

        ctx.globalCompositeOperation = 'lighter';

        for (const p of this.particles) {
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.hue = (p.hue + p.hueSpeed * dt) % 360;

            if (p.x < -p.size) p.x = w + p.size;
            else if (p.x > w + p.size) p.x = -p.size;
            if (p.y < -p.size) p.y = h + p.size;
            else if (p.y > h + p.size) p.y = -p.size;

            const grad = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size);
            grad.addColorStop(0, `hsla(${p.hue}, 95%, 62%, ${0.55 * brightness})`);
            grad.addColorStop(0.45, `hsla(${p.hue}, 95%, 52%, ${0.18 * brightness})`);
            grad.addColorStop(1, `hsla(${p.hue}, 95%, 50%, 0)`);
            ctx.fillStyle = grad;
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fill();
        }

        ctx.globalCompositeOperation = 'source-over';
    }
}
