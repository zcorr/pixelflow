class PlasmaMode {
    init(w, h) {
        this.w = w;
        this.h = h;
        this.scale = 5;
        this.tempCanvas = document.createElement('canvas');
        this.tempCtx = this.tempCanvas.getContext('2d');
        this.imageData = null;
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

    render(ctx, t, w, h, brightness) {
        const lowW = this.lowW;
        const lowH = this.lowH;
        const data = this.imageData.data;
        const tt = t * 0.6;

        // Precompute trig terms that don't depend on x or y
        const t1 = tt;
        const t2 = tt * 1.3;
        const t3 = tt * 0.7;
        const t4 = tt * 1.1;

        for (let y = 0; y < lowH; y++) {
            const yOff = Math.sin(y * 0.045 + t2);
            for (let x = 0; x < lowW; x++) {
                const v = Math.sin(x * 0.04 + t1)
                        + yOff
                        + Math.sin((x + y) * 0.03 + t3)
                        + Math.sin(Math.sqrt((x - lowW / 2) * (x - lowW / 2) + (y - lowH / 2) * (y - lowH / 2)) * 0.05 + t4);
                const norm = (v + 4) / 8;
                const hue = (norm * 360 + tt * 35) % 360;
                const rgb = hslToRgbFast(hue, 0.78, 0.5 * brightness);
                const idx = (y * lowW + x) * 4;
                data[idx] = rgb[0];
                data[idx + 1] = rgb[1];
                data[idx + 2] = rgb[2];
                data[idx + 3] = 255;
            }
        }

        this.tempCtx.putImageData(this.imageData, 0, 0);
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(this.tempCanvas, 0, 0, w, h);
    }
}

function hslToRgbFast(h, s, l) {
    h = ((h % 360) + 360) % 360;
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const hp = h / 60;
    const x = c * (1 - Math.abs((hp % 2) - 1));
    let r1, g1, b1;
    if (hp < 1) { r1 = c; g1 = x; b1 = 0; }
    else if (hp < 2) { r1 = x; g1 = c; b1 = 0; }
    else if (hp < 3) { r1 = 0; g1 = c; b1 = x; }
    else if (hp < 4) { r1 = 0; g1 = x; b1 = c; }
    else if (hp < 5) { r1 = x; g1 = 0; b1 = c; }
    else { r1 = c; g1 = 0; b1 = x; }
    const m = l - c / 2;
    return [
        Math.round((r1 + m) * 255),
        Math.round((g1 + m) * 255),
        Math.round((b1 + m) * 255)
    ];
}
