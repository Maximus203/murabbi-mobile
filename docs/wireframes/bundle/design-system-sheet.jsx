// Murabbi — Design System sheet (tokens + component examples)

const ColorSwatch = ({ name, val, fg }) => (
  <div className="ds-swatch">
    <div className="sw" style={{ background: val, color: fg || '#000' }}/>
    <div className="nm">{name}</div>
    <div className="vl">{val}</div>
  </div>
);

const DSPanel = () => (
  <div style={{ width: 1080, background: 'var(--bg-primary)', color: 'var(--text-primary)' }}>
    {/* Header */}
    <div style={{ padding: '40px 40px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 18 }}>
        <Logo size={36}/>
        <div>
          <div className="h1" style={{ fontSize: 28 }}>Murabbi · Design System</div>
          <div className="caption" style={{ marginTop: 2 }}>Sobre. Aéré. Ancré. — v1.0 · Avril 2026</div>
        </div>
      </div>
      <p className="body body-secondary" style={{ maxWidth: 720, margin: 0 }}>
        Un OS personnel de croissance humaine. L'interface tient du carnet Moleskine numérisé : elle ne crie pas, elle accompagne.
      </p>
    </div>

    {/* Colors */}
    <div className="ds-section">
      <h2>Couleurs · Backgrounds & Texte</h2>
      <div className="ds-grid" style={{ gridTemplateColumns: 'repeat(6, 1fr)' }}>
        <ColorSwatch name="bg-primary" val="#F5F2ED"/>
        <ColorSwatch name="bg-surface" val="#FDFBF8"/>
        <ColorSwatch name="bg-input" val="#EDE9E2"/>
        <ColorSwatch name="text-primary" val="#1C1A16"/>
        <ColorSwatch name="text-secondary" val="#6B6155"/>
        <ColorSwatch name="text-tertiary" val="#A89880"/>
      </div>
    </div>

    <div className="ds-section">
      <h2>Couleurs · Accent ocre & Sémantiques</h2>
      <div className="ds-grid" style={{ gridTemplateColumns: 'repeat(6, 1fr)' }}>
        <ColorSwatch name="accent" val="#8B6F47"/>
        <ColorSwatch name="accent-hover" val="#7A6240"/>
        <ColorSwatch name="success" val="#6B8C6B"/>
        <ColorSwatch name="warning" val="#9B5E3C"/>
        <ColorSwatch name="danger" val="#8C3D3D"/>
        <ColorSwatch name="border-emphasis" val="rgba(28,26,22,0.16)"/>
      </div>
    </div>

    <div className="ds-section">
      <h2>Couleurs · Catégories</h2>
      <div className="ds-grid" style={{ gridTemplateColumns: 'repeat(5, 1fr)' }}>
        <ColorSwatch name="religion" val="#8B6F47"/>
        <ColorSwatch name="sport" val="#6B8C6B"/>
        <ColorSwatch name="santé" val="#5C7A8C"/>
        <ColorSwatch name="mental" val="#7A6B8C"/>
        <ColorSwatch name="social" val="#9B7A4A"/>
      </div>
    </div>

    {/* Type */}
    <div className="ds-section">
      <h2>Typographie · Geist + Geist Mono + Noto Sans Arabic</h2>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>Display 48</span>
          <span className="display">42</span>
          <span className="caption">Geist Mono Medium · -1px tracking</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>H1 · 26</span>
          <span className="h1">Bon retour.</span>
          <span className="caption">Geist SemiBold · -0.3px</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>H2 · 18</span>
          <span className="h2">Prières du jour</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>H3 · 15</span>
          <span className="h3">Lecture du Coran</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>Body · 14</span>
          <span className="body">Patience, régularité, ancrage.</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>Label · 11</span>
          <span className="label">INTENTION DU JOUR</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>Caption · 11</span>
          <span className="caption">15h42 — dans 1h 18min</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 24 }}>
          <span className="caption mono" style={{ width: 110 }}>Arabe</span>
          <span style={{ fontFamily: 'var(--font-arabic)', fontSize: 22, fontWeight: 500 }}>الفجر · الظهر · العصر · المغرب · العشاء</span>
        </div>
      </div>
    </div>

    {/* Buttons */}
    <div className="ds-section">
      <h2>Boutons · 4 types + 1 lien</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 16 }}>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>Primaire</div>
          <button className="btn-primary">Continuer</button>
          <div className="caption" style={{ marginTop: 8 }}>Hover</div>
          <button className="btn-primary" style={{ background: 'var(--accent-hover)' }}>Continuer</button>
          <div className="caption" style={{ marginTop: 8 }}>Disabled</div>
          <button className="btn-primary" disabled>Continuer</button>
        </div>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>Secondaire</div>
          <button className="btn-secondary">Modifier</button>
        </div>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>Ghost</div>
          <button className="btn-ghost">Continuer avec Google</button>
        </div>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>Destructeur</div>
          <button className="btn-destructive"><Icon.Trash size={14}/> Supprimer</button>
        </div>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>Lien tertiaire</div>
          <button className="link-tertiary">Mot de passe oublié ?</button>
        </div>
      </div>
    </div>

    {/* Inputs */}
    <div className="ds-section">
      <h2>Inputs</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        <div>
          <label className="field-label">Texte</label>
          <input className="input" placeholder="vous@exemple.com"/>
        </div>
        <div>
          <label className="field-label">Avec icône</label>
          <div className="input-wrap">
            <span className="input-icon"><Icon.Mail size={16}/></span>
            <input className="input with-icon-left" placeholder="vous@exemple.com"/>
          </div>
        </div>
        <div>
          <label className="field-label">Password</label>
          <div className="input-wrap">
            <span className="input-icon"><Icon.Lock size={16}/></span>
            <input className="input with-icon-left with-icon-right" type="password" placeholder="••••••••"/>
            <button className="input-icon-right"><Icon.Eye size={16}/></button>
          </div>
        </div>
        <div>
          <label className="field-label">Select</label>
          <div className="input-wrap">
            <input className="input with-icon-right" defaultValue="MWL" readOnly/>
            <span className="input-icon-right"><Icon.ChevronDown size={16}/></span>
          </div>
        </div>
      </div>
    </div>

    {/* Cards */}
    <div className="ds-section">
      <h2>Cartes</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
        <div className="card">
          <div className="label" style={{ marginBottom: 8 }}>CARTE SIMPLE</div>
          <div className="h3">Titre de carte</div>
          <p className="caption" style={{ margin: '4px 0 0' }}>16px radius · 0.5px border · padding 20</p>
        </div>
        <div className="card-video" style={{ minHeight: 130 }}>
          <video autoPlay muted loop playsInline poster="media/01_fallback.png">
            <source src="media/01.mp4" type="video/mp4"/>
          </video>
          <div className="video-overlay-light-85"/>
          <div className="video-content" style={{ padding: 20 }}>
            <div className="label">CARTE AVEC VIDÉO</div>
            <p className="body italic" style={{ margin: '8px 0 0' }}>"Texte sombre par-dessus overlay light 85%."</p>
          </div>
        </div>
      </div>
    </div>

    {/* Badges & chips */}
    <div className="ds-section">
      <h2>Badges & Chips</h2>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap' }}>
        <span className="badge-system">Système</span>
        <span className="badge-level"><Icon.Star size={11} stroke="var(--accent)"/> Aspirant · Niveau 2</span>
        <span className="chip"><span className="dot" style={{ background: 'var(--cat-religion)' }}/> Religion</span>
        <span className="chip active"><span className="dot" style={{ background: 'var(--cat-sport)' }}/> Sport · actif</span>
        <span className="dot-status s-ontime"/>
        <span className="dot-status s-late"/>
        <span className="dot-status s-missed"/>
        <span className="dot-status s-pending"/>
      </div>
    </div>

    {/* Bottom nav + Headers */}
    <div className="ds-section">
      <h2>Bottom Nav · Headers</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        <div style={{ position: 'relative', height: 100, background: 'var(--bg-primary)', borderRadius: 16, overflow: 'hidden', border: '0.5px solid var(--border-default)' }}>
          <div style={{ position: 'absolute', inset: 0 }}><BottomNav active="home"/></div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ background: 'var(--bg-primary)', borderRadius: 12, overflow: 'hidden', border: '0.5px solid var(--border-default)' }}>
            <HeaderTitle title="Mes Habitudes" action={<button className="btn-icon"><Icon.Plus size={18} stroke="var(--accent)"/></button>}/>
          </div>
          <div style={{ background: 'var(--bg-primary)', borderRadius: 12, overflow: 'hidden', border: '0.5px solid var(--border-default)' }}>
            <HeaderBack title="Nouvelle habitude"/>
          </div>
        </div>
      </div>
    </div>

    {/* Spacing/Radii */}
    <div className="ds-section">
      <h2>Espacement · Rayons · Iconographie</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 28 }}>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>ESPACEMENT (4px grid)</div>
          {[['1',4],['2',8],['3',12],['4',16],['5',20],['6',24],['8',32]].map(([n, v]) => (
            <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 6 }}>
              <span className="mono caption" style={{ width: 24 }}>{n}</span>
              <div style={{ background: 'var(--accent)', height: 8, width: v, borderRadius: 2 }}/>
              <span className="caption mono">{v}px</span>
            </div>
          ))}
        </div>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>RAYONS</div>
          {[['chip',6],['button',10],['card',16],['pill',100]].map(([n, v]) => (
            <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
              <div style={{ width: 56, height: 32, background: 'var(--accent-light)', borderRadius: v, border: '0.5px solid var(--accent-border)' }}/>
              <span className="caption">{n} · {v}px</span>
            </div>
          ))}
        </div>
        <div>
          <div className="caption" style={{ marginBottom: 8 }}>ICÔNES (Lucide · 1.5px)</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 10 }}>
            {[Icon.Home, Icon.Compass, Icon.Activity, Icon.Layers, Icon.Trophy, Icon.Bell,
              Icon.Sun, Icon.Moon, Icon.Calendar, Icon.Star, Icon.Heart, Icon.Book].map((Ic, i) => (
              <div key={i} style={{
                aspectRatio: 1, background: 'var(--bg-surface)',
                border: '0.5px solid var(--border-default)', borderRadius: 8,
                display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)'
              }}><Ic size={20}/></div>
            ))}
          </div>
        </div>
      </div>
    </div>
  </div>
);

window.DSPanel = DSPanel;
