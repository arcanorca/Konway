.pragma library

// Spatial activity model for the Adaptive injector.
//
// The GPU reduces the simulation grid into a small tile map (see tile_probe.frag):
// per tile, how much of it is alive and how much of it changed since the previous
// generation. This module keeps a short memory of those maps and decides *what*
// to spawn *where*, so the wallpaper stays interesting instead of settling into
// a handful of blinkers and still lifes.
//
// Everything here is pure (no QML types) so it can be unit-tested with node.

var OCCUPIED_EPSILON = 0.0005;
var HOT_EPSILON = 0.0005;
var EMA_TAU_SEC = 20.0;
var WARMUP_PROBES = 3;

// Spaceship bases. `heading` is the verified travel direction in screen
// coordinates (x right, y down). Rotating cells by 90 degrees rotates it too.
var SHIPS = {
    glider: {
        heading: [1, 1],
        cells: [[1, 0], [2, 1], [0, 2], [1, 2], [2, 2]]
    },
    lwss: {
        heading: [-1, 0],
        cells: [[1, 0], [4, 0], [0, 1], [0, 2], [4, 2], [0, 3], [1, 3], [2, 3], [3, 3]]
    }
};

var DIAGONALS = [[1, 1], [-1, 1], [1, -1], [-1, -1]];
var ORTHOGONALS = [[1, 0], [-1, 0], [0, 1], [0, -1]];

function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v));
}

function lerp(a, b, t) {
    return a + (b - a) * t;
}

function tileCountsFor(gridW, gridH) {
    return {
        cols: clamp(Math.round(gridW / 8), 12, 40),
        rows: clamp(Math.round(gridH / 8), 8, 30)
    };
}

function createState(cols, rows) {
    var n = cols * rows;
    return {
        cols: cols,
        rows: rows,
        n: n,
        density: new Float32Array(n),
        change: new Float32Array(n),
        occupied: new Uint8Array(n),
        ageSec: new Float32Array(n),
        probes: 0,
        lastProbeSec: -1,
        hotEma: 0,
        occEma: 0,
        lastSpawnSec: -1e9,
        lastKinds: [],
        lastTargets: []
    };
}

function ingest(state, density, change, nowSec) {
    var dt = state.lastProbeSec < 0 ? 1.0 : clamp(nowSec - state.lastProbeSec, 0.05, 30.0);
    var hot = 0;
    var occ = 0;

    for (var i = 0; i < state.n; ++i) {
        var d = density[i];
        var c = change[i];
        var o = d > OCCUPIED_EPSILON ? 1 : 0;

        state.density[i] = d;
        state.change[i] = c;
        if (o) {
            occ += 1;
            state.ageSec[i] = state.occupied[i] ? state.ageSec[i] + dt : 0.0001;
        } else {
            state.ageSec[i] = 0;
        }
        state.occupied[i] = o;
        if (c > HOT_EPSILON) {
            hot += 1;
        }
    }

    var hotFrac = hot / state.n;
    var occFrac = occ / state.n;
    if (state.probes === 0) {
        state.hotEma = hotFrac;
        state.occEma = occFrac;
    } else {
        var a = 1.0 - Math.exp(-dt / EMA_TAU_SEC);
        state.hotEma += (hotFrac - state.hotEma) * a;
        state.occEma += (occFrac - state.occEma) * a;
    }
    state.probes += 1;
    state.lastProbeSec = nowSec;
}

function tileIndex(state, i, j) {
    return j * state.cols + i;
}

function quadrantOccupancy(state) {
    var sums = [0, 0, 0, 0];
    var counts = [0, 0, 0, 0];
    for (var j = 0; j < state.rows; ++j) {
        for (var i = 0; i < state.cols; ++i) {
            var q = (j * 2 >= state.rows ? 2 : 0) + (i * 2 >= state.cols ? 1 : 0);
            counts[q] += 1;
            sums[q] += state.occupied[tileIndex(state, i, j)];
        }
    }
    return sums.map(function (s, q) {
        return counts[q] > 0 ? s / counts[q] : 0;
    });
}

function occupiedNeighbours(state, i, j, wrap) {
    var count = 0;
    for (var dj = -1; dj <= 1; ++dj) {
        for (var di = -1; di <= 1; ++di) {
            if (di === 0 && dj === 0) {
                continue;
            }
            var ni = i + di;
            var nj = j + dj;
            if (wrap) {
                ni = (ni + state.cols) % state.cols;
                nj = (nj + state.rows) % state.rows;
            } else if (ni < 0 || nj < 0 || ni >= state.cols || nj >= state.rows) {
                continue;
            }
            count += state.occupied[tileIndex(state, ni, nj)];
        }
    }
    return count;
}

// Isolated clusters that have been sitting in the same tile for a long time:
// blinkers, still lifes and other burnt-out leftovers.
function staleTiles(state, minAgeSec, wrap) {
    var out = [];
    for (var j = 0; j < state.rows; ++j) {
        for (var i = 0; i < state.cols; ++i) {
            var idx = tileIndex(state, i, j);
            if (!state.occupied[idx] || state.ageSec[idx] < minAgeSec) {
                continue;
            }
            if (state.density[idx] > 0.5) {
                continue;
            }
            if (occupiedNeighbours(state, i, j, wrap) > 3) {
                continue;
            }
            out.push({ i: i, j: j, age: state.ageSec[idx] });
        }
    }
    return out;
}

function summarize(state, opts) {
    var o = opts || {};
    var quads = quadrantOccupancy(state);
    var maxQ = Math.max.apply(null, quads);
    var minQ = Math.min.apply(null, quads);
    var minAge = o.staleSec !== undefined ? o.staleSec : 60;
    return {
        occupancy: state.occEma,
        hotCoverage: state.hotEma,
        quadrants: quads,
        imbalance: maxQ > 0.001 ? (maxQ - minQ) / maxQ : 1.0,
        stale: staleTiles(state, minAge, !!o.wrap)
    };
}

function targetsFor(liveliness) {
    var l = clamp(liveliness, 0, 1);
    return {
        hot: lerp(0.10, 0.38, l),
        occupancy: lerp(0.14, 0.48, l),
        cooldownSec: lerp(16, 5, l),
        maxQuietSec: lerp(110, 28, l),
        staleSec: lerp(90, 40, l)
    };
}

function pressureFor(summary, targets, liveliness) {
    var hotGap = 1.0 - summary.hotCoverage / targets.hot;
    var occGap = 0.7 * (1.0 - summary.occupancy / targets.occupancy);
    var imbalance = 0.45 * summary.imbalance * (summary.occupancy < targets.occupancy * 1.6 ? 1.0 : 0.3);
    var staleBoost = Math.min(0.30, summary.stale.length * 0.05) * lerp(0.25, 1.0, clamp(liveliness, 0, 1));
    return clamp(Math.max(hotGap, occGap, imbalance) + staleBoost, 0, 1);
}

function weightedPick(items, weightOf, rng) {
    var total = 0;
    for (var i = 0; i < items.length; ++i) {
        total += Math.max(0, weightOf(items[i]));
    }
    if (total <= 0) {
        return items.length ? items[Math.floor(rng() * items.length)] : null;
    }
    var roll = rng() * total;
    for (var k = 0; k < items.length; ++k) {
        roll -= Math.max(0, weightOf(items[k]));
        if (roll <= 0) {
            return items[k];
        }
    }
    return items[items.length - 1];
}

function tileTouchesRect(state, i, j, gridW, gridH, rect) {
    if (!rect) {
        return false;
    }
    var x0 = (i / state.cols) * gridW;
    var x1 = ((i + 1) / state.cols) * gridW;
    var y0 = (j / state.rows) * gridH;
    var y1 = ((j + 1) / state.rows) * gridH;
    return x1 > rect.x - rect.pad && x0 < rect.x + rect.w + rect.pad
        && y1 > rect.y - rect.pad && y0 < rect.y + rect.h + rect.pad;
}

function voidScoreAt(state, i, j, radius, wrap) {
    var free = 0;
    var total = 0;
    for (var dj = -radius; dj <= radius; ++dj) {
        for (var di = -radius; di <= radius; ++di) {
            var ni = i + di;
            var nj = j + dj;
            if (wrap) {
                ni = (ni + state.cols) % state.cols;
                nj = (nj + state.rows) % state.rows;
            } else if (ni < 0 || nj < 0 || ni >= state.cols || nj >= state.rows) {
                continue;
            }
            total += 1;
            if (!state.occupied[tileIndex(state, ni, nj)]) {
                free += 1;
            }
        }
    }
    return total > 0 ? free / total : 0;
}

function pickVoidTile(state, ctx, rng) {
    var quads = quadrantOccupancy(state);
    var maxQ = Math.max.apply(null, quads);
    var candidates = [];

    for (var j = 0; j < state.rows; ++j) {
        for (var i = 0; i < state.cols; ++i) {
            if (tileTouchesRect(state, i, j, ctx.gridW, ctx.gridH, ctx.clock)) {
                continue;
            }
            var q = (j * 2 >= state.rows ? 2 : 0) + (i * 2 >= state.cols ? 1 : 0);
            var need = maxQ > 0.001 ? (maxQ - quads[q]) / maxQ : 1.0;
            var recent = 1.0;
            for (var t = 0; t < state.lastTargets.length; ++t) {
                var rt = state.lastTargets[t];
                if (Math.abs(rt.i - i) <= 3 && Math.abs(rt.j - j) <= 3) {
                    recent *= 0.2;
                }
            }
            var v = voidScoreAt(state, i, j, 2, ctx.wrap);
            candidates.push({
                i: i,
                j: j,
                weight: (0.04 + v * v * v) * (1.0 + 1.2 * need) * recent
            });
        }
    }

    return weightedPick(candidates, function (c) { return c.weight; }, rng);
}

function tileCenterCell(state, tile, ctx) {
    return {
        x: Math.floor(((tile.i + 0.5) / state.cols) * ctx.gridW),
        y: Math.floor(((tile.j + 0.5) / state.rows) * ctx.gridH)
    };
}

function rotateOnce(cells) {
    var out = [];
    var minX = Infinity;
    var minY = Infinity;
    for (var i = 0; i < cells.length; ++i) {
        var nx = -cells[i][1];
        var ny = cells[i][0];
        out.push([nx, ny]);
        minX = Math.min(minX, nx);
        minY = Math.min(minY, ny);
    }
    return out.map(function (c) { return [c[0] - minX, c[1] - minY]; });
}

// Returns the cells of `shipId` travelling along `heading`, origin at (0,0).
function orientedShip(shipId, heading) {
    var ship = SHIPS[shipId];
    var cells = ship.cells.map(function (c) { return [c[0], c[1]]; });
    var h = [ship.heading[0], ship.heading[1]];
    for (var turn = 0; turn < 4; ++turn) {
        if (h[0] === heading[0] && h[1] === heading[1]) {
            return cells;
        }
        cells = rotateOnce(cells);
        h = [-h[1], h[0]];
    }
    return null;
}

function shipBounds(cells) {
    var w = 0;
    var h = 0;
    for (var i = 0; i < cells.length; ++i) {
        w = Math.max(w, cells[i][0] + 1);
        h = Math.max(h, cells[i][1] + 1);
    }
    return { w: w, h: h };
}

function placeShip(shipId, heading, centerCell) {
    var cells = orientedShip(shipId, heading);
    if (!cells) {
        return [];
    }
    var b = shipBounds(cells);
    var ox = centerCell.x - Math.floor(b.w / 2);
    var oy = centerCell.y - Math.floor(b.h / 2);
    return cells.map(function (c) { return { x: ox + c[0], y: oy + c[1] }; });
}

function tileOfCell(state, cell, ctx) {
    var i = Math.floor((cell.x / ctx.gridW) * state.cols);
    var j = Math.floor((cell.y / ctx.gridH) * state.rows);
    if (ctx.wrap) {
        return { i: (i + state.cols) % state.cols, j: (j + state.rows) % state.rows };
    }
    if (i < 0 || j < 0 || i >= state.cols || j >= state.rows) {
        return null;
    }
    return { i: i, j: j };
}

// How many occupied tiles a ship launched from `start` would cross.
function rayOccupancy(state, ctx, start, heading, lengthCells) {
    var hits = 0;
    var seen = {};
    var steps = Math.max(4, Math.round(lengthCells / 4));
    for (var s = 1; s <= steps; ++s) {
        var cell = { x: start.x + heading[0] * s * 4, y: start.y + heading[1] * s * 4 };
        var tile = tileOfCell(state, cell, ctx);
        if (!tile) {
            return hits + 3;
        }
        var key = tile.i + "," + tile.j;
        if (seen[key]) {
            continue;
        }
        seen[key] = true;
        hits += state.occupied[tileIndex(state, tile.i, tile.j)];
    }
    return hits;
}

function pickHeading(state, ctx, origin, headings, lengthCells, rng, sign) {
    var best = [];
    var bestScore = Infinity;
    for (var h = 0; h < headings.length; ++h) {
        var heading = headings[h];
        var ray = { x: origin.x, y: origin.y };
        var score = rayOccupancy(state, ctx, ray, [heading[0] * sign, heading[1] * sign], lengthCells);
        if (score < bestScore) {
            bestScore = score;
            best = [heading];
        } else if (score === bestScore) {
            best.push(heading);
        }
    }
    return best[Math.floor(rng() * best.length)];
}

function buildSoup(center, size, fill, rng) {
    var cells = [];
    var half = Math.floor(size / 2);
    for (var y = 0; y < size; ++y) {
        for (var x = 0; x < size; ++x) {
            var dx = (x - half) / (size / 2);
            var dy = (y - half) / (size / 2);
            // Rounded patch so soups look organic rather than square.
            if (dx * dx + dy * dy > 1.15) {
                continue;
            }
            if (rng() < fill) {
                cells.push({ x: center.x - half + x, y: center.y - half + y });
            }
        }
    }
    return cells;
}

function kindWeights(state, ctx, summary, hasStale) {
    var w = { bloom: 1.0, drift: 0.9, stir: 0.0, soup: 0.6 };
    if (hasStale && ctx.allowShips) {
        w.stir = 1.3 + Math.min(1.5, summary.stale.length * 0.15);
    }
    if (!ctx.allowShips || !ctx.lifeRule) {
        w.drift = 0;
        w.stir = 0;
    }
    if (!ctx.allowGrowth) {
        w.bloom = 0;
    }
    if (ctx.chill) {
        // Relaxed profile: travellers first, no sudden soups.
        w.bloom *= 0.45;
        w.drift *= 1.35;
        w.soup *= 0.15;
    }
    for (var h = 0; h < state.lastKinds.length; ++h) {
        var k = state.lastKinds[h];
        if (w[k] !== undefined) {
            w[k] *= 0.5;
        }
    }
    return w;
}

function rememberAction(state, kind, tile, nowSec) {
    state.lastKinds.push(kind);
    if (state.lastKinds.length > 3) {
        state.lastKinds.shift();
    }
    if (tile) {
        state.lastTargets.push({ i: tile.i, j: tile.j });
        if (state.lastTargets.length > 5) {
            state.lastTargets.shift();
        }
    }
    state.lastSpawnSec = nowSec;
}

// ctx: { nowSec, liveliness, chill, gridW, gridH, wrap, lifeRule,
//        allowShips, allowGrowth, clock: {x,y,w,h,pad} | null }
// Returns null (do nothing) or { kind, cells?, center, tile, pressure }.
function decide(state, ctx, rng) {
    var random = rng || Math.random;
    if (state.probes < WARMUP_PROBES) {
        return null;
    }

    var targets = targetsFor(ctx.liveliness);
    var chillScale = ctx.chill ? 1.8 : 1.0;
    var clockScale = ctx.clock ? 1.5 : 1.0;
    var sinceSpawn = ctx.nowSec - state.lastSpawnSec;
    if (sinceSpawn < targets.cooldownSec * chillScale * clockScale) {
        return null;
    }

    var summary = summarize(state, { staleSec: targets.staleSec, wrap: ctx.wrap });
    var pressure = pressureFor(summary, targets, ctx.liveliness);

    var chance;
    if (pressure <= 0.10) {
        chance = 0.02 * lerp(0.4, 1.0, clamp(ctx.liveliness, 0, 1));
    } else {
        chance = clamp((0.10 + 0.85 * Math.pow(pressure, 1.3)) * lerp(0.4, 1.0, clamp(ctx.liveliness, 0, 1)), 0, 0.95);
    }
    var overdue = sinceSpawn > targets.maxQuietSec * chillScale && pressure > 0.10;
    if (!overdue && random() > chance) {
        return null;
    }

    var weights = kindWeights(state, ctx, summary, summary.stale.length > 0);
    var kinds = Object.keys(weights).filter(function (k) { return weights[k] > 0; });
    if (!kinds.length) {
        return null;
    }
    var kind = weightedPick(kinds, function (k) { return weights[k]; }, random);

    var tile;
    var center;
    var cells = null;

    if (kind === "stir") {
        var pool = summary.stale.filter(function (t) {
            return !tileTouchesRect(state, t.i, t.j, ctx.gridW, ctx.gridH, ctx.clock);
        });
        if (!pool.length) {
            kind = "drift";
        } else {
            tile = weightedPick(pool, function (t) { return t.age; }, random);
            center = tileCenterCell(state, tile, ctx);
            var shipId = (!ctx.chill && random() < 0.3) ? "lwss" : "glider";
            var headings = shipId === "glider" ? DIAGONALS : ORTHOGONALS;
            // Launch from the side whose approach lane is emptiest.
            var travel = pickHeading(state, ctx, center, headings, 24, random, -1);
            var distance = 16 + Math.floor(random() * 6);
            var start = { x: center.x - travel[0] * distance, y: center.y - travel[1] * distance };
            cells = placeShip(shipId, travel, start);
        }
    }

    if (kind !== "stir") {
        tile = pickVoidTile(state, ctx, random);
        if (!tile) {
            return null;
        }
        center = tileCenterCell(state, tile, ctx);

        if (kind === "drift") {
            var driftShip = (!ctx.chill && random() < 0.25) ? "lwss" : "glider";
            var driftHeadings = driftShip === "glider" ? DIAGONALS : ORTHOGONALS;
            var go = pickHeading(state, ctx, center, driftHeadings, 40, random, 1);
            cells = placeShip(driftShip, go, center);
        } else if (kind === "soup") {
            cells = buildSoup(center, 6 + Math.floor(random() * 4), 0.36 + random() * 0.14, random);
        }
    }

    rememberAction(state, kind, tile, ctx.nowSec);
    return {
        kind: kind,
        tile: tile,
        center: center,
        cells: cells,
        pressure: pressure
    };
}

function describe(state, ctx) {
    var targets = targetsFor(ctx.liveliness);
    var summary = summarize(state, { staleSec: targets.staleSec, wrap: ctx.wrap });
    return {
        occupancy: summary.occupancy,
        hotCoverage: summary.hotCoverage,
        imbalance: summary.imbalance,
        stale: summary.stale.length,
        pressure: pressureFor(summary, targets, ctx.liveliness)
    };
}
