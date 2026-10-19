#!/usr/bin/env node
// Headless check of the Adaptive injector (contents/ui/lib/activityMap.js).
//
// Runs a real Conway engine on a torus, reduces it to the same tile map the
// GPU probe produces, and compares an unattended world against one managed by
// the injector. Also verifies the hard-coded spaceship headings by simulation.
//
//   node tools/simulate_injection.js            # report + assertions
//   node tools/simulate_injection.js --quiet    # assertions only

const fs = require("fs");
const path = require("path");

const libPath = path.join(__dirname, "..", "contents", "ui", "lib", "activityMap.js");
const source = fs.readFileSync(libPath, "utf8").replace(".pragma library", "");
const lib = new Function(source + "; return { createState, ingest, decide, describe, tileCountsFor, placeShip, orientedShip, SHIPS };")();

const quiet = process.argv.includes("--quiet");
let failures = 0;
function check(name, ok, detail) {
    if (!ok) failures += 1;
    if (!quiet || !ok) console.log((ok ? "  ok   " : "  FAIL ") + name + (detail ? "  " + detail : ""));
}

function mulberry32(seed) {
    return function () {
        seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
        let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

class Life {
    constructor(w, h) {
        this.w = w; this.h = h;
        this.cur = new Uint8Array(w * h);
        this.prev = new Uint8Array(w * h);
        this.gen = 0;
    }
    set(x, y) {
        x = ((x % this.w) + this.w) % this.w;
        y = ((y % this.h) + this.h) % this.h;
        this.cur[y * this.w + x] = 1;
    }
    step() {
        const { w, h, cur } = this;
        const next = this.prev;
        for (let y = 0; y < h; ++y) {
            const ym = ((y + h - 1) % h) * w, y0 = y * w, yp = ((y + 1) % h) * w;
            for (let x = 0; x < w; ++x) {
                const xm = (x + w - 1) % w, xp = (x + 1) % w;
                const n = cur[ym + xm] + cur[ym + x] + cur[ym + xp] + cur[y0 + xm] + cur[y0 + xp] + cur[yp + xm] + cur[yp + x] + cur[yp + xp];
                next[y0 + x] = (n === 3 || (n === 2 && cur[y0 + x])) ? 1 : 0;
            }
        }
        this.prev = cur;
        this.cur = next;
        this.gen += 1;
    }
    alive() { let c = 0; for (let i = 0; i < this.cur.length; ++i) c += this.cur[i]; return c; }
    // Same reduction as shaders/tile_probe.frag: alive fraction + changed fraction per tile.
    tiles(cols, rows) {
        const density = new Float32Array(cols * rows), change = new Float32Array(cols * rows);
        for (let j = 0; j < rows; ++j) {
            const y0 = Math.floor(j * this.h / rows), y1 = Math.floor((j + 1) * this.h / rows);
            for (let i = 0; i < cols; ++i) {
                const x0 = Math.floor(i * this.w / cols), x1 = Math.floor((i + 1) * this.w / cols);
                let a = 0, c = 0, n = 0;
                for (let y = y0; y < y1; ++y) for (let x = x0; x < x1; ++x) {
                    const k = y * this.w + x;
                    a += this.cur[k]; c += this.cur[k] !== this.prev[k] ? 1 : 0; n += 1;
                }
                density[j * cols + i] = Math.round(255 * a / n) / 255;
                change[j * cols + i] = Math.round(255 * c / n) / 255;
            }
        }
        return { density, change };
    }
}

// --- 1. Ship headings are verified by running them -----------------------------------
function centroid(life) {
    let sx = 0, sy = 0, n = 0;
    for (let y = 0; y < life.h; ++y) for (let x = 0; x < life.w; ++x) if (life.cur[y * life.w + x]) { sx += x; sy += y; n += 1; }
    return { x: sx / n, y: sy / n, n };
}
if (!quiet) console.log("Spaceship headings");
for (const id of Object.keys(lib.SHIPS)) {
    const headings = id === "glider" ? [[1, 1], [-1, 1], [1, -1], [-1, -1]] : [[1, 0], [-1, 0], [0, 1], [0, -1]];
    for (const hd of headings) {
        const life = new Life(80, 80);
        for (const c of lib.placeShip(id, hd, { x: 40, y: 40 })) life.set(c.x, c.y);
        const before = centroid(life);
        for (let g = 0; g < 48; ++g) life.step();
        const after = centroid(life);
        const dx = after.x - before.x, dy = after.y - before.y;
        const ok = after.n === before.n && Math.sign(Math.round(dx)) === hd[0] && Math.sign(Math.round(dy)) === hd[1];
        check(id + " heading " + hd, ok, "moved (" + dx.toFixed(1) + "," + dy.toFixed(1) + ") population " + before.n + "->" + after.n);
    }
}

// --- 2. Dull-world recovery ------------------------------------------------------------
const GRID_W = 192, GRID_H = 108, TPS = 3, PROBE_SEC = 1, TICK_SEC = 2;
const { cols, rows } = lib.tileCountsFor(GRID_W, GRID_H);

function settle(seed) {
    const rng = mulberry32(seed);
    const life = new Life(GRID_W, GRID_H);
    for (let i = 0; i < life.cur.length; ++i) life.cur[i] = rng() < 0.05 ? 1 : 0;
    for (let g = 0; g < 2500; ++g) life.step();   // let the startup soup burn out
    return life;
}

function run(label, seed, minutes, options) {
    const life = settle(seed);
    const rng = mulberry32(seed + 99);
    const state = lib.createState(cols, rows);
    const stats = { occ: [], hot: [], actions: {}, spawns: 0, quadrantMin: [] };
    const totalSec = minutes * 60;
    let tAccum = 0;

    for (let sec = 0; sec < totalSec; sec += PROBE_SEC) {
        for (let g = 0; g < TPS * PROBE_SEC; ++g) life.step();
        const t = life.tiles(cols, rows);
        lib.ingest(state, t.density, t.change, sec);

        if (options.adaptive && sec % TICK_SEC === 0) {
            const ctx = {
                nowSec: sec, liveliness: options.liveliness, chill: !!options.chill,
                gridW: GRID_W, gridH: GRID_H, wrap: true, lifeRule: true,
                allowShips: true, allowGrowth: true, clock: options.clock || null
            };
            const act = lib.decide(state, ctx, rng);
            if (act) {
                stats.spawns += 1;
                stats.actions[act.kind] = (stats.actions[act.kind] || 0) + 1;
                if (act.kind === "bloom") {
                    // r-pentomino stands in for a catalog methuselah.
                    for (const [x, y] of [[1, 0], [2, 0], [0, 1], [1, 1], [1, 2]]) life.set(act.center.x - 1 + x, act.center.y - 1 + y);
                } else {
                    for (const c of act.cells) life.set(c.x, c.y);
                }
            }
        }
        if (sec % 30 === 0) {
            const d = lib.describe(state, { liveliness: options.liveliness, wrap: true });
            stats.occ.push(d.occupancy); stats.hot.push(d.hotCoverage);
        }
        tAccum += 1;
    }
    const avg = (a) => a.reduce((s, v) => s + v, 0) / Math.max(1, a.length);
    const tail = (a) => avg(a.slice(Math.floor(a.length / 2)));
    return { label, occ: tail(stats.occ), hot: tail(stats.hot), spawns: stats.spawns, actions: stats.actions, alive: life.alive(), perMin: stats.spawns / minutes };
}

const MINUTES = 20;
const seeds = [11, 23, 37];
const rows_out = [];
function mean(results, key) { return results.reduce((s, r) => s + r[key], 0) / results.length; }
function scenario(label, options) {
    const results = seeds.map((s) => run(label, s, MINUTES, options));
    rows_out.push({ label, occ: mean(results, "occ"), hot: mean(results, "hot"), perMin: mean(results, "perMin"), alive: mean(results, "alive"), actions: results[0].actions });
    return rows_out[rows_out.length - 1];
}

const none = scenario("unattended", { adaptive: false, liveliness: 0.5 });
const hush = scenario("adaptive L=0.1", { adaptive: true, liveliness: 0.1 });
const calm = scenario("adaptive L=0.3", { adaptive: true, liveliness: 0.3 });
const mid = scenario("adaptive L=0.6", { adaptive: true, liveliness: 0.6 });
const lively = scenario("adaptive L=0.9", { adaptive: true, liveliness: 0.9 });
const chill = scenario("chill L=0.5", { adaptive: true, liveliness: 0.5, chill: true });
const clock = scenario("adaptive L=0.6 + clock", { adaptive: true, liveliness: 0.6, clock: { x: 76, y: 46, w: 40, h: 16, pad: 3 } });

if (!quiet) {
    console.log("\nSteady state after " + MINUTES + " simulated minutes (mean of " + seeds.length + " seeds, " + cols + "x" + rows + " tiles)");
    console.log("scenario                   occupied tiles   hot tiles   spawns/min   alive cells");
    for (const r of rows_out) {
        console.log(r.label.padEnd(26) + (r.occ * 100).toFixed(1).padStart(10) + " %" + (r.hot * 100).toFixed(1).padStart(10) + " %" + r.perMin.toFixed(2).padStart(10) + (r.alive).toFixed(0).padStart(14));
    }
    console.log("\naction mix (seed 11):");
    for (const r of rows_out) console.log("  " + r.label.padEnd(26) + JSON.stringify(r.actions));
}

console.log("\nAssertions");
check("unattended world is dull (few hot tiles)", none.hot < 0.12, "hot=" + (none.hot * 100).toFixed(1) + "%");
check("adaptive keeps more of the screen moving", mid.hot > none.hot * 2.0, (mid.hot * 100).toFixed(1) + "% vs " + (none.hot * 100).toFixed(1) + "%");
check("adaptive keeps more of the screen occupied", mid.occ > none.occ * 1.5, (mid.occ * 100).toFixed(1) + "% vs " + (none.occ * 100).toFixed(1) + "%");
check("liveliness ordering holds (spawn rate)", hush.perMin < calm.perMin && calm.perMin < mid.perMin && mid.perMin < lively.perMin);
check("low liveliness stays restrained", hush.perMin < 2.0 && hush.hot > none.hot * 3, hush.perMin.toFixed(2) + "/min, hot " + (hush.hot * 100).toFixed(1) + "%");
check("does not flood the world", lively.occ < 0.85, "occ=" + (lively.occ * 100).toFixed(1) + "%");
check("chill spawns less often than adaptive at same liveliness", chill.perMin < mid.perMin);
check("injection stays gentle on spawn rate", mid.perMin < 8, mid.perMin.toFixed(2) + "/min");
check("mix of action kinds is used", Object.keys(mid.actions).length >= 3, JSON.stringify(mid.actions));

if (failures > 0) {
    console.log("\n" + failures + " check(s) failed");
    process.exit(1);
}
console.log("\nall checks passed");
