// Murabbi Extras — In-app empty/celebration moments + App Icon variations

// ── In-app celebration / streak / level-up screens (iOS frame) ────────────

function InAppStreakDay7({ width = 360 }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow:'hidden', position:'relative', background: M.bgPrimary, fontFamily: M.fontSans, color: M.textPrimary }}>
      <IOSStatusBar/>
      <div style={{ padding: '0 24px', display:'flex', alignItems:'center', justifyContent:'space-between', height: 44 }}>
        <Icon name="x" size={20} color={M.textSecondary}/>
        <span style={{ fontSize: 12, color: M.textTertiary, fontFamily: M.fontMono, letterSpacing: 0.6 }}>STREAK</span>
        <Icon name="more-horizontal" size={20} color={M.textSecondary}/>
      </div>
      <div style={{ padding: '36px 32px 0', textAlign:'center' }}>
        <div style={{ display:'flex', justifyContent:'center', marginBottom: 24 }}>
          <div style={{ width: 96, height: 96, borderRadius: 999, background: M.accentLight, display:'flex', alignItems:'center', justifyContent:'center', border: `1px solid ${M.accentBorder}` }}>
            <Icon name="flame" size={42} color={M.accent} stroke={1.4}/>
          </div>
        </div>
        <div style={{ fontFamily: M.fontMono, fontSize: 11, color: M.textTertiary, letterSpacing: 1.4, textTransform:'uppercase', fontWeight: 500, marginBottom: 12 }}>7 jours consécutifs</div>
        <h1 style={{ fontFamily: M.fontSans, fontSize: 28, fontWeight: 500, letterSpacing: -0.5, lineHeight: 1.15, margin: 0, marginBottom: 12 }}>Une semaine ancrée.</h1>
        <p style={{ fontSize: 14, color: M.textSecondary, lineHeight: 1.55, margin: 0 }}>
          Sept jours sans rupture. Continuez à votre rythme — la régularité compte plus que l'intensité.
        </p>
      </div>
      <div style={{ position:'absolute', bottom: 36, left: 24, right: 24 }}>
        <div style={{ background: M.bgSurface, border: `0.5px solid ${M.borderDefault}`, borderRadius: 14, padding: '14px 16px', marginBottom: 14 }}>
          <div style={{ fontSize: 10, color: M.textTertiary, fontFamily: M.fontMono, letterSpacing: 0.6, textTransform:'uppercase', marginBottom: 8, fontWeight: 500 }}>7 derniers jours</div>
          <div style={{ display:'flex', gap: 6, alignItems:'center' }}>
            {['L','M','M','J','V','S','D'].map((d, i) => (
              <div key={i} style={{ flex: 1, textAlign:'center' }}>
                <div style={{ fontFamily: M.fontMono, fontSize: 9, color: M.textTertiary, marginBottom: 4 }}>{d}</div>
                <div style={{ width: 20, height: 20, borderRadius: 999, background: M.success, margin:'0 auto', display:'flex', alignItems:'center', justifyContent:'center' }}>
                  <Icon name="check" size={11} color="#fff" stroke={2.5}/>
                </div>
              </div>
            ))}
          </div>
        </div>
        <button style={{ width: '100%', padding: '14px', background: M.textPrimary, color: M.textOnDark, border:'none', borderRadius: 999, fontFamily: M.fontSans, fontSize: 14, fontWeight: 500, cursor:'pointer' }}>Continuer</button>
      </div>
    </div>
  );
}

function InAppLevelUp({ width = 360 }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow:'hidden', position:'relative', background:'#1C1A16', fontFamily: M.fontSans, color: '#fff' }}>
      <Wallpaper tone="dusk" style={{ opacity: 0.85 }}/>
      <div style={{ position:'relative', height: '100%', display:'flex', flexDirection:'column' }}>
        <IOSStatusBar dark/>
        <div style={{ padding: '0 24px', display:'flex', alignItems:'center', justifyContent:'space-between', height: 44 }}>
          <Icon name="x" size={20} color="rgba(255,255,255,0.7)"/>
          <span style={{ fontSize: 12, color:'rgba(255,255,255,0.6)', fontFamily: M.fontMono, letterSpacing: 0.6 }}>NIVEAU</span>
          <span style={{ width: 20 }}/>
        </div>
        <div style={{ flex: 1, padding: '36px 32px 0', textAlign:'center' }}>
          <div style={{ fontFamily: M.fontMono, fontSize: 11, letterSpacing: 1.4, textTransform:'uppercase', opacity: 0.6, marginBottom: 16 }}>Niveau 1 sur 5</div>
          <div style={{ display:'flex', justifyContent:'center', marginBottom: 24 }}>
            <div style={{ width: 120, height: 120, borderRadius: 999, border: '1.5px solid rgba(255,255,255,0.30)', display:'flex', alignItems:'center', justifyContent:'center' }}>
              <MurabbiGlyph size={64} color="#fff" stroke={1.2}/>
            </div>
          </div>
          <h1 style={{ fontSize: 32, fontWeight: 400, letterSpacing: -0.6, lineHeight: 1.1, margin: 0, marginBottom: 8 }}>Murid</h1>
          <p style={{ fontSize: 13, opacity: 0.75, lineHeight: 1.55, margin: 0, fontStyle:'italic' }}>« le disciple »</p>
          <p style={{ fontSize: 14, opacity: 0.85, lineHeight: 1.6, margin: '20px auto 0', maxWidth: 280 }}>
            Vous avez fait le premier pas, et vous l'avez tenu. C'est ici que la route commence.
          </p>
        </div>
        <div style={{ padding: '24px 24px 36px' }}>
          <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: 8, fontSize: 11, opacity: 0.7 }}>
            <span>Murid</span>
            <span style={{ fontFamily: M.fontMono }}>120 / 500 pts</span>
            <span>Salik</span>
          </div>
          <div style={{ height: 4, borderRadius: 2, background:'rgba(255,255,255,0.15)', overflow:'hidden', marginBottom: 16 }}>
            <div style={{ width:'24%', height:'100%', background:'#fff' }}/>
          </div>
          <button style={{ width: '100%', padding: '14px', background:'#fff', color: M.textPrimary, border:'none', borderRadius: 999, fontFamily: M.fontSans, fontSize: 14, fontWeight: 500, cursor:'pointer' }}>Continuer</button>
        </div>
      </div>
    </div>
  );
}

function InAppEmptyState({ width = 360 }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow:'hidden', position:'relative', background: M.bgPrimary, fontFamily: M.fontSans, color: M.textPrimary }}>
      <IOSStatusBar/>
      <div style={{ padding: '0 24px', display:'flex', alignItems:'center', justifyContent:'space-between', height: 44 }}>
        <Icon name="chevron-right" size={20} color={M.textSecondary} style={{ transform:'rotate(180deg)' }}/>
        <span style={{ fontSize: 15, fontWeight: 500 }}>Mes habitudes</span>
        <Icon name="plus" size={20} color={M.textSecondary}/>
      </div>
      <div style={{ flex: 1, padding: '60px 36px 0', textAlign:'center' }}>
        <div style={{ display:'flex', justifyContent:'center', marginBottom: 28 }}>
          <div style={{ width: 88, height: 88, borderRadius: 999, background: M.bgSurface, border: `0.5px dashed ${M.borderEmphasis}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Icon name="bookmark" size={32} color={M.textTertiary} stroke={1.4}/>
          </div>
        </div>
        <h2 style={{ fontSize: 20, fontWeight: 500, letterSpacing: -0.3, margin: 0, marginBottom: 10 }}>Rien encore.</h2>
        <p style={{ fontSize: 13, color: M.textSecondary, lineHeight: 1.6, margin: 0, maxWidth: 260, marginInline:'auto' }}>
          Choisissez une collection pour démarrer, ou créez une habitude sur mesure. On commence petit.
        </p>
      </div>
      <div style={{ position:'absolute', bottom: 36, left: 24, right: 24, display:'flex', flexDirection:'column', gap: 10 }}>
        <button style={{ padding: '14px', background: M.textPrimary, color: M.textOnDark, border:'none', borderRadius: 999, fontFamily: M.fontSans, fontSize: 14, fontWeight: 500, cursor:'pointer' }}>Parcourir les collections</button>
        <button style={{ padding: '14px', background:'transparent', color: M.textPrimary, border: `0.5px solid ${M.borderEmphasis}`, borderRadius: 999, fontFamily: M.fontSans, fontSize: 14, fontWeight: 500, cursor:'pointer' }}>Créer une habitude</button>
      </div>
    </div>
  );
}

function InAppDayDone({ width = 360 }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow:'hidden', position:'relative', background: M.bgPrimary, fontFamily: M.fontSans, color: M.textPrimary }}>
      <IOSStatusBar/>
      <div style={{ padding: '0 24px', display:'flex', alignItems:'center', justifyContent:'space-between', height: 44 }}>
        <span style={{ fontSize: 11, fontFamily: M.fontMono, color: M.textTertiary, letterSpacing: 0.6, textTransform:'uppercase' }}>JEU 23 AVR</span>
        <Icon name="more-horizontal" size={20} color={M.textSecondary}/>
      </div>
      <div style={{ padding: '40px 32px 0', textAlign:'center' }}>
        <div style={{ display:'flex', justifyContent:'center', marginBottom: 20 }}>
          <div style={{ width: 76, height: 76, borderRadius: 999, background: M.success, display:'flex', alignItems:'center', justifyContent:'center', boxShadow: '0 8px 24px rgba(107,140,107,0.30)' }}>
            <Icon name="check" size={36} color="#fff" stroke={2.2}/>
          </div>
        </div>
        <div style={{ fontFamily: M.fontMono, fontSize: 11, color: M.success, letterSpacing: 1.2, textTransform:'uppercase', fontWeight: 500, marginBottom: 10 }}>Journée complète</div>
        <h1 style={{ fontSize: 26, fontWeight: 500, letterSpacing: -0.4, lineHeight: 1.15, margin: 0, marginBottom: 12 }}>Tout est validé.</h1>
        <p style={{ fontSize: 14, color: M.textSecondary, lineHeight: 1.55, margin: 0 }}>
          5 prières · 9 habitudes · à l'heure. Reposez-vous.
        </p>
      </div>
      <div style={{ position:'absolute', bottom: 100, left: 24, right: 24, background: M.bgSurface, border: `0.5px solid ${M.borderDefault}`, borderRadius: 16, padding: 16 }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom: 12 }}>
          <span style={{ fontSize: 13, fontWeight: 500 }}>Score du jour</span>
          <span style={{ fontFamily: M.fontMono, fontSize: 18, fontWeight: 500 }}>100 pts</span>
        </div>
        <div style={{ display:'flex', gap: 4 }}>
          {Array.from({ length: 14 }).map((_, i) => (
            <div key={i} style={{ flex: 1, height: 4, borderRadius: 2, background: M.success }}/>
          ))}
        </div>
        <div style={{ display:'flex', justifyContent:'space-between', marginTop: 10, fontSize: 11, color: M.textTertiary }}>
          <span>Salik · 320 pts</span>
          <span style={{ fontFamily: M.fontMono }}>14j de suite</span>
        </div>
      </div>
      <div style={{ position:'absolute', bottom: 36, left: 24, right: 24 }}>
        <button style={{ width:'100%', padding: '14px', background:'transparent', color: M.textPrimary, border: `0.5px solid ${M.borderEmphasis}`, borderRadius: 999, fontFamily: M.fontSans, fontSize: 14, fontWeight: 500, cursor:'pointer' }}>Voir le récap</button>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// App Icons — variations + on-grid context
// ──────────────────────────────────────────────────────────────────────────

function AppIconShowcase({ size = 88, label, sub, variant }) {
  return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap: 10 }}>
      <AppIconMurabbi size={size} variant={variant}/>
      <div style={{ textAlign:'center' }}>
        <div style={{ fontSize: 12, fontWeight: 500, color: M.textPrimary, fontFamily: M.fontSans }}>{label}</div>
        <div style={{ fontSize: 10, color: M.textTertiary, fontFamily: M.fontMono, letterSpacing: 0.4, marginTop: 2 }}>{sub}</div>
      </div>
    </div>
  );
}

function AppIconOnHome({ width = 360, tone = 'morning' }) {
  // Show the Murabbi icon among others on a real iOS home grid
  const icons = [
    { fauxColor:'#34C759', glyph:'✓' },
    { murabbi: true },
    { fauxColor:'#5856D6', glyph:'M' },
    { fauxColor:'#FF9500', glyph:'P' },
    { fauxColor:'#007AFF', glyph:'S' },
    { fauxColor:'#FF2D55', glyph:'♥' },
    { fauxColor:'#5AC8FA', glyph:'☁' },
    { fauxColor:'#AF52DE', glyph:'A' },
  ];
  return (
    <div style={{ width, height: 480, borderRadius: width * 0.115 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone={tone}/>
      <div style={{ position:'relative', height:'100%', display:'flex', flexDirection:'column' }}>
        <IOSStatusBar dark/>
        <div style={{ padding: '14px 22px 0', flex: 1, display:'grid', gridTemplateColumns:'repeat(4, 1fr)', gridAutoRows: 'min-content', gap: 18, justifyItems:'center' }}>
          {icons.map((it, i) => (
            <div key={i} style={{ textAlign:'center' }}>
              {it.murabbi ? <AppIconMurabbi size={56} variant="light"/> : <FauxAppIcon size={56} color={it.fauxColor} glyph={it.glyph}/>}
              <div style={{ fontSize: 10, color:'#fff', marginTop: 6, fontFamily:'SF Pro Text, system-ui', textShadow:'0 1px 2px rgba(0,0,0,0.4)' }}>{it.murabbi ? 'Murabbi' : ''}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  InAppStreakDay7, InAppLevelUp, InAppEmptyState, InAppDayDone,
  AppIconShowcase, AppIconOnHome,
});
