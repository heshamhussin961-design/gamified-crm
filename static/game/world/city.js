// ═══════════════════════════════════════════════════════════════
//  CITY — turns a RoadGraph into a 3D world (roads, sidewalks,
//  buildings, props), optimised with merged geometry + instancing.
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { RoadGraph, DIR } from '../engine/roadgraph.js';
import { loadGLB, loadMany, sizeOf, measure, buildInstanced } from '../engine/assets.js';

// Building pools per district (Kenney City + Suburban kits).
const POOLS = {
  downtown: [
    'city/commercial/building-skyscraper-a.glb',
    'city/commercial/building-skyscraper-b.glb',
    'city/commercial/building-skyscraper-c.glb',
    'city/commercial/building-skyscraper-d.glb',
    'city/commercial/building-skyscraper-e.glb',
  ],
  commercial: [
    'city/commercial/building-a.glb', 'city/commercial/building-c.glb',
    'city/commercial/building-e.glb', 'city/commercial/building-g.glb',
    'city/commercial/building-i.glb', 'city/commercial/building-k.glb',
    'city/commercial/building-m.glb',
  ],
  residential: [
    'city/suburban/building-type-a.glb', 'city/suburban/building-type-c.glb',
    'city/suburban/building-type-e.glb', 'city/suburban/building-type-g.glb',
    'city/suburban/building-type-i.glb', 'city/suburban/building-type-k.glb',
    'city/suburban/building-type-m.glb', 'city/suburban/building-type-o.glb',
  ],
  waterfront: [
    'city/commercial/building-b.glb', 'city/commercial/building-d.glb',
    'city/suburban/building-type-b.glb', 'city/suburban/building-type-d.glb',
  ],
};
const TREE_PATHS = ['city/suburban/tree-large.glb', 'city/suburban/tree-small.glb'];
const LIGHT_PATH = 'city/roads/light-square.glb';

export async function buildCity(scene, { quality, onStatus = () => {} } = {}) {
  const graph = new RoadGraph({ cols: 27, rows: 27, cellSize: 12, roadEvery: 3, seed: 7 });
  const cell = graph.cell;
  const colliders = [];

  // ── Lighting ──────────────────────────────────────────────
  scene.background = new THREE.Color(0x9ec9e8);
  scene.fog = new THREE.Fog(0x9ec9e8, quality.fogNear, quality.drawDistance);
  scene.add(new THREE.AmbientLight(0xffffff, 0.62));
  scene.add(new THREE.HemisphereLight(0xbfe3ff, 0x6e7a5e, 0.45));
  const sun = new THREE.DirectionalLight(0xfff6e0, 1.05);
  sun.position.set(80, 120, 60);
  if (quality.shadows) {
    sun.castShadow = true;
    sun.shadow.mapSize.set(quality.shadowMapSize, quality.shadowMapSize);
    const S = 90;
    sun.shadow.camera.near = 1; sun.shadow.camera.far = 320;
    sun.shadow.camera.left = -S; sun.shadow.camera.right = S;
    sun.shadow.camera.top = S; sun.shadow.camera.bottom = -S;
    sun.shadow.bias = -0.0004;
  }
  scene.add(sun);

  const bounds = graph.worldBounds();
  const groundW = (bounds.x + cell) * 2;
  const groundD = (bounds.z + cell) * 2;

  // ── Ground (grass) ───────────────────────────────────────
  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(groundW, groundD),
    new THREE.MeshStandardMaterial({ color: 0x5cb46b, roughness: 0.97 }),
  );
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  // ── Roads (merged asphalt) + lane lines + crosswalks ─────
  onStatus('building roads');
  const roadGeos = [];
  const laneGeos = [];
  const crossGeos = [];
  const ROAD_W = cell;                 // road fills the cell width
  const tmp = new THREE.Object3D();

  const pushPlane = (arr, w, d, x, y, z, rotZ = 0) => {
    const g = new THREE.PlaneGeometry(w, d);
    g.rotateX(-Math.PI / 2);
    if (rotZ) g.rotateY(rotZ);
    g.translate(x, y, z);
    arr.push(g);
  };

  graph.forEachRoadCell((r, c, x, z, mask) => {
    // asphalt tile
    pushPlane(roadGeos, ROAD_W, ROAD_W, x, 0.02, z);
    const deg = countBits(mask);
    if (deg >= 3) {
      // crosswalk stripes on each connected side
      for (const [k, ang] of [['N', 0], ['S', 0], ['E', Math.PI / 2], ['W', Math.PI / 2]]) {
        if (!(mask & DIR[k])) continue;
        const off = cell * 0.34;
        const ox = k === 'E' ? off : k === 'W' ? -off : 0;
        const oz = k === 'S' ? off : k === 'N' ? -off : 0;
        for (let s = -2; s <= 2; s++) {
          pushPlane(crossGeos, 0.7, 0.18, x + ox + (ang ? 0 : s * 0.9), 0.04, z + oz + (ang ? s * 0.9 : 0), ang);
        }
      }
    } else if (mask === (DIR.N | DIR.S)) {
      for (let s = -1; s <= 1; s++) pushPlane(laneGeos, 0.18, 1.6, x, 0.035, z + s * (cell / 3));
    } else if (mask === (DIR.E | DIR.W)) {
      for (let s = -1; s <= 1; s++) pushPlane(laneGeos, 1.6, 0.18, x + s * (cell / 3), 0.035, z);
    }
  });

  addMerged(scene, roadGeos, new THREE.MeshStandardMaterial({ color: 0x33373d, roughness: 0.9 }), { receive: true });
  addMerged(scene, laneGeos, new THREE.MeshStandardMaterial({ color: 0xf4d35e, roughness: 0.6 }));
  addMerged(scene, crossGeos, new THREE.MeshStandardMaterial({ color: 0xf2f2f2, roughness: 0.7 }));

  // ── Sidewalks (raised slab per block cell, flush to road) ─
  onStatus('laying sidewalks');
  const swGeos = [];
  graph.forEachBlockCell((r, c, x, z) => {
    const g = new THREE.BoxGeometry(cell, 0.16, cell);
    g.translate(x, 0.08, z);
    swGeos.push(g);
  });
  addMerged(scene, swGeos, new THREE.MeshStandardMaterial({ color: 0xb9b4ac, roughness: 0.95 }), { receive: true });

  // ── Buildings (instanced per type, by district) ──────────
  onStatus('raising buildings');
  const allPaths = [...new Set(Object.values(POOLS).flat())];
  const gltfs = {};
  const loaded = await loadMany(allPaths);
  allPaths.forEach((p, i) => { if (loaded[i]) gltfs[p] = loaded[i]; });

  // Target building HEIGHT per district (clearly taller than the ~1.8u player).
  // Footprint is clamped afterwards so a building never spills into the road.
  const HEIGHT_TARGET = { downtown: 24, commercial: 13, residential: 7.5, waterfront: 9 };
  const MAX_FOOTPRINT = cell * 0.82;   // keep clear of the road
  const SIDEWALK_TOP = 0.16;

  const byPath = {};
  graph.forEachBlockCell((r, c, x, z) => {
    const district = graph.districtAt(r, c);
    const pool = POOLS[district] || POOLS.commercial;
    // leave some residential gaps as small parks for variety
    if (district === 'residential' && graph.rand() < 0.22) return;
    const path = pool[Math.floor(graph.rand() * pool.length)];
    const gltf = gltfs[path];
    if (!gltf) return;

    const box0 = measure(gltf, path);
    const size = new THREE.Vector3(); box0.getSize(size);
    const footprint = Math.max(size.x, size.z) || 1;
    const h = size.y || 1;

    // scale to hit the height target, but never let footprint exceed MAX_FOOTPRINT
    let scale = (HEIGHT_TARGET[district] || 10) / h;
    scale = Math.min(scale, MAX_FOOTPRINT / footprint);
    // base sits on the sidewalk top (account for model's own min.y)
    const baseY = SIDEWALK_TOP - box0.min.y * scale;

    (byPath[path] ||= []).push({
      position: new THREE.Vector3(x, baseY, z),
      rotationY: Math.floor(graph.rand() * 4) * (Math.PI / 2),
      scale,
    });

    // collider — actual scaled footprint, inset 15% so the pavement stays walkable
    const half = (footprint * scale) / 2 * 0.85;
    colliders.push(new THREE.Box3(
      new THREE.Vector3(x - half, 0, z - half),
      new THREE.Vector3(x + half, h * scale, z + half),
    ));
  });

  let buildingCount = 0;
  for (const [path, transforms] of Object.entries(byPath)) {
    const inst = buildInstanced(gltfs[path], transforms);
    if (inst) { scene.add(inst); buildingCount += transforms.length; }
  }

  // ── Trees on residential blocks (instanced) ──────────────
  if (quality.treeDensity > 0) {
    onStatus('planting trees');
    const trees = await loadMany(TREE_PATHS);
    const treeTfms = TREE_PATHS.map(() => []);
    graph.forEachBlockCell((r, c, x, z) => {
      if (graph.districtAt(r, c) !== 'residential') return;
      if (graph.rand() > quality.treeDensity * 0.5) return;
      const ti = graph.rand() < 0.5 ? 0 : 1;
      if (!trees[ti]) return;
      const sz = sizeOf(trees[ti], TREE_PATHS[ti]);
      const scale = (cell * 0.22) / (Math.max(sz.x, sz.z) || 1);
      treeTfms[ti].push({
        position: new THREE.Vector3(x + (graph.rand() - 0.5) * cell * 0.5, 0.15, z + (graph.rand() - 0.5) * cell * 0.5),
        rotationY: graph.rand() * Math.PI * 2,
        scale,
      });
    });
    treeTfms.forEach((tf, i) => { if (tf.length && trees[i]) { const g = buildInstanced(trees[i], tf); if (g) scene.add(g); } });
  }

  // ── Street lights along roads (instanced) ────────────────
  if (quality.propDensity > 0) {
    onStatus('installing lights');
    const lightGltf = await loadGLB(LIGHT_PATH).catch(() => null);
    if (lightGltf) {
      const lsz = sizeOf(lightGltf, LIGHT_PATH);
      const scale = 5 / (lsz.y || 1);
      const tfms = [];
      graph.forEachRoadCell((r, c, x, z, mask) => {
        // place lamps along straight segments, every other cell, on the curb side
        const straightV = mask === (DIR.N | DIR.S);
        const straightH = mask === (DIR.E | DIR.W);
        if (!straightV && !straightH) return;
        if ((r + c) % 2 !== 0) return;
        if (graph.rand() > quality.propDensity) return;
        const off = cell * 0.46;
        if (straightV) tfms.push({ position: new THREE.Vector3(x + off, 0.1, z), rotationY: -Math.PI / 2, scale });
        else tfms.push({ position: new THREE.Vector3(x, 0.1, z + off), rotationY: 0, scale });
      });
      if (tfms.length) { const g = buildInstanced(lightGltf, tfms); if (g) scene.add(g); }
    }
  }

  // ── Road edge lines (frame the streets) ──────────────────
  onStatus('painting road edges');
  const edgeGeos = [];
  graph.forEachRoadCell((r, c, x, z, mask) => {
    // draw a thin white line on each side that borders a block (not another road)
    const sides = [['N', 0, -1], ['S', 0, 1], ['E', 1, 0], ['W', -1, 0]];
    for (const [k, dx, dz] of sides) {
      if (mask & DIR[k]) continue; // road continues this way → no edge line
      const e = cell * 0.5 - 0.15;
      const horizontal = (dx === 0);
      const g = new THREE.PlaneGeometry(horizontal ? cell * 0.9 : 0.16, horizontal ? 0.16 : cell * 0.9);
      g.rotateX(-Math.PI / 2);
      g.translate(x + dx * e, 0.05, z + dz * e);
      edgeGeos.push(g);
    }
  });
  addMerged(scene, edgeGeos, new THREE.MeshStandardMaterial({ color: 0xe8e8e8, roughness: 0.7 }));

  // ── Parks in empty residential cells (green + extra trees) ─
  if (quality.treeDensity > 0) {
    onStatus('growing parks');
    const parkTrees = await loadMany(TREE_PATHS);
    const parkGeos = [];
    const extraTreeTfms = TREE_PATHS.map(() => []);
    graph.forEachBlockCell((r, c, x, z) => {
      if (graph.districtAt(r, c) !== 'residential') return;
      // ~18% of residential cells become parks
      if (graph.rand() > 0.18) return;
      const g = new THREE.BoxGeometry(cell * 0.92, 0.04, cell * 0.92);
      g.translate(x, 0.18, z);
      parkGeos.push(g);
      const n = 2 + Math.floor(graph.rand() * 2);
      for (let i = 0; i < n; i++) {
        const ti = graph.rand() < 0.5 ? 0 : 1;
        if (!parkTrees[ti]) continue;
        const sz = sizeOf(parkTrees[ti], TREE_PATHS[ti]);
        const sc = (cell * 0.25) / (Math.max(sz.x, sz.z) || 1);
        extraTreeTfms[ti].push({
          position: new THREE.Vector3(x + (graph.rand() - 0.5) * cell * 0.6, 0.2, z + (graph.rand() - 0.5) * cell * 0.6),
          rotationY: graph.rand() * Math.PI * 2, scale: sc,
        });
      }
    });
    addMerged(scene, parkGeos, new THREE.MeshStandardMaterial({ color: 0x6cc457, roughness: 0.95 }), { receive: true });
    extraTreeTfms.forEach((tf, i) => { if (tf.length && parkTrees[i]) { const g = buildInstanced(parkTrees[i], tf); if (g) scene.add(g); } });
  }

  // ── AL SAEB HQ landmark (centre of downtown) ─────────────
  onStatus('raising AL SAEB HQ');
  const hqGltf = await loadGLB('city/commercial/building-skyscraper-c.glb').catch(() => null);
  // place it one block north of the centre intersection so it doesn't block spawn
  const hqCellR = Math.max(1, Math.round(graph.rows / 2) - 1);
  const hqCellC = Math.round(graph.cols / 2) + 1;
  const hqW = graph.cellToWorld(hqCellR, hqCellC);
  if (hqGltf) {
    const box0 = measure(hqGltf, 'hq');
    const size = new THREE.Vector3(); box0.getSize(size);
    const scale = 40 / (size.y || 1);                 // tallest in the city
    const hq = hqGltf.scene.clone(true);
    hq.scale.setScalar(scale);
    hq.position.set(hqW.x, 0.16 - box0.min.y * scale, hqW.z);
    hq.traverse(o => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
    scene.add(hq);
    const fp = Math.max(size.x, size.z) * scale / 2 * 0.8;
    colliders.push(new THREE.Box3(new THREE.Vector3(hqW.x - fp, 0, hqW.z - fp), new THREE.Vector3(hqW.x + fp, size.y * scale, hqW.z + fp)));
  }
  scene.add(makeLabel('🏢 AL SAEB HQ', hqW.x, 46, hqW.z, 22));

  // ── Spawn: snap to a road intersection near the centre ───
  const snap = (v) => Math.max(0, Math.round(v / graph.roadEvery) * graph.roadEvery);
  const sr = snap(Math.floor(graph.rows / 2));
  const sc = snap(Math.floor(graph.cols / 2));
  const spawnW = graph.cellToWorld(sr, sc);
  const spawn = { x: spawnW.x, y: 0, z: spawnW.z };

  onStatus('done');
  return {
    graph, colliders, bounds, sun,
    spawn,
    stats: { buildings: buildingCount, nodes: graph.nodes.length, edges: graph.edges.length },
  };
}

// ── helpers ──────────────────────────────────────────────────
function addMerged(scene, geos, material, { receive = false, cast = false } = {}) {
  if (!geos.length) return null;
  const merged = mergeGeometries(geos, false);
  geos.forEach(g => g.dispose());
  const mesh = new THREE.Mesh(merged, material);
  mesh.receiveShadow = receive;
  mesh.castShadow = cast;
  scene.add(mesh);
  return mesh;
}
function countBits(m) { let d = 0; while (m) { d += m & 1; m >>= 1; } return d; }

// Floating text label (canvas → sprite). worldY = height above ground.
function makeLabel(text, x, worldY, z, worldWidth = 16) {
  const canvas = document.createElement('canvas');
  canvas.width = 512; canvas.height = 128;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = 'rgba(15,18,30,0.85)';
  roundRect(ctx, 8, 8, 496, 112, 24); ctx.fill();
  ctx.strokeStyle = 'rgba(212,168,71,0.7)'; ctx.lineWidth = 4;
  roundRect(ctx, 8, 8, 496, 112, 24); ctx.stroke();
  ctx.font = 'bold 56px Cairo, sans-serif';
  ctx.fillStyle = '#F4C962'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillText(text, 256, 68);
  const tex = new THREE.CanvasTexture(canvas);
  tex.anisotropy = 4;
  const mat = new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false });
  const sprite = new THREE.Sprite(mat);
  sprite.position.set(x, worldY, z);
  sprite.scale.set(worldWidth, worldWidth * 0.25, 1);
  return sprite;
}
function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}
