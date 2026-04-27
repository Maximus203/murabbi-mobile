// Murabbi Logo v3 — Differentiation test, Lockups, Variations, Brand guide, Spec
// =============================================================================

// ── Differentiation test (PARTIE 5) ──────────────────────────────────────────
function DifferentiationPanel() {
  // Original distinct M shapes — placeholder silhouettes for known competing M logos.
  // These are NOT recreations of those logos — they are abstract "M-family" reductions
  // used purely to verify visual distance from common M tropes.
  const tropes = [
    { id: 't1', label: 'M en biais', sub: 'Italique avec un coin coupé',
      svg: <svg width="120" height="100" viewBox="0 0 120 100"><path d="M 10 100 L 30 0 L 60 70 L 90 0 L 110 100 L 95 100 L 80 30 L 65 90 L 55 90 L 40 30 L 25 100 Z" fill="#A89880" transform="skewX(-10) translate(10,0)"/></svg>},
    { id: 't2', label: 'Double arche', sub: 'Deux courbes en demi-cercle',
      svg: <svg width="120" height="100" viewBox="0 0 120 100"><path d="M 0 100 L 0 30 A 30 30 0 0 1 60 30 L 60 100 L 75 100 L 75 30 A 22 22 0 0 1 120 30 L 120 100 L 105 100 L 105 30 A 8 8 0 0 0 90 30 L 90 100 L 45 100 L 45 30 A 15 15 0 0 0 15 30 L 15 100 Z" fill="#A89880"/></svg>},
    { id: 't3', label: 'M griffu', sub: 'Trois griffes pointues',
      svg: <svg width="120" height="100" viewBox="0 0 120 100"><path d="M 0 100 L 5 0 L 30 60 L 35 0 L 60 80 L 85 0 L 90 60 L 115 0 L 120 100 L 100 100 L 95 50 L 75 100 L 60 100 L 45 100 L 25 50 L 20 100 Z" fill="#A89880"/></svg>},
    { id: 't4', label: 'M serif classique', sub: 'Empattements en bas',
      svg: <svg width="120" height="100" viewBox="0 0 120 100"><path d="M 0 100 L 0 90 L 8 90 L 8 14 L 0 12 L 0 0 L 30 0 L 60 70 L 90 0 L 120 0 L 120 12 L 112 14 L 112 90 L 120 90 L 120 100 L 80 100 L 80 90 L 90 90 L 90 24 L 64 84 L 56 84 L 30 24 L 30 90 L 40 90 L 40 100 Z" fill="#A89880"/></svg>},
    { id: 't5', label: 'M dans rond', sub: 'Lettre encerclée',
      svg: <svg width="120" height="100" viewBox="0 0 120 100"><circle cx="60" cy="50" r="44" fill="none" stroke="#A89880" strokeWidth="6"/><path d="M 36 75 L 36 25 L 50 25 L 60 50 L 70 25 L 84 25 L 84 75 L 76 75 L 76 35 L 64 65 L 56 65 L 44 35 L 44 75 Z" fill="#A89880"/></svg>},
    { id: 't6', label: 'M géométrique fin', sub: 'Outline en trait fin',
      svg: <svg width="120" height="100" viewBox="0 0 120 100"><path d="M 5 95 L 5 5 L 25 5 L 60 70 L 95 5 L 115 5 L 115 95 L 100 95 L 100 30 L 65 90 L 55 90 L 20 30 L 20 95 Z" fill="none" stroke="#A89880" strokeWidth="3"/></svg>},
  ];
  return (
    <Card padding={28}>
      <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', gap: 28, alignItems: 'flex-start' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, padding: '28px 0', borderRight: `0.5px solid ${T.border}`, paddingRight: 28 }}>
          <GlyphM size={120} color={T.ink}/>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: T.accent, fontWeight: 500, marginTop: 4 }}>Murabbi M</div>
          <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec, textAlign: 'center', lineHeight: 1.5 }}>Bloc plein, asymétrie au pied, micro-courbe à la vallée</div>
        </div>
        <div>
          <div style={{ fontFamily: T.fontSans, fontSize: 13, color: T.textSec, lineHeight: 1.65, marginBottom: 18 }}>
            Notre M Murabbi posé à côté de six familles de M typographiques courantes (formes abstraites, pas de marques précises). Le test passe : <strong style={{ color: T.ink }}>aucune confusion possible</strong> grâce au pas asymétrique et à la verticalité massive des posts.
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
            {tropes.map(t => (
              <div key={t.id} style={{ background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 12, padding: 16, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
                <div style={{ height: 80, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{t.svg}</div>
                <div style={{ fontFamily: T.fontSans, fontSize: 12, fontWeight: 500, color: T.ink }}>{t.label}</div>
                <div style={{ fontFamily: T.fontMono, fontSize: 9.5, color: T.textTer, textAlign: 'center' }}>{t.sub}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Card>
  );
}

// ── Lockups ──────────────────────────────────────────────────────────────────
function LockupsPanel() {
  const items = [
    { id: 'L1', label: 'Symbole M seul', el: <GlyphM size={56} color={T.ink}/> },
    { id: 'L2', label: 'Lockup horizontal', el: <LockupH glyphSize={44} wordSize={28}/> },
    { id: 'L3', label: 'Lockup vertical', el: <LockupV glyphSize={66} wordSize={22}/> },
    { id: 'L4', label: 'Bilingue horizontal', el: <LockupH glyphSize={40} wordSize={22} withArabic={true}/> },
    { id: 'L5', label: 'Vertical avec arabe', el: <LockupV glyphSize={64} wordSize={22} withArabic={true}/> },
    { id: 'L6', label: 'Wordmark seul', el: <Wordmark size={36}/> },
    { id: 'L7', label: 'مربي seul', el: <WordmarkAr size={36}/> },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
      {items.map(it => (
        <div key={it.id}>
          <Card padding={0} bg={T.bgSurface}>
            <div style={{ height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 }}>{it.el}</div>
          </Card>
          <Tag id={it.id} label={it.label}/>
        </div>
      ))}
    </div>
  );
}

// ── Color variations (Section A) ─────────────────────────────────────────────
function ColorVariants() {
  const vs = [
    { id: 'A1', label: 'Brun foncé · sable', sub: 'Officiel — par défaut', bg: T.bgPrimary, color: T.ink },
    { id: 'A2', label: 'Ocre · sable', sub: 'Pour faire vibrer', bg: T.bgPrimary, color: T.accent },
    { id: 'A3', label: 'Ivoire · brun', sub: 'Mode sombre, headers', bg: T.ink, color: T.ivory },
    { id: 'A4', label: 'Noir pur · blanc', sub: 'Print N&B', bg: '#FFFFFF', color: '#000000' },
    { id: 'A5', label: 'Blanc · noir', sub: 'Inverse de A4', bg: '#000000', color: '#FFFFFF' },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 16 }}>
      {vs.map(v => (
        <div key={v.id}>
          <div style={{ background: v.bg, border: `0.5px solid ${T.border}`, borderRadius: 14, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <GlyphM size={84} color={v.color}/>
          </div>
          <Tag id={v.id} label={v.label} sub={v.sub}/>
        </div>
      ))}
    </div>
  );
}

// ── App icons (Section B) ────────────────────────────────────────────────────
function AppIcons() {
  const icons = [
    { id: 'B1', label: 'iOS 1024×1024', sub: 'sable + brun', bg: T.bgPrimary, color: T.ink },
    { id: 'B2', label: 'Android adaptive', sub: 'masque appliqué', bg: T.bgPrimary, color: T.ink, masks: true },
    { id: 'B3', label: 'iOS 18 — Dark', sub: 'brun + ivoire', bg: T.ink, color: T.ivory },
    { id: 'B4', label: 'iOS 18 — Tinted', sub: 'monochrome accent', bg: 'rgba(139,111,71,0.18)', color: T.accent },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 20 }}>
      {icons.map(ic => (
        <div key={ic.id}>
          {ic.masks ? (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10 }}>
              {['50%', '32%', '18%', '50% / 50% 18% 50% 18%'].map((br, i) => (
                <div key={i} style={{ background: ic.bg, borderRadius: br, aspectRatio: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}` }}>
                  <GlyphM size={48} color={ic.color}/>
                </div>
              ))}
            </div>
          ) : (
            <div style={{ background: ic.bg, borderRadius: 36, aspectRatio: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}` }}>
              <GlyphM size={108} color={ic.color}/>
            </div>
          )}
          <Tag id={ic.id} label={ic.label} sub={ic.sub}/>
        </div>
      ))}
    </div>
  );
}

// ── Favicons (Section C) ─────────────────────────────────────────────────────
function Favicons() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
      <div>
        <Card padding={24}>
          <div style={{ display: 'flex', gap: 24, alignItems: 'flex-end', justifyContent: 'center', height: 130 }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 64, height: 64, background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GlyphM size={32} color={T.ink}/></div>
              <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>32×32 — réel</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 32, height: 32, background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GlyphM size={16} color={T.ink}/></div>
              <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>32×32 — taille réelle</span>
            </div>
          </div>
        </Card>
        <Tag id="C1" label="Favicon 32×32"/>
      </div>
      <div>
        <Card padding={24}>
          <div style={{ display: 'flex', gap: 24, alignItems: 'flex-end', justifyContent: 'center', height: 130 }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 96, height: 96, background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GlyphM size={48} color={T.ink}/></div>
              <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>16×16 — agrandi 6×</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 16, height: 16, background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 3, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GlyphM size={11} color={T.ink}/></div>
              <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>16×16 — taille réelle</span>
            </div>
          </div>
        </Card>
        <Tag id="C2" label="Favicon 16×16" sub="Test critique de la RÈGLE 0.4 — encore lisible"/>
      </div>
      <div>
        <Card padding={24}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 130 }}>
            <div style={{ width: 130, height: 130, background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 30, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GlyphM size={68} color={T.ink}/></div>
          </div>
        </Card>
        <Tag id="C3" label="Apple Touch Icon 180×180"/>
      </div>
    </div>
  );
}

// ── Headers (Section D) ──────────────────────────────────────────────────────
function Headers() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <div>
        <Card padding={0} bg={T.bgPrimary}>
          <div style={{ height: 80, padding: '0 20px', display: 'flex', alignItems: 'center', borderBottom: `0.5px solid ${T.border}` }}>
            <LockupH glyphSize={28} wordSize={18}/>
          </div>
        </Card>
        <Tag id="D1" label="Header web mobile (375×80)"/>
      </div>
      <div>
        <Card padding={0} bg={T.bgPrimary}>
          <div style={{ height: 80, padding: '0 56px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: `0.5px solid ${T.border}` }}>
            <LockupH glyphSize={32} wordSize={20}/>
            <div style={{ display: 'flex', gap: 32, fontFamily: T.fontMono, fontSize: 11, letterSpacing: '0.14em', textTransform: 'uppercase', color: T.textSec }}>
              <span>Mission</span><span>Méthode</span><span>Tarifs</span><span>Connexion</span>
            </div>
          </div>
        </Card>
        <Tag id="D2" label="Header web desktop (1440×80)"/>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        <div>
          <Card padding={0} bg="#F2EFE8">
            <div style={{ height: 60, padding: '0 18px', display: 'flex', alignItems: 'center' }}>
              <GlyphM size={22} color={T.ink}/>
              <div style={{ marginLeft: 10, fontFamily: T.fontSans, fontSize: 14, fontWeight: 600, color: T.ink, letterSpacing: '-0.02em' }}>Murabbi</div>
              <div style={{ marginLeft: 8, fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: T.textTer }}>Admin</div>
            </div>
          </Card>
          <Tag id="D3" label="Header back-office (240×60)"/>
        </div>
        <div>
          <Card padding={0} bg={T.bgSurface}>
            <div style={{ height: 120, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <LockupH glyphSize={40} wordSize={26}/>
            </div>
          </Card>
          <Tag id="D4" label="Header email (600×120)"/>
        </div>
      </div>
    </div>
  );
}

// ── Splash + Loading (Section E) ─────────────────────────────────────────────
function SplashAndLoading() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 24 }}>
      <div>
        <Card padding={0} bg={T.bgPrimary}>
          <div style={{ aspectRatio: '375/650', maxHeight: 540, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 18 }}>
            <GlyphM size={92} color={T.ink}/>
            <Wordmark size={28}/>
            <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.3em', textTransform: 'uppercase', color: T.textTer, marginTop: 6 }}>Formateur de soi</div>
          </div>
        </Card>
        <Tag id="E1" label="Splash screen mobile" sub="Plein écran, M centré, wordmark + tagline"/>
      </div>
      <div>
        <Card padding={0} bg={T.bgPrimary}>
          <div style={{ height: 280, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ animation: 'breathe 2.4s ease-in-out infinite' }}>
              <GlyphM size={64} color={T.ink}/>
            </div>
          </div>
        </Card>
        <Tag id="E2" label="Loading state" sub="Pulse très doux, 2.4s ease-in-out"/>
      </div>
    </div>
  );
}

// ── Watermarks + badges (Section F) ──────────────────────────────────────────
function Watermarks() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
      <div>
        <Card padding={0}>
          <div style={{ height: 200, background: 'linear-gradient(135deg, #2a2520 0%, #4a3d2a 100%)', borderRadius: 18, position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', inset: 0, backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 8px, rgba(255,255,255,0.025) 8px, rgba(255,255,255,0.025) 9px)' }}/>
            <div style={{ position: 'absolute', bottom: 14, right: 14, opacity: 0.4 }}>
              <GlyphM size={22} color={T.ivory}/>
            </div>
          </div>
        </Card>
        <Tag id="F1" label="Watermark image" sub="Bas-droite, opacité 40 %"/>
      </div>
      <div>
        <Card padding={20}>
          <div style={{ height: 160, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '6px 12px 6px 8px', background: T.bgPrimary, border: `0.5px solid ${T.border}`, borderRadius: 100 }}>
              <GlyphM size={14} color={T.ink}/>
              <span style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: T.textSec }}>Powered by Murabbi</span>
            </div>
          </div>
        </Card>
        <Tag id="F2" label="Badge « Powered by »"/>
      </div>
      <div>
        <Card padding={20}>
          <div style={{ height: 160, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 64, height: 64, borderRadius: '50%', background: T.bgSurface, border: `1.5px solid ${T.accent}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <GlyphM size={28} color={T.accent}/>
              </div>
              <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: T.accent, fontWeight: 500 }}>Niveau débloqué</div>
            </div>
          </div>
        </Card>
        <Tag id="F3" label="Badge « Niveau Murabbi »"/>
      </div>
    </div>
  );
}

// ── Documents (Section G) ────────────────────────────────────────────────────
function DocumentsBlock() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 20 }}>
      <div>
        <Card padding={0} bg="#FDFCF9">
          <div style={{ aspectRatio: '210/297', maxHeight: 380, padding: 28, display: 'flex', flexDirection: 'column' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, paddingBottom: 12, borderBottom: `0.5px solid ${T.border}` }}>
              <GlyphM size={16} color={T.ink}/>
              <span style={{ fontFamily: T.fontSans, fontSize: 10, fontWeight: 600, color: T.ink, letterSpacing: '-0.02em' }}>Murabbi</span>
              <span style={{ marginLeft: 'auto', fontFamily: T.fontMono, fontSize: 8, color: T.textTer, letterSpacing: '0.14em', textTransform: 'uppercase' }}>Avril 2026</span>
            </div>
            <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 6 }}>
              {[1,1,0.9,0.7,0,1,0.95,0.8,0.6].map((w, i) => (
                <div key={i} style={{ height: 4, width: `${w * 100}%`, background: w === 0 ? 'transparent' : T.border, borderRadius: 2 }}/>
              ))}
            </div>
          </div>
        </Card>
        <Tag id="G1" label="En-tête A4 — coin sup. gauche"/>
      </div>
      <div>
        <Card padding={0} bg="#FDFCF9">
          <div style={{ aspectRatio: '210/297', maxHeight: 380, padding: 28, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
            <div style={{ paddingTop: 12, borderTop: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', gap: 8 }}>
              <GlyphM size={12} color={T.textSec}/>
              <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textSec, letterSpacing: '0.14em' }}>murabbi.app</span>
              <span style={{ marginLeft: 'auto', fontFamily: T.fontMono, fontSize: 9, color: T.textTer }}>1 / 4</span>
            </div>
          </div>
        </Card>
        <Tag id="G2" label="Pied de page document"/>
      </div>
    </div>
  );
}

// ── Social (Section H) ───────────────────────────────────────────────────────
function SocialBlock() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 2fr', gap: 20 }}>
      <div>
        <Card padding={0} bg={T.bgPrimary}>
          <div style={{ aspectRatio: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <GlyphM size={120} color={T.ink}/>
          </div>
        </Card>
        <Tag id="H1" label="Avatar carré 400×400"/>
      </div>
      <div>
        <Card padding={0} bg={T.bgPrimary} style={{ borderRadius: '50%' }}>
          <div style={{ aspectRatio: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '50%' }}>
            <GlyphM size={108} color={T.ink}/>
          </div>
        </Card>
        <Tag id="H2" label="Avatar circulaire" sub="Marge de sécurité respectée"/>
      </div>
      <div>
        <Card padding={0} bg={T.bgPrimary}>
          <div style={{ aspectRatio: '3/1', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 32 }}>
            <GlyphM size={84} color={T.ink}/>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <Wordmark size={32}/>
              <div style={{ fontFamily: T.fontMono, fontSize: 11, letterSpacing: '0.2em', textTransform: 'uppercase', color: T.textTer }}>Formateur de soi</div>
            </div>
          </div>
        </Card>
        <Tag id="H3" label="Cover/banner 1500×500"/>
      </div>
    </div>
  );
}

// ── Brand guide ──────────────────────────────────────────────────────────────
function BrandGuidePanel() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
      <Card padding={28}>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 14 }}>Espacement</div>
        <div style={{ background: T.bgPrimary, borderRadius: 12, padding: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', height: 220 }}>
          <div style={{ position: 'absolute', inset: 32, border: `1px dashed ${T.accentBorder}`, borderRadius: 4 }}/>
          <GlyphM size={64} color={T.ink}/>
        </div>
        <div style={{ marginTop: 14, fontFamily: T.fontSans, fontSize: 12.5, color: T.textSec, lineHeight: 1.6 }}>
          Zone de respiration égale à <strong style={{ color: T.ink }}>50%</strong> de la largeur du M autour du symbole. Lockup complet : zone égale à la <strong style={{ color: T.ink }}>hauteur</strong> du M.
        </div>
      </Card>
      <Card padding={28}>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 14 }}>Tailles minimum</div>
        <div style={{ display: 'flex', gap: 24, alignItems: 'flex-end', justifyContent: 'space-around', height: 100, padding: 16, background: T.bgPrimary, borderRadius: 12 }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <GlyphM size={24} color={T.ink}/>
            <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer }}>24px symbole</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <LockupH glyphSize={32} wordSize={20}/>
            <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer }}>32px lockup</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <Wordmark size={16}/>
            <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer }}>16px wordmark</span>
          </div>
        </div>
      </Card>
      <Card padding={28} style={{ gridColumn: '1 / -1' }}>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 16 }}>Do · Don't</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
          {[
            { ok: false, label: 'Ne pas étirer', el: <div style={{ transform: 'scaleY(0.55)' }}><GlyphM size={56} color={T.ink}/></div> },
            { ok: false, label: 'Ne pas pivoter', el: <div style={{ transform: 'rotate(15deg)' }}><GlyphM size={48} color={T.ink}/></div> },
            { ok: false, label: 'Ne pas encadrer', el: <div style={{ width: 64, height: 64, borderRadius: '50%', border: `2px solid ${T.ink}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><GlyphM size={32} color={T.ink}/></div> },
            { ok: false, label: 'Ne pas ombrer', el: <div style={{ filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.4))' }}><GlyphM size={48} color={T.ink}/></div> },
            { ok: true, label: 'Proportions officielles', el: <GlyphM size={48} color={T.ink}/> },
            { ok: true, label: 'Couleurs palette', el: <GlyphM size={48} color={T.accent}/> },
            { ok: true, label: 'Sur fond autorisé', el: <div style={{ background: T.ink, borderRadius: 8, padding: 8, display: 'flex' }}><GlyphM size={40} color={T.ivory}/></div> },
            { ok: true, label: 'Tailles respectées', el: <GlyphM size={56} color={T.ink}/> },
          ].map((d, i) => (
            <div key={i} style={{ background: T.bgPrimary, borderRadius: 12, padding: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, position: 'relative', border: `1px solid ${d.ok ? 'rgba(86,154,99,0.3)' : 'rgba(180,80,80,0.25)'}` }}>
              <div style={{ position: 'absolute', top: 10, right: 10, width: 18, height: 18, borderRadius: '50%', background: d.ok ? '#5e9970' : '#b95a5a', color: 'white', fontFamily: T.fontMono, fontSize: 11, display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 1 }}>{d.ok ? '✓' : '×'}</div>
              <div style={{ height: 80, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{d.el}</div>
              <div style={{ fontFamily: T.fontSans, fontSize: 11.5, color: T.textSec, textAlign: 'center', lineHeight: 1.4 }}>{d.label}</div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

// ── Spec sheet ───────────────────────────────────────────────────────────────
function SpecSheet() {
  return (
    <Card padding={36}>
      <div className="markdown-spec">
        <h1>Murabbi · Logo Spec Sheet</h1>
        <p><em>v3.0 — Avril 2026 · Direction : M custom sculpté</em></p>

        <h2>Symbole · Géométrie officielle</h2>
        <table>
          <tbody>
            <tr><td>viewBox</td><td><code>0 0 120 100</code></td></tr>
            <tr><td>posts.width</td><td>30u (gauche 0–30, droit 90–120)</td></tr>
            <tr><td>valley.apex</td><td>y = 54u, plateau x = 57–63u</td></tr>
            <tr><td>valley.curve</td><td><code>Q 60 53</code> — micro-courbe</td></tr>
            <tr><td>notch.ceiling</td><td>y = 28u</td></tr>
            <tr><td>step.right</td><td>y = 94u (signature : −6u)</td></tr>
            <tr><td>step.left</td><td>y = 100u (ligne de base)</td></tr>
          </tbody>
        </table>

        <h2>Path SVG officiel (V3)</h2>
        <pre><code>{`<svg viewBox="0 0 120 100" xmlns="http://www.w3.org/2000/svg">
  <path d="${symbolPathM(3)}" fill="#1C1A16"/>
</svg>`}</code></pre>

        <h2>Couleurs · Palette officielle</h2>
        <table>
          <tbody>
            <tr><td>Brun foncé</td><td><code>#1C1A16</code> · couleur principale</td></tr>
            <tr><td>Sable</td><td><code>#F5F2ED</code> · fond officiel</td></tr>
            <tr><td>Ivoire</td><td><code>#FDFBF8</code> · sur fond brun</td></tr>
            <tr><td>Ocre</td><td><code>#8B6F47</code> · accent</td></tr>
          </tbody>
        </table>

        <h2>Typographie</h2>
        <table>
          <tbody>
            <tr><td>Wordmark latin</td><td>Geist SemiBold · tracking −0.025em</td></tr>
            <tr><td>Wordmark arabe</td><td>Noto Sans Arabic Medium · 1.15× hauteur latine</td></tr>
            <tr><td>Tagline</td><td>Geist Mono Medium · tracking 0.22em · uppercase</td></tr>
          </tbody>
        </table>

        <h2>Tailles minimum</h2>
        <ul>
          <li>Symbole seul · 24 px (exception favicon 16 px)</li>
          <li>Lockup horizontal · 32 px</li>
          <li>Wordmark seul · 16 px</li>
        </ul>

        <h2>Détail signature — Sens</h2>
        <p>Le pied droit relevé de 6u est l'expression géométrique de l'<strong>إرتقاء</strong> — l'élévation, la progression, le pas en avant. C'est la racine du nom <em>Murabbi</em> (formateur, éducateur, celui qui élève). La micro-courbe au creux de la vallée est une trace très discrète de croissant, sans cliché.</p>

        <h2>Tenue dans 10 ans</h2>
        <p>Le M est un objet <strong>géométrique pur</strong>, sans gradient, sans effet, sans tendance. Sa solidité vient de sa construction (chiffres précis) et non de sa décoration. Comme un Helvetica de 1957 ou un Apple monogram contemporain — il ne dépend d'aucune mode pour exister.</p>

        <hr/>
        <p><em>Murabbi · Logo & Identité v3.0 · مربي · Formateur de soi</em></p>
      </div>
    </Card>
  );
}

// ── Export panel ─────────────────────────────────────────────────────────────
function ExportPanel() {
  const variants = [
    { id: 'A1', label: 'Brun · sable', bg: '#F5F2ED', color: '#1C1A16' },
    { id: 'A2', label: 'Ocre · sable', bg: '#F5F2ED', color: '#8B6F47' },
    { id: 'A3', label: 'Ivoire · brun', bg: '#1C1A16', color: '#FDFBF8' },
    { id: 'A4', label: 'Noir · blanc', bg: '#FFFFFF', color: '#000000' },
    { id: 'A5', label: 'Blanc · noir', bg: '#000000', color: '#FFFFFF' },
  ];
  const makeSvg = (v) => `<svg width="240" height="200" viewBox="0 0 120 100" xmlns="http://www.w3.org/2000/svg"><rect width="120" height="100" fill="${v.bg}"/><path d="${symbolPathM(3)}" fill="${v.color}"/></svg>`;
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
      {variants.map(v => (
        <Card key={v.id} padding={20}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ width: 96, height: 80, background: v.bg, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <GlyphM size={42} color={v.color}/>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: T.fontMono, fontSize: 10, color: T.textTer, letterSpacing: '0.14em', textTransform: 'uppercase' }}>{v.id}</div>
              <div style={{ fontFamily: T.fontSans, fontSize: 13, fontWeight: 500, color: T.ink, margin: '2px 0 8px' }}>{v.label}</div>
              <CopyBtn getSvg={() => makeSvg(v)}/>
            </div>
          </div>
        </Card>
      ))}
    </div>
  );
}

Object.assign(window, {
  DifferentiationPanel, LockupsPanel, ColorVariants, AppIcons, Favicons, Headers,
  SplashAndLoading, Watermarks, DocumentsBlock, SocialBlock, BrandGuidePanel,
  SpecSheet, ExportPanel,
});
