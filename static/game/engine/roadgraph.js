// ═══════════════════════════════════════════════════════════════
//  ROAD GRAPH — procedural city layout on a cell grid
//  Produces:
//   - grid[r][c] cell types: 'road' | 'block'
//   - per road cell: connection bitmask (N/E/S/W) for lane lines + crosswalks
//   - graph nodes (intersections) + edges (segments) for nav + minimap
//  Pure data — no THREE dependency. world/city.js turns it into meshes.
// ═══════════════════════════════════════════════════════════════

export const DIR = { N: 1, E: 2, S: 4, W: 8 };
const DR = { N: [-1, 0], E: [0, 1], S: [1, 0], W: [0, -1] };

export class RoadGraph {
  // cols/rows = grid size in CELLS. cellSize = world units per cell.
  // blockSize = how many cells between roads (block width in cells).
  constructor({ cols = 25, rows = 25, cellSize = 12, roadEvery = 3, seed = 1 } = {}) {
    this.cols = cols;
    this.rows = rows;
    this.cell = cellSize;
    this.roadEvery = roadEvery;
    this.seed = seed;
    this.grid = [];        // grid[r][c] = 'road' | 'block'
    this.conn = [];        // conn[r][c] = bitmask of road neighbours
    this.nodes = [];       // {r,c,x,z,degree}
    this.edges = [];       // {a:{r,c}, b:{r,c}, horizontal:bool}
    this._rng = mulberry32(seed);
    this._generate();
  }

  // World-space centre of a cell. Grid is centred on origin.
  cellToWorld(r, c) {
    const x = (c - (this.cols - 1) / 2) * this.cell;
    const z = (r - (this.rows - 1) / 2) * this.cell;
    return { x, z };
  }
  worldToCell(x, z) {
    const c = Math.round(x / this.cell + (this.cols - 1) / 2);
    const r = Math.round(z / this.cell + (this.rows - 1) / 2);
    return { r, c };
  }

  inBounds(r, c) { return r >= 0 && r < this.rows && c >= 0 && c < this.cols; }
  isRoad(r, c) { return this.inBounds(r, c) && this.grid[r][c] === 'road'; }

  _generate() {
    // 1) Base Manhattan grid: a road line every `roadEvery` cells, both axes.
    for (let r = 0; r < this.rows; r++) {
      this.grid[r] = [];
      for (let c = 0; c < this.cols; c++) {
        const roadRow = (r % this.roadEvery === 0);
        const roadCol = (c % this.roadEvery === 0);
        this.grid[r][c] = (roadRow || roadCol) ? 'road' : 'block';
      }
    }

    // 2) Compute connection bitmask for every road cell.
    this.conn = [];
    for (let r = 0; r < this.rows; r++) {
      this.conn[r] = [];
      for (let c = 0; c < this.cols; c++) {
        if (this.grid[r][c] !== 'road') { this.conn[r][c] = 0; continue; }
        let m = 0;
        for (const k of ['N', 'E', 'S', 'W']) {
          const [dr, dc] = DR[k];
          if (this.isRoad(r + dr, c + dc)) m |= DIR[k];
        }
        this.conn[r][c] = m;
      }
    }

    // 3) Build graph: nodes at intersections (degree != 2 or corner), edges between them.
    this._buildGraph();
  }

  _degree(m) {
    let d = 0;
    for (const k of ['N', 'E', 'S', 'W']) if (m & DIR[k]) d++;
    return d;
  }

  _isStraightThrough(m) {
    return m === (DIR.N | DIR.S) || m === (DIR.E | DIR.W);
  }

  _buildGraph() {
    this.nodes = [];
    this.edges = [];
    const nodeAt = {};
    // Nodes = road cells that are NOT straight-through (intersections, corners, ends).
    for (let r = 0; r < this.rows; r++) {
      for (let c = 0; c < this.cols; c++) {
        if (this.grid[r][c] !== 'road') continue;
        const m = this.conn[r][c];
        if (!this._isStraightThrough(m)) {
          const w = this.cellToWorld(r, c);
          const node = { r, c, x: w.x, z: w.z, degree: this._degree(m) };
          nodeAt[`${r},${c}`] = this.nodes.length;
          this.nodes.push(node);
        }
      }
    }
    // Edges: walk from each node along E and S until the next node.
    const findNext = (r, c, dr, dc) => {
      let rr = r + dr, cc = c + dc;
      while (this.isRoad(rr, cc)) {
        if (nodeAt[`${rr},${cc}`] !== undefined) return { r: rr, c: cc };
        // stop if it's not a straight passthrough in our travel direction
        const m = this.conn[rr][cc];
        if (!this._isStraightThrough(m)) return { r: rr, c: cc };
        rr += dr; cc += dc;
      }
      return null;
    };
    for (const n of this.nodes) {
      for (const [dr, dc, horizontal] of [[0, 1, true], [1, 0, false]]) {
        if (!this.isRoad(n.r + dr, n.c + dc)) continue;
        const next = findNext(n.r, n.c, dr, dc);
        if (next && nodeAt[`${next.r},${next.c}`] !== undefined) {
          this.edges.push({
            a: { r: n.r, c: n.c },
            b: { r: next.r, c: next.c },
            horizontal,
          });
        }
      }
    }
  }

  // Iterate every road cell with its world pos + connection mask.
  forEachRoadCell(cb) {
    for (let r = 0; r < this.rows; r++) {
      for (let c = 0; c < this.cols; c++) {
        if (this.grid[r][c] !== 'road') continue;
        const w = this.cellToWorld(r, c);
        cb(r, c, w.x, w.z, this.conn[r][c]);
      }
    }
  }

  // Iterate every block cell (for placing buildings).
  forEachBlockCell(cb) {
    for (let r = 0; r < this.rows; r++) {
      for (let c = 0; c < this.cols; c++) {
        if (this.grid[r][c] !== 'block') continue;
        const w = this.cellToWorld(r, c);
        cb(r, c, w.x, w.z);
      }
    }
  }

  // District by region (used for visual variety). Returns 'downtown'|'commercial'|'residential'|'waterfront'.
  districtAt(r, c) {
    const midR = this.rows / 2, midC = this.cols / 2;
    const dr = Math.abs(r - midR), dc = Math.abs(c - midC);
    const dist = Math.max(dr, dc);
    if (dist < this.rows * 0.18) return 'downtown';      // tall towers centre
    if (r > this.rows * 0.78) return 'waterfront';        // south edge = corniche
    if (dist < this.rows * 0.38) return 'commercial';
    return 'residential';
  }

  rand() { return this._rng(); }

  worldBounds() {
    const half = { x: (this.cols * this.cell) / 2, z: (this.rows * this.cell) / 2 };
    return half;
  }
}

// Deterministic PRNG so the city is identical each load.
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
