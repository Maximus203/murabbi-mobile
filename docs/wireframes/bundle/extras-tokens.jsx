// Murabbi Extras Mobile — Tokens, Icons, Shared helpers

const M = {
  // Palette terreuse (héritée des wireframes mobile)
  bgPrimary: '#F5F2ED',
  bgSurface: '#FDFBF8',
  bgInput:   '#EDE9E2',

  textPrimary:   '#1C1A16',
  textSecondary: '#6B6155',
  textTertiary:  '#A89880',
  textOnDark:    '#FDFBF8',

  accent:       '#8B6F47',
  accentLight:  'rgba(139, 111, 71, 0.10)',
  accentBorder: 'rgba(139, 111, 71, 0.25)',

  success:      '#6B8C6B',
  successLight: 'rgba(107, 140, 107, 0.10)',
  warning:      '#9B5E3C',
  warningLight: 'rgba(155, 94, 60, 0.10)',
  danger:       '#8C3D3D',
  dangerLight:  'rgba(140, 61, 61, 0.10)',

  borderDefault:  'rgba(28, 26, 22, 0.08)',
  borderEmphasis: 'rgba(28, 26, 22, 0.16)',

  // Catégories
  catReligion: '#8B6F47',
  catSport:    '#6B8C6B',
  catSante:    '#5C7A8C',
  catMental:   '#7A6B8C',
  catSocial:   '#9B7A4A',

  fontSans:   "'Geist', system-ui, -apple-system, sans-serif",
  fontMono:   "'Geist Mono', ui-monospace, monospace",
  fontArabic: "'Noto Sans Arabic', 'Geist', sans-serif",
};

// ── Lucide icons (1.5 stroke, round caps) ──────────────────────────────────
const ICON_PATHS = {
  'check': 'M20 6L9 17l-5-5',
  'x': 'M18 6L6 18M6 6l12 12',
  'clock': 'M12 22a10 10 0 100-20 10 10 0 000 20zM12 6v6l4 2',
  'bell': 'M6 8a6 6 0 1112 0c0 7 3 7 3 9H3c0-2 3-2 3-9zM10.3 21a1.94 1.94 0 003.4 0',
  'sun': 'M12 17a5 5 0 100-10 5 5 0 000 10zM12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42',
  'sunrise': 'M17 18a5 5 0 00-10 0M12 2v7M5.2 11.2l1.4 1.4M2 18h2M20 18h2M22 22H2M16 5l-4 4-4-4',
  'sunset': 'M17 18a5 5 0 00-10 0M12 9V2M5.2 11.2l1.4 1.4M2 18h2M20 18h2M22 22H2M16 5l-4 4-4-4',
  'moon': 'M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z',
  'book': 'M4 19.5A2.5 2.5 0 016.5 17H20V2H6.5A2.5 2.5 0 004 4.5v15zM4 19.5A2.5 2.5 0 006.5 22H20v-5',
  'heart': 'M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z',
  'activity': 'M22 12h-4l-3 9L9 3l-3 9H2',
  'feather': 'M20.24 12.24a6 6 0 00-8.49-8.49L5 10.5V19h8.5l6.74-6.76zM16 8L2 22M17.5 15H9',
  'flame': 'M8.5 14.5A2.5 2.5 0 0011 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 11-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 002.5 2.5z',
  'sparkles': 'M12 3l1.91 4.09L18 9l-4.09 1.91L12 15l-1.91-4.09L6 9l4.09-1.91L12 3zM18 14l1 2 2 1-2 1-1 2-1-2-2-1 2-1 1-2zM5 14l1 2 2 1-2 1-1 2-1-2-2-1 2-1 1-2z',
  'chevron-right': 'M9 18l6-6-6-6',
  'chevron-down': 'M6 9l6 6 6-6',
  'chevron-up': 'M18 15l-6-6-6 6',
  'arrow-up-right': 'M7 17L17 7M7 7h10v10',
  'plus': 'M12 5v14M5 12h14',
  'minus': 'M5 12h14',
  'more-horizontal': 'M5 12a1 1 0 100 2 1 1 0 000-2zM12 12a1 1 0 100 2 1 1 0 000-2zM19 12a1 1 0 100 2 1 1 0 000-2z',
  'circle': 'M12 22a10 10 0 100-20 10 10 0 000 20z',
  'circle-check': 'M12 22a10 10 0 100-20 10 10 0 000 20zM8 12l3 3 5-5',
  'wifi': 'M5 13a10 10 0 0114 0M8.5 16.5a5 5 0 017 0M12 20h.01M2 8.82a15 15 0 0120 0',
  'battery': 'M16 7H3a2 2 0 00-2 2v6a2 2 0 002 2h13a2 2 0 002-2v-1h2v-4h-2V9a2 2 0 00-2-2z',
  'signal': 'M2 22h.01M5 22V18M9 22V14M13 22V10M17 22V6M21 22V2',
  'play': 'M5 3l14 9-14 9V3z',
  'pause': 'M6 4h4v16H6zM14 4h4v16h-4z',
  'calendar': 'M19 4H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V6a2 2 0 00-2-2zM16 2v4M8 2v4M3 10h18',
  'target': 'M12 22a10 10 0 100-20 10 10 0 000 20zM12 18a6 6 0 100-12 6 6 0 000 12zM12 14a2 2 0 100-4 2 2 0 000 4z',
  'trending-up': 'M23 6l-9.5 9.5-5-5L1 18M17 6h6v6',
  'compass': 'M12 22a10 10 0 100-20 10 10 0 000 20zM16.24 7.76l-2.12 6.36-6.36 2.12 2.12-6.36 6.36-2.12z',
  'mountain': 'M3 21l6-12 4 8 3-5 5 9H3z',
  'star': 'M12 2l3.09 6.26 6.91 1-5 4.87 1.18 6.88L12 17.77 5.82 21l1.18-6.88-5-4.87 6.91-1L12 2z',
  'bookmark': 'M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z',
  'volume-x': 'M11 5L6 9H2v6h4l5 4V5zM23 9l-6 6M17 9l6 6',
  'flashlight': 'M9 2h6l-1 6h-4z M9 8h6v6c0 2-1 3-3 3s-3-1-3-3z M11 17v5',
  'camera': 'M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2zM12 17a4 4 0 100-8 4 4 0 000 8z',
  'mic': 'M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3zM19 10v2a7 7 0 01-14 0v-2M12 19v4M8 23h8',
  'lock': 'M5 11h14a2 2 0 012 2v7a2 2 0 01-2 2H5a2 2 0 01-2-2v-7a2 2 0 012-2zM7 11V7a5 5 0 0110 0v4',
  'bell-off': 'M13.73 21a2 2 0 01-3.46 0M18.63 13A17.89 17.89 0 0118 8M6.26 6.26A5.86 5.86 0 006 8c0 7-3 9-3 9h14M18 8a6 6 0 00-9.33-5M1 1l22 22',
  'home': 'M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1V9.5z',
  'search': 'M11 19a8 8 0 100-16 8 8 0 000 16zM21 21l-4.35-4.35',
  'message-circle': 'M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z',
  'phone': 'M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z',
  'send': 'M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z',
  'eye': 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8zM12 15a3 3 0 100-6 3 3 0 000 6z',
  'pen-tool': 'M12 19l7-7 3 3-7 7-3-3zM18 13l-1.5-7.5L2 2l3.5 14.5L13 18zM2 2l7.586 7.586M11 11a2 2 0 11-4 0 2 2 0 014 0z',
};

function Icon({ name, size = 16, color = 'currentColor', stroke = 1.5, fill = 'none', style }) {
  const d = ICON_PATHS[name] || ICON_PATHS['circle'];
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={{ display: 'block', flexShrink: 0, ...style }}>
      <path d={d}/>
    </svg>
  );
}

// ── Murabbi Logo (cercle ouvert + barre verticale, glyphe minimal) ─────────
function MurabbiGlyph({ size = 24, color = M.accent, stroke = 1.5 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={{ display: 'block' }}>
      <circle cx="12" cy="12" r="9"/>
      <line x1="12" y1="3" x2="12" y2="21"/>
    </svg>
  );
}

// ── App icon (square, with rounded corners — used across home screens) ─────
function AppIconMurabbi({ size = 56, variant = 'light', radius }) {
  const r = radius != null ? radius : Math.round(size * 0.225); // iOS continuous corner ratio
  const palette = {
    light:  { bg: M.bgPrimary, fg: M.accent },
    dark:   { bg: M.textPrimary, fg: '#D6C4A8' },
    tinted: { bg: '#3D2E1F',     fg: '#F5E5C8' },
    sage:   { bg: '#1F2A1F',     fg: '#A6C0A6' },
  };
  const p = palette[variant] || palette.light;
  return (
    <div style={{ width: size, height: size, borderRadius: r, background: p.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', boxShadow: variant==='light' ? '0 1px 2px rgba(28,26,22,0.08)' : 'none', overflow:'hidden' }}>
      {/* subtle inner stroke for legibility on dark/tinted */}
      <div style={{ position:'absolute', inset:0, borderRadius:r, boxShadow:`inset 0 0 0 0.5px rgba(255,255,255,${variant==='light'?0:0.05})` }}/>
      <MurabbiGlyph size={size * 0.52} color={p.fg} stroke={1.4}/>
    </div>
  );
}

// ── Generic faux app icon (for filling home-screen contexts) ───────────────
function FauxAppIcon({ size = 56, color = '#999', glyph = '', radius }) {
  const r = radius != null ? radius : Math.round(size * 0.225);
  return (
    <div style={{ width: size, height: size, borderRadius: r, background: color, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontFamily: M.fontSans, fontWeight: 600, fontSize: size * 0.36 }}>
      {glyph}
    </div>
  );
}

// ── Wallpaper (custom sober gradients) ─────────────────────────────────────
function Wallpaper({ tone = 'sand', children, style }) {
  const grads = {
    sand:  'radial-gradient(120% 90% at 50% 10%, #C8B79A 0%, #8E7956 45%, #4A3F2E 100%)',
    dusk:  'radial-gradient(120% 90% at 30% 0%, #D6B998 0%, #876B4C 40%, #2A1E14 100%)',
    night: 'radial-gradient(120% 90% at 50% 0%, #4A3E32 0%, #2A2218 45%, #110D08 100%)',
    morning: 'radial-gradient(120% 90% at 50% 0%, #F0E2C8 0%, #C9A87E 45%, #6E4F32 100%)',
  };
  return (
    <div style={{ position: 'absolute', inset: 0, background: grads[tone] || grads.sand, ...style }}>
      {children}
    </div>
  );
}

// ── Status bar (iOS / Android) ─────────────────────────────────────────────
function IOSStatusBar({ time = '9:41', dark = false }) {
  const c = dark ? '#fff' : M.textPrimary;
  return (
    <div style={{
      height: 54, padding: '0 28px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
      paddingBottom: 12, fontFamily: 'SF Pro Display, system-ui, sans-serif', fontWeight: 600, fontSize: 17, color: c, letterSpacing: -0.2,
      pointerEvents: 'none'
    }}>
      <span>{time}</span>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <Icon name="signal" size={17} color={c} stroke={2.2}/>
        <Icon name="wifi" size={15} color={c} stroke={2}/>
        <div style={{ width: 26, height: 12, borderRadius: 3, border: `1px solid ${c}`, position: 'relative', opacity: 0.95 }}>
          <div style={{ position: 'absolute', right: -3, top: 3, width: 2, height: 6, background: c, borderRadius: 1 }}/>
          <div style={{ position: 'absolute', inset: 1.5, background: c, borderRadius: 1.5 }}/>
        </div>
      </div>
    </div>
  );
}

function AndroidStatusBar({ time = '09:41', dark = false }) {
  const c = dark ? '#fff' : '#1C1A16';
  return (
    <div style={{
      height: 32, padding: '0 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      fontFamily: 'Roboto, system-ui, sans-serif', fontWeight: 500, fontSize: 14, color: c,
      pointerEvents: 'none'
    }}>
      <span>{time}</span>
      <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
        <Icon name="signal" size={14} color={c} stroke={2.4}/>
        <Icon name="wifi" size={13} color={c} stroke={2.2}/>
        <div style={{ display: 'flex', alignItems: 'center', gap: 2, fontSize: 11, fontWeight: 500 }}>87%</div>
        <div style={{ width: 22, height: 11, borderRadius: 2, border: `1px solid ${c}`, position: 'relative' }}>
          <div style={{ position: 'absolute', inset: 1.5, width: 14, background: c, borderRadius: 1 }}/>
        </div>
      </div>
    </div>
  );
}

// ── Lock screen clock (iOS) ────────────────────────────────────────────────
function IOSLockClock({ date = 'jeudi 23 avril', time = '9:41', color = '#fff' }) {
  return (
    <div style={{ textAlign: 'center', color, pointerEvents: 'none' }}>
      <div style={{ fontFamily: 'SF Pro Display, system-ui', fontWeight: 500, fontSize: 17, letterSpacing: 0.3, marginBottom: 4, opacity: 0.95 }}>{date}</div>
      <div style={{ fontFamily: 'SF Pro Display, system-ui', fontWeight: 200, fontSize: 88, letterSpacing: -3, lineHeight: 1, textShadow: '0 2px 16px rgba(0,0,0,0.15)' }}>{time}</div>
    </div>
  );
}

// ── Lock screen clock (Android — Pixel) ────────────────────────────────────
function AndroidLockClock({ date = '23 avr.', time = '09:41', color = '#fff' }) {
  return (
    <div style={{ color, pointerEvents: 'none', padding: '0 24px' }}>
      <div style={{ fontFamily: 'Roboto, system-ui', fontWeight: 400, fontSize: 14, opacity: 0.85, marginBottom: 8, letterSpacing: 0.3 }}>{date}</div>
      <div style={{ fontFamily: '"Google Sans", "Roboto", system-ui', fontWeight: 300, fontSize: 96, letterSpacing: -4, lineHeight: 0.95 }}>{time}</div>
    </div>
  );
}

// ── Section title (in-document) ────────────────────────────────────────────
function SectionLabel({ kicker, title, sub }) {
  return (
    <div style={{ marginBottom: 24 }}>
      {kicker && (
        <div style={{ fontFamily: M.fontMono, fontSize: 10, letterSpacing: 1.6, textTransform: 'uppercase', color: M.textTertiary, fontWeight: 500, marginBottom: 8 }}>
          {kicker}
        </div>
      )}
      <h2 style={{ fontFamily: M.fontSans, fontSize: 22, fontWeight: 500, letterSpacing: -0.3, color: M.textPrimary, margin: 0 }}>{title}</h2>
      {sub && <p style={{ fontFamily: M.fontSans, fontSize: 13, color: M.textSecondary, margin: '6px 0 0 0', lineHeight: 1.5, maxWidth: 600 }}>{sub}</p>}
    </div>
  );
}

// ── Mockup label (under each artboard-like mockup) ─────────────────────────
function MockupLabel({ id, name, sub }) {
  return (
    <div style={{ marginTop: 14, fontFamily: M.fontSans }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 2 }}>
        <span style={{ fontFamily: M.fontMono, fontSize: 10, fontWeight: 500, color: M.textTertiary, letterSpacing: 1.2 }}>{id}</span>
      </div>
      <div style={{ fontSize: 13, fontWeight: 500, color: M.textPrimary, lineHeight: 1.3 }}>{name}</div>
      {sub && <div style={{ fontSize: 11, color: M.textSecondary, lineHeight: 1.4, marginTop: 2 }}>{sub}</div>}
    </div>
  );
}

Object.assign(window, { M, Icon, MurabbiGlyph, AppIconMurabbi, FauxAppIcon, Wallpaper, IOSStatusBar, AndroidStatusBar, IOSLockClock, AndroidLockClock, SectionLabel, MockupLabel });
