// Murabbi Logo v3 — Iterations + Construction panel
function IterationCard({ id, name, tagline, version, notes, isFinal }) {
  return (
    <div style={{
      background: T.bgSurface,
      border: isFinal ? `1px solid ${T.accent}` : `0.5px solid ${T.border}`,
      borderRadius: 22, overflow: 'hidden', position: 'relative',
    }}>
      {isFinal && (
        <div style={{
          position: 'absolute', top: 14, right: 14, zIndex: 2,
          fontFamily: T.fontMono, fontSize: 9, fontWeight: 500,
          letterSpacing: '0.18em', textTransform: 'uppercase',
          color: T.accent, background: T.accentLight,
          border: `0.5px solid ${T.accentBorder}`,
          padding: '5px 10px', borderRadius: 100,
        }}>★ Finalisée</div>
      )}
      <div style={{
        background: T.bgPrimary, height: 280,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        borderBottom: `0.5px solid ${T.border}`,
      }}>
        <GlyphMfinal size={170} color={T.ink} version={version}/>
      </div>
      <div style={{ background: T.bgPrimary, padding: '20px 24px', borderBottom: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
        {[64, 40, 24, 16].map(sz => (
          <div key={sz} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <GlyphMfinal size={sz} color={T.ink} version={version}/>
            <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>{sz}px</span>
          </div>
        ))}
      </div>
      <div style={{ padding: 24 }}>
        <div style={{ fontFamily: T.fontMono, fontSize: 11, color: T.textTer, fontWeight: 500, letterSpacing: '0.16em', marginBottom: 4 }}>ITÉRATION {id}</div>
        <h3 style={{ fontFamily: T.fontSans, fontSize: 22, fontWeight: 500, color: T.ink, margin: '0 0 4px 0', letterSpacing: '-0.02em' }}>{name}</h3>
        <div style={{ fontFamily: T.fontSans, fontStyle: 'italic', fontSize: 13, color: T.textSec, marginBottom: 16 }}>« {tagline} »</div>
        <div style={{ paddingTop: 16, borderTop: `0.5px solid ${T.border}` }}>
          <div style={{ fontFamily: T.fontMono, fontSize: 9, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 8 }}>Ce qui change</div>
          <ul style={{ fontFamily: T.fontSans, fontSize: 12.5, color: T.textSec, lineHeight: 1.55, margin: 0, paddingLeft: 16 }}>
            {notes.map((n, i) => <li key={i} style={{ marginBottom: 4 }}>{n}</li>)}
          </ul>
        </div>
      </div>
    </div>
  );
}

function IterationsPanel() {
  const its = [
    { id: 'V1', version: 1, name: 'Le M brouillon', tagline: 'On pose la structure',
      notes: [
        'Posts égaux et fins (28u), géométrie symétrique stricte',
        'Vallée centrale en V net, pointe à 60u, pas de plateau',
        'Pas encore de signature distinctive',
        'Pieds posés à plat sur la ligne de base',
      ]},
    { id: 'V2', version: 2, name: 'Le M raffiné', tagline: 'On cherche l\'équilibre',
      notes: [
        'Posts épaissis à 32u — gain de présence et stabilité',
        'Plateau de vallée de 2u : la pointe n\'est plus un cri, c\'est un repos',
        'Plafond du contre-creux remonté à y=32 → meilleure tenue à petite échelle',
        'Toujours symétrique : on cherche encore la signature',
      ]},
    { id: 'V3', version: 3, name: 'Le M finalisé', tagline: 'On engrave le pas',
      notes: [
        'Posts ramenés à 30u (point d\'équilibre entre V1 et V2)',
        'Plateau de vallée porté à 6u, avec une micro-courbe ascendante (Q 60 53) — le croissant subtil',
        'Plafond du contre-creux à y=28 — la respiration intérieure devient plus généreuse',
        'SIGNATURE : pied droit relevé de 6u par rapport au pied gauche. Asymétrie volontaire qui dit « إرتقاء » (ascension, élévation)',
        'Cette V3 est la version officielle déclinée dans tout ce qui suit',
      ], isFinal: true },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24 }}>
      {its.map(it => <IterationCard key={it.id} {...it}/>)}
    </div>
  );
}

function ConstructionPanel() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 24 }}>
      <Card padding={0} bg={T.bgPrimary}>
        <div style={{ padding: '32px 32px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <GlyphMfinal size={420} color={T.ink} version={3} showGrid={true}/>
        </div>
        <div style={{ padding: '24px 32px 32px', borderTop: `0.5px solid ${T.border}`, marginTop: 32 }}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, fontWeight: 500, marginBottom: 12 }}>Grille de construction · 120 × 100 u</div>
          <div style={{ fontFamily: T.fontMono, fontSize: 11.5, lineHeight: 1.85, color: T.textSec }}>
            <div>posts.width &nbsp;&nbsp;= 30u (gauche : 0–30, droit : 90–120)</div>
            <div>valley.apex &nbsp;= y 54u, plateau x 57–63u (6u)</div>
            <div>valley.curve = Q(60, 53) — micro-courbe ascendante</div>
            <div>notch.ceiling= y 28u (contre-creux supérieur)</div>
            <div>step.right &nbsp;&nbsp;= pied droit posé à y 94u (−6u)</div>
            <div>step.left &nbsp;&nbsp;&nbsp;= pied gauche posé à y 100u (ligne de base)</div>
          </div>
        </div>
      </Card>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.accent, fontWeight: 500, marginBottom: 10 }}>Détail signature 1 · L'asymétrie du pas</div>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.65, color: T.ink, margin: 0 }}>
            Le pied droit du M est posé <strong>6u plus haut</strong> que le pied gauche. Au premier regard, on voit un M solide. Au deuxième regard, on remarque que le pied droit avance, comme un pas en avant. Au troisième, on lit l'<strong style={{ color: T.accent }}>إرتقاء</strong> — l'élévation, sens premier de Murabbi.
          </p>
        </Card>
        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.accent, fontWeight: 500, marginBottom: 10 }}>Détail signature 2 · La micro-courbe</div>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.65, color: T.ink, margin: 0 }}>
            Le plateau de la vallée n'est pas tout à fait plat. Une <strong>micro-courbe quadratique</strong> (Q 60 53) le fait monter d'une unité au centre. Imperceptible à 16 px ; lisible à 1024 px comme la trace très discrète d'un croissant inversé. La référence lunaire ne se montre que dans l'app icon de l'App Store.
          </p>
        </Card>
        <Card padding={24}>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.accent, fontWeight: 500, marginBottom: 10 }}>Détail signature 3 · Les pleins</div>
          <p style={{ fontFamily: T.fontSans, fontSize: 13, lineHeight: 1.65, color: T.ink, margin: 0 }}>
            Le M est un <strong>bloc plein</strong>, sans fioriture, sans terminal serif, sans courbe externe. La géométrie est lue d'un coup d'œil. La précision est dans les chiffres, pas dans la décoration.
          </p>
        </Card>
      </div>
    </div>
  );
}

Object.assign(window, { IterationsPanel, ConstructionPanel });
