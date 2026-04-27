// Murabbi Extras — Lock Screen widgets (iOS) + Live Activities (Dynamic Island & banner)

// ── iOS Lock Screen widget shells (rectangular & circular & inline) ───────
function LSRect({ children }) {
  return (
    <div style={{
      width: 158, height: 76, borderRadius: 16,
      background: 'rgba(28,26,22,0.30)', backdropFilter: 'blur(20px)', WebkitBackdropFilter:'blur(20px)',
      border: '0.5px solid rgba(255,255,255,0.16)',
      color: '#fff', padding: '10px 12px', fontFamily: M.fontSans, position:'relative', overflow:'hidden',
    }}>{children}</div>
  );
}
function LSCirc({ children }) {
  return (
    <div style={{
      width: 76, height: 76, borderRadius: 999,
      background:'rgba(28,26,22,0.30)', backdropFilter:'blur(20px)', WebkitBackdropFilter:'blur(20px)',
      border:'0.5px solid rgba(255,255,255,0.16)',
      color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', flexDirection:'column', fontFamily: M.fontSans,
    }}>{children}</div>
  );
}
function LSInline({ children }) {
  return (
    <div style={{
      padding: '4px 10px', borderRadius: 999, background:'rgba(28,26,22,0.30)', backdropFilter:'blur(16px)', WebkitBackdropFilter:'blur(16px)',
      border:'0.5px solid rgba(255,255,255,0.14)', color:'#fff', fontSize: 13, fontFamily: M.fontSans, fontWeight: 500,
      display:'inline-flex', alignItems:'center', gap: 6,
    }}>{children}</div>
  );
}

// LS rectangular widgets
function LSRectScore() {
  return (
    <LSRect>
      <div style={{ display:'flex', alignItems:'center', gap: 10 }}>
        <div style={{ position:'relative', width: 38, height: 38 }}>
          <svg width="38" height="38" style={{ transform:'rotate(-90deg)' }}>
            <circle cx="19" cy="19" r="16" fill="none" stroke="rgba(255,255,255,0.20)" strokeWidth="3"/>
            <circle cx="19" cy="19" r="16" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeDasharray={`${2*Math.PI*16*0.42} ${2*Math.PI*16}`}/>
          </svg>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 9, opacity: 0.7, fontWeight: 500, letterSpacing: 0.6, textTransform:'uppercase' }}>Aujourd'hui</div>
          <div style={{ fontFamily: M.fontMono, fontSize: 18, fontWeight: 500, lineHeight: 1, marginTop: 2 }}>42 pts</div>
          <div style={{ fontSize: 10, opacity: 0.7, marginTop: 2 }}>3/5 prières</div>
        </div>
      </div>
    </LSRect>
  );
}
function LSRectAsr() {
  return (
    <LSRect>
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <div>
          <div style={{ fontFamily: M.fontArabic, fontSize: 18, fontWeight: 500, lineHeight: 1 }}>العصر</div>
          <div style={{ fontSize: 10, opacity: 0.75, fontWeight: 500, marginTop: 2 }}>Asr · dans 1 h 23</div>
        </div>
        <div style={{ fontFamily: M.fontMono, fontSize: 18, fontWeight: 500 }}>16:32</div>
      </div>
      <div style={{ position:'absolute', bottom: 8, left: 12, right: 12, display:'flex', gap: 4 }}>
        {[true,true,false,false,false].map((d,i)=>(
          <div key={i} style={{ flex: 1, height: 3, borderRadius: 2, background: d ? '#fff' : 'rgba(255,255,255,0.25)' }}/>
        ))}
      </div>
    </LSRect>
  );
}

// LS circular widgets
function LSCircRing() {
  return (
    <LSCirc>
      <div style={{ position:'relative', width: 56, height: 56 }}>
        <svg width="56" height="56" style={{ transform:'rotate(-90deg)' }}>
          <circle cx="28" cy="28" r="24" fill="none" stroke="rgba(255,255,255,0.20)" strokeWidth="3"/>
          <circle cx="28" cy="28" r="24" fill="none" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeDasharray={`${2*Math.PI*24*0.42} ${2*Math.PI*24}`}/>
        </svg>
        <div style={{ position:'absolute', inset:0, display:'flex', alignItems:'center', justifyContent:'center', fontFamily: M.fontMono, fontSize: 13, fontWeight: 500 }}>42%</div>
      </div>
    </LSCirc>
  );
}
function LSCircNext() {
  return (
    <LSCirc>
      <div style={{ fontSize: 8, opacity: 0.7, fontWeight: 500, letterSpacing: 0.6, textTransform: 'uppercase' }}>Asr</div>
      <div style={{ fontFamily: M.fontMono, fontSize: 16, fontWeight: 500, lineHeight: 1.1 }}>16:32</div>
      <div style={{ fontSize: 9, opacity: 0.7, marginTop: 2 }}>1 h 23</div>
    </LSCirc>
  );
}
function LSCircStreak() {
  return (
    <LSCirc>
      <Icon name="flame" size={16} color="#fff"/>
      <div style={{ fontFamily: M.fontMono, fontSize: 14, fontWeight: 500, marginTop: 2 }}>14j</div>
    </LSCirc>
  );
}

// ── iOS Lock-screen layout demonstrating widget slots ─────────────────────
function LockWidgetsContextIOS({ width = 360, tone = 'dusk', children }) {
  return (
    <div style={{ width, height: 720, borderRadius: width * 0.115 - 8, overflow: 'hidden', position: 'relative', background: '#000' }}>
      <Wallpaper tone={tone}/>
      <div style={{ position:'relative', height: '100%', display:'flex', flexDirection:'column' }}>
        <IOSStatusBar dark/>
        {/* Inline widget slot above clock */}
        <div style={{ padding: '8px 0 0', textAlign:'center' }}>
          {children?.inline || (
            <LSInline>
              <Icon name="sun" size={11} color="#fff"/>
              <span>Asr · 16:32</span>
            </LSInline>
          )}
        </div>
        <div style={{ padding: '6px 0 0', textAlign:'center' }}>
          <IOSLockClock color="#fff"/>
        </div>
        {/* Widget row below clock */}
        <div style={{ padding: '14px 22px 0', display:'flex', gap: 8, justifyContent:'center' }}>
          {children?.row || (
            <>
              <LSCircRing/>
              <LSRectAsr/>
              <LSCircStreak/>
            </>
          )}
        </div>
        <div style={{ flex: 1 }}/>
        {/* Camera / flashlight pills */}
        <div style={{ padding: '0 28px 14px', display:'flex', justifyContent:'space-between' }}>
          <div style={{ width: 44, height: 44, borderRadius: 999, background:'rgba(28,26,22,0.4)', display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Icon name="flashlight" size={18} color="#fff"/>
          </div>
          <div style={{ width: 44, height: 44, borderRadius: 999, background:'rgba(28,26,22,0.4)', display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Icon name="camera" size={18} color="#fff"/>
          </div>
        </div>
        <div style={{ height: 18, display:'flex', justifyContent:'center', alignItems:'center' }}>
          <div style={{ width: 130, height: 4, background:'#fff', opacity: 0.8, borderRadius: 2 }}/>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Live Activities (iOS) — Dynamic Island compact / expanded / minimal pair
// + Lock-screen Live Activity card
// ──────────────────────────────────────────────────────────────────────────

function LADynamicIslandCompact() {
  return (
    <IPhoneFrame width={320} dark>
      <IOSStatusBar dark/>
      <DynamicIsland
        variant="compact"
        width={320}
        leftIcon={<Icon name="sun" size={13} color="#FFB44A" stroke={2}/>}
        rightLabel="01:23"
      />
      <Wallpaper tone="dusk" style={{ top: 60, borderRadius: 0 }}/>
    </IPhoneFrame>
  );
}

function LADynamicIslandExpanded() {
  return (
    <IPhoneFrame width={320} dark>
      <IOSStatusBar dark/>
      <DynamicIsland
        variant="expanded"
        width={320}
        expanded={
          <div style={{ display:'flex', flexDirection:'column', gap: 8 }}>
            <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
              <div style={{ display:'flex', alignItems:'center', gap: 10 }}>
                <div style={{ width: 32, height: 32, borderRadius: 8, background:'rgba(214,196,168,0.18)', display:'flex', alignItems:'center', justifyContent:'center' }}>
                  <Icon name="sun" size={16} color="#FFB44A" stroke={2}/>
                </div>
                <div>
                  <div style={{ fontFamily: M.fontArabic, fontSize: 16, fontWeight: 500, lineHeight: 1 }}>العصر</div>
                  <div style={{ fontSize: 10, opacity: 0.65, fontWeight: 500, marginTop: 2 }}>Asr · à l'heure jusqu'à 16:47</div>
                </div>
              </div>
              <div style={{ textAlign:'right' }}>
                <div style={{ fontFamily: M.fontMono, fontSize: 18, fontWeight: 500, lineHeight: 1 }}>01:23</div>
                <div style={{ fontSize: 9, opacity: 0.55, marginTop: 2, fontFamily: M.fontMono, letterSpacing: 0.4 }}>restant</div>
              </div>
            </div>
            <div style={{ display:'flex', gap: 4, marginTop: 6 }}>
              <div style={{ flex: 1, height: 3, borderRadius: 2, background:'#fff', opacity: 0.9 }}/>
              <div style={{ flex: 1, height: 3, borderRadius: 2, background:'rgba(255,255,255,0.20)' }}/>
            </div>
          </div>
        }
      />
      <Wallpaper tone="dusk" style={{ top: 100, borderRadius: 0 }}/>
    </IPhoneFrame>
  );
}

function LADynamicIslandPair() {
  return (
    <IPhoneFrame width={320} dark>
      <IOSStatusBar dark/>
      <DynamicIsland
        variant="minimal-pair"
        width={320}
        leftIcon={<MurabbiGlyph size={13} color="#D6C4A8" stroke={1.8}/>}
        rightIcon={<Icon name="sun" size={11} color="#FFB44A" stroke={2.2}/>}
      />
      <Wallpaper tone="morning" style={{ top: 60, borderRadius: 0 }}/>
    </IPhoneFrame>
  );
}

function LALockCard() {
  return (
    <LockContextIOS tone="dusk">
      <div style={{
        background:'rgba(28,26,22,0.55)', backdropFilter:'blur(24px)', WebkitBackdropFilter:'blur(24px)',
        border:'0.5px solid rgba(255,255,255,0.10)', borderRadius: 18, color:'#fff', fontFamily: M.fontSans,
        padding: 14,
      }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: 10 }}>
          <div style={{ display:'flex', alignItems:'center', gap: 8 }}>
            <AppIconMurabbi size={20} variant="dark" radius={5}/>
            <span style={{ fontSize: 11, fontWeight: 500, opacity: 0.8 }}>MURABBI · LIVE</span>
          </div>
          <span style={{ fontSize: 11, opacity: 0.65 }}>plage à l'heure</span>
        </div>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom: 10 }}>
          <div>
            <div style={{ fontFamily: M.fontArabic, fontSize: 26, fontWeight: 500, lineHeight: 1 }}>العصر</div>
            <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4, fontWeight: 500 }}>Asr · 16:32 → 16:47</div>
          </div>
          <div style={{ textAlign:'right' }}>
            <div style={{ fontFamily: M.fontMono, fontSize: 28, fontWeight: 500, lineHeight: 1 }}>01:23</div>
            <div style={{ fontSize: 10, opacity: 0.6, marginTop: 4, fontFamily: M.fontMono, letterSpacing: 0.4, textTransform: 'uppercase' }}>Restant</div>
          </div>
        </div>
        <div style={{ height: 4, borderRadius: 2, background:'rgba(255,255,255,0.15)', overflow:'hidden' }}>
          <div style={{ width: '64%', height: '100%', background:'#fff' }}/>
        </div>
        <div style={{ display:'flex', gap: 8, marginTop: 12 }}>
          <button style={{ flex: 1, padding: '9px', background:'#fff', color: M.textPrimary, border:'none', borderRadius: 999, fontFamily: M.fontSans, fontSize: 13, fontWeight: 600, cursor:'pointer' }}>Validé à l'heure</button>
          <button style={{ flex: 1, padding: '9px', background:'rgba(255,255,255,0.15)', color:'#fff', border:'none', borderRadius: 999, fontFamily: M.fontSans, fontSize: 13, fontWeight: 500, cursor:'pointer' }}>Plus tard</button>
        </div>
      </div>
    </LockContextIOS>
  );
}

Object.assign(window, {
  LSRect, LSCirc, LSInline, LSRectScore, LSRectAsr, LSCircRing, LSCircNext, LSCircStreak,
  LockWidgetsContextIOS,
  LADynamicIslandCompact, LADynamicIslandExpanded, LADynamicIslandPair, LALockCard,
});
