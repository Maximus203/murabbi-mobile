// Murabbi Logo — All variations of recommended Exploration B (incomplete circle)

const G = GlyphB;        // stroke-style glyph for displays
const GFill = GlyphBFilled; // filled equivalent for app icons / favicons

// ── Section A — Color variants ──────────────────────────────────────────
function ColorVariants() {
  const variants = [
    { id: 'A1', label: 'Accent ocre · sable', sub: 'Version par défaut', bg: T.bgPrimary, fg: T.accent },
    { id: 'A2', label: 'Brun foncé · sable',  sub: 'Contextes formels', bg: T.bgPrimary, fg: T.ink },
    { id: 'A3', label: 'Ivoire · brun foncé', sub: 'Mode sombre, headers premium', bg: T.ink, fg: T.ivory },
    { id: 'A4', label: 'Mono noir · blanc',   sub: 'Print noir et blanc', bg: '#FFFFFF', fg: '#000000' },
    { id: 'A5', label: 'Mono blanc · noir',   sub: 'Inverse de A4', bg: '#000000', fg: '#FFFFFF' },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 18 }}>
      {variants.map(v => (
        <div key={v.id}>
          <div style={{ background: v.bg, height: 200, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}` }}>
            <G size={96} color={v.fg}/>
          </div>
          <Tag id={v.id} label={v.label} sub={v.sub}/>
        </div>
      ))}
    </div>
  );
}

// ── App Icon tile (filled glyph for crispness at app-icon scale) ────────
function AppIconTile({ size = 180, bg, fg, glyphPct = 0.55, radiusPct = 0.225 }) {
  const r = size * radiusPct;
  return (
    <div style={{
      width: size, height: size, borderRadius: r,
      background: bg,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 1px 3px rgba(28,26,22,0.10)',
      overflow: 'hidden', position: 'relative',
    }}>
      <GFill size={size * glyphPct} color={fg}/>
    </div>
  );
}

// ── Section B — App icons ───────────────────────────────────────────────
function AppIcons() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 24 }}>
      <div>
        <div style={{ background: T.bgPrimary, height: 240, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}` }}>
          <AppIconTile size={180} bg={T.bgPrimary} fg={T.accent}/>
        </div>
        <Tag id="B1" label="App icon iOS · 1024×1024" sub="Sable + accent ocre. Le cercle occupe 55% de la zone."/>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, height: 240, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'space-around', border: `0.5px solid ${T.border}`, padding: '0 16px' }}>
          <div style={{ width: 72, height: 72, borderRadius: '50%', background: T.bgPrimary, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 3px rgba(28,26,22,0.10)' }}><GFill size={42} color={T.accent}/></div>
          <div style={{ width: 72, height: 72, borderRadius: 18, background: T.bgPrimary, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 3px rgba(28,26,22,0.10)' }}><GFill size={42} color={T.accent}/></div>
          <div style={{ width: 72, height: 72, borderRadius: 6, background: T.bgPrimary, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 3px rgba(28,26,22,0.10)' }}><GFill size={42} color={T.accent}/></div>
        </div>
        <Tag id="B2" label="Android adaptive" sub="Foreground + background séparés. Compatible toutes formes."/>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, height: 240, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}` }}>
          <AppIconTile size={180} bg={T.ink} fg={T.ivory}/>
        </div>
        <Tag id="B3" label="iOS 18 · variant Dark" sub="Brun foncé + symbole ivoire."/>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, height: 240, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}`, position: 'relative' }}>
          <div style={{ width: 180, height: 180, borderRadius: 40, background: 'linear-gradient(135deg, rgba(139,111,71,0.85), rgba(139,111,71,1))', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 3px rgba(28,26,22,0.10)' }}>
            <GFill size={100} color="#FDFBF8"/>
          </div>
          <span style={{ position: 'absolute', bottom: 12, right: 14, fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.12em' }}>simulé · teinté</span>
        </div>
        <Tag id="B4" label="iOS 18 · variant Tinted" sub="Symbole monochrome — iOS applique sa teinte."/>
      </div>
    </div>
  );
}

// ── Section C — Favicons ────────────────────────────────────────────────
function Favicons() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24 }}>
      <div>
        <div style={{ background: T.bgPrimary, height: 200, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}`, gap: 32 }}>
          <GFill size={32} color={T.accent}/>
          <div style={{ fontFamily: T.fontMono, fontSize: 11, color: T.textTer }}>actual size →</div>
          <GFill size={96} color={T.accent}/>
        </div>
        <Tag id="C1" label="Favicon 32×32" sub="Version filled — l'ouverture reste lisible."/>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, height: 200, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}`, gap: 32 }}>
          <GFill size={16} color={T.accent}/>
          <div style={{ fontFamily: T.fontMono, fontSize: 11, color: T.textTer }}>actual size →</div>
          <GFill size={96} color={T.accent}/>
        </div>
        <Tag id="C2" label="Favicon 16×16" sub="L'ouverture devient un point ; le cercle reste reconnaissable. ✓ test critique."/>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, height: 200, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}` }}>
          <AppIconTile size={140} bg={T.bgPrimary} fg={T.accent}/>
        </div>
        <Tag id="C3" label="Apple Touch Icon · 180×180" sub="Pour iOS Safari → Ajouter à l'écran d'accueil."/>
      </div>
    </div>
  );
}

// ── Section D — Headers ─────────────────────────────────────────────────
function Headers() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      {/* D1 mobile */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, overflow: 'hidden', maxWidth: 460, margin: '0 auto' }}>
          <div style={{ width: 375, height: 80, background: T.bgPrimary, display: 'flex', alignItems: 'center', padding: '0 20px', borderBottom: `0.5px solid ${T.border}`, margin: '0 auto' }}>
            <LockupH Glyph={G} glyphSize={28} wordSize={18}/>
          </div>
          <div style={{ height: 220, background: T.bgPrimary, padding: 20, opacity: 0.5 }}>
            <div style={{ height: 14, background: T.bgInput, borderRadius: 4, marginBottom: 12, width: '60%' }}/>
            <div style={{ height: 10, background: T.bgInput, borderRadius: 4, marginBottom: 8 }}/>
            <div style={{ height: 10, background: T.bgInput, borderRadius: 4, width: '85%' }}/>
          </div>
        </div>
        <Tag id="D1" label="Header web mobile · 375×80" sub="Lockup horizontal compact." align="center"/>
      </div>

      {/* D2 desktop */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, overflow: 'hidden' }}>
          <div style={{ height: 80, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 40px', borderBottom: `0.5px solid ${T.border}` }}>
            <LockupH Glyph={G} glyphSize={32} wordSize={20}/>
            <div style={{ display: 'flex', gap: 28, fontFamily: T.fontSans, fontSize: 14, color: T.textSec }}>
              <span>Manifeste</span><span>Habitudes</span><span>Tarifs</span><span>Connexion</span>
            </div>
          </div>
          <div style={{ height: 200, background: T.bgPrimary }}/>
        </div>
        <Tag id="D2" label="Header web desktop · 1440×80" sub="Lockup avec espacement généreux + nav."/>
      </div>

      {/* D3 admin & D4 email side by side */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.4fr', gap: 24 }}>
        <div>
          <div style={{ background: '#F2EFE8', borderRadius: 16, border: `0.5px solid ${T.border}`, overflow: 'hidden' }}>
            <div style={{ height: 60, display: 'flex', alignItems: 'center', padding: '0 20px', gap: 12, borderBottom: `0.5px solid ${T.border}` }}>
              <G size={22} color={T.accent}/>
              <span style={{ fontFamily: T.fontSans, fontSize: 14, fontWeight: 600, color: T.ink, letterSpacing: '-0.01em' }}>Murabbi</span>
              <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, padding: '2px 6px', background: T.bgInput, borderRadius: 4, letterSpacing: '0.12em' }}>ADMIN</span>
            </div>
            <div style={{ height: 200, padding: 12, opacity: 0.4, fontFamily: T.fontSans, fontSize: 12, color: T.textSec }}>
              <div style={{ padding: '6px 10px' }}>Tableau de bord</div>
              <div style={{ padding: '6px 10px' }}>Utilisateurs</div>
              <div style={{ padding: '6px 10px' }}>Contenu</div>
              <div style={{ padding: '6px 10px' }}>Analytics</div>
            </div>
          </div>
          <Tag id="D3" label="Header back-office · 240×60" sub="Sidebar admin. Fond #F2EFE8."/>
        </div>
        <div>
          <div style={{ background: T.bgSurface, borderRadius: 16, border: `0.5px solid ${T.border}`, overflow: 'hidden' }}>
            <div style={{ height: 120, background: T.bgPrimary, display: 'flex', alignItems: 'center', justifyContent: 'center', borderBottom: `0.5px solid ${T.border}` }}>
              <LockupV Glyph={G} glyphSize={42} wordSize={18}/>
            </div>
            <div style={{ padding: '20px 32px', opacity: 0.55 }}>
              <div style={{ height: 12, background: T.bgInput, borderRadius: 4, width: '40%', marginBottom: 12 }}/>
              <div style={{ height: 10, background: T.bgInput, borderRadius: 4, marginBottom: 8 }}/>
              <div style={{ height: 10, background: T.bgInput, borderRadius: 4, width: '90%' }}/>
            </div>
          </div>
          <Tag id="D4" label="Header email transactionnel · 600×120" sub="Centré, sobre. Pour bienvenue / récap."/>
        </div>
      </div>
    </div>
  );
}

// ── Section E — Splash & Loading ─────────────────────────────────────────
function SplashAndLoading() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
      <div>
        <div style={{ width: '100%', aspectRatio: '390 / 844', background: T.bgPrimary, borderRadius: 28, border: `0.5px solid ${T.border}`, position: 'relative', overflow: 'hidden', maxWidth: 360, margin: '0 auto' }}>
          <div style={{ position: 'absolute', top: 18, left: 0, right: 0, padding: '0 28px', display: 'flex', justifyContent: 'space-between', fontFamily: 'system-ui', fontSize: 13, fontWeight: 600, color: T.ink }}>
            <span>9:41</span><span>· · ·</span>
          </div>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <LockupV Glyph={G} glyphSize={92} wordSize={28} withTagline/>
          </div>
          <div style={{ position: 'absolute', bottom: 28, left: 0, right: 0, textAlign: 'center', fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer }}>
            مربي
          </div>
        </div>
        <Tag id="E1" label="Splash screen mobile" sub="Symbole + Murabbi + tagline FORMATEUR DE SOI." align="center"/>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 360, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 32, position: 'relative' }}>
          <div style={{ animation: 'spin-slow 8s linear infinite' }}>
            <G size={92} color={T.accent}/>
          </div>
          <style>{`@keyframes spin-slow { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
          <div style={{ fontFamily: T.fontMono, fontSize: 11, letterSpacing: '0.2em', textTransform: 'uppercase', color: T.textTer }}>
            Chargement…
          </div>
        </div>
        <Tag id="E2" label="Loading state · rotation lente" sub="Le cercle inachevé tourne lentement (8s, linear, infini) — le mouvement nait de l'ouverture."/>
      </div>
    </div>
  );
}

// ── Section F — Watermark & badges ──────────────────────────────────────
function Watermarks() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24 }}>
      <div>
        <div style={{ height: 240, borderRadius: 16, position: 'relative', overflow: 'hidden', background: 'linear-gradient(135deg, #6B5840 0%, #3A2F22 100%)', border: `0.5px solid ${T.border}` }}>
          <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at 30% 30%, rgba(253,251,248,0.18), transparent 50%), radial-gradient(ellipse at 70% 70%, rgba(28,26,22,0.4), transparent 60%)' }}/>
          <div style={{ position: 'absolute', bottom: 16, right: 16, opacity: 0.4 }}>
            <G size={36} color={T.ivory}/>
          </div>
        </div>
        <Tag id="F1" label="Watermark sur image" sub="Bas-droite, opacité 40%, ivoire/brun selon fond."/>
      </div>
      <div>
        <div style={{ height: 240, borderRadius: 16, background: T.bgPrimary, border: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 10, padding: '10px 16px', background: T.bgSurface, border: `0.5px solid ${T.border}`, borderRadius: 100, fontFamily: T.fontSans }}>
            <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.16em', textTransform: 'uppercase' }}>Powered by</span>
            <G size={18} color={T.accent}/>
            <span style={{ fontSize: 13, fontWeight: 600, color: T.ink, letterSpacing: '-0.01em' }}>Murabbi</span>
          </div>
        </div>
        <Tag id="F2" label='Badge "Powered by Murabbi"' sub="Pour collaborations futures."/>
      </div>
      <div>
        <div style={{ height: 240, borderRadius: 16, background: T.bgPrimary, border: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ width: 110, height: 110, borderRadius: '50%', border: `1.5px solid ${T.accent}`, display: 'flex', alignItems: 'center', justifyContent: 'center', background: T.bgSurface, position: 'relative' }}>
            <G size={56} color={T.accent}/>
            <div style={{ position: 'absolute', bottom: -10, left: '50%', transform: 'translateX(-50%)', background: T.accent, color: T.ivory, fontFamily: T.fontMono, fontSize: 9, padding: '3px 10px', borderRadius: 100, letterSpacing: '0.12em', textTransform: 'uppercase', fontWeight: 500, whiteSpace: 'nowrap' }}>Niveau 7</div>
          </div>
        </div>
        <Tag id="F3" label='Badge "Niveau Murabbi débloqué"' sub="Gamification rare. Symbole pastillé."/>
      </div>
    </div>
  );
}

// ── Section G — Documents ───────────────────────────────────────────────
function DocumentsBlock() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
      <div>
        <div style={{ width: '100%', aspectRatio: '210 / 297', background: '#FFFFFF', borderRadius: 12, border: `0.5px solid ${T.border}`, padding: '36px 40px', boxShadow: '0 1px 4px rgba(28,26,22,0.06)', maxWidth: 360, margin: '0 auto' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, paddingBottom: 18, borderBottom: `0.5px solid ${T.border}` }}>
              <G size={20} color={T.accent}/>
              <span style={{ fontFamily: T.fontSans, fontSize: 14, fontWeight: 600, color: T.ink, letterSpacing: '-0.01em' }}>Murabbi</span>
            </div>
            <div style={{ marginTop: 32, opacity: 0.4 }}>
              <div style={{ height: 14, background: T.bgInput, borderRadius: 4, width: '60%', marginBottom: 12 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, marginBottom: 6 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, marginBottom: 6 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, width: '88%', marginBottom: 18 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, marginBottom: 6 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, width: '92%' }}/>
            </div>
        </div>
        <Tag id="G1" label="En-tête de document A4" sub="Coin supérieur gauche. Contrats / factures." align="center"/>
      </div>
      <div>
        <div style={{ width: '100%', aspectRatio: '210 / 297', background: '#FFFFFF', borderRadius: 12, border: `0.5px solid ${T.border}`, padding: '36px 40px', boxShadow: '0 1px 4px rgba(28,26,22,0.06)', maxWidth: 360, margin: '0 auto', display: 'flex', flexDirection: 'column' }}>
            <div style={{ flex: 1, opacity: 0.3, paddingTop: 60 }}>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, marginBottom: 6 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, marginBottom: 6 }}/>
              <div style={{ height: 8, background: T.bgInput, borderRadius: 4, width: '85%' }}/>
            </div>
            <div style={{ paddingTop: 12, borderTop: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <G size={12} color={T.textTer}/>
                <span>murabbi.app</span>
              </div>
              <span>p. 1 / 4</span>
            </div>
        </div>
        <Tag id="G2" label="Pied de page de document" sub="Filet fin, symbole + URL." align="center"/>
      </div>
    </div>
  );
}

// ── Section H — Social ──────────────────────────────────────────────────
function SocialBlock() {
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 24 }}>
        <div>
          <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, padding: 32, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ width: 200, height: 200, background: T.bgPrimary, borderRadius: 12, border: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 3px rgba(28,26,22,0.08)' }}>
              <G size={108} color={T.accent}/>
            </div>
          </div>
          <Tag id="H1" label="Avatar carré · 400×400" sub="Instagram, X, LinkedIn. Symbole centré."/>
        </div>
        <div>
          <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, padding: 32, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ width: 200, height: 200, background: T.bgPrimary, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 1px 3px rgba(28,26,22,0.08)' }}>
              <G size={94} color={T.accent}/>
            </div>
          </div>
          <Tag id="H2" label="Avatar circulaire" sub="Marge de sécurité pour le crop circulaire."/>
        </div>
      </div>
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, padding: 0, overflow: 'hidden' }}>
          <div style={{ aspectRatio: '1500 / 500', background: 'linear-gradient(135deg, #F5F2ED 0%, #E8DFD0 100%)', display: 'flex', alignItems: 'center', padding: '0 80px' }}>
            <LockupH Glyph={G} glyphSize={72} wordSize={42}/>
          </div>
        </div>
        <Tag id="H3" label="Cover/Banner social · 1500×500" sub="Logo aligné gauche, espace de respiration à droite."/>
      </div>
    </div>
  );
}

Object.assign(window, { ColorVariants, AppIcons, Favicons, Headers, SplashAndLoading, Watermarks, DocumentsBlock, SocialBlock, AppIconTile });
