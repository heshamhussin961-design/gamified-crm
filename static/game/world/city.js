// ═══════════════════════════════════════════════════════════════
//  CITY — turns a RoadGraph into a 3D world (roads, sidewalks,
//  buildings, props), optimised with merged geometry + instancing.
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { RoadGraph, DIR } from '../engine/roadgraph.js';
import { loadGLB, loadMany, sizeOf, buildInstanced } from '../engine/assets.js';

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

  // ── Sidewalks (raised slab per block cell) ───────────────
  onStatus('laying sidewalks');
  const swGeos = [];
  graph.forEachBlockCell((r, c, x, z) => {
    const g = new THREE.BoxGeometry(cell * 0.98, 0.16, cell * 0.98);
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

  // transforms grouped by building path
  const byPath = {};
  graph.forEachBlockCell((r, c, x, z) => {
    const district = graph.districtAt(r, c);
    const pool = POOLS[district] || POOLS.commercial;
    // leave some residential gaps as parks/empty for variety
    if (district === 'residential' && graph.rand() < 0.22) return;
    const path = pool[Math.floor(graph.rand() * pool.length)];
    const gltf = gltfs[path];
    if (!gltf) return;
    const size = sizeOf(gltf, path);
    const footprint = Math.max(size.x, size.z) || 1;
    const target = cell * (district === 'downtown' ? 0.78 : 0.66);
    const scale = target / footprint;
    (byPath[path] ||= []).push({
      position: new THREE.Vector3(x, 0, z),
      rotationY: Math.floor(graph.rand() * 4) * (Math.PI / 2),
      scale,
    });
    // collider — AABB sized to scaled footprint
    const half = (footprint * scale) / 2;
    const box = new THREE.Box3(
      new THREE.Vector3(x - half, 0, z - half),
      new THREE.Vector3(x + half, size.y * scale, z + half),
    );
    colliders.push(box);
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

  // ── Street lights at intersections (instanced) ───────────
  if (quality.propDensity > 0) {
    onStatus('installing lights');
    const lightGltf = await loadGLB(LIGHT_PATH).catch(() => null);
    if (lightGltf) {
      const lsz = sizeOf(lightGltf, LIGHT_PATH);
      const scale = 4.5 / (lsz.y || 1);
      const tfms = [];
      for (const n of graph.nodes) {
        if (n.degree < 3) continue;
        if (graph.rand() > quality.propDensity) continue;
        tfms.push({ position: new THREE.Vector3(n.x + cell * 0.38, 0.1, n.z + cell * 0.38), rotationY: graph.rand() * Math.PI * 2, scale });
      }
      if (tfms.length) { const g = buildInstanced(lightGltf, tfms); if (g) scene.add(g); }
    }
  }

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
