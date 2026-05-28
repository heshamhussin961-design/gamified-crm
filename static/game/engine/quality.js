// ═══════════════════════════════════════════════════════════════
//  QUALITY — device detection + responsive quality tiers
//  One source of truth for all perf-sensitive knobs. Everything else
//  (renderer, city density, draw distance, shadows) reads from here.
// ═══════════════════════════════════════════════════════════════

const isMobile = /Android|iPhone|iPad|iPod|Opera Mini|IEMobile|Mobile/i.test(navigator.userAgent)
  || (navigator.maxTouchPoints > 1 && window.innerWidth < 1024);

const hwThreads = navigator.hardwareConcurrency || (isMobile ? 4 : 8);
const deviceMem = navigator.deviceMemory || (isMobile ? 4 : 8);

// Tier: 'low' | 'mid' | 'high'
function detectTier() {
  if (isMobile) {
    return (hwThreads >= 8 && deviceMem >= 6) ? 'mid' : 'low';
  }
  if (hwThreads >= 8 && deviceMem >= 8) return 'high';
  if (hwThreads >= 4) return 'mid';
  return 'low';
}

const TIER = detectTier();

// Per-tier knobs. Tuned conservatively so 'low' stays smooth on phones.
const PRESETS = {
  low: {
    pixelRatio: Math.min(window.devicePixelRatio || 1, 1.25),
    antialias: false,
    shadows: false,
    shadowMapSize: 1024,
    drawDistance: 90,     // fog far / chunk radius basis
    fogNear: 35,
    chunkRadius: 2,       // how many chunk-rings to keep loaded
    maxLights: 0,         // extra dynamic point lights beyond sun
    treeDensity: 0.3,
    propDensity: 0.3,
    npcCount: 0,
    trafficCount: 0,
    instancedOnly: true,  // skip non-instanced decorative clones
  },
  mid: {
    pixelRatio: Math.min(window.devicePixelRatio || 1, 1.5),
    antialias: true,
    shadows: true,
    shadowMapSize: 2048,
    drawDistance: 140,
    fogNear: 60,
    chunkRadius: 3,
    maxLights: 6,
    treeDensity: 0.6,
    propDensity: 0.6,
    npcCount: 12,
    trafficCount: 8,
    instancedOnly: false,
  },
  high: {
    pixelRatio: Math.min(window.devicePixelRatio || 1, 2),
    antialias: true,
    shadows: true,
    shadowMapSize: 4096,
    drawDistance: 220,
    fogNear: 90,
    chunkRadius: 4,
    maxLights: 16,
    treeDensity: 1.0,
    propDensity: 1.0,
    npcCount: 30,
    trafficCount: 18,
    instancedOnly: false,
  },
};

export const Quality = {
  tier: TIER,
  isMobile,
  ...PRESETS[TIER],
  // Allow runtime override (settings menu later)
  set(tier) {
    if (!PRESETS[tier]) return;
    Object.assign(this, { tier }, PRESETS[tier]);
  },
  describe() {
    return `tier=${this.tier} mobile=${this.isMobile} threads=${hwThreads} mem=${deviceMem}GB dpr=${this.pixelRatio}`;
  },
};
