// Murabbi Logo — Construction grid for Exploration B (recommended)

function ConstructionGrid({ size = 480 }) {
  const grid = T.borderEm;
  const guide = 'rgba(139, 111, 71, 0.55)';
  const measure = T.textSec;

  // Same geometry as GlyphB
  const rOut = 44.5;
  const rIn  = 35.5;
  const cx = 50, cy = 50;
  const a1 = -101 * Math.PI / 180;
  const a2 = -79  * Math.PI / 180;
  const p1o = { x: cx + rOut * Math.cos(a1), y: cy + rOut * Math.sin(a1) };
  const p2o = { x: cx + rOut * Math.cos(a2), y: cy + rOut * Math.sin(a2) };
  const p1i = { x: cx + rIn * Math.cos(a1), y: cy + rIn * Math.sin(a1) };
  const p2i = { x: cx + rIn * Math.cos(a2), y: cy + rIn * Math.sin(a2) };
  const d = `M ${p2o.x.toFixed(2)} ${p2o.y.toFixed(2)} A ${rOut} ${rOut} 0 1 1 ${p1o.x.toFixed(2)} ${p1o.y.toFixed(2)} L ${p1i.x.toFixed(2)} ${p1i.y.toFixed(2)} A ${rIn} ${rIn} 0 1 0 ${p2i.x.toFixed(2)} ${p2i.y.toFixed(2)} Z`;

  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block', overflow: 'visible' }}>
      {/* Outer bounds */}
      <rect x="0" y="0" width="100" height="100" fill="none" stroke={grid} strokeWidth="0.2" strokeDasharray="0.6 0.6"/>

      {/* Baseline grid 10u */}
      {[10,20,30,40,50,60,70,80,90].map(n => (
        <g key={n}>
          <line x1={n} y1="0" x2={n} y2="100" stroke={grid} strokeWidth="0.08"/>
          <line x1="0" y1={n} x2="100" y2={n} stroke={grid} strokeWidth="0.08"/>
        </g>
      ))}

      {/* Center axes */}
      <line x1="0" y1="50" x2="100" y2="50" stroke={guide} strokeWidth="0.15" strokeDasharray="1 1"/>
      <line x1="50" y1="0" x2="50" y2="100" stroke={guide} strokeWidth="0.15" strokeDasharray="1 1"/>

      {/* Construction circles */}
      <circle cx={cx} cy={cy} r={rOut} fill="none" stroke={guide} strokeWidth="0.25"/>
      <circle cx={cx} cy={cy} r={rIn}  fill="none" stroke={guide} strokeWidth="0.25"/>
      <circle cx={cx} cy={cy} r="0.7" fill={guide}/>

      {/* Gap angle wedge */}
      <line x1={cx} y1={cy} x2={p1o.x} y2={p1o.y} stroke={guide} strokeWidth="0.2" strokeDasharray="0.8 0.8"/>
      <line x1={cx} y1={cy} x2={p2o.x} y2={p2o.y} stroke={guide} strokeWidth="0.2" strokeDasharray="0.8 0.8"/>

      {/* The actual glyph — outline + filled ghost */}
      <path d={d} fill={T.accent} opacity="0.10"/>
      <path d={d} fill="none" stroke={T.ink} strokeWidth="0.4"/>

      {/* Endpoint markers */}
      <circle cx={p1o.x} cy={p1o.y} r="0.8" fill={T.accent}/>
      <circle cx={p2o.x} cy={p2o.y} r="0.8" fill={T.accent}/>
      <circle cx={p1i.x} cy={p1i.y} r="0.8" fill={T.accent}/>
      <circle cx={p2i.x} cy={p2i.y} r="0.8" fill={T.accent}/>

      {/* Measurement labels */}
      <g style={{ fontFamily: T.fontMono, fontSize: 2.4, fill: measure }}>
        <text x="50" y="3" textAnchor="middle">22°</text>
        <text x="95" y="50" textAnchor="end">r·out = 44.5u</text>
        <text x="58" y="65" >r·in = 35.5u</text>
        <text x="50" y="98" textAnchor="middle">trait = 9u</text>
      </g>
    </svg>
  );
}

function ConstructionPanel() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 32 }}>
      <Card padding={48} bg={T.bgPrimary}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <ConstructionGrid size={440}/>
        </div>
      </Card>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 12 }}>Grille</div>
          <h3 style={{ fontFamily: T.fontSans, fontSize: 18, fontWeight: 500, margin: '0 0 8px 0', color: T.ink }}>Carré 100×100u, centré</h3>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.6, color: T.textSec, margin: 0 }}>
            Le cercle est tracé autour du centre exact (50, 50). Symétrie verticale parfaite. Aucun élément n'existe en dehors du cercle.
          </p>
        </Card>

        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 12 }}>Géométrie</div>
          <h3 style={{ fontFamily: T.fontSans, fontSize: 18, fontWeight: 500, margin: '0 0 8px 0', color: T.ink }}>Anneau, deux rayons</h3>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.6, color: T.textSec, margin: 0 }}>
            Rayon extérieur <span style={{ fontFamily: T.fontMono, color: T.ink }}>44.5u</span>, rayon intérieur <span style={{ fontFamily: T.fontMono, color: T.ink }}>35.5u</span>. Trait de <span style={{ fontFamily: T.fontMono, color: T.ink }}>9u</span> constant — aucune variation d'épaisseur.
          </p>
        </Card>

        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 12 }}>Ouverture</div>
          <h3 style={{ fontFamily: T.fontSans, fontSize: 18, fontWeight: 500, margin: '0 0 8px 0', color: T.ink }}>22° au sommet</h3>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.6, color: T.textSec, margin: 0 }}>
            L'angle d'ouverture est de <span style={{ fontFamily: T.fontMono, color: T.ink }}>22°</span> centré exactement à <span style={{ fontFamily: T.fontMono, color: T.ink }}>−90°</span> (haut). Soit ~6% de la circonférence absente. Les extrémités sont franches, géométriques — pas calligraphiques.
          </p>
        </Card>

        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 12 }}>Zone de protection</div>
          <h3 style={{ fontFamily: T.fontSans, fontSize: 18, fontWeight: 500, margin: '0 0 8px 0', color: T.ink }}>50% de la largeur du symbole</h3>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.6, color: T.textSec, margin: 0 }}>
            Aucun élément graphique ne doit empiéter dans une zone égale à la moitié de la largeur du cercle, autour de toutes ses arêtes.
          </p>
        </Card>
      </div>
    </div>
  );
}

Object.assign(window, { ConstructionGrid, ConstructionPanel });
