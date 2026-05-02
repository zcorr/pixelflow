(function () {
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d', { alpha: false });
    const modeSelect = document.getElementById('mode');
    const speedInput = document.getElementById('speed');
    const speedVal = document.getElementById('speed-val');
    const brightnessInput = document.getElementById('brightness');
    const brightnessVal = document.getElementById('brightness-val');
    const paletteSelect = document.getElementById('palette');
    const modeLabel = document.getElementById('mode-label');
    const body = document.body;

    const modeNames = {
        aurora: 'Aurora',
        plasma: 'Plasma',
        particles: 'Particles',
        pixelrain: 'Pixel rain',
        sweep: 'Sweep'
    };

    const modeOrder = ['aurora', 'plasma', 'particles', 'pixelrain', 'sweep'];

    const state = {
        currentMode: 'aurora',
        autoMode: false,
        autoCycleAt: 0,
        autoCycleInterval: 45000,
        speed: 1,
        brightness: 0.85,
        paletteIndex: 0,
        paused: false,
        time: 0,
        lastFrame: performance.now(),
        modes: {}
    };

    function currentPalette() {
        return PALETTES[state.paletteIndex] || PALETTES[0];
    }

    function resize() {
        const dpr = window.devicePixelRatio || 1;
        const w = window.innerWidth;
        const h = window.innerHeight;
        canvas.width = Math.round(w * dpr);
        canvas.height = Math.round(h * dpr);
        canvas.style.width = w + 'px';
        canvas.style.height = h + 'px';
        ctx.scale(dpr, dpr);
        Object.values(state.modes).forEach(mode => {
            if (mode.resize) mode.resize(w, h);
        });
    }

    function initModes() {
        state.modes.aurora = new AuroraMode();
        state.modes.plasma = new PlasmaMode();
        state.modes.particles = new ParticlesMode();
        state.modes.pixelrain = new PixelRainMode();
        state.modes.sweep = new SweepMode();
        const w = window.innerWidth;
        const h = window.innerHeight;
        Object.values(state.modes).forEach(mode => {
            if (mode.init) mode.init(w, h);
        });
    }

    function setMode(name) {
        if (name === 'auto') {
            state.autoMode = true;
            if (state.currentMode === 'aurora' && performance.now() < 1000) {
                // already on aurora at boot — keep it for the first cycle
            }
            state.autoCycleAt = performance.now() + state.autoCycleInterval;
            modeLabel.textContent = modeNames[state.currentMode] + ' (auto)';
        } else {
            state.autoMode = false;
            state.currentMode = name;
            modeLabel.textContent = modeNames[name];
            const mode = state.modes[name];
            if (mode && mode.reset) mode.reset();
        }
    }

    function cycleAuto() {
        const idx = modeOrder.indexOf(state.currentMode);
        const next = modeOrder[(idx + 1) % modeOrder.length];
        state.currentMode = next;
        modeLabel.textContent = modeNames[next] + ' (auto)';
        const mode = state.modes[next];
        if (mode && mode.reset) mode.reset();
    }

    function render(now) {
        const dt = Math.min(100, now - state.lastFrame) / 1000;
        state.lastFrame = now;

        if (!state.paused) {
            state.time += dt * state.speed;
        }

        if (state.autoMode && now > state.autoCycleAt) {
            cycleAuto();
            state.autoCycleAt = now + state.autoCycleInterval;
        }

        const mode = state.modes[state.currentMode];
        if (mode) {
            const lw = window.innerWidth;
            const lh = window.innerHeight;
            ctx.fillStyle = '#000';
            ctx.fillRect(0, 0, lw, lh);
            mode.render(ctx, state.time, lw, lh, state.brightness, currentPalette());
        }

        requestAnimationFrame(render);
    }

    let hideTimeout = null;
    const HIDE_DELAY = 2800;

    function showControls() {
        body.classList.add('show-controls');
        body.classList.add('show-cursor');
        clearTimeout(hideTimeout);
        hideTimeout = setTimeout(() => {
            body.classList.remove('show-controls');
            body.classList.remove('show-cursor');
        }, HIDE_DELAY);
    }

    document.addEventListener('mousemove', showControls);
    document.addEventListener('keydown', showControls);
    document.addEventListener('touchstart', showControls);

    const controlsEl = document.getElementById('controls');
    controlsEl.addEventListener('mouseenter', () => clearTimeout(hideTimeout));
    controlsEl.addEventListener('mouseleave', () => {
        clearTimeout(hideTimeout);
        hideTimeout = setTimeout(() => {
            body.classList.remove('show-controls');
            body.classList.remove('show-cursor');
        }, HIDE_DELAY);
    });

    modeSelect.addEventListener('change', (e) => setMode(e.target.value));
    speedInput.addEventListener('input', (e) => {
        state.speed = parseFloat(e.target.value);
        speedVal.textContent = state.speed.toFixed(2);
    });
    brightnessInput.addEventListener('input', (e) => {
        state.brightness = parseFloat(e.target.value);
        brightnessVal.textContent = Math.round(state.brightness * 100) + '%';
    });
    paletteSelect.addEventListener('change', (e) => {
        state.paletteIndex = parseInt(e.target.value, 10);
    });

    function setModeFromKey(name) {
        modeSelect.value = name;
        setMode(name);
    }

    document.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return;
        switch (e.key.toLowerCase()) {
            case 'f':
                e.preventDefault();
                if (!document.fullscreenElement) {
                    document.documentElement.requestFullscreen().catch(() => {});
                } else {
                    document.exitFullscreen().catch(() => {});
                }
                break;
            case ' ':
                e.preventDefault();
                state.paused = !state.paused;
                body.classList.toggle('is-paused', state.paused);
                break;
            case '1': setModeFromKey('aurora'); break;
            case '2': setModeFromKey('plasma'); break;
            case '3': setModeFromKey('particles'); break;
            case '4': setModeFromKey('pixelrain'); break;
            case '5': setModeFromKey('sweep'); break;
            case 'a': setModeFromKey('auto'); break;
            case '[':
            case ']': {
                e.preventDefault();
                const n = PALETTES.length;
                const delta = e.key === '[' ? -1 : 1;
                state.paletteIndex = (state.paletteIndex + delta + n) % n;
                paletteSelect.value = String(state.paletteIndex);
                break;
            }
        }
    });

    window.addEventListener('resize', resize);

    // paused indicator element (added dynamically so the DOM can be tiny)
    const pausedEl = document.createElement('div');
    pausedEl.id = 'paused-indicator';
    pausedEl.textContent = 'Paused';
    document.body.appendChild(pausedEl);

    resize();
    initModes();
    setMode('aurora');
    showControls();
    requestAnimationFrame(render);
})();
