class PixelRainMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.pixelSize = 10;
        this.lastT = -1;
        this.spawn();
    }

    spawn() {
        this.cols = Math.ceil(this.w / this.pixelSize);
        this.drops = [];
        for (let i = 0; i < this.cols; i++) {
            this.drops.push(this.makeDrop(true));
        }
    }

    makeDrop(initial) {
        return {
            y: initial ? Math.random() * this.h : -this.pixelSize * (8 + Math.random() * 12),
            speed: 80 + Math.random() * 220,
            hue: Math.random() * 360,
            hueSpeed: 10 + Math.random() * 40,
            trail: 8 + Math.floor(Math.random() * 14)
        };
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

        // Slowly shifting background — every pixel sees color change even when no drop hits it
        const bgHue = (t * 9) % 360;
        ctx.fillStyle = `hsl(${bgHue}, 25%, ${14 * brightness}%)`;
        ctx.fillRect(0, 0, w, h);

        const ps = this.pixelSize;

        for (let i = 0; i < this.drops.length; i++) {
            const drop = this.drops[i];
            drop.y += drop.speed * dt;
            drop.hue = (drop.hue + drop.hueSpeed * dt) % 360;

            if (drop.y - drop.trail * ps > h) {
                Object.assign(drop, this.makeDrop(false));
            }

            const x = i * ps;
            for (let j = 0; j < drop.trail; j++) {
                const y = drop.y - j * ps;
                if (y < -ps || y > h) continue;
                const fade = 1 - j / drop.trail;
                const alpha = fade * 0.95 * brightness;
                const lightness = (62 - j * 3.2) * brightness;
                ctx.fillStyle = `hsla(${drop.hue}, 88%, ${lightness}%, ${alpha})`;
                ctx.fillRect(x, y, ps, ps);
            }
        }
    }
}
