// Murabbi Logo — Brand Guide and In-context mockups (Exploration B)

// ── In-context mockups ──────────────────────────────────────────────────
function HomescreenIOS() {
  const apps = [
    { c: '#34C759', g: '✓' }, { c: '#FF9500', g: '🗓' }, { c: '#5856D6', g: '♪' }, { c: '#FF3B30', g: '✉' },
    { c: '#007AFF', g: 'M' }, { c: '#AF52DE', g: 'P' }, { c: '#1C1A16', g: 'X' }, { c: '#FF2D55', g: '❤' },
    { c: '#34AADC', g: 'W' }, null, { c: '#A2845E', g: 'B' }, { c: '#5AC8FA', g: 'S' },
  ];
  return (
    <div style={{ width: 320, aspectRatio: '390 / 844', borderRadius: 36, overflow: 'hidden', position: 'relative', background: 'linear-gradient(180deg, #C9A87E 0%, #6E4F32 50%, #2A1E14 100%)', boxShadow: '0 8px 24px rgba(28,26,22,0.18)' }}>
      <div style={{ position: 'absolute', top: 14, left: 0, right: 0, padding: '0 28px', display: 'flex', justifyContent: 'space-between', fontFamily: 'system-ui', fontSize: 14, fontWeight: 600, color: '#fff' }}>
        <span>9:41</span><span>· · ·</span>
      </div>
      <div style={{ paddingTop: 64, paddingLeft: 20, paddingRight: 20, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px 12px' }}>
        {apps.map((a, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            {a === null ? (
              <AppIconTile size={62} bg={T.bgPrimary} fg={T.accent}/>
            ) : (
              <div style={{ width: 62, height: 62, borderRadius: 14, background: a.c, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: 22, fontWeight: 600, boxShadow: '0 1px 2px rgba(0,0,0,0.2)' }}>{a.g}</div>
            )}
            <div style={{ fontSize: 10, color: '#fff', fontFamily: 'system-ui', fontWeight: 400, textShadow: '0 1px 2px rgba(0,0,0,0.4)' }}>
              {a === null ? 'Murabbi' : ['Tâches','Calendrier','Musique','Mail','Maps','Photos','X','Santé','Météo','','Bourse','Safari'][i]}
            </div>
          </div>
        ))}
      </div>
      <div style={{ position: 'absolute', top: 64 + 20 + (62+24), left: 20 + 12 + 62 + 6, width: 74, height: 74, borderRadius: 18, border: `2px solid ${T.accent}`, pointerEvents: 'none', boxShadow: '0 0 0 4px rgba(139,111,71,0.15)' }}/>
    </div>
  );
}

function EmailMockup() {
  return (
    <div style={{ width: '100%', maxWidth: 480, background: T.bgSurface, borderRadius: 12, border: `0.5px solid ${T.border}`, overflow: 'hidden', boxShadow: '0 1px 4px rgba(28,26,22,0.06)' }}>
      <div style={{ padding: '14px 20px', borderBottom: `0.5px solid ${T.border}`, fontFamily: T.fontSans, fontSize: 12, color: T.textSec }}>
        <span style={{ fontWeight: 500, color: T.ink }}>De</span> Murabbi &lt;hello@murabbi.app&gt;
      </div>
      <div style={{ height: 100, background: T.bgPrimary, borderBottom: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <LockupV Glyph={GlyphB} glyphSize={40} wordSize={16}/>
      </div>
      <div style={{ padding: 28 }}>
        <h3 style={{ fontFamily: T.fontSans, fontSize: 22, fontWeight: 500, letterSpacing: '-0.02em', color: T.ink, margin: '0 0 12px 0' }}>Bienvenue, Cherif.</h3>
        <p style={{ fontFamily: T.fontSans, fontSize: 13.5, color: T.textSec, lineHeight: 1.65, margin: '0 0 18px 0' }}>
          Tu viens de rejoindre Murabbi. Voici comment tirer parti de ta première semaine — un rythme, pas une course.
        </p>
        <div style={{ display: 'inline-block', padding: '12px 20px', background: T.accent, color: T.ivory, fontFamily: T.fontSans, fontSize: 14, fontWeight: 500, borderRadius: 8 }}>
          Ouvrir l'application
        </div>
      </div>
    </div>
  );
}

function SocialAvatarsContext() {
  return (
    <div style={{ display: 'flex', gap: 16, alignItems: 'center', justifyContent: 'center', flexWrap: 'wrap' }}>
      <div style={{ width: 280, padding: 16, background: T.bgSurface, borderRadius: 12, border: `0.5px solid ${T.border}`, fontFamily: T.fontSans }}>
        <div style={{ display: 'flex', gap: 12 }}>
          <div style={{ width: 44, height: 44, borderRadius: '50%', background: T.bgPrimary, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <GlyphB size={26} color={T.accent}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontWeight: 600, fontSize: 14, color: T.ink }}>Murabbi</span>
              <span style={{ fontSize: 13, color: T.textTer }}>@murabbi</span>
            </div>
            <p style={{ fontSize: 13.5, color: T.ink, lineHeight: 1.5, margin: '4px 0 0 0' }}>
              On ne devient pas constant en se motivant. On le devient en réduisant la friction.
            </p>
          </div>
        </div>
      </div>
      <div style={{ width: 280, background: T.bgSurface, borderRadius: 12, border: `0.5px solid ${T.border}`, overflow: 'hidden' }}>
        <div style={{ aspectRatio: '1500 / 500', background: 'linear-gradient(135deg, #F5F2ED 0%, #E8DFD0 100%)', display: 'flex', alignItems: 'center', padding: '0 20px' }}>
          <LockupH Glyph={GlyphB} glyphSize={28} wordSize={16}/>
        </div>
        <div style={{ padding: '0 14px', position: 'relative', paddingBottom: 16 }}>
          <div style={{ width: 56, height: 56, borderRadius: '50%', background: T.bgPrimary, border: '3px solid #fff', display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: -28 }}>
            <GlyphB size={32} color={T.accent}/>
          </div>
          <div style={{ marginTop: 8, fontFamily: T.fontSans }}>
            <div style={{ fontWeight: 600, fontSize: 14, color: T.ink }}>Murabbi</div>
            <div style={{ fontSize: 12, color: T.textSec, lineHeight: 1.4, marginTop: 2 }}>OS personnel de croissance · Habitudes</div>
            <div style={{ fontSize: 11, color: T.textTer, marginTop: 4 }}>Paris · 142 abonnés</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function InContextPanel() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 28 }}>
      <Card padding={32} bg={T.bgPrimary}>
        <div style={{ display: 'flex', justifyContent: 'center' }}><HomescreenIOS/></div>
        <Tag id="X1" label="Sur l'écran d'accueil iOS" sub="L'icône Murabbi parmi d'autres apps. La sobriété tient sa place." align="center"/>
      </Card>
      <Card padding={32} bg={T.bgPrimary}>
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-start', minHeight: 420 }}><EmailMockup/></div>
        <Tag id="X2" label="Email transactionnel" sub="Header centré sobre. Wordmark vertical." align="center"/>
      </Card>
      <Card padding={32} bg={T.bgPrimary} style={{ gridColumn: 'span 2' }}>
        <SocialAvatarsContext/>
        <Tag id="X3" label="Avatars réseaux sociaux" sub="X (carré arrondi), LinkedIn (avatar circulaire + cover). Le glyphe seul porte l'identité." align="center"/>
      </Card>
    </div>
  );
}

// ── Brand Guide ─────────────────────────────────────────────────────────
function ClearSpace() {
  return (
    <svg viewBox="-50 -50 200 200" width={300} height={300} style={{ display: 'block' }}>
      <rect x="-50" y="-50" width="200" height="200" fill="none" stroke={T.accent} strokeWidth="0.6" strokeDasharray="3 3" opacity="0.5"/>
      <g style={{ fontFamily: T.fontMono, fontSize: 8, fill: T.accent }}>
        <text x="-46" y="-34">x</text>
        <text x="124" y="-34">x</text>
        <text x="-46" y="138">x</text>
        <text x="124" y="138">x</text>
      </g>
      <rect x="0" y="0" width="100" height="100" fill="none" stroke={T.borderEm} strokeWidth="0.4"/>
      {/* Embed the actual GlyphB inline (stroke version) */}
      <g>
        {(() => {
          const r = 40, sw = 9;
          const a1 = -101 * Math.PI / 180;
          const a2 = -79  * Math.PI / 180;
          const p1 = { x: 50 + r * Math.cos(a2), y: 50 + r * Math.sin(a2) };
          const p2 = { x: 50 + r * Math.cos(a1), y: 50 + r * Math.sin(a1) };
          const d = `M ${p1.x.toFixed(2)} ${p1.y.toFixed(2)} A ${r} ${r} 0 1 1 ${p2.x.toFixed(2)} ${p2.y.toFixed(2)}`;
          return <path d={d} fill="none" stroke={T.accent} strokeWidth={sw} strokeLinecap="butt"/>;
        })()}
      </g>
    </svg>
  );
}

function MinSizes() {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 32, padding: '24px 16px', background: T.bgPrimary, borderRadius: 12, border: `0.5px solid ${T.border}` }}>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
        <GlyphB size={24} color={T.ink}/>
        <div style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>24px</div>
        <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec }}>Symbole seul · min</div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
        <LockupH Glyph={GlyphB} glyphSize={32} wordSize={20}/>
        <div style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>32px</div>
        <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec }}>Lockup horizontal · min</div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
        <Wordmark size={16} color={T.ink}/>
        <div style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>16px</div>
        <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec }}>Wordmark seul · min</div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
        <GlyphBFilled size={16} color={T.ink}/>
        <div style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>16px</div>
        <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec }}>Favicon · exception</div>
      </div>
    </div>
  );
}

function BackgroundsAllowed() {
  const ok = [
    { c: '#F5F2ED', label: 'Sable', val: '#F5F2ED', fg: T.accent },
    { c: '#FDFBF8', label: 'Ivoire', val: '#FDFBF8', fg: T.accent },
    { c: '#1C1A16', label: 'Brun foncé', val: '#1C1A16', fg: T.ivory },
    { c: '#FFFFFF', label: 'Blanc pur', val: '#FFFFFF', fg: '#000' },
    { c: '#000000', label: 'Noir pur', val: '#000000', fg: '#FFF' },
  ];
  const ko = [
    { bg: 'linear-gradient(45deg, #ff5e62, #ff9966)', label: 'Couleur vive', sub: 'Hors palette' },
    { bg: 'linear-gradient(135deg, #00A86B, #34C759)', label: 'Vert islamique', sub: 'Cliché à éviter' },
    { bg: 'repeating-linear-gradient(45deg, #C9A87E, #C9A87E 10px, #B89770 10px, #B89770 20px)', label: 'Texture', sub: 'Réduit la lisibilité' },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.6fr 1fr', gap: 24 }}>
      <div>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: '#6B8C6B', marginBottom: 10, fontWeight: 500 }}>✓ Fonds autorisés</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 10 }}>
          {ok.map(b => (
            <div key={b.val}>
              <div style={{ background: b.c, height: 90, borderRadius: 10, border: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <GlyphB size={42} color={b.fg}/>
              </div>
              <div style={{ marginTop: 6, fontFamily: T.fontSans, fontSize: 11, color: T.ink }}>{b.label}</div>
              <div style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer }}>{b.val}</div>
            </div>
          ))}
        </div>
      </div>
      <div>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: '#8C3D3D', marginBottom: 10, fontWeight: 500 }}>✗ Fonds interdits</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {ko.map((b, i) => (
            <div key={i}>
              <div style={{ background: b.bg, height: 90, borderRadius: 10, border: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
                <GlyphB size={42} color={T.ivory}/>
                <div style={{ position: 'absolute', inset: 0, borderRadius: 10, border: '1.5px dashed #8C3D3D', opacity: 0.7 }}/>
              </div>
              <div style={{ marginTop: 6, fontFamily: T.fontSans, fontSize: 11, color: T.ink }}>{b.label}</div>
              <div style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer }}>{b.sub}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// A "closed circle" SVG — used in don'ts to show what NOT to do
function ClosedCircle({ size = 64, color = T.accent }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block' }}>
      <circle cx="50" cy="50" r="40" fill="none" stroke={color} strokeWidth="9"/>
    </svg>
  );
}
// A "circle with a dot in the gap" — another don't
function CircleWithDot({ size = 64, color = T.accent }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block' }}>
      <g>
        {(() => {
          const r = 40, sw = 9;
          const a1 = -101 * Math.PI / 180;
          const a2 = -79  * Math.PI / 180;
          const p1 = { x: 50 + r * Math.cos(a2), y: 50 + r * Math.sin(a2) };
          const p2 = { x: 50 + r * Math.cos(a1), y: 50 + r * Math.sin(a1) };
          const d = `M ${p1.x.toFixed(2)} ${p1.y.toFixed(2)} A ${r} ${r} 0 1 1 ${p2.x.toFixed(2)} ${p2.y.toFixed(2)}`;
          return <path d={d} fill="none" stroke={color} strokeWidth={sw} strokeLinecap="butt"/>;
        })()}
      </g>
      <circle cx="50" cy="10" r="3.5" fill={color}/>
    </svg>
  );
}

function DoDont() {
  const rules = [
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <ClosedCircle size={64} color={T.accent}/>, label: 'Fermer l\'ouverture du cercle', okSub: 'Inachèvement préservé', koSub: 'Jamais de cercle complet' },
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <CircleWithDot size={64} color={T.accent}/>, label: 'Ajouter un point ou un astre', okSub: 'Ouverture pure', koSub: 'Aucun élément additionnel' },
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <div style={{ transform: 'scaleX(1.6)' }}><GlyphB size={64} color={T.accent}/></div>, label: 'Étirer le symbole', okSub: 'Proportions originales', koSub: 'Jamais déformé' },
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <div style={{ transform: 'rotate(120deg)' }}><GlyphB size={64} color={T.accent}/></div>, label: 'Faire pivoter le cercle', okSub: 'Ouverture en haut', koSub: 'Orientation fixe' },
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <GlyphB size={64} color="#FF3B30"/>, label: 'Changer la couleur hors palette', okSub: 'Accent ocre', koSub: 'Pas de rouge / vert vif' },
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <div style={{ filter: 'drop-shadow(2px 4px 6px rgba(0,0,0,0.4))' }}><GlyphB size={64} color={T.accent}/></div>, label: 'Ajouter une ombre', okSub: 'Logo plat', koSub: 'Aucun effet' },
    { ok: <GlyphB size={64} color={T.accent}/>, ko: <div style={{ width: 50, height: 64, overflow: 'hidden' }}><GlyphB size={64} color={T.accent}/></div>, label: 'Recadrer pour cacher l\'ouverture', okSub: 'Symbole entier', koSub: 'Jamais tronqué' },
    { ok: <GlyphB size={64} color={T.ink}/>, ko: <div style={{ background: '#888', padding: 8, borderRadius: 8 }}><GlyphB size={48} color="#999"/></div>, label: 'Contraste insuffisant', okSub: 'Contraste vérifié', koSub: '< 4.5:1 interdit' },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
      {rules.map((r, i) => (
        <Card key={i} padding={20}>
          <div style={{ fontFamily: T.fontSans, fontSize: 13, fontWeight: 500, color: T.ink, marginBottom: 14 }}>{r.label}</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <div style={{ height: 120, background: T.bgPrimary, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}`, position: 'relative' }}>
                {r.ok}
                <span style={{ position: 'absolute', top: 6, left: 8, fontFamily: T.fontMono, fontSize: 10, color: '#6B8C6B', letterSpacing: '0.1em' }}>✓</span>
              </div>
              <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec, marginTop: 6 }}>{r.okSub}</div>
            </div>
            <div>
              <div style={{ height: 120, background: T.bgPrimary, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `0.5px solid ${T.border}`, position: 'relative', overflow: 'hidden' }}>
                {r.ko}
                <span style={{ position: 'absolute', top: 6, left: 8, fontFamily: T.fontMono, fontSize: 10, color: '#8C3D3D', letterSpacing: '0.1em' }}>✗</span>
              </div>
              <div style={{ fontFamily: T.fontSans, fontSize: 11, color: T.textSec, marginTop: 6 }}>{r.koSub}</div>
            </div>
          </div>
        </Card>
      ))}
    </div>
  );
}

function BrandGuidePanel() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 32 }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        <Card padding={32}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 14, fontWeight: 500 }}>Zone de protection</div>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
            <ClearSpace/>
          </div>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, color: T.textSec, lineHeight: 1.6, margin: 0 }}>
            La zone de respiration <span style={{ fontFamily: T.fontMono, color: T.ink }}>x</span> est égale à 50% de la largeur du symbole. Aucun élément graphique, texte ou bord d'image ne doit s'y aventurer.
          </p>
        </Card>
        <Card padding={32}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 14, fontWeight: 500 }}>Tailles minimum</div>
          <MinSizes/>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, color: T.textSec, lineHeight: 1.6, margin: '16px 0 0 0' }}>
            En dessous de ces tailles, le logo perd son intégrité. Le favicon 16×16 est la seule exception tolérée — l'ouverture devient un point mais le cercle reste lisible.
          </p>
        </Card>
      </div>

      <Card padding={32}>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 14, fontWeight: 500 }}>Fonds</div>
        <BackgroundsAllowed/>
      </Card>

      <div>
        <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 14, fontWeight: 500 }}>Do / Don't</div>
        <DoDont/>
      </div>
    </div>
  );
}

Object.assign(window, { BrandGuidePanel, InContextPanel });
