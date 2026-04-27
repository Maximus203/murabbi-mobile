// Murabbi Extras — Notifications (15) — iOS + Android

// Shared base notification card (iOS lock-screen style)
function IOSNotif({ title = 'Murabbi', subtitle, body, caption, icon, time = 'maintenant', dark = true, actions, expanded, image, style }) {
  return (
    <div style={{
      width: '100%', borderRadius: 18,
      background: dark ? 'rgba(28,26,22,0.55)' : 'rgba(253,251,248,0.92)',
      backdropFilter: 'blur(24px)', WebkitBackdropFilter: 'blur(24px)',
      border: `0.5px solid ${dark ? 'rgba(255,255,255,0.10)' : 'rgba(28,26,22,0.06)'}`,
      color: dark ? '#fff' : M.textPrimary,
      fontFamily: M.fontSans, overflow: 'hidden',
      ...style,
    }}>
      {image && (
        <div style={{ width: '100%', height: 110, background: image, position: 'relative' }}>
          <div style={{ position:'absolute', inset:0, background:'linear-gradient(180deg, rgba(0,0,0,0.0), rgba(0,0,0,0.45))' }}/>
        </div>
      )}
      <div style={{ padding: '12px 14px', display: 'flex', gap: 10, alignItems: 'flex-start' }}>
        <div style={{ marginTop: 1 }}>{icon || <AppIconMurabbi size={36} variant={dark ? 'dark' : 'light'}/>}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 1 }}>
            <span style={{ fontSize: 13, fontWeight: 600, letterSpacing: -0.1 }}>{title}</span>
            <span style={{ fontSize: 11, opacity: 0.65 }}>{time}</span>
          </div>
          {subtitle && <div style={{ fontSize: 13, fontWeight: 500, marginTop: 2, lineHeight: 1.3 }}>{subtitle}</div>}
          {body && <div style={{ fontSize: 13, lineHeight: 1.35, marginTop: 2, opacity: 0.92 }}>{body}</div>}
          {caption && <div style={{ fontSize: 12, marginTop: 4, opacity: 0.65 }}>{caption}</div>}
        </div>
      </div>
      {expanded}
      {actions && (
        <div style={{ display: 'flex', borderTop: `0.5px solid ${dark ? 'rgba(255,255,255,0.10)' : 'rgba(28,26,22,0.06)'}` }}>
          {actions.map((a, i) => (
            <button key={i} style={{
              flex: 1, padding: '11px 8px', background: 'transparent', border: 'none',
              borderLeft: i ? `0.5px solid ${dark ? 'rgba(255,255,255,0.10)' : 'rgba(28,26,22,0.06)'}` : 'none',
              color: a.color || (dark ? '#fff' : M.textPrimary),
              fontFamily: M.fontSans, fontSize: 13, fontWeight: a.bold ? 600 : 500, cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>
              {a.icon}{a.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// Pixel/Android notification card (Material 3)
function AndroidNotif({ title = 'Murabbi', body, caption, actions, time = 'maintenant', icon, image, style }) {
  return (
    <div style={{
      width: '100%', borderRadius: 28, background: '#1F1B16',
      color: '#F2E9DA', fontFamily: M.fontSans, overflow: 'hidden',
      border: '0.5px solid rgba(255,255,255,0.06)',
      ...style,
    }}>
      <div style={{ padding: '12px 16px 6px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 18, height: 18 }}>
          <MurabbiGlyph size={18} color="#D6C4A8" stroke={1.6}/>
        </div>
        <span style={{ fontSize: 12, fontWeight: 500, letterSpacing: 0.1 }}>Murabbi</span>
        <span style={{ fontSize: 12, opacity: 0.55 }}>· {time}</span>
      </div>
      <div style={{ padding: '0 16px 12px', display: 'flex', gap: 12, alignItems: 'flex-start' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 500, lineHeight: 1.3, marginBottom: 2 }}>{title}</div>
          {body && <div style={{ fontSize: 13, lineHeight: 1.4, opacity: 0.9 }}>{body}</div>}
          {caption && <div style={{ fontSize: 12, marginTop: 4, opacity: 0.6 }}>{caption}</div>}
        </div>
        {icon || <AppIconMurabbi size={40} variant="dark" radius={10}/>}
      </div>
      {image && <div style={{ height: 140, margin: '0 16px 12px', borderRadius: 16, background: image, backgroundSize:'cover', backgroundPosition:'center' }}/>}
      {actions && (
        <div style={{ display: 'flex', gap: 4, padding: '0 8px 10px' }}>
          {actions.map((a, i) => (
            <button key={i} style={{
              flex: 1, padding: '10px', background: 'transparent', border: 'none',
              color: a.color || '#D6C4A8', fontFamily: M.fontSans, fontSize: 13, fontWeight: 500,
              letterSpacing: 0.4, textTransform: 'uppercase', borderRadius: 999, cursor: 'pointer',
            }}>{a.label}</button>
          ))}
        </div>
      )}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Mockup contexts
// ──────────────────────────────────────────────────────────────────────────

function LockContextIOS({ children, tone = 'dusk', clockColor = '#fff', height = 720, width = 360 }) {
  return (
    <div style={{ width, height, borderRadius: width * 0.115 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone={tone}/>
      <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <IOSStatusBar dark/>
        <div style={{ padding: '8px 0 0', textAlign: 'center' }}>
          <IOSLockClock color={clockColor}/>
        </div>
        <div style={{ flex: 1, padding: '20px 12px 32px', display: 'flex', flexDirection: 'column', gap: 8, justifyContent: 'flex-end' }}>
          {children}
        </div>
        <div style={{ height: 18, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <div style={{ width: 130, height: 4, background: '#fff', opacity: 0.8, borderRadius: 2 }}/>
        </div>
      </div>
    </div>
  );
}

function BannerContextIOS({ children, tone = 'morning', width = 360 }) {
  // Shows a notif banner sliding from the top, on top of an in-app screen
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow: 'hidden', position: 'relative', background: M.bgPrimary }}>
      {/* Faux app screen behind (very simple Murabbi home) */}
      <FakeAppHome/>
      {/* Banner overlay */}
      <div style={{ position: 'absolute', top: 54, left: 8, right: 8, zIndex: 10 }}>
        {children}
      </div>
    </div>
  );
}

function FakeAppHome() {
  return (
    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', fontFamily: M.fontSans, color: M.textPrimary }}>
      <IOSStatusBar/>
      <div style={{ padding: '8px 24px 0', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <div>
          <div style={{ fontSize: 11, color: M.textTertiary, fontWeight: 500, letterSpacing: 0.6, textTransform:'uppercase' }}>Aujourd'hui</div>
          <div style={{ fontSize: 24, fontWeight: 500, marginTop: 4 }}>Cherif</div>
        </div>
        <div style={{ width: 36, height: 36, borderRadius: 999, background: M.bgSurface, border: `0.5px solid ${M.borderDefault}` }}/>
      </div>
      <div style={{ padding: '24px', flex: 1, display:'flex', flexDirection:'column', gap: 12 }}>
        <div style={{ background: M.bgSurface, border: `0.5px solid ${M.borderDefault}`, borderRadius: 16, padding: 20, height: 160, opacity: 0.7 }}/>
        <div style={{ background: M.bgSurface, border: `0.5px solid ${M.borderDefault}`, borderRadius: 16, padding: 20, height: 110, opacity: 0.7 }}/>
        <div style={{ background: M.bgSurface, border: `0.5px solid ${M.borderDefault}`, borderRadius: 16, padding: 20, height: 110, opacity: 0.5 }}/>
      </div>
    </div>
  );
}

function StackContextIOS({ stacked, top, width = 360 }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone="dusk"/>
      <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <IOSStatusBar dark/>
        <div style={{ padding: '8px 0 0', textAlign: 'center' }}>
          <IOSLockClock color="#fff"/>
        </div>
        <div style={{ flex: 1, padding: '24px 12px 32px', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', position:'relative' }}>
          {/* Stacked group */}
          <div style={{ position:'relative', marginBottom: 8 }}>
            <div style={{ position:'absolute', left: 16, right: 16, bottom: -10, height: 80, background:'rgba(28,26,22,0.55)', backdropFilter:'blur(24px)', WebkitBackdropFilter:'blur(24px)', borderRadius: 18, border:'0.5px solid rgba(255,255,255,0.08)' }}/>
            <div style={{ position:'absolute', left: 8, right: 8, bottom: -5, height: 80, background:'rgba(28,26,22,0.55)', backdropFilter:'blur(24px)', WebkitBackdropFilter:'blur(24px)', borderRadius: 18, border:'0.5px solid rgba(255,255,255,0.08)' }}/>
            <div style={{ position:'relative' }}>{top}</div>
          </div>
          {stacked && (
            <div style={{ marginTop: 14, padding:'0 8px', textAlign:'center', color:'#fff', fontSize: 12, fontWeight: 500, opacity: 0.8 }}>
              {stacked}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// 15 Notification mockups
// ──────────────────────────────────────────────────────────────────────────

function NotifA1() {
  return (
    <LockContextIOS tone="morning" clockColor="#1C1A16">
      <IOSNotif
        title="Murabbi · Religion"
        body="Lecture du Coran — il est l'heure"
        caption="15:00 · à valider avant 15:15"
        icon={<AppIconMurabbi size={36} variant="light"/>}
        dark={false}
        actions={[
          { label: 'Validé', icon: <Icon name="check" size={14} color={M.success}/>, color: M.success, bold: true },
          { label: 'Plus tard', color: M.textSecondary },
        ]}
      />
    </LockContextIOS>
  );
}

function NotifA2() {
  return (
    <PixelLockContext>
      <AndroidNotif
        title="30 squats — il est l'heure"
        body="Sport · plage 07h–21h"
        caption="09:30"
        actions={[{ label: 'Validé' }, { label: 'Plus tard' }]}
      />
    </PixelLockContext>
  );
}

function NotifA3() {
  return (
    <BannerContextIOS>
      <IOSNotif
        title="Murabbi · Salat"
        subtitle={<span><span style={{ fontFamily: M.fontArabic, fontSize: 16, fontWeight: 500 }}>العصر</span> · Asr — 16:32</span>}
        caption="Plage à l'heure : jusqu'à 16:47"
        time="à l'instant"
        icon={<AppIconMurabbi size={36} variant="light"/>}
        dark={false}
      />
    </BannerContextIOS>
  );
}

function NotifA4() {
  return (
    <PixelLockContext>
      <AndroidNotif
        title="Asr · 16:32"
        body="Plage à l'heure : jusqu'à 16:47"
        caption="العصر"
        actions={[
          { label: 'À l\'heure', color: '#A6C0A6' },
          { label: 'Manquée', color: '#C28A8A' },
          { label: 'Plus tard' },
        ]}
      />
    </PixelLockContext>
  );
}

function NotifA5() {
  // Expanded long-press preview with image
  return (
    <LockContextIOS tone="dusk">
      <IOSNotif
        title="Murabbi · Religion"
        subtitle="Maghrib approche"
        caption="Plage à l'heure : 19:42 → 20:15"
        time="à l'instant"
        icon={<AppIconMurabbi size={36} variant="dark"/>}
        image="linear-gradient(180deg, #5C4A38 0%, #2A1E14 100%)"
        expanded={
          <div style={{ padding: '4px 14px 14px', borderTop: '0.5px solid rgba(255,255,255,0.10)' }}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', padding:'10px 0' }}>
              <span style={{ fontSize: 12, opacity: 0.7 }}>Aujourd'hui</span>
              <span style={{ fontFamily: M.fontMono, fontSize: 13, fontWeight: 500 }}>24 pts · 3/5 prières</span>
            </div>
            <div style={{ display:'flex', gap: 6, marginTop: 4 }}>
              {['#6B8C6B','#6B8C6B','#9B5E3C','rgba(255,255,255,0.15)','rgba(255,255,255,0.15)'].map((c,i)=>(
                <div key={i} style={{ flex:1, height:4, borderRadius:2, background:c }}/>
              ))}
            </div>
          </div>
        }
        actions={[
          { label: 'À l\'heure', color: '#A6C0A6', bold:true },
          { label: 'Reporter' },
          { label: 'Voir l\'app' },
        ]}
      />
    </LockContextIOS>
  );
}

function NotifA6() {
  return (
    <LockContextIOS tone="morning" clockColor="#1C1A16">
      <IOSNotif
        title="Murabbi"
        body="7 jours consécutifs"
        caption="Continuez à votre rythme"
        icon={<AppIconMurabbi size={36} variant="light"/>}
        dark={false}
        actions={[{ label: 'Voir mes statistiques', color: M.accent, bold: true }]}
      />
    </LockContextIOS>
  );
}

function NotifA7() {
  return (
    <LockContextIOS tone="morning" clockColor="#1C1A16">
      <IOSNotif
        title="Murabbi"
        body="30 jours consécutifs"
        caption="Régularité installée"
        icon={<AppIconMurabbi size={36} variant="light"/>}
        dark={false}
        actions={[{ label: 'Voir mes statistiques', color: M.accent, bold: true }]}
      />
    </LockContextIOS>
  );
}

function NotifA8() {
  return (
    <LockContextIOS tone="dusk">
      <IOSNotif
        title="Murabbi"
        subtitle="Une année. Régularité ancrée."
        caption="365 jours consécutifs"
        time="à l'instant"
        icon={<AppIconMurabbi size={36} variant="dark"/>}
        image="linear-gradient(180deg, #6E5538 0%, #2A1E14 100%)"
        actions={[{ label: 'Voir le récap', color: '#D6C4A8', bold: true }]}
      />
    </LockContextIOS>
  );
}

function NotifA9() {
  return (
    <LockContextIOS tone="morning" clockColor="#1C1A16">
      <IOSNotif
        title="Murabbi"
        body="Niveau Murid débloqué"
        caption="Niveau 1 sur 5 atteint"
        icon={<AppIconMurabbi size={36} variant="light"/>}
        dark={false}
        actions={[{ label: 'Voir', color: M.accent, bold: true }]}
      />
    </LockContextIOS>
  );
}

function NotifA10() {
  return (
    <LockContextIOS tone="morning" clockColor="#1C1A16">
      <IOSNotif
        title="Murabbi"
        body="Nouvelle collection disponible : Routine Ramadan"
        caption="14 habitudes · Religion, Santé"
        icon={<AppIconMurabbi size={36} variant="light"/>}
        dark={false}
        actions={[{ label: 'Découvrir', color: M.accent, bold: true }]}
      />
    </LockContextIOS>
  );
}

function NotifA11() {
  return (
    <PixelLockContext>
      <AndroidNotif
        title="Nouvelle collection : Routine Ramadan"
        body="14 habitudes · Religion, Santé"
        caption="il y a 1 min"
        actions={[{ label: 'Découvrir' }, { label: 'Plus tard' }]}
      />
    </PixelLockContext>
  );
}

function NotifA12() {
  return (
    <LockContextIOS tone="dusk">
      <IOSNotif
        title="Murabbi · Cette semaine"
        body="28 prières à l'heure sur 35 — meilleur jour : mercredi"
        caption="Voir le récap complet"
        time="dim. 20:00"
        icon={<AppIconMurabbi size={36} variant="dark"/>}
        actions={[{ label: 'Voir le récap', color: '#D6C4A8', bold: true }]}
      />
    </LockContextIOS>
  );
}

function NotifA13() {
  // In-app toast confirming a quick-action validation
  return (
    <div style={{ width: 360, height: 720, borderRadius: 360 * 0.115 - 8, overflow: 'hidden', position: 'relative', background: M.bgPrimary }}>
      <FakeAppHome/>
      <div style={{ position: 'absolute', bottom: 90, left: 0, right: 0, display: 'flex', justifyContent: 'center', zIndex: 10 }}>
        <div style={{
          background: M.bgSurface, border: `0.5px solid rgba(107,140,107,0.30)`,
          borderRadius: 999, padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 10,
          boxShadow: '0 8px 24px rgba(28,26,22,0.10)',
          fontFamily: M.fontSans,
        }}>
          <div style={{ width: 22, height: 22, borderRadius: 999, background: M.success, display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Icon name="check" size={13} color="#fff" stroke={2.4}/>
          </div>
          <div style={{ fontSize: 13, color: M.textPrimary, fontWeight: 500 }}>
            Habitude validée <span style={{ color: M.textTertiary, fontWeight: 400 }}>· </span>
            <span style={{ fontFamily: M.fontMono, color: M.success, fontWeight: 500 }}>+3 pts</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function NotifA14() {
  return (
    <StackContextIOS
      top={
        <IOSNotif
          title="Murabbi · 3 rappels"
          body="Asr · 16:32"
          caption="2 autres rappels en attente"
          icon={<AppIconMurabbi size={36} variant="dark"/>}
          actions={[{ label: 'Tout voir', color: '#D6C4A8', bold: true }]}
        />
      }
    />
  );
}

function NotifA15() {
  // System permission prompt
  return (
    <LockContextIOS tone="morning" clockColor="#1C1A16">
      <div style={{
        background: 'rgba(253,251,248,0.96)', backdropFilter:'blur(24px)', WebkitBackdropFilter:'blur(24px)',
        borderRadius: 14, padding: 20, fontFamily: M.fontSans, color: M.textPrimary,
        border: '0.5px solid rgba(28,26,22,0.06)',
        boxShadow: '0 8px 24px rgba(0,0,0,0.10)',
      }}>
        <div style={{ display:'flex', justifyContent:'center', marginBottom: 12 }}>
          <AppIconMurabbi size={48} variant="light"/>
        </div>
        <div style={{ fontSize: 15, fontWeight: 600, textAlign:'center', marginBottom: 4 }}>« Murabbi » souhaite vous envoyer des notifications</div>
        <div style={{ fontSize: 12, textAlign:'center', color: M.textSecondary, lineHeight: 1.45, marginBottom: 14 }}>
          Murabbi vous rappellera vos prières et vos habitudes selon les plages horaires que vous définirez.
        </div>
        <div style={{ display:'flex', borderTop: '0.5px solid rgba(28,26,22,0.10)', margin: '0 -20px -20px' }}>
          <button style={{ flex:1, padding:'12px', background:'transparent', border:'none', color:'#007AFF', fontFamily: M.fontSans, fontSize: 15, fontWeight: 400, cursor:'pointer' }}>Refuser</button>
          <div style={{ width: '0.5px', background:'rgba(28,26,22,0.10)' }}/>
          <button style={{ flex:1, padding:'12px', background:'transparent', border:'none', color:'#007AFF', fontFamily: M.fontSans, fontSize: 15, fontWeight: 600, cursor:'pointer' }}>Autoriser</button>
        </div>
      </div>
    </LockContextIOS>
  );
}

function PixelLockContext({ children, width = 360 }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.085 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone="night"/>
      <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column' }}>
        <AndroidStatusBar dark/>
        <div style={{ padding: '20px 24px 0' }}>
          <AndroidLockClock color="#fff"/>
        </div>
        <div style={{ flex: 1, padding: '20px 12px 24px', display: 'flex', flexDirection: 'column', gap: 8, justifyContent: 'flex-end' }}>
          {children}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  IOSNotif, AndroidNotif, LockContextIOS, BannerContextIOS, StackContextIOS, FakeAppHome, PixelLockContext,
  NotifA1, NotifA2, NotifA3, NotifA4, NotifA5, NotifA6, NotifA7, NotifA8, NotifA9, NotifA10,
  NotifA11, NotifA12, NotifA13, NotifA14, NotifA15,
});
