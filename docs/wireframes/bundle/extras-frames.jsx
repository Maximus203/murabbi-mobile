// Murabbi Extras — Realistic device frames (iPhone 14 Pro, Pixel 8) + simplified shells

// ── iPhone 14 Pro frame (393×852, Dynamic Island) ──────────────────────────
function IPhoneFrame({ children, width = 360, scale = 1, dark = false, style }) {
  // Reference dims of iPhone 14 Pro: 393 × 852. We scale via width.
  const ratio = 852 / 393;
  const w = width;
  const h = Math.round(w * ratio);
  const bezel = Math.round(w * 0.020);
  const radius = Math.round(w * 0.115);
  return (
    <div style={{
      width: w, height: h, borderRadius: radius,
      background: '#0A0A0A',
      padding: bezel,
      position: 'relative',
      boxShadow: '0 20px 60px rgba(28,26,22,0.18), 0 4px 12px rgba(28,26,22,0.10), inset 0 0 0 1px rgba(255,255,255,0.06)',
      ...style,
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: radius - bezel,
        background: dark ? '#0E0B07' : M.bgPrimary,
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Dynamic Island */}
        <div style={{
          position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
          width: Math.round(w * 0.31), height: Math.round(w * 0.094),
          background: '#000', borderRadius: 999, zIndex: 50,
        }}/>
        {children}
      </div>
    </div>
  );
}

// ── Dynamic Island variants (compact / expanded / minimal-pair) ────────────
function DynamicIsland({ variant = 'compact', leftIcon, leftLabel, rightLabel, rightIcon, expanded, width = 360 }) {
  // Width / position relative to a 360px-wide phone
  if (variant === 'minimal-pair') {
    return (
      <div style={{ position: 'absolute', top: 11, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 8, zIndex: 60, pointerEvents: 'none' }}>
        <div style={{ width: 28, height: 28, borderRadius: 999, background: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {leftIcon}
        </div>
        <div style={{ width: width * 0.31 - 36, height: 28, borderRadius: 999, background: '#000' }}/>
        <div style={{ width: 28, height: 28, borderRadius: 999, background: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {rightIcon}
        </div>
      </div>
    );
  }
  if (variant === 'expanded') {
    return (
      <div style={{ position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)', zIndex: 60, width: width * 0.78, background: '#000', color: '#fff', borderRadius: 38, padding: '14px 18px', boxShadow: '0 8px 24px rgba(0,0,0,0.4)' }}>
        {expanded}
      </div>
    );
  }
  // compact: pill with content tucked left/right of the cutout
  return (
    <div style={{ position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)', zIndex: 60, height: width * 0.094, width: width * 0.55, background: '#000', borderRadius: 999, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: `0 ${width * 0.045}px`, fontFamily: M.fontSans }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {leftIcon}
        {leftLabel && <span style={{ fontSize: 12, fontWeight: 500 }}>{leftLabel}</span>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        {rightLabel && <span style={{ fontFamily: M.fontMono, fontSize: 13, fontWeight: 500 }}>{rightLabel}</span>}
        {rightIcon}
      </div>
    </div>
  );
}

// ── Pixel 8 frame (412×915 logical) ────────────────────────────────────────
function PixelFrame({ children, width = 360, dark = false, style }) {
  const ratio = 915 / 412;
  const w = width;
  const h = Math.round(w * ratio);
  const bezel = Math.round(w * 0.022);
  const radius = Math.round(w * 0.085);
  return (
    <div style={{
      width: w, height: h, borderRadius: radius,
      background: '#1A1A1A', padding: bezel, position: 'relative',
      boxShadow: '0 20px 60px rgba(28,26,22,0.18), 0 4px 12px rgba(28,26,22,0.10)',
      ...style,
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: radius - bezel,
        background: dark ? '#0E0B07' : M.bgPrimary,
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Punch hole camera (top center) */}
        <div style={{ position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)', width: 12, height: 12, borderRadius: 999, background: '#000', zIndex: 50 }}/>
        {children}
      </div>
    </div>
  );
}

Object.assign(window, { IPhoneFrame, DynamicIsland, PixelFrame });
