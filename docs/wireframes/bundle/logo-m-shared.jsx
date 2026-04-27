// Murabbi Logo v3 — Shared tokens, wordmarks, lockups (custom M direction)
const T = {
  bgPage:    '#EFEBE2',
  bgPrimary: '#F5F2ED',
  bgSurface: '#FDFBF8',
  ink:       '#1C1A16',
  textSec:   '#6B6155',
  textTer:   '#A89880',
  ivory:     '#FDFBF8',
  accent:    '#8B6F47',
  accentLight: 'rgba(139, 111, 71, 0.10)',
  accentBorder: 'rgba(139, 111, 71, 0.25)',
  border:    'rgba(28, 26, 22, 0.08)',
  borderEm:  'rgba(28, 26, 22, 0.16)',
  fontSans:  "'Geist', 'Inter', -apple-system, system-ui, sans-serif",
  fontMono:  "'Geist Mono', 'JetBrains Mono', ui-monospace, monospace",
  fontArabic: "'Noto Sans Arabic', 'Geist', sans-serif",
};

function Wordmark({ size = 24, color = T.ink, weight = 600 }) {
  return <span style={{
    fontFamily: T.fontSans, fontWeight: weight, fontSize: size,
    letterSpacing: size > 32 ? '-0.04em' : '-0.025em',
    color, lineHeight: 1, display: 'inline-block', whiteSpace: 'nowrap',
  }}>Murabbi</span>;
}

function WordmarkAr({ size = 24, color = T.ink, weight = 500 }) {
  return <span style={{
    fontFamily: T.fontArabic, fontWeight: weight, fontSize: size * 1.15,
    color, lineHeight: 1, display: 'inline-block', direction: 'rtl',
  }}>مربي</span>;
}

function MidDot({ size = 20, color = T.textTer }) {
  return <span style={{ color, fontSize: size, lineHeight: 1, padding: '0 0.4em', userSelect: 'none' }}>·</span>;
}

// Horizontal lockup: M + wordmark
function LockupH({ glyphSize = 40, wordSize = 22, color = T.ink, gap, withArabic = false }) {
  const g = gap != null ? gap : Math.round(glyphSize * 0.32);
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: g }}>
      <GlyphM size={glyphSize} color={color}/>
      <Wordmark size={wordSize} color={color}/>
      {withArabic && <><MidDot size={wordSize} color={color === T.ivory ? 'rgba(253,251,248,0.5)' : T.textTer}/><WordmarkAr size={wordSize} color={color}/></>}
    </div>
  );
}

function LockupV({ glyphSize = 64, wordSize = 22, color = T.ink, withArabic = false, withTagline = false }) {
  return (
    <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: Math.round(glyphSize * 0.28) }}>
      <GlyphM size={glyphSize} color={color}/>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
        <Wordmark size={wordSize} color={color}/>
        {withArabic && <WordmarkAr size={wordSize * 0.85} color={color}/>}
        {withTagline && (
          <div style={{ fontFamily: T.fontMono, fontSize: wordSize * 0.34, letterSpacing: '0.22em', textTransform: 'uppercase', color: color === T.ivory ? 'rgba(253,251,248,0.55)' : T.textTer, marginTop: 6 }}>
            Formateur de soi
          </div>
        )}
      </div>
    </div>
  );
}

function Card({ children, style, padding = 24, bg = T.bgSurface, border = true }) {
  return <div style={{
    background: bg,
    border: border ? `0.5px solid ${T.border}` : 'none',
    borderRadius: 18, padding, ...style,
  }}>{children}</div>;
}

function Section({ kicker, title, sub, children, id }) {
  return (
    <section id={id} style={{ marginTop: 96, scrollMarginTop: 32 }}>
      <div style={{ marginBottom: 32, maxWidth: 760 }}>
        {kicker && <div style={{ fontFamily: T.fontMono, fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 12 }}>{kicker}</div>}
        <h2 style={{ fontFamily: T.fontSans, fontSize: 36, fontWeight: 500, letterSpacing: '-0.02em', color: T.ink, margin: 0, lineHeight: 1.15 }}>{title}</h2>
        {sub && <p style={{ fontFamily: T.fontSans, fontSize: 15, color: T.textSec, margin: '12px 0 0 0', lineHeight: 1.6, maxWidth: 680 }}>{sub}</p>}
      </div>
      {children}
    </section>
  );
}

function Tag({ id, label, sub, align = 'left' }) {
  return (
    <div style={{ marginTop: 14, fontFamily: T.fontSans, textAlign: align }}>
      <div style={{ fontFamily: T.fontMono, fontSize: 10, fontWeight: 500, color: T.textTer, letterSpacing: '0.14em', textTransform: 'uppercase' }}>{id}</div>
      <div style={{ fontSize: 13, fontWeight: 500, color: T.ink, lineHeight: 1.3, marginTop: 2 }}>{label}</div>
      {sub && <div style={{ fontSize: 11, color: T.textSec, lineHeight: 1.4, marginTop: 2 }}>{sub}</div>}
    </div>
  );
}

function CopyBtn({ getSvg, label = 'Copier le SVG' }) {
  const [done, setDone] = React.useState(false);
  const onClick = () => {
    navigator.clipboard.writeText(getSvg()).then(() => {
      setDone(true);
      setTimeout(() => setDone(false), 1400);
    });
  };
  return <button onClick={onClick} style={{
    fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.1em', textTransform: 'uppercase',
    padding: '6px 10px', background: 'transparent', border: `0.5px solid ${T.borderEm}`, color: T.textSec,
    borderRadius: 6, cursor: 'pointer', fontWeight: 500,
  }}>{done ? '✓ Copié' : label}</button>;
}

Object.assign(window, { T, Wordmark, WordmarkAr, MidDot, LockupH, LockupV, Card, Section, Tag, CopyBtn });
