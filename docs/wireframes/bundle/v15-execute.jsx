// Murabbi v1.5 — HB-EXECUTE modal bottom sheet (4 variants + states)

// ============================================================================
// SHARED — Bottom sheet shell, drag handle, sticky CTA
// ============================================================================

const BottomSheet = ({ children, onClose }) => (
  <div className="phone" style={{
    background: 'rgba(28, 26, 22, 0.55)', position: 'relative'
  }}>
    <StatusBar dark/>
    {/* Faded background hint of HB-DETAIL */}
    <div style={{
      position: 'absolute', inset: 0, background: 'rgba(245, 242, 237, 0.0)',
      backdropFilter: 'blur(2px)'
    }}/>
    {/* Sheet */}
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0,
      height: '92%',
      background: 'var(--bg-primary)',
      borderTopLeftRadius: 24, borderTopRightRadius: 24,
      borderTop: '0.5px solid var(--border-default)',
      display: 'flex', flexDirection: 'column', overflow: 'hidden'
    }}>
      {/* Drag handle */}
      <div style={{ padding: '10px 0 4px', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, borderRadius: 100, background: 'var(--text-tertiary)', opacity: 0.4 }}/>
      </div>
      {children}
    </div>
  </div>
);

const SheetHeader = ({ name, category, color, time, mono }) => (
  <div style={{
    padding: '8px 24px 18px', borderBottom: '0.5px solid var(--border-default)',
    position: 'relative'
  }}>
    <button style={{
      position: 'absolute', top: 4, right: 18, background: 'none', border: 'none',
      cursor: 'pointer', padding: 6, display: 'flex'
    }}>
      <Icon.X size={20} stroke="var(--text-secondary)"/>
    </button>
    <h1 className="h1" style={{ fontSize: 22, paddingRight: 30 }}>{name}</h1>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
      <span className="dot" style={{ background: color, width: 6, height: 6 }}/>
      <span className="caption">{category}</span>
      <span className="caption" style={{ color: 'var(--text-tertiary)' }}>·</span>
      <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>{time}</span>
    </div>
    {mono && (
      <div className="caption" style={{ fontFamily: 'var(--font-mono)', marginTop: 6, color: 'var(--text-tertiary)' }}>
        {mono}
      </div>
    )}
  </div>
);

// Sticky validation footer
const StickyValidate = ({ enabled, label = "Valider l'habitude", caption, onClick }) => (
  <div style={{
    padding: '14px 24px 24px', borderTop: '0.5px solid var(--border-default)',
    background: 'var(--bg-primary)'
  }}>
    {caption && (
      <p className="caption" style={{ textAlign: 'center', marginBottom: 10, color: 'var(--text-secondary)' }}>
        {caption}
      </p>
    )}
    <button className="btn-primary" disabled={!enabled} onClick={onClick}>
      {enabled && <Icon.Check size={16} stroke="white" strokeWidth={2.5}/>}
      {label}
    </button>
  </div>
);

// ============================================================================
// CIRCULAR PROGRESS RING — for timer
// ============================================================================
const TimerRing = ({ size = 240, stroke = 4, progress = 0.62, time = '12:34', running = true }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const dash = c * progress;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size}>
        <circle cx={size/2} cy={size/2} r={r}
          stroke="var(--text-tertiary)" strokeWidth={stroke} fill="none" opacity={0.3}/>
        <circle cx={size/2} cy={size/2} r={r}
          stroke="var(--accent)" strokeWidth={stroke} fill="none"
          strokeLinecap="round"
          strokeDasharray={`${dash} ${c}`}
          transform={`rotate(-90 ${size/2} ${size/2})`}/>
      </svg>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center'
      }}>
        <div style={{
          fontFamily: 'var(--font-mono)', fontSize: 56, fontWeight: 500,
          letterSpacing: '-1.5px', color: 'var(--text-primary)', lineHeight: 1
        }}>{time}</div>
        <div className="caption" style={{ fontFamily: 'var(--font-mono)', marginTop: 8 }}>
          {running ? 'min · sec' : 'en pause'}
        </div>
      </div>
    </div>
  );
};

// Round action button
const RoundBtn = ({ icon, variant = 'secondary', onClick, label }) => {
  const styles = {
    primary: { background: 'var(--accent)', color: 'white', border: '0.5px solid var(--accent)' },
    secondary: { background: 'var(--bg-surface)', color: 'var(--accent)', border: '0.5px solid var(--accent-border)' },
    ghost: { background: 'transparent', color: 'var(--text-secondary)', border: '0.5px solid var(--border-emphasis)' }
  }[variant];
  return (
    <button onClick={onClick} aria-label={label} style={{
      width: 64, height: 64, borderRadius: '50%',
      ...styles, cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center'
    }}>
      {icon}
    </button>
  );
};

// ============================================================================
// VARIANT A — Timer running
// ============================================================================
const HBExecuteTimerRunning = () => (
  <BottomSheet>
    <SheetHeader name="Méditation" category="Mental" color="var(--cat-mental)"
      time="06:30 · 20 min" mono="20 min · timer · sauge"/>
    <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center', gap: 32 }}>
      <TimerRing progress={0.62} time="12:34" running/>
      <div style={{ display: 'flex', gap: 16 }}>
        <RoundBtn label="Pause" variant="secondary"
          icon={<V15Icon.Pause size={22} stroke="var(--accent)" strokeWidth={2}/>}/>
        <RoundBtn label="Arrêter" variant="ghost"
          icon={<V15Icon.Square size={22} stroke="var(--text-secondary)" strokeWidth={2}/>}/>
      </div>
      <p className="caption" style={{ textAlign: 'center', maxWidth: 260, lineHeight: 1.5 }}>
        Une notification vous préviendra à 5 minutes de la fin
      </p>
    </div>
    <StickyValidate enabled={false} label="Arrêter le timer pour valider"/>
  </BottomSheet>
);

// VARIANT A.2 — Timer paused
const HBExecuteTimerPaused = () => (
  <BottomSheet>
    <SheetHeader name="Méditation" category="Mental" color="var(--cat-mental)"
      time="06:30 · 20 min" mono="En pause · 7:26 écoulées"/>
    <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center', gap: 32 }}>
      <TimerRing progress={0.37} time="12:34" running={false}/>
      <div style={{ display: 'flex', gap: 16 }}>
        <RoundBtn label="Reprendre" variant="primary"
          icon={<V15Icon.Play size={22} stroke="white" strokeWidth={2}/>}/>
        <RoundBtn label="Arrêter" variant="ghost"
          icon={<V15Icon.Square size={22} stroke="var(--text-secondary)" strokeWidth={2}/>}/>
      </div>
      <p className="caption" style={{ textAlign: 'center', maxWidth: 260 }}>
        Reprenez quand vous êtes prêt — le compte continuera là où il s'est arrêté
      </p>
    </div>
    <StickyValidate enabled={false} label="Arrêter le timer pour valider"/>
  </BottomSheet>
);

// VARIANT A.3 — Timer initial (not started)
const HBExecuteTimerInitial = () => (
  <BottomSheet>
    <SheetHeader name="Méditation" category="Mental" color="var(--cat-mental)"
      time="06:30 · 20 min" mono="20 min · timer · sauge"/>
    <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center', gap: 32 }}>
      <TimerRing progress={0} time="20:00" running/>
      <RoundBtn label="Démarrer" variant="primary"
        icon={<V15Icon.Play size={26} stroke="white" strokeWidth={2}/>}/>
      <p className="caption" style={{ textAlign: 'center' }}>
        Préparez votre espace, puis démarrez quand vous êtes prêt
      </p>
    </div>
    <StickyValidate enabled={true} caption="Vous pouvez aussi valider sans démarrer le timer"/>
  </BottomSheet>
);

// ============================================================================
// VARIANT B — Objectif chiffré (counter)
// ============================================================================
const HBExecuteCounter = ({ actual = 3, target = 5, unit = 'pages', name = 'Lecture du Coran',
  category = 'Religion', color = 'var(--cat-religion)' }) => {
  const enabled = actual >= target;
  const ratio = Math.min(1, actual / target);
  return (
    <BottomSheet>
      <SheetHeader name={name} category={category} color={color}
        time="06:00–08:00" mono={`${target} ${unit} · objectif · sauge`}/>
      <div style={{ flex: 1, padding: '32px 24px', display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'flex-start', gap: 20, overflowY: 'auto' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, justifyContent: 'center' }}>
            <span className="display" style={{ fontSize: 64,
              color: enabled ? 'var(--success)' : 'var(--accent)', letterSpacing: '-2px' }}>{actual}</span>
            <span className="display" style={{ fontSize: 32, color: 'var(--text-tertiary)' }}>/ {target}</span>
          </div>
          <h2 className="h2" style={{ marginTop: 4, color: 'var(--text-secondary)' }}>{unit}</h2>
        </div>
        <div style={{ width: '80%' }}>
          <MiniProgressBar actual={actual} target={target} width="100%" height={6}/>
        </div>

        {/* Mode A — Increment */}
        <div style={{ width: '100%', marginTop: 12 }}>
          <div className="label" style={{ textAlign: 'center', marginBottom: 14 }}>SAISIE PAR INCRÉMENT</div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 24 }}>
            <RoundBtn label="moins" variant="ghost"
              icon={<Icon.Minus size={22} stroke="var(--text-primary)"/>}/>
            <div style={{
              fontFamily: 'var(--font-mono)', fontSize: 40, fontWeight: 500,
              minWidth: 80, textAlign: 'center', color: 'var(--text-primary)'
            }}>{actual}</div>
            <RoundBtn label="plus" variant="primary"
              icon={<Icon.Plus size={22} stroke="white" strokeWidth={2}/>}/>
          </div>
        </div>

        {/* Separator */}
        <div className="divider-text" style={{ width: '100%', margin: '8px 0 0' }}>OU</div>

        {/* Mode B — Total input */}
        <div style={{ width: '100%' }}>
          <div className="label" style={{ marginBottom: 8 }}>SAISIR LE TOTAL</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <input className="input" type="number" placeholder={`${target}`}
              style={{ fontFamily: 'var(--font-mono)', flex: 1 }}/>
            <button className="btn-secondary" style={{ width: 'auto', padding: '0 18px', minHeight: 48, whiteSpace: 'nowrap' }}>
              Mettre à jour
            </button>
          </div>
        </div>
      </div>
      <StickyValidate
        enabled={enabled}
        caption={enabled ? null : `Atteignez l'objectif de ${target} ${unit} pour valider`}/>
    </BottomSheet>
  );
};

// ============================================================================
// VARIANT C — Subtasks
// ============================================================================
const HBExecuteSubtasks = ({ tasks, allRequired = true, name = 'Routine du matin',
  category = 'Religion', color = 'var(--cat-religion)' }) => {
  const total = tasks.length;
  const done = tasks.filter(t => t.done).length;
  const enabled = allRequired ? done === total : true;
  return (
    <BottomSheet>
      <SheetHeader name={name} category={category} color={color}
        time="06:00–07:30" mono={`${total} étapes · sous-tâches · sauge`}/>
      <div style={{ flex: 1, padding: '8px 0 0', overflowY: 'auto' }}>
        <div style={{ padding: '14px 24px 4px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span className="label">ÉTAPES</span>
          <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>
            <span style={{ color: enabled ? 'var(--success)' : 'var(--text-primary)', fontWeight: 500 }}>{done}</span>
            <span style={{ color: 'var(--text-tertiary)' }}> / {total} cochées</span>
          </span>
        </div>
        <div style={{ padding: '0 24px' }}>
          {tasks.map((t, i) => (
            <button key={i} style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: 14,
              padding: '14px 0', minHeight: 56,
              background: 'transparent', border: 'none',
              borderBottom: i < tasks.length - 1 ? '0.5px solid var(--border-default)' : 'none',
              cursor: 'pointer', textAlign: 'left'
            }}>
              <MiniCheckbox checked={t.done}/>
              <div style={{ flex: 1 }}>
                <div className="h3" style={{
                  color: t.done ? 'var(--text-tertiary)' : 'var(--text-primary)',
                  textDecoration: t.done ? 'line-through' : 'none'
                }}>{t.title}</div>
              </div>
              <span className="caption" style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)' }}>
                {String(i + 1).padStart(2, '0')}
              </span>
            </button>
          ))}
        </div>
      </div>
      <StickyValidate
        enabled={enabled}
        caption={!enabled
          ? "Cochez toutes les sous-tâches obligatoires"
          : (allRequired ? null : "Sous-tâches optionnelles · vous pouvez valider quand vous voulez")
        }/>
    </BottomSheet>
  );
};

// ============================================================================
// VARIANT D — Tout combiné (timer + objectif + sous-tâches)
// ============================================================================
const HBExecuteCombined = () => {
  const tasks = [
    { title: "Préparer le tapis", done: true },
    { title: "10 min de respiration", done: true },
    { title: "Lecture des Mu'awwidhat", done: false },
  ];
  return (
    <BottomSheet>
      <SheetHeader name="Séance complète du matin" category="Mental" color="var(--cat-mental)"
        time="06:30–07:00" mono="20 min · 8 répétitions · 3 étapes"/>
      <div style={{ flex: 1, padding: '14px 0 0', overflowY: 'auto' }}>

        {/* Timer ring (réduit 160) */}
        <div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0' }}>
          <TimerRing size={160} stroke={3} progress={0.62} time="07:34" running/>
        </div>

        {/* Objectif chiffré */}
        <div style={{ padding: '0 24px', textAlign: 'center', marginTop: 4 }}>
          <div className="label" style={{ marginBottom: 6 }}>RÉPÉTITIONS</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, justifyContent: 'center' }}>
            <span className="display" style={{ fontSize: 36, color: 'var(--accent)' }}>5</span>
            <span className="display" style={{ fontSize: 22, color: 'var(--text-tertiary)' }}>/ 8</span>
          </div>
          <div style={{ marginTop: 8, display: 'flex', justifyContent: 'center', gap: 12 }}>
            <button className="btn-secondary" style={{ width: 'auto', minHeight: 36, padding: '0 14px', fontSize: 13 }}>
              <Icon.Minus size={14}/>
            </button>
            <button className="btn-secondary" style={{ width: 'auto', minHeight: 36, padding: '0 14px', fontSize: 13 }}>
              <Icon.Plus size={14}/>
            </button>
          </div>
        </div>

        {/* Subtasks */}
        <div style={{ padding: '20px 24px 0' }}>
          <div className="label" style={{ marginBottom: 10 }}>ÉTAPES · 2 / 3</div>
          {tasks.map((t, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0',
              borderBottom: i < tasks.length - 1 ? '0.5px solid var(--border-default)' : 'none'
            }}>
              <MiniCheckbox checked={t.done}/>
              <span style={{
                flex: 1, fontSize: 14,
                color: t.done ? 'var(--text-tertiary)' : 'var(--text-primary)',
                textDecoration: t.done ? 'line-through' : 'none'
              }}>{t.title}</span>
            </div>
          ))}
        </div>
      </div>
      <StickyValidate enabled={false}
        caption="Arrêtez le timer et complétez tous les critères pour valider"/>
    </BottomSheet>
  );
};

// ============================================================================
// HB-EXECUTE STATES — counter variants
// ============================================================================
const HBExecuteCounter_Empty = () => <HBExecuteCounter actual={0} target={5} unit="pages"/>;
const HBExecuteCounter_Partial = () => <HBExecuteCounter actual={3} target={5} unit="pages"/>;
const HBExecuteCounter_Reached = () => <HBExecuteCounter actual={5} target={5} unit="pages"/>;
const HBExecuteCounter_Exceeded = () => <HBExecuteCounter actual={7} target={5} unit="pages"/>;

const HBExecuteSubtasks_Partial = () => (
  <HBExecuteSubtasks allRequired={true} tasks={[
    { title: "Ablutions complètes", done: true },
    { title: "2 raka'ats du Fajr", done: true },
    { title: "Dhikr du matin (33×)", done: true },
    { title: "Lecture des Mu'awwidhat", done: false },
    { title: "Du'a du matin", done: false },
  ]}/>
);
const HBExecuteSubtasks_All = () => (
  <HBExecuteSubtasks allRequired={true} tasks={[
    { title: "Ablutions complètes", done: true },
    { title: "2 raka'ats du Fajr", done: true },
    { title: "Dhikr du matin (33×)", done: true },
    { title: "Lecture des Mu'awwidhat", done: true },
    { title: "Du'a du matin", done: true },
  ]}/>
);

// ============================================================================
// EXPORT — mobile-only (S-11 : ScreenHAB02v15 admin component vit dans murabbi-admin)
// ============================================================================

Object.assign(window, {
  BottomSheet, SheetHeader, StickyValidate, TimerRing, RoundBtn,
  HBExecuteTimerRunning, HBExecuteTimerPaused, HBExecuteTimerInitial,
  HBExecuteCounter, HBExecuteCounter_Empty, HBExecuteCounter_Partial,
  HBExecuteCounter_Reached, HBExecuteCounter_Exceeded,
  HBExecuteSubtasks, HBExecuteSubtasks_Partial, HBExecuteSubtasks_All,
  HBExecuteCombined,
});
