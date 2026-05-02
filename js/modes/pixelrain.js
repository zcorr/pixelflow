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
            hueIndex: Math.random(),
            hueSpeed: 0.05 + Math.random() * 0.1,
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

    render(ctx, t, w, h, brightness, palette) {
        const dt = this.lastT < 0 ? 1 / 60 : Math.min(0.1, t - this.lastT);
        this.lastT = t;

        const bg = rgbAt(palette, t * 0.025);
        ctx.fillStyle = rgbaString(bg, Math.min(1, 0.28 * brightness));
        ctx.fillRect(0, 0, w, h);

        const ps = this.pixelSize;

        for (let i = 0; i < this.drops.length; i++) {
            const drop = this.drops[i];
            drop.y += drop.speed * dt;
            drop.hueIndex = (drop.hueIndex + drop.hueSpeed * dt) % 1;
            if (drop.hueIndex < 0) drop.hueIndex += 1;

            if (drop.y - drop.trail * ps > h) {
                Object.assign(drop, this.makeDrop(false));
            }

            const rgb = rgbAt(palette, drop.hueIndex);
            const x = i * ps;
            for (let j = 0; j < drop.trail; j++) {
                const y = drop.y - j * ps;
                if (y < -ps || y > h) continue;
                const fade = 1 - j / drop.trail;
                const alpha = fade * 0.85 * brightness;
                ctx.fillStyle = rgbaString(rgb, alpha);
                ctx.fillRect(x, y, ps, ps);
            }
        }
    }
}
