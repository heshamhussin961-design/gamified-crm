// ═══════════════════════════════════════════════════════════════
//  CONTROLS — input (keyboard + touch) + walking player controller
//  with simple AABB collision against city colliders.
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';

// ── Input: keyboard + dual-touch (left = move, right = look) ──
export class Input {
  constructor(domEl) {
    this.keys = {};
    this.move = { x: 0, y: 0 };       // -1..1 normalised stick
    this.look = { dx: 0, dy: 0 };     // per-frame look delta (consumed each frame)
    this.run = false;
    this._moveTouchId = null;
    this._lookTouchId = null;
    this._moveOrigin = { x: 0, y: 0 };

    addEventListener('keydown', e => {
      this.keys[e.code] = true;
      if (e.code === 'ShiftLeft' || e.code === 'ShiftRight') this.run = true;
    });
    addEventListener('keyup', e => {
      this.keys[e.code] = false;
      if (e.code === 'ShiftLeft' || e.code === 'ShiftRight') this.run = false;
    });

    // Mouse look (desktop) — drag anywhere
    let mouseDown = false, lastX = 0, lastY = 0;
    domEl.addEventListener('mousedown', e => { mouseDown = true; lastX = e.clientX; lastY = e.clientY; });
    addEventListener('mouseup', () => { mouseDown = false; });
    addEventListener('mousemove', e => {
      if (!mouseDown) return;
      this.look.dx += (e.clientX - lastX); this.look.dy += (e.clientY - lastY);
      lastX = e.clientX; lastY = e.clientY;
    });

    // Touch: left half = move stick, right half = look
    domEl.addEventListener('touchstart', e => {
      for (const t of e.changedTouches) {
        if (t.clientX < innerWidth / 2 && this._moveTouchId === null) {
          this._moveTouchId = t.identifier; this._moveOrigin = { x: t.clientX, y: t.clientY };
        } else if (this._lookTouchId === null) {
          this._lookTouchId = t.identifier; this._lookLast = { x: t.clientX, y: t.clientY };
        }
      }
    }, { passive: true });
    domEl.addEventListener('touchmove', e => {
      for (const t of e.changedTouches) {
        if (t.identifier === this._moveTouchId) {
          const dx = t.clientX - this._moveOrigin.x, dy = t.clientY - this._moveOrigin.y;
          const R = 60;
          this.move.x = Math.max(-1, Math.min(1, dx / R));
          this.move.y = Math.max(-1, Math.min(1, dy / R));
          this.run = Math.hypot(dx, dy) > R * 0.85;
        } else if (t.identifier === this._lookTouchId) {
          this.look.dx += (t.clientX - this._lookLast.x); this.look.dy += (t.clientY - this._lookLast.y);
          this._lookLast = { x: t.clientX, y: t.clientY };
        }
      }
    }, { passive: true });
    const endTouch = e => {
      for (const t of e.changedTouches) {
        if (t.identifier === this._moveTouchId) { this._moveTouchId = null; this.move.x = 0; this.move.y = 0; this.run = false; }
        if (t.identifier === this._lookTouchId) { this._lookTouchId = null; }
      }
    };
    domEl.addEventListener('touchend', endTouch, { passive: true });
    domEl.addEventListener('touchcancel', endTouch, { passive: true });
  }

  // Combined move vector from keyboard + stick. y+ = forward.
  axis() {
    let x = this.move.x, y = -this.move.y; // stick: up = forward
    if (this.keys['KeyW'] || this.keys['ArrowUp']) y += 1;
    if (this.keys['KeyS'] || this.keys['ArrowDown']) y -= 1;
    if (this.keys['KeyD'] || this.keys['ArrowRight']) x += 1;
    if (this.keys['KeyA'] || this.keys['ArrowLeft']) x -= 1;
    const len = Math.hypot(x, y);
    if (len > 1) { x /= len; y /= len; }
    return { x, y };
  }

  consumeLook() { const l = { ...this.look }; this.look.dx = 0; this.look.dy = 0; return l; }
}

// ── Simple low-poly player proxy (replace with rigged char in Phase 2) ──
export function makePlayerProxy() {
  const g = new THREE.Group();
  const bodyMat = new THREE.MeshStandardMaterial({ color: 0xD4A847, roughness: 0.5, metalness: 0.1 });
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.4, 0.9, 6, 12), bodyMat);
  body.position.y = 1.0; body.castShadow = true;
  g.add(body);
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.32, 16, 16), new THREE.MeshStandardMaterial({ color: 0xf0c98a, roughness: 0.6 }));
  head.position.y = 1.85; head.castShadow = true;
  g.add(head);
  // facing indicator (nose)
  const nose = new THREE.Mesh(new THREE.ConeGeometry(0.12, 0.3, 8), new THREE.MeshStandardMaterial({ color: 0x222 }));
  nose.rotation.x = Math.PI / 2; nose.position.set(0, 1.85, 0.32);
  g.add(nose);
  return g;
}

// ── Walking controller ───────────────────────────────────────
export class WalkController {
  constructor(player, colliders, { speed = 5.5, runMul = 1.9 } = {}) {
    this.player = player;
    this.colliders = colliders;
    this.speed = speed;
    this.runMul = runMul;
    this.radius = 0.5;
    this.velocityY = 0;
    this._box = new THREE.Box3();
  }

  update(dt, input, cameraYaw) {
    const a = input.axis();
    const moving = (a.x !== 0 || a.y !== 0);
    if (moving) {
      // camera-relative movement: forward(a.y)=(sin,cos), right(a.x)=(cos,-sin)
      const sin = Math.sin(cameraYaw), cos = Math.cos(cameraYaw);
      const dirX = a.x * cos + a.y * sin;
      const dirZ = -a.x * sin + a.y * cos;
      const sp = this.speed * (input.run ? this.runMul : 1) * dt;
      this._tryMove(dirX * sp, dirZ * sp);
      // face movement direction
      this.player.rotation.y = Math.atan2(dirX, dirZ);
    }
    return moving;
  }

  _tryMove(dx, dz) {
    const p = this.player.position;
    // X axis
    if (!this._blocked(p.x + dx, p.z)) p.x += dx;
    // Z axis
    if (!this._blocked(p.x, p.z + dz)) p.z += dz;
  }

  _blocked(x, z) {
    const r = this.radius;
    for (const b of this.colliders) {
      if (x + r > b.min.x && x - r < b.max.x && z + r > b.min.z && z - r < b.max.z) return true;
    }
    return false;
  }
}
