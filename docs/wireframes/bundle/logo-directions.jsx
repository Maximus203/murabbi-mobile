// Murabbi Logo — Directions panel (3 explorations of "incomplete circle")

function DirectionCard({ id, name, tagline, Glyph, justification, strengths, weaknesses, isRecommended }) {
  return (
    <div style={{
      background: T.bgSurface,
      border: isRecommended ? `1px solid ${T.accent}` : `0.5px solid ${T.border}`,
      borderRadius: 22,
      padding: 0,
      overflow: 'hidden',
      position: 'relative',
    }}>
      {isRecommended && (
        <div style={{
          position: 'absolute', top: 14, right: 14, zIndex: 2,
          fontFamily: T.fontMono, fontSize: 9, fontWeight: 500,
          letterSpacing: '0.18em', textTransform: 'uppercase',
          color: T.accent, background: T.accentLight,
          border: `0.5px solid ${T.accentBorder}`,
          padding: '5px 10px', borderRadius: 100,
        }}>★ Recommandée</div>
      )}

      {/* Hero — large glyph centered on sand */}
      <div style={{
        background: T.bgPrimary, height: 280,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        borderBottom: `0.5px solid ${T.border}`,
      }}>
        <Glyph size={170} color={T.accent}/>
      </div>

      {/* Scale ladder */}
      <div style={{ background: T.bgPrimary, padding: '20px 24px', borderBottom: `0.5px solid ${T.border}`, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 16 }}>
        {[64, 40, 24, 16].map(sz => (
          <div key={sz} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <Glyph size={sz} color={T.ink}/>
            <span style={{ fontFamily: T.fontMono, fontSize: 9, color: T.textTer, letterSpacing: '0.1em' }}>{sz}px</span>
          </div>
        ))}
      </div>

      {/* Name + justification */}
      <div style={{ padding: 24 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginBottom: 4 }}>
          <span style={{ fontFamily: T.fontMono, fontSize: 11, color: T.textTer, fontWeight: 500, letterSpacing: '0.16em' }}>EXPLORATION {id}</span>
        </div>
        <h3 style={{ fontFamily: T.fontSans, fontSize: 22, fontWeight: 500, color: T.ink, margin: '0 0 4px 0', letterSpacing: '-0.02em' }}>{name}</h3>
        <div style={{ fontFamily: T.fontSans, fontStyle: 'italic', fontSize: 13, color: T.textSec, marginBottom: 16 }}>« {tagline} »</div>

        <p style={{ fontFamily: T.fontSans, fontSize: 13.5, lineHeight: 1.65, color: T.ink, margin: '0 0 18px 0' }}>{justification}</p>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, paddingTop: 16, borderTop: `0.5px solid ${T.border}` }}>
          <div>
            <div style={{ fontFamily: T.fontMono, fontSize: 9, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 6 }}>Forces</div>
            <ul style={{ fontFamily: T.fontSans, fontSize: 12.5, color: T.textSec, lineHeight: 1.5, margin: 0, paddingLeft: 14 }}>
              {strengths.map((s, i) => <li key={i} style={{ marginBottom: 3 }}>{s}</li>)}
            </ul>
          </div>
          <div>
            <div style={{ fontFamily: T.fontMono, fontSize: 9, letterSpacing: '0.18em', textTransform: 'uppercase', color: T.textTer, marginBottom: 6 }}>Faiblesses</div>
            <ul style={{ fontFamily: T.fontSans, fontSize: 12.5, color: T.textSec, lineHeight: 1.5, margin: 0, paddingLeft: 14 }}>
              {weaknesses.map((w, i) => <li key={i} style={{ marginBottom: 3 }}>{w}</li>)}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

function DirectionsPanel({ recommended, onPick, picked }) {
  const dirs = [
    {
      id: 'A', name: 'Croissant minimal', tagline: 'La lune en ascension', Glyph: GlyphA,
      justification: "Un cercle dont l'ouverture est large \u2014 environ un quart du parcours est absent. Le trait restant forme un croissant \u00e9pur\u00e9 inclin\u00e9 vers le haut-droite, comme une lune en phase ascendante. La r\u00e9f\u00e9rence lunaire est ici la plus directe \u2014 mais sans \u00e9toile, sans pointe, sans clich\u00e9 ottoman.",
      strengths: ['R\u00e9f\u00e9rence \u00e0 la lune \u00e9vidente, m\u00e9morable', 'Tr\u00e8s photog\u00e9nique en grand format', 'Tient bien aux petites tailles \u2014 forme massive'],
      weaknesses: ['La r\u00e9f\u00e9rence islamique est explicite \u2014 fronti\u00e8re d\u00e9licate', 'Moins universel : un public non-musulman lira "lune" avant de lire "cercle inachev\u00e9"', 'Plus difficile \u00e0 distinguer d\u2019un croissant d\u00e9coratif'],
    },
    {
      id: 'B', name: 'Boucle interrompue', tagline: 'Le trait qui ne se referme pas', Glyph: GlyphB,
      justification: "Un cercle presque complet, dont le trait s'interrompt nettement au sommet. L'ouverture est d'environ 6\u202f% \u2014 \u00e0 peine perceptible, mais d\u00e9cisive. La forme dit\u202f: \u00ab\u202fle travail n'est jamais fini, on continue, on revient\u202f\u00bb. La r\u00e9f\u00e9rence lunaire est compl\u00e8tement implicite\u202f: c\u2019est avant tout un cercle, pas un croissant.",
      strengths: ['Reste lisible comme cercle \u00e0 16\u202fpx', 'R\u00e9f\u00e9rence islamique invisible aux non-initi\u00e9s', 'Intemporalit\u00e9 maximale \u2014 g\u00e9om\u00e9trie pure', 'Fort potentiel m\u00e9taphorique\u202f: r\u00e9p\u00e9tition + inachev\u00e9'],
      weaknesses: ['L\u2019ouverture est subtile \u2014 risque d\u2019\u00eatre interpr\u00e9t\u00e9 comme un anneau imparfait', 'Demande une attention \u00e9ditoriale forte pour transmettre le sens'],
    },
    {
      id: 'C', name: 'Tracé en mouvement', tagline: 'Le geste posé du calame', Glyph: GlyphC,
      justification: "Le m\u00eame cercle ouvert, mais dont l'\u00e9paisseur du trait varie sur son parcours\u202f: \u00e9pais dans la partie basse (l\u2019ancrage), il s\u2019affine progressivement en remontant vers l\u2019ouverture au sommet. C\u2019est une g\u00e9om\u00e9trie qui sugg\u00e8re le mouvement \u2014 le calame qui se l\u00e8ve.",
      strengths: ['Le plus distinctif des trois \u2014 caract\u00e8re imm\u00e9diat', 'Sugg\u00e8re un sens de lecture (du bas vers le haut)', 'Croissance et \u00e9l\u00e9vation visuellement port\u00e9es par la forme'],
      weaknesses: ['Risque de para\u00eetre \u00ab\u202fcalligraphique\u202f\u00bb plut\u00f4t que g\u00e9om\u00e9trique', 'Plus difficile \u00e0 reproduire en favicon 16\u202fpx (l\u2019affinement dispara\u00eet)', 'Vieillit moins bien que la sym\u00e9trie pure de B'],
    },
  ];

  return (
    <>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, marginTop: 8 }}>
        {dirs.map(d => (
          <div key={d.id} onClick={() => onPick(d.id)} style={{ cursor: 'pointer', opacity: picked === d.id || picked === null ? 1 : 0.55, transition: 'opacity 0.2s' }}>
            <DirectionCard {...d} isRecommended={recommended === d.id}/>
          </div>
        ))}
      </div>

      {/* Recommendation banner */}
      <div style={{ marginTop: 28, background: T.accentLight, border: `0.5px solid ${T.accentBorder}`, borderRadius: 22, padding: 36, display: 'grid', gridTemplateColumns: '1fr 1.6fr', gap: 32, alignItems: 'center' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18, paddingRight: 24, borderRight: `0.5px solid ${T.accentBorder}` }}>
          <GlyphB size={140} color={T.accent}/>
          <Wordmark size={28} color={T.ink}/>
        </div>
        <div>
          <div style={{ fontFamily: T.fontMono, fontSize: 10, letterSpacing: '0.2em', textTransform: 'uppercase', color: T.accent, marginBottom: 10, fontWeight: 500 }}>★ Ma recommandation</div>
          <h3 style={{ fontFamily: T.fontSans, fontSize: 32, fontWeight: 500, color: T.ink, margin: '0 0 14px 0', letterSpacing: '-0.02em', lineHeight: 1.15 }}>Exploration B — Boucle interrompue</h3>
          <p style={{ fontFamily: T.fontSans, fontSize: 14, lineHeight: 1.65, color: T.textSec, margin: 0 }}>
            C\u2019est l\u2019interpr\u00e9tation qui satisfait toutes les r\u00e8gles critiques simultan\u00e9ment. <strong style={{ color: T.ink }}>Intemporalit\u00e9</strong>\u202f: un cercle est la forme la plus stable du r\u00e9pertoire g\u00e9om\u00e9trique. <strong style={{ color: T.ink }}>Discr\u00e9tion</strong>\u202f: l\u2019ouverture fine est suffisamment subtile pour que le public non-musulman lise simplement un cercle \u00e9l\u00e9gant, et suffisamment pr\u00e9sente pour que le public musulman y reconnaisse la r\u00e9f\u00e9rence lunaire. <strong style={{ color: T.ink }}>Scalabilit\u00e9</strong>\u202f: la forme reste reconnaissable \u00e0 16\u202fpx, m\u00eame quand l\u2019ouverture devient un point. <strong style={{ color: T.ink }}>Diff\u00e9renciation</strong>\u202f: c\u2019est exactement l\u00e0 que Murabbi se s\u00e9pare des cercles complets de la concurrence \u2014 m\u00eame ouverture, sens compl\u00e8tement diff\u00e9rent.
          </p>
          <p style={{ fontFamily: T.fontSans, fontSize: 14, lineHeight: 1.65, color: T.textSec, margin: '12px 0 0 0' }}>
            Les variations compl\u00e8tes ci-dessous d\u00e9clinent cette direction.
          </p>
        </div>
      </div>
    </>
  );
}

Object.assign(window, { DirectionsPanel });
