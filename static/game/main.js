// ═══════════════════════════════════════════════════════════════
//  MAIN — AL SAEB World engine bootstrap (Phase 0 foundation)
//  Renderer + scene + city + walking player + follow camera + loop.
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Quality } from './engine/quality.js';
import { onLoadProgress } from './engine/assets.js';
import { buildCity } from './world/city.js';
import { Input, makePlayerProxy, WalkController } from './player/controls.js';
import { FollowCamera } from './player/camera.js';

const elStatus = document.getElementById('boot-status');
const elBar = document.getElementById('boot-bar');
const elLoading = document.getElementById('loading');
const elHud = document.getElementById('hud-stats');
const setStatus = (t) => { if (elStatus) elStatus.textContent = t; };

onLoadProgress((loaded, total) => {
  if (elBar && total) elBar.style.width = Math.floor((loaded / total) * 100) + '%';
});

async function boot() {
  setStatus('بدء المحرك — ' + Quality.describe());

  // Renderer
  const canvas = document.getElementById('game-canvas');
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: Quality.antialias, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Quality.pixelRatio);
  renderer.setSize(innerWidth, innerHeight);
  if (Quality.shadows) { renderer.shadowMap.enabled = true; renderer.shadowMap.type = THREE.PCFSoftShadowMap; }
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  // Scene + camera
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.1, Quality.drawDistance + 60);

  // Build city
  setStatus('بناء المدينة...');
  const city = await buildCity(scene, { quality: Quality, onStatus: setStatus });

  // Player
  const player = makePlayerProxy();
  player.position.set(city.spawn.x, city.spawn.y, city.spawn.z);
  scene.add(player);

  // Input + controllers
  const input = new Input(canvas);
  const walk = new WalkController(player, city.colliders);
  const follow = new FollowCamera(camera, player);

  // Resize
  addEventListener('resize', () => {
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight);
  });

  // HUD updater (throttled)
  let fps = 0, fpsAcc = 0, fpsFrames = 0, hudT = 0;
  function updateHud(dt) {
    fpsAcc += dt; fpsFrames++;
    hudT += dt;
    if (hudT >= 0.5) {
      fps = Math.round(fpsFrames / fpsAcc);
      fpsAcc = 0; fpsFrames = 0; hudT = 0;
      if (elHud) {
        const d = city.graph.districtAt(...Object.values(city.graph.worldToCell(player.position.x, player.position.z)));
        elHud.innerHTML =
          `FPS <b>${fps}</b> · ${Quality.tier} · مباني <b>${city.stats.buildings}</b><br>` +
          `الحي: <b>${districtAr(d)}</b> · X ${player.position.x.toFixed(0)} Z ${player.position.z.toFixed(0)}`;
      }
    }
  }

  // Hide loader
  if (elLoading) { elLoading.style.opacity = '0'; setTimeout(() => elLoading.style.display = 'none', 500); }

  // Loop
  const clock = new THREE.Clock();
  function frame() {
    const dt = Math.min(clock.getDelta(), 0.05);
    const look = input.consumeLook();
    follow.update(dt, look);
    walk.update(dt, input, follow.moveYaw);
    updateHud(dt);
    renderer.render(scene, camera);
    requestAnimationFrame(frame);
  }
  frame();

  // expose for debugging
  window.__world = { scene, camera, renderer, city, player, Quality };
  setStatus('جاهز');
}

function districtAr(d) {
  return { downtown: 'وسط المدينة', commercial: 'تجاري', residential: 'سكني', waterfront: 'الكورنيش' }[d] || d;
}

boot().catch(err => {
  console.error('World boot failed:', err);
  setStatus('فشل التحميل: ' + err.message);
});
