class PlasmaMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.scale = 5;
        this.tempCanvas = document.createElement('canvas');
        this.tempCtx = this.tempCanvas.getContext('2d');
        this.imageData = null;
        this.lut = new PaletteLUT(256);
        this.allocate();
    }

    allocate() {
        const lowW = Math.max(1, Math.ceil(this.w / this.scale));
        const lowH = Math.max(1, Math.ceil(this.h / this.scale));
        this.tempCanvas.width = lowW;
        this.tempCanvas.height = lowH;
        this.imageData = this.tempCtx.createImageData(lowW, lowH);
        this.lowW = lowW;
        this.lowH = lowH;
    }

    resize(w, h) {
        this.w = w;
        this.h = h;
        this.allocate();
    }

    reset() {}

    render(ctx, t, w, h, brightness, palette) {
        const lowW = this.lowW;
        const lowH = this.lowH;
        const data = this.imageData.data;
        const tt = t * 0.6;

        this.lut.rebuildIfNeeded(palette, brightness);
        const lut = this.lut;
        const lutSize = lut.size;

        const t1 = tt;
        const t2 = tt * 1.3;
        const t3 = tt * 0.7;
        const t4 = tt * 1.1;
        const halfW = lowW / 2;
        const halfH = lowH / 2;

        for (let y = 0; y < lowH; y++) {
            const yOff = Math.sin(y * 0.045 + t2);
            const dy = y - halfH;
            for (let x = 0; x < lowW; x++) {
                const dx = x - halfW;
                const v = Math.sin(x * 0.04 + t1)
                        + yOff
                        + Math.sin((x + y) * 0.03 + t3)
                        + Math.sin(Math.sqrt(dx * dx + dy * dy) * 0.05 + t4);
                const norm = (v + 4) / 8;
                let lutIdx = Math.floor(norm * lutSize + tt * 30);
                lutIdx = ((lutIdx % lutSize) + lutSize) % lutSize;

                const idx = (y * lowW + x) * 4;
                data[idx] = lut.r[lutIdx];
                data[idx + 1] = lut.g[lutIdx];
                data[idx + 2] = lut.b[lutIdx];
                data[idx + 3] = 255;
            }
        }

        this.tempCtx.putImageData(this.imageData, 0, 0);
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(this.tempCanvas, 0, 0, w, h);
    }
}
