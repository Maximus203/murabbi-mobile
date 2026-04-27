// Murabbi Extras — Home screen widgets · iOS (9) + Android (4)

// ── Base widget shell ─────────────────────────────────────────────────────
function WidgetShell({ size = 'small', children, dark = false, accent = false, style }) {
  const dims = {
    small:   { w: 158, h: 158 },
    medium:  { w: 338, h: 158 },
    large:   { w: 338, h: 354 },
  };
  const d = dims[size];
  const bg = dark ? '#1C1A16' : accent ? M.accent : M.bgSurface;
  const fg = dark || accent ? M.textOnDark : M.textPrimary;
  return (
    <div style={{
      width: d.w, height: d.h, borderRadius: 22,
      background: bg, color: fg,
      padding: 16, fontFamily: M.fontSans,
      boxShadow: '0 4px 14px rgba(28,26,22,0.10), 0 1px 2px rgba(28,26,22,0.06)',
      position: 'relative', overflow: 'hidden',
      ...style,
    }}>
      {children}
    </div>
  );
}

// ── Header inside a widget ────────────────────────────────────────────────
function WidgetHeader({ kicker, dark, accent }) {
  const c = dark || accent ? 'rgba(253,251,248,0.65)' : M.textTertiary;
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <span style={{ fontSize: 9, fontWeight: 500, letterSpacing: 1.2, textTransform: 'uppercase', color: c, fontFamily: M.fontSans }}>{kicker}</span>
      <MurabbiGlyph size={12} color={c} stroke={1.6}/>
    </div>
  );
}

// ── Progress ring (used in B1, B7) ────────────────────────────────────────
function Ring({ pct = 0.42, size = 64, stroke = 4, color = M.accent, track = 'rgba(0,0,0,0.08)', label }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <div style={{ width: size, height: size, position: 'relative' }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={track} strokeWidth={stroke}/>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={stroke}
          strokeLinecap="round" strokeDasharray={`${c*pct} ${c}`}/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: M.fontMono, fontSize: size*0.22, fontWeight: 500 }}>{label}</div>
    </div>
  );
}

// ── 7-day dots ───────────────────────────────────────────────────────────
function DotRow({ days = ['v','v','v','v','v','o','p'], dark }) {
  // v = validé, o = en retard, m = manqué, p = pending
  const colorOf = (k) => {
    if (k === 'v') return M.success;
    if (k === 'o') return M.warning;
    if (k === 'm') return M.danger;
    return dark ? 'rgba(255,255,255,0.18)' : 'rgba(28,26,22,0.10)';
  };
  return (
    <div style={{ display:'flex', gap: 6, alignItems:'center' }}>
      {days.map((d, i) => (
        <div key={i} style={{ width: 8, height: 8, borderRadius: 999, background: colorOf(d) }}/>
      ))}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// iOS — 9 widgets
// ──────────────────────────────────────────────────────────────────────────

function WidgetB1() {
  return (
    <WidgetShell size="small">
      <WidgetHeader kicker="Aujourd'hui"/>
      <div style={{ height: '100%', display:'flex', flexDirection:'column', justifyContent:'space-between', paddingTop: 4 }}>
        <div style={{ display:'flex', justifyContent:'center', marginTop: 8 }}>
          <Ring pct={0.42} size={84} stroke={4} color={M.accent} label="42%"/>
        </div>
        <div>
          <div style={{ fontFamily: M.fontMono, fontSize: 22, fontWeight: 500, color: M.textPrimary, lineHeight:1 }}>42 pts</div>
          <div style={{ fontSize: 10, color: M.textTertiary, fontFamily: M.fontSans, fontWeight: 500, letterSpacing: 0.6, textTransform: 'uppercase', marginTop: 4 }}>aujourd'hui</div>
        </div>
      </div>
    </WidgetShell>
  );
}

function WidgetB2() {
  return (
    <WidgetShell size="small">
      <div style={{ display:'flex', alignItems:'flex-start', justifyContent:'space-between' }}>
        <span style={{ fontSize: 9, fontWeight: 500, letterSpacing: 1.2, textTransform: 'uppercase', color: M.textTertiary }}>Prochaine prière</span>
        <Icon name="sun" size={14} color={M.warning}/>
      </div>
      <div style={{ marginTop: 10 }}>
        <div style={{ fontFamily: M.fontArabic, fontSize: 28, fontWeight: 500, lineHeight: 1, color: M.textPrimary }}>العصر</div>
        <div style={{ fontSize: 12, color: M.textSecondary, marginTop: 4, fontWeight: 500 }}>Asr</div>
      </div>
      <div style={{ position: 'absolute', bottom: 16, left: 16, right: 16 }}>
        <div style={{ fontFamily: M.fontMono, fontSize: 22, fontWeight: 500, color: M.textPrimary, lineHeight: 1 }}>16:32</div>
        <div style={{ fontSize: 10, color: M.textTertiary, marginTop: 4, fontWeight: 500, letterSpacing: 0.4 }}>dans 1 h 23</div>
      </div>
    </WidgetShell>
  );
}

function WidgetB3() {
  return (
    <WidgetShell size="small">
      <WidgetHeader kicker="Streak"/>
      <div style={{ marginTop: 12 }}>
        <div style={{ display:'flex', alignItems:'baseline', gap: 6 }}>
          <span style={{ fontFamily: M.fontMono, fontSize: 44, fontWeight: 500, color: M.textPrimary, lineHeight: 1 }}>14</span>
          <span style={{ fontSize: 13, color: M.textSecondary, fontWeight: 500 }}>j</span>
        </div>
        <div style={{ fontSize: 10, color: M.textTertiary, marginTop: 4, fontWeight: 500, letterSpacing: 0.6, textTransform: 'uppercase' }}>jours de suite</div>
      </div>
      <div style={{ position:'absolute', bottom: 16, left: 16, right: 16 }}>
        <div style={{ fontSize: 9, color: M.textTertiary, fontWeight: 500, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 6 }}>7 derniers</div>
        <DotRow days={['v','v','v','v','v','o','v']}/>
      </div>
    </WidgetShell>
  );
}

function WidgetB4() {
  return (
    <WidgetShell size="medium">
      <WidgetHeader kicker="Aujourd'hui · jeudi 23 avril"/>
      <div style={{ marginTop: 14, display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 14, alignItems:'center' }}>
        <div style={{ display:'flex', flexDirection:'column', alignItems:'flex-start', gap: 6 }}>
          <Ring pct={0.42} size={56} stroke={4} color={M.accent} label="42%"/>
          <div style={{ fontFamily: M.fontMono, fontSize: 13, fontWeight: 500 }}>42 pts</div>
        </div>
        <div>
          <div style={{ fontSize: 9, color: M.textTertiary, letterSpacing: 0.8, textTransform: 'uppercase', fontWeight: 500, marginBottom: 4 }}>Prières</div>
          <div style={{ fontFamily: M.fontMono, fontSize: 22, fontWeight: 500, lineHeight: 1 }}>3<span style={{ color: M.textTertiary }}>/5</span></div>
          <div style={{ marginTop: 6 }}>
            <DotRow days={['v','v','o','p','p']}/>
          </div>
        </div>
        <div>
          <div style={{ fontSize: 9, color: M.textTertiary, letterSpacing: 0.8, textTransform: 'uppercase', fontWeight: 500, marginBottom: 4 }}>Habitudes</div>
          <div style={{ fontFamily: M.fontMono, fontSize: 22, fontWeight: 500, lineHeight: 1 }}>6<span style={{ color: M.textTertiary }}>/9</span></div>
          <div style={{ marginTop: 6 }}>
            <DotRow days={['v','v','v','v','v','v','o','p','p']}/>
          </div>
        </div>
      </div>
      <div style={{ position:'absolute', bottom: 0, left: 0, right: 0, padding: '10px 16px', borderTop: `0.5px solid ${M.borderDefault}`, display:'flex', alignItems:'center', justifyContent:'space-between', fontSize: 11 }}>
        <span style={{ color: M.textSecondary }}>Prochain : <span style={{ color: M.textPrimary, fontWeight: 500 }}>Asr</span></span>
        <span style={{ fontFamily: M.fontMono, color: M.textPrimary, fontWeight: 500 }}>dans 1 h 23</span>
      </div>
    </WidgetShell>
  );
}

function WidgetB5() {
  const items = [
    { time:'16:32', title:'Asr', sub:'à l\'heure jusqu\'à 16:47', icon:'sun' },
    { time:'17:00', title:'Lecture du Coran', sub:'20 min', icon:'book' },
    { time:'19:47', title:'Maghrib', sub:'plage à l\'heure', icon:'sunset' },
  ];
  return (
    <WidgetShell size="medium">
      <WidgetHeader kicker="À venir aujourd'hui"/>
      <div style={{ marginTop: 12, display:'flex', flexDirection:'column', gap: 10 }}>
        {items.map((it, i) => (
          <div key={i} style={{ display:'flex', alignItems:'center', gap: 10 }}>
            <span style={{ fontFamily: M.fontMono, fontSize: 12, fontWeight: 500, color: M.textPrimary, minWidth: 38 }}>{it.time}</span>
            <Icon name={it.icon} size={13} color={M.textSecondary}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: M.textPrimary, lineHeight: 1.2 }}>{it.title}</div>
              <div style={{ fontSize: 10, color: M.textTertiary, marginTop: 1 }}>{it.sub}</div>
            </div>
          </div>
        ))}
      </div>
    </WidgetShell>
  );
}

function WidgetB6() {
  const prayers = [
    { ar:'الفجر', fr:'Fajr', t:'05:14', s:'v' },
    { ar:'الظهر', fr:'Dhuhr', t:'13:08', s:'v' },
    { ar:'العصر', fr:'Asr', t:'16:32', s:'p', next: true },
    { ar:'المغرب', fr:'Maghrib', t:'19:47', s:'p' },
    { ar:'العشاء', fr:'Isha', t:'21:09', s:'p' },
  ];
  const colorOf = (k) => k==='v'?M.success:k==='o'?M.warning:k==='m'?M.danger:'rgba(28,26,22,0.10)';
  return (
    <WidgetShell size="medium">
      <WidgetHeader kicker="Salat · jeudi"/>
      <div style={{ marginTop: 14, display:'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 10 }}>
        {prayers.map((p, i) => (
          <div key={i} style={{ textAlign:'center', position: 'relative' }}>
            {p.next && <div style={{ position:'absolute', top: -8, left: '50%', transform: 'translateX(-50%)', width: 4, height: 4, background: M.accent, borderRadius: 999 }}/>}
            <div style={{ fontFamily: M.fontArabic, fontSize: 14, fontWeight: 500, color: p.next ? M.accent : M.textPrimary, lineHeight: 1 }}>{p.ar}</div>
            <div style={{ fontSize: 10, color: M.textSecondary, marginTop: 4, fontWeight: 500 }}>{p.fr}</div>
            <div style={{ fontFamily: M.fontMono, fontSize: 11, color: M.textTertiary, marginTop: 2 }}>{p.t}</div>
            <div style={{ width: 8, height: 8, borderRadius: 999, background: colorOf(p.s), margin: '6px auto 0' }}/>
          </div>
        ))}
      </div>
    </WidgetShell>
  );
}

function WidgetB7() {
  const habits = [
    { name:'Adhkar du matin', cat: M.catReligion, status:'v' },
    { name:'Lecture du Coran', cat: M.catReligion, status:'p' },
    { name:'30 min de marche', cat: M.catSport, status:'v' },
    { name:'Verre d\'eau', cat: M.catSante, status:'v' },
  ];
  const colorOf = (k) => k==='v'?M.success:k==='p'?'rgba(28,26,22,0.10)':k==='o'?M.warning:M.danger;
  return (
    <WidgetShell size="large">
      <div style={{ display:'flex', alignItems:'flex-start', justifyContent:'space-between' }}>
        <div>
          <div style={{ fontSize: 9, fontWeight: 500, letterSpacing: 1.2, textTransform: 'uppercase', color: M.textTertiary }}>Jeudi 23 avril</div>
          <div style={{ display:'flex', alignItems:'baseline', gap: 8, marginTop: 4 }}>
            <span style={{ fontFamily: M.fontMono, fontSize: 28, fontWeight: 500, color: M.textPrimary, lineHeight: 1 }}>42</span>
            <span style={{ fontSize: 11, color: M.textSecondary, fontWeight: 500 }}>pts · niveau Murid</span>
          </div>
        </div>
        <Ring pct={0.42} size={48} stroke={3.5} color={M.accent} label="42%"/>
      </div>

      <div style={{ marginTop: 16, paddingTop: 14, borderTop: `0.5px solid ${M.borderDefault}` }}>
        <div style={{ fontSize: 9, fontWeight: 500, letterSpacing: 1.2, textTransform: 'uppercase', color: M.textTertiary, marginBottom: 10 }}>Salat</div>
        <div style={{ display:'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 8 }}>
          {[
            { ar:'الفجر', fr:'Fajr', s:'v' },
            { ar:'الظهر', fr:'Dhuhr', s:'v' },
            { ar:'العصر', fr:'Asr', s:'p', next: true },
            { ar:'المغرب', fr:'Maghrib', s:'p' },
            { ar:'العشاء', fr:'Isha', s:'p' },
          ].map((p, i) => (
            <div key={i} style={{ background: M.bgPrimary, borderRadius: 10, padding: '8px 4px', textAlign:'center', position:'relative', border: p.next ? `0.5px solid ${M.accentBorder}` : '0.5px solid transparent' }}>
              <div style={{ fontFamily: M.fontArabic, fontSize: 13, fontWeight: 500, color: M.textPrimary, lineHeight: 1 }}>{p.ar}</div>
              <div style={{ fontSize: 9, color: M.textSecondary, marginTop: 3, fontWeight: 500 }}>{p.fr}</div>
              <div style={{ width: 6, height: 6, borderRadius: 999, background: colorOf(p.s), margin: '5px auto 0' }}/>
            </div>
          ))}
        </div>
      </div>

      <div style={{ marginTop: 14, paddingTop: 12, borderTop: `0.5px solid ${M.borderDefault}` }}>
        <div style={{ fontSize: 9, fontWeight: 500, letterSpacing: 1.2, textTransform: 'uppercase', color: M.textTertiary, marginBottom: 8 }}>Habitudes</div>
        <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
          {habits.map((h, i) => (
            <div key={i} style={{ display:'flex', alignItems:'center', gap: 8 }}>
              <div style={{ width: 6, height: 6, borderRadius: 999, background: h.cat }}/>
              <span style={{ flex:1, fontSize: 11, fontWeight: 500, color: M.textPrimary }}>{h.name}</span>
              <div style={{ width: 14, height: 14, borderRadius: 999, background: h.status==='v'?M.success:'transparent', border: h.status==='v'?'none':`1px solid ${M.borderEmphasis}`, display:'inline-flex', alignItems:'center', justifyContent:'center' }}>
                {h.status==='v' && <Icon name="check" size={9} color="#fff" stroke={2.6}/>}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ position:'absolute', bottom: 0, left: 0, right: 0, padding: '10px 16px', borderTop: `0.5px solid ${M.borderDefault}`, display:'flex', alignItems:'center', justifyContent:'space-between', fontSize: 10 }}>
        <span style={{ color: M.textTertiary, fontWeight: 500, letterSpacing: 0.6, textTransform: 'uppercase' }}>Streak</span>
        <span style={{ fontFamily: M.fontMono, color: M.textPrimary, fontWeight: 500 }}>14 jours</span>
      </div>
    </WidgetShell>
  );
}

function WidgetB8() {
  const days = Array.from({ length: 30 }, (_, i) => {
    const r = (i * 17) % 13;
    if (i >= 22) return 'p';
    if (r < 9) return 'v';
    if (r < 11) return 'o';
    return 'm';
  });
  const colorOf = (k) => k==='v'?M.success:k==='o'?M.warning:k==='m'?M.danger:'rgba(28,26,22,0.06)';
  return (
    <WidgetShell size="large">
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between' }}>
        <div>
          <div style={{ fontSize: 9, fontWeight: 500, letterSpacing: 1.2, textTransform: 'uppercase', color: M.textTertiary }}>Avril 2026</div>
          <div style={{ fontSize: 13, color: M.textPrimary, fontWeight: 500, marginTop: 4 }}>23 jours · 84 % à l'heure</div>
        </div>
        <MurabbiGlyph size={14} color={M.textTertiary}/>
      </div>
      <div style={{ marginTop: 16, display:'grid', gridTemplateColumns:'repeat(7, 1fr)', gap: 6 }}>
        {['L','M','M','J','V','S','D'].map((d, i) => (
          <div key={i} style={{ fontSize: 9, color: M.textTertiary, fontFamily: M.fontMono, textAlign:'center', fontWeight: 500 }}>{d}</div>
        ))}
        {/* Padding for the 1st of the month (Wednesday) */}
        {[0,1].map(i => <div key={`pad-${i}`}/>)}
        {days.map((s, i) => (
          <div key={i} style={{ aspectRatio:'1', borderRadius: 6, background: colorOf(s), display:'flex', alignItems:'flex-start', justifyContent:'flex-start', padding: '4px 5px', fontSize: 9, color: s==='p' ? M.textTertiary : 'rgba(255,255,255,0.85)', fontFamily: M.fontMono, fontWeight: 500 }}>{i+1}</div>
        ))}
      </div>
      <div style={{ position:'absolute', bottom: 16, left: 16, right: 16, display:'flex', alignItems:'center', justifyContent:'flex-end', gap: 10, fontSize: 9, color: M.textTertiary }}>
        <Legend dot={M.success} label="à l'heure"/>
        <Legend dot={M.warning} label="en retard"/>
        <Legend dot={M.danger} label="manquée"/>
      </div>
    </WidgetShell>
  );
}

function Legend({ dot, label }) {
  return (
    <span style={{ display:'inline-flex', alignItems:'center', gap: 4 }}>
      <span style={{ width: 6, height: 6, borderRadius: 999, background: dot }}/>
      <span style={{ fontFamily: M.fontSans, fontWeight: 500 }}>{label}</span>
    </span>
  );
}

function WidgetB9() {
  // iOS Add Widget picker — Murabbi entry
  return (
    <div style={{ width: 360, height: 540, borderRadius: 26, background: 'rgba(28,26,22,0.85)', backdropFilter:'blur(40px)', WebkitBackdropFilter:'blur(40px)', overflow:'hidden', color:'#fff', fontFamily: M.fontSans, position: 'relative' }}>
      <div style={{ padding: '16px 20px 12px', display:'flex', alignItems:'center', gap: 10, borderBottom: '0.5px solid rgba(255,255,255,0.10)' }}>
        <Icon name="chevron-right" size={16} color="rgba(255,255,255,0.6)" style={{ transform:'rotate(180deg)' }}/>
        <div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.55)' }}>Apps · </div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>Murabbi</div>
        </div>
        <div style={{ marginLeft:'auto' }}>
          <AppIconMurabbi size={32} variant="dark"/>
        </div>
      </div>
      <div style={{ padding: 20, overflow:'hidden' }}>
        <div style={{ fontSize: 14, color:'rgba(255,255,255,0.7)', textAlign:'center', marginBottom: 16 }}>Score du jour</div>
        <div style={{ display:'flex', justifyContent:'center', marginBottom: 14 }}>
          <WidgetB1/>
        </div>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'center', gap: 6, marginBottom: 18 }}>
          {[true, false, false, false, false, false, false, false].map((a, i) => (
            <div key={i} style={{ width: 6, height: 6, borderRadius: 999, background: a ? '#fff' : 'rgba(255,255,255,0.30)' }}/>
          ))}
        </div>
        <div style={{ background:'rgba(255,255,255,0.15)', borderRadius: 12, padding: '14px 16px', display:'flex', alignItems:'center', justifyContent:'center' }}>
          <span style={{ fontSize: 16, fontWeight: 500, color:'#fff' }}>+ Ajouter le widget</span>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Android — 4 widgets (Material 3 with Murabbi sand palette)
// ──────────────────────────────────────────────────────────────────────────

function AndroidWidgetShell({ size = 'small', children }) {
  const dims = {
    small:  { w: 158, h: 158 },
    medium: { w: 338, h: 158 },
    large:  { w: 338, h: 354 },
  };
  const d = dims[size];
  return (
    <div style={{
      width: d.w, height: d.h, borderRadius: 28,
      background: M.bgSurface, color: M.textPrimary,
      padding: 16, fontFamily: M.fontSans,
      boxShadow: '0 4px 14px rgba(28,26,22,0.10), 0 1px 2px rgba(28,26,22,0.06)',
      position: 'relative', overflow: 'hidden',
      border: '0.5px solid rgba(28,26,22,0.06)',
    }}>
      {children}
    </div>
  );
}

function WidgetC1() {
  return (
    <AndroidWidgetShell size="small">
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <span style={{ fontSize: 10, color: M.textTertiary, fontWeight: 500, letterSpacing: 0.6, textTransform:'uppercase' }}>Aujourd'hui</span>
        <MurabbiGlyph size={12} color={M.textTertiary}/>
      </div>
      <div style={{ display:'flex', justifyContent:'center', marginTop: 8 }}>
        <Ring pct={0.42} size={84} stroke={4} color={M.accent} label="42%"/>
      </div>
      <div style={{ position:'absolute', bottom: 16, left: 16, right: 16 }}>
        <div style={{ fontFamily: M.fontMono, fontSize: 18, fontWeight: 500 }}>42 pts</div>
      </div>
    </AndroidWidgetShell>
  );
}

function WidgetC2() {
  return (
    <AndroidWidgetShell size="medium">
      <WidgetHeader kicker="Aujourd'hui · jeudi 23 avril"/>
      <div style={{ marginTop: 14, display:'grid', gridTemplateColumns:'1fr 1fr 1fr', gap: 14 }}>
        <div style={{ display:'flex', flexDirection:'column', gap: 6 }}>
          <Ring pct={0.42} size={56} stroke={4} color={M.accent} label="42%"/>
          <div style={{ fontFamily: M.fontMono, fontSize: 13, fontWeight: 500 }}>42 pts</div>
        </div>
        <div>
          <div style={{ fontSize: 9, color: M.textTertiary, letterSpacing: 0.8, textTransform:'uppercase', fontWeight: 500, marginBottom: 4 }}>Prières</div>
          <div style={{ fontFamily: M.fontMono, fontSize: 22, fontWeight: 500, lineHeight: 1 }}>3<span style={{ color: M.textTertiary }}>/5</span></div>
          <div style={{ marginTop: 6 }}><DotRow days={['v','v','o','p','p']}/></div>
        </div>
        <div>
          <div style={{ fontSize: 9, color: M.textTertiary, letterSpacing: 0.8, textTransform:'uppercase', fontWeight: 500, marginBottom: 4 }}>Habitudes</div>
          <div style={{ fontFamily: M.fontMono, fontSize: 22, fontWeight: 500, lineHeight: 1 }}>6<span style={{ color: M.textTertiary }}>/9</span></div>
          <div style={{ marginTop: 6 }}><DotRow days={['v','v','v','v','v','v','o','p','p']}/></div>
        </div>
      </div>
    </AndroidWidgetShell>
  );
}

function WidgetC3() {
  return (
    <AndroidWidgetShell size="large">
      <WidgetB7/>
    </AndroidWidgetShell>
  );
}

function WidgetC4() {
  // Pixel widget picker
  return (
    <div style={{ width: 360, height: 540, borderRadius: 32, background:'#1F1B16', overflow:'hidden', color:'#F2E9DA', fontFamily: M.fontSans, position:'relative', border:'0.5px solid rgba(255,255,255,0.06)' }}>
      <div style={{ padding:'16px 20px 12px', borderBottom:'0.5px solid rgba(255,255,255,0.08)', display:'flex', alignItems:'center', gap:12 }}>
        <AppIconMurabbi size={32} variant="dark"/>
        <div>
          <div style={{ fontSize: 16, fontWeight: 500 }}>Murabbi</div>
          <div style={{ fontSize: 11, color:'rgba(255,255,255,0.55)' }}>4 widgets disponibles</div>
        </div>
      </div>
      <div style={{ padding: 16, display:'grid', gridTemplateColumns:'1fr 1fr', gap: 12 }}>
        <div style={{ background:'rgba(255,255,255,0.04)', borderRadius: 16, padding: 10 }}>
          <div style={{ transform:'scale(0.7)', transformOrigin:'top left', height: 140, marginBottom: -50 }}><WidgetC1/></div>
          <div style={{ marginTop: 6, fontSize: 12, fontWeight: 500 }}>Score du jour</div>
          <div style={{ fontSize: 10, color:'rgba(255,255,255,0.55)' }}>2×2 · cercle de progression</div>
        </div>
        <div style={{ background:'rgba(255,255,255,0.04)', borderRadius: 16, padding: 10 }}>
          <div style={{ transform:'scale(0.4)', transformOrigin:'top left', height: 140, marginBottom: -55, width: 380 }}><WidgetC2/></div>
          <div style={{ marginTop: 6, fontSize: 12, fontWeight: 500 }}>Vue d'ensemble</div>
          <div style={{ fontSize: 10, color:'rgba(255,255,255,0.55)' }}>4×2 · prières + habitudes</div>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Home screen contexts (iOS / Pixel)
// ──────────────────────────────────────────────────────────────────────────

function IOSHomeContext({ children, width = 360, tone = 'morning' }) {
  // 4-column grid background, our widgets float on top
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone={tone}/>
      <div style={{ position:'relative', height: '100%', display:'flex', flexDirection:'column' }}>
        <IOSStatusBar dark/>
        <div style={{ padding: '14px 22px 0', flex: 1, display:'flex', flexDirection:'column', gap: 14 }}>
          {children}
        </div>
        {/* Dock */}
        <div style={{ margin: '0 14px 8px', padding: 10, background:'rgba(255,255,255,0.18)', backdropFilter:'blur(20px)', WebkitBackdropFilter:'blur(20px)', borderRadius: 26, display:'flex', justifyContent:'space-around' }}>
          <FauxAppIcon size={50} color="#34C759" glyph="✓"/>
          <FauxAppIcon size={50} color="#5856D6" glyph="M"/>
          <AppIconMurabbi size={50} variant="light"/>
          <FauxAppIcon size={50} color="#FF9500" glyph="P"/>
        </div>
        <div style={{ height: 18, display:'flex', justifyContent:'center', alignItems:'center' }}>
          <div style={{ width: 130, height: 4, background:'#fff', opacity: 0.8, borderRadius: 2 }}/>
        </div>
      </div>
    </div>
  );
}

function PixelHomeContext({ children, width = 360, tone = 'night' }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.085 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone={tone}/>
      <div style={{ position:'relative', height: '100%', display:'flex', flexDirection:'column' }}>
        <AndroidStatusBar dark/>
        {/* Search pill */}
        <div style={{ margin: '8px 16px 14px', padding: '10px 16px', background:'rgba(255,255,255,0.12)', backdropFilter:'blur(20px)', WebkitBackdropFilter:'blur(20px)', borderRadius: 999, display:'flex', alignItems:'center', gap: 10, color:'rgba(255,255,255,0.7)', fontSize: 13 }}>
          <Icon name="search" size={16} color="rgba(255,255,255,0.7)"/>
          <span style={{ fontFamily:'Roboto, sans-serif' }}>Rechercher</span>
        </div>
        <div style={{ padding: '0 14px', flex: 1, display:'flex', flexDirection:'column', gap: 14 }}>
          {children}
        </div>
        {/* Dock */}
        <div style={{ margin: '0 14px 14px', padding: '10px 0', display:'flex', justifyContent:'space-around' }}>
          <FauxAppIcon size={48} color="#34C759" glyph="✓" radius={999}/>
          <FauxAppIcon size={48} color="#FBBC04" glyph="G" radius={999}/>
          <AppIconMurabbi size={48} variant="light" radius={999}/>
          <FauxAppIcon size={48} color="#EA4335" glyph="M" radius={999}/>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  WidgetShell, WidgetHeader, Ring, DotRow, Legend, AndroidWidgetShell,
  WidgetB1, WidgetB2, WidgetB3, WidgetB4, WidgetB5, WidgetB6, WidgetB7, WidgetB8, WidgetB9,
  WidgetC1, WidgetC2, WidgetC3, WidgetC4,
  IOSHomeContext, PixelHomeContext,
});
