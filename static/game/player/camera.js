// ═══════════════════════════════════════════════════════════════
//  CAMERA — smooth third-person orbit/follow camera.
//  Yaw/pitch driven by input look-delta; position eases behind target.
// ═══════════════════════════════════════════════════════════════
import * as THREE from 'three';

export class FollowCamera {
  constructor(camera, target) {
    this.camera = camera;
    this.target = target;
    this.yaw = Math.PI;          // behind the player
    this.pitch = 0.32;           // looking slightly down
    this.distance = 8;
    this.minPitch = 0.05;
    this.maxPitch = 1.2;
    this.height = 1.6;
    this.sens = 0.0045;
    this._pos = new THREE.Vector3();
    this._look = new THREE.Vector3();
  }

  update(dt, lookDelta) {
    this.yaw -= lookDelta.dx * this.sens;
    this.pitch += lookDelta.dy * this.sens;
    this.pitch = Math.max(this.minPitch, Math.min(this.maxPitch, this.pitch));

    const t = this.target.position;
    const horiz = Math.cos(this.pitch) * this.distance;
    const desired = this._pos.set(
      t.x - Math.sin(this.yaw) * horiz,
      t.y + this.height + Math.sin(this.pitch) * this.distance,
      t.z - Math.cos(this.yaw) * horiz,
    );
    // smooth follow
    const lerp = 1 - Math.pow(0.0015, dt);
    this.camera.position.lerp(desired, lerp);
    this._look.set(t.x, t.y + this.height, t.z);
    this.camera.lookAt(this._look);
  }

  // Yaw the player should align "forward" to (for camera-relative movement).
  get moveYaw() { return this.yaw; }
}
