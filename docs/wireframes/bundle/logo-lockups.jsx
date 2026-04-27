// Murabbi Logo — Lockups (PARTIE 4) — uses GlyphB (recommended direction)

function LockupsPanel() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 18 }}>
      {/* 1. Symbol alone */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <GlyphB size={96} color={T.accent}/>
        </div>
        <Tag id="L1" label="Symbole seul" sub="Le pivot du système — utilisé partout où l'espace est rare."/>
      </div>
      {/* 2. Symbol + Latin horizontal */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <LockupH Glyph={GlyphB} glyphSize={56} wordSize={34}/>
        </div>
        <Tag id="L2" label="Lockup horizontal · symbole + Murabbi" sub="Header desktop, signature email, en-têtes."/>
      </div>
      {/* 3. Symbol + Latin vertical */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 220, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <LockupV Glyph={GlyphB} glyphSize={68} wordSize={26}/>
        </div>
        <Tag id="L3" label="Lockup vertical · symbole au-dessus" sub="Splash, avatar carré, format restreint."/>
      </div>
      {/* 4. Symbol + Arabic */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 18 }}>
          <GlyphB size={56} color={T.accent}/>
          <WordmarkAr size={36} color={T.ink}/>
        </div>
        <Tag id="L4" label="Lockup arabe · symbole + مربي" sub="Versions arabes de l'app, communications RTL."/>
      </div>
      {/* 5. Bilingual */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 14 }}>
            <GlyphB size={48} color={T.accent}/>
            <Wordmark size={28} color={T.ink}/>
            <MidDot size={24} color={T.textTer}/>
            <WordmarkAr size={28} color={T.ink}/>
          </div>
        </div>
        <Tag id="L5" label="Lockup bilingue · Murabbi · مربي" sub="Communications internationales, packaging."/>
      </div>
      {/* 6. Wordmark Latin only */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Wordmark size={56} color={T.ink}/>
        </div>
        <Tag id="L6" label="Wordmark Murabbi seul" sub="Footer, signature très large, contextes typographiques."/>
      </div>
      {/* 7. Wordmark Arabic only */}
      <div>
        <div style={{ background: T.bgPrimary, borderRadius: 16, border: `0.5px solid ${T.border}`, height: 180, display: 'flex', alignItems: 'center', justifyContent: 'center', gridColumn: 'span 2' }}>
          <WordmarkAr size={64} color={T.ink}/>
        </div>
        <Tag id="L7" label="Wordmark مربي seul" sub="Documents arabes, contextes culturels spécifiques."/>
      </div>
    </div>
  );
}

Object.assign(window, { LockupsPanel });
