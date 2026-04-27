// Murabbi Logo — Spec sheet (Markdown) and SVG export panel — Exploration B

const SPEC_MD = `# Murabbi — Logo & Identité visuelle · Spec sheet

**Version** 2.0 — Avril 2026
**Direction recommandée** B — Boucle interrompue (cercle inachevé)
**Format racine** SVG vectoriel · 100×100 viewBox

---

## 1. Symbole

| Propriété | Valeur |
|---|---|
| Format de base | SVG, viewBox \`0 0 100 100\` |
| Construction | Cercle centré exactement à (50, 50) |
| Rayon extérieur | 44.5u |
| Rayon intérieur | 35.5u |
| Graisse de trait | 9u (constante) |
| Ouverture | 22° centrée à −90° (haut), soit ~6% de la circonférence |
| Extrémités | Franches (butt) — pas de calligraphie |
| Couleur par défaut | \`#8B6F47\` (accent ocre) |

## 2. Palette

| Token | Valeur | Usage |
|---|---|---|
| Accent ocre | \`#8B6F47\` | Couleur principale du logo |
| Brun foncé | \`#1C1A16\` | Logo sur fond clair, mode formel |
| Sable | \`#F5F2ED\` | Fond principal |
| Ivoire | \`#FDFBF8\` | Fond surface, logo inversé |
| Noir pur | \`#000000\` | Print mono uniquement |
| Blanc pur | \`#FFFFFF\` | Print mono uniquement |

## 3. Typographie

**Wordmark latin** \`Murabbi\` — Geist SemiBold (600), tracking −0.02em à −0.04em.
**Wordmark arabe** \`مربي\` — Noto Sans Arabic Medium (500), hauteur visuelle 1.15× le latin, RTL strict.

## 4. Lockups (L1–L7)

L1 Symbole · L2 H lockup · L3 V lockup · L4 Symbole + arabe · L5 Bilingue · L6 Wordmark FR · L7 Wordmark AR.

## 5. Variations (29 livrables)

A1–A5 couleurs · B1–B4 app icons · C1–C3 favicons · D1–D4 headers · E1–E2 splash & loading · F1–F3 watermarks & badges · G1–G2 documents · H1–H3 social.

## 6. Espacement

Zone de protection = 50% de la largeur du symbole. Lockup H gap = 35% du symbole. Lockup V gap = 28%.

## 7. Tailles minimum

Symbole 24px · Lockup H 32px · Wordmark 16px · Favicon 16×16 (exception).

## 8. Fonds autorisés

\`#F5F2ED\` · \`#FDFBF8\` · \`#1C1A16\` · \`#FFFFFF\` · \`#000000\`.

## 9. Interdits absolus

- ❌ Fermer le cercle
- ❌ Ajouter un point, un astre, un trait dans l'ouverture
- ❌ Faire pivoter (l'ouverture est en haut, point)
- ❌ Étirer, recadrer, déformer
- ❌ Gradient, ombre portée, effet 3D, glassmorphism
- ❌ Couleur hors palette
- ❌ Ajouter une lettre M ou toute calligraphie à l'intérieur
- ❌ Étoile, coupole, ou tout cliché islamique

## 10. Loading animation (E2)

\`\`\`css
@keyframes spin-slow { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
.murabbi-loading { animation: spin-slow 8s linear infinite; }
\`\`\`

## 11. SVG canonique du symbole (filled)

\`\`\`xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="#8B6F47">
  <path d="M 57.61 6.30 A 44.5 44.5 0 1 1 42.39 6.30 L 44.15 14.62 A 35.5 35.5 0 1 0 55.85 14.62 Z"/>
</svg>
\`\`\`

## 12. SVG canonique du symbole (stroke)

\`\`\`xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path fill="none" stroke="#8B6F47" stroke-width="9" stroke-linecap="butt"
    d="M 47.36 10.62 A 40 40 0 1 1 52.64 10.62"/>
</svg>
\`\`\`

---

*Murabbi · مربي — Formateur de soi*
*Brief Logo & Identité v2.0 — Conception : Avril 2026*
`;

function SpecSheet() {
  const html = SPEC_MD
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    .replace(/^---$/gm, '<hr/>')
    .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/^\| (.+) \|$/gm, (m) => '<tr>' + m.slice(2, -2).split(' | ').map(c => `<td>${c}</td>`).join('') + '</tr>')
    .replace(/(<tr>[\s\S]+?<\/tr>)+/g, m => `<table>${m}</table>`)
    .replace(/^- (.+)$/gm, '<li>$1</li>')
    .replace(/(<li>[\s\S]+?<\/li>\n?)+/g, m => `<ul>${m}</ul>`)
    .replace(/\n\n/g, '</p><p>')
    .replace(/^\*([^*]+)\*$/gm, '<em>$1</em>');
  return (
    <Card padding={48} bg={T.bgSurface}>
      <div className="markdown-spec" dangerouslySetInnerHTML={{ __html: '<p>' + html + '</p>' }}/>
    </Card>
  );
}

// ── SVG export ──────────────────────────────────────────────────────────
function symbolSvgString(color) {
  // Filled version — same geometry as GlyphBFilled
  const rOut = 44.5, rIn = 35.5, cx = 50, cy = 50;
  const a1 = -101 * Math.PI / 180, a2 = -79 * Math.PI / 180;
  const p1o = { x: cx + rOut * Math.cos(a1), y: cy + rOut * Math.sin(a1) };
  const p2o = { x: cx + rOut * Math.cos(a2), y: cy + rOut * Math.sin(a2) };
  const p1i = { x: cx + rIn * Math.cos(a1), y: cy + rIn * Math.sin(a1) };
  const p2i = { x: cx + rIn * Math.cos(a2), y: cy + rIn * Math.sin(a2) };
  const d = `M ${p2o.x.toFixed(2)} ${p2o.y.toFixed(2)} A ${rOut} ${rOut} 0 1 1 ${p1o.x.toFixed(2)} ${p1o.y.toFixed(2)} L ${p1i.x.toFixed(2)} ${p1i.y.toFixed(2)} A ${rIn} ${rIn} 0 1 0 ${p2i.x.toFixed(2)} ${p2i.y.toFixed(2)} Z`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100" fill="${color}">\n  <path d="${d}"/>\n</svg>`;
}

const SVG_EXPORTS = {
  'symbol-ocre.svg':       '#8B6F47',
  'symbol-ink.svg':        '#1C1A16',
  'symbol-ivory.svg':      '#FDFBF8',
  'symbol-mono-black.svg': '#000000',
  'symbol-mono-white.svg': '#FFFFFF',
};

function ExportPanel() {
  const [copied, setCopied] = React.useState(null);
  const copy = (name, color) => {
    navigator.clipboard.writeText(symbolSvgString(color)).then(() => {
      setCopied(name);
      setTimeout(() => setCopied(null), 1400);
    });
  };
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
      {Object.entries(SVG_EXPORTS).map(([name, color]) => (
        <Card key={name} padding={20}>
          <div style={{ height: 100, background: color === '#FFFFFF' ? '#000' : (color === '#FDFBF8' || color === '#1C1A16') ? T.bgPrimary : '#FFF', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12, border: `0.5px solid ${T.border}` }}>
            <GlyphBFilled size={56} color={color}/>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
            <div style={{ overflow: 'hidden' }}>
              <div style={{ fontFamily: T.fontMono, fontSize: 11, color: T.ink, fontWeight: 500, whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>{name}</div>
              <div style={{ fontFamily: T.fontMono, fontSize: 10, color: T.textTer }}>{color}</div>
            </div>
            <button onClick={() => copy(name, color)} style={{
              fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.1em', textTransform: 'uppercase',
              padding: '6px 10px', background: copied === name ? T.accentLight : 'transparent',
              border: `0.5px solid ${T.borderEm}`, color: copied === name ? T.accent : T.textSec,
              borderRadius: 6, cursor: 'pointer', fontWeight: 500, flexShrink: 0,
            }}>{copied === name ? '✓ Copié' : 'Copier'}</button>
          </div>
        </Card>
      ))}
      <Card padding={20} bg={T.accentLight} style={{ border: `0.5px solid ${T.accentBorder}`, gridColumn: 'span 3' }}>
        <div style={{ fontFamily: T.fontSans, fontSize: 14, fontWeight: 500, color: T.ink }}>Tous les fichiers SVG sont aussi disponibles à part</div>
        <div style={{ fontFamily: T.fontSans, fontSize: 12, color: T.textSec, marginTop: 4 }}>
          Voir le dossier <code style={{ fontFamily: T.fontMono, fontSize: 11 }}>logo-exports/</code> à la racine du projet.
        </div>
      </Card>
    </div>
  );
}

Object.assign(window, { SpecSheet, ExportPanel });
