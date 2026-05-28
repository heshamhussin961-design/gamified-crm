// ═══════════════════════════════════════════════════════════════
//  CAMERA — smooth third-person follow with wall collision.
//  Yaw/pitch from input look-delta; camera eases behind target and
//  pulls in when a building (AABB collider) is between it and the player.
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';

export class FollowCamera {
  constructor(camera, target) {
    this.camera = camera;
    this.target = target;
    this.colliders = [];
    this.yaw = Math.PI;          // behind the player
    this.pitch = 0.32;           // looking slightly down
    this.distance = 8;
    this.minPitch = 0.05;
    this.maxPitch = 1.2;
    this.height = 1.6;
    this.minDistance = 1.8;
    this.sens = 0.0045;
    this._look = new THREE.Vector3();
    this._desired = new THREE.Vector3();
    this._dir = new THREE.Vector3();
    this._ray = new THREE.Ray();
    this._hit = new THREE.Vector3();
  }

  setColliders(arr) { this.colliders = arr || []; }

  update(dt, lookDelta) {
    this.yaw -= lookDelta.dx * this.sens;
    this.pitch += lookDelta.dy * this.sens;
    this.pitch = Math.max(this.minPitch, Math.min(this.maxPitch, this.pitch));

    const t = this.target.position;
    this._look.set(t.x, t.y + this.height, t.z);

    // Offset from look point to the camera (full, un-collided).
    const horiz = Math.cos(this.pitch) * this.distance;
    this._desired.set(
      -Math.sin(this.yaw) * horiz,
      Math.sin(this.pitch) * this.distance,
      -Math.cos(this.yaw) * horiz,
    );
    const fullDist = this._desired.length();
    this._dir.copy(this._desired).normalize();

    // Wall collision: cast from look point outward, clamp to nearest hit.
    let allowed = fullDist;
    this._ray.origin.copy(this._look);
    this._ray.direction.copy(this._dir);
    for (const b of this.colliders) {
      const p = this._ray.intersectBox(b, this._hit);
      if (p) {
        const d = this._look.distanceTo(p);
        if (d < allowed) allowed = d;
      }
    }
    allowed = Math.max(this.minDistance, allowed - 0.45);

    const camTarget = this._desired.copy(this._dir).multiplyScalar(allowed).add(this._look);
    // ease toward target (snappier when colliding, to avoid clipping)
    const lerp = 1 - Math.pow(0.0015, dt);
    this.camera.position.lerp(camTarget, lerp);
    this.camera.lookAt(this._look);
  }

  get moveYaw() { return this.yaw; }
}
