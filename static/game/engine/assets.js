// ═══════════════════════════════════════════════════════════════
//  ASSETS — GLB loading, caching, bbox measuring, instancing helpers
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const ASSET_ROOT = '/static/game3d/assets';

const manager = new THREE.LoadingManager();
const loader = new GLTFLoader(manager);
const _cache = new Map();      // path -> gltf
const _bboxCache = new Map();  // path -> THREE.Box3 (of base scene)

let _onProgress = null;
manager.onProgress = (url, loaded, total) => { if (_onProgress) _onProgress(loaded, total, url); };

export function onLoadProgress(cb) { _onProgress = cb; }

export function assetUrl(rel) {
  return rel.startsWith('http') || rel.startsWith('/') ? rel : `${ASSET_ROOT}/${rel}`;
}

export async function loadGLB(rel) {
  const url = assetUrl(rel);
  if (_cache.has(url)) return _cache.get(url);
  const gltf = await new Promise((res, rej) => loader.load(url, res, undefined, rej));
  _cache.set(url, gltf);
  return gltf;
}

// Load multiple, tolerate failures (returns null for failed entries).
export async function loadMany(relPaths) {
  return Promise.all(relPaths.map(p => loadGLB(p).catch(() => null)));
}

// Clone a loaded model's scene, enable shadows.
export function cloneModel(gltf, { castShadow = true, receiveShadow = true } = {}) {
  if (!gltf?.scene) return null;
  const obj = gltf.scene.clone(true);
  obj.traverse(o => {
    if (o.isMesh) { o.castShadow = castShadow; o.receiveShadow = receiveShadow; }
  });
  return obj;
}

// Measure a model's world-space bounding box (cached). Useful to know tile size.
export function measure(gltf, key) {
  if (key && _bboxCache.has(key)) return _bboxCache.get(key).clone();
  const box = new THREE.Box3().setFromObject(gltf.scene);
  if (key) _bboxCache.set(key, box.clone());
  return box;
}

export function sizeOf(gltf, key) {
  const box = measure(gltf, key);
  const v = new THREE.Vector3();
  box.getSize(v);
  return v; // {x, y, z}
}

// ── Instancing ──────────────────────────────────────────────────
// Build an InstancedMesh per unique geometry+material in a model, so we can
// render hundreds of copies cheaply. Returns a Group containing the instanced
// meshes plus an `update(transforms)` to set positions.
//
// transforms: array of { position:Vector3, rotationY:number, scale:number }
export function buildInstanced(gltf, transforms) {
  if (!gltf?.scene || !transforms.length) return null;
  const group = new THREE.Group();
  const meshParts = [];
  gltf.scene.updateWorldMatrix(true, true);
  gltf.scene.traverse(o => {
    if (o.isMesh) {
      meshParts.push({ geometry: o.geometry, material: o.material, matrix: o.matrixWorld.clone() });
    }
  });
  const dummy = new THREE.Object3D();
  for (const part of meshParts) {
    const inst = new THREE.InstancedMesh(part.geometry, part.material, transforms.length);
    inst.castShadow = true;
    inst.receiveShadow = true;
    inst.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    for (let i = 0; i < transforms.length; i++) {
      const t = transforms[i];
      dummy.position.copy(t.position);
      dummy.rotation.set(0, t.rotationY || 0, 0);
      dummy.scale.setScalar(t.scale || 1);
      dummy.updateMatrix();
      // Compose with the mesh's local-within-model matrix so multi-part models stay aligned.
      dummy.matrix.multiply(part.matrix);
      inst.setMatrixAt(i, dummy.matrix);
    }
    inst.instanceMatrix.needsUpdate = true;
    inst.frustumCulled = true;
    group.add(inst);
  }
  return group;
}

export { manager };
