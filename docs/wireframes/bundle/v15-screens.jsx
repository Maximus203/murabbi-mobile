// Murabbi v1.5 — Modified screens (HM-01, HB-01, HB-02, HB-DETAIL)
// Surgical additions: objectif chiffré, sous-tâches, timer in-app

// ============================================================================
// V15 ICONS — additional Lucide stroke icons used by v1.5
// ============================================================================
const V15Icon = {
  Timer: (p) => <I {...p}><line x1="10" y1="2" x2="14" y2="2"/><line x1="12" y1="14" x2="15" y2="11"/><circle cx="12" cy="14" r="8"/></I>,
  Play: (p) => <I {...p}><polygon points="5 3 19 12 5 21 5 3"/></I>,
  Pause: (p) => <I {...p}><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></I>,
  Square: (p) => <I {...p}><rect x="4" y="4" width="16" height="16" rx="2"/></I>,
  GripVertical: (p) => <I {...p}><circle cx="9" cy="5" r="1"/><circle cx="9" cy="12" r="1"/><circle cx="9" cy="19" r="1"/><circle cx="15" cy="5" r="1"/><circle cx="15" cy="12" r="1"/><circle cx="15" cy="19" r="1"/></I>,
  Trash2: (p) => <I {...p}><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></I>,
  Target: (p) => <I {...p}><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></I>,
  ListChecks: (p) => <I {...p}><path d="M3 17l2 2 4-4"/><path d="M3 7l2 2 4-4"/><path d="M13 6h8M13 12h8M13 18h8"/></I>,
  RotateCcw: (p) => <I {...p}><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></I>,
};

// ============================================================================
// V15 PRIMITIVES — small reusable bits for the new features
// ============================================================================

// Mini progress bar (4px) — used on HabitRow when objectif chiffré active
const MiniProgressBar = ({ actual, target, width = '60%', height = 4 }) => {
  const ratio = Math.min(1, actual / target);
  const fill = ratio >= 1 ? 'var(--success)'
    : ratio >= 0.5 ? 'var(--accent)'
    : 'rgba(139, 111, 71, 0.4)';
  return (
    <div style={{
      width, height, background: 'var(--bg-input)', borderRadius: 100,
      overflow: 'hidden', position: 'relative'
    }}>
      <div style={{
        width: `${ratio * 100}%`, height: '100%',
        background: fill, borderRadius: 100,
        transition: 'width 0.4s ease, background 0.3s ease'
      }}/>
    </div>
  );
};

// Timer badge (discreet) — shown on HabitRow when timer running
const TimerBadge = ({ time = '12:34' }) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '3px 8px', background: 'var(--accent-light)',
    border: '0.5px solid var(--accent-border)', borderRadius: 100,
    color: 'var(--accent)', fontSize: 10, fontWeight: 500
  }}>
    <V15Icon.Timer size={11} stroke="var(--accent)"/>
    <span style={{ fontFamily: 'var(--font-mono)' }}>{time}</span>
    <span style={{ letterSpacing: 0.3 }}>restant</span>
  </div>
);

// Pulse dot — animated indicator for timer in progress
const PulseDot = ({ color = 'var(--accent)' }) => (
  <>
    <style>{`
      @keyframes v15-pulse { 0%,100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.5; transform: scale(0.85); } }
    `}</style>
    <span style={{
      display: 'inline-block', width: 6, height: 6, borderRadius: '50%',
      background: color, animation: 'v15-pulse 1.4s ease-in-out infinite'
    }}/>
  </>
);

// Toggle (matches existing design system)
const V15Toggle = ({ on = false, onChange = () => {}, disabled = false }) => (
  <button onClick={() => !disabled && onChange(!on)} disabled={disabled} style={{
    width: 38, height: 22, borderRadius: 100, padding: 2,
    background: on ? 'var(--accent)' : 'var(--bg-input)',
    border: 'none', cursor: disabled ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.5 : 1, transition: 'background 0.2s', flexShrink: 0
  }}>
    <span style={{
      display: 'block', width: 18, height: 18, borderRadius: '50%',
      background: 'var(--bg-surface)',
      transform: on ? 'translateX(16px)' : 'translateX(0)',
      transition: 'transform 0.2s', boxShadow: '0 0 0 0.5px rgba(28,26,22,0.08)'
    }}/>
  </button>
);

// Section pliable (used in HB-02)
const CollapsibleSection = ({ label, count, toggle, on, onToggle, children, defaultOpen = true }) => {
  const [open, setOpen] = React.useState(defaultOpen);
  return (
    <div style={{
      marginBottom: 16, borderRadius: 12,
      border: '0.5px solid var(--border-default)', background: 'var(--bg-surface)'
    }}>
      <button onClick={() => setOpen(!open)} style={{
        width: '100%', padding: '14px 16px', background: 'transparent', border: 'none',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        cursor: 'pointer', textAlign: 'left'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Icon.ChevronDown size={14} stroke="var(--text-tertiary)"
            style={{ transform: open ? 'rotate(0deg)' : 'rotate(-90deg)', transition: 'transform 0.2s' }}/>
          <span className="label">{label}</span>
          {count && <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>{count}</span>}
        </div>
        {toggle && (
          <span onClick={(e) => e.stopPropagation()}>
            <V15Toggle on={on} onChange={onToggle}/>
          </span>
        )}
      </button>
      {open && on !== false && (
        <div style={{ padding: '4px 16px 16px', borderTop: '0.5px solid var(--border-default)' }}>
          {children}
        </div>
      )}
    </div>
  );
};

// Mini-checkbox 24x24
const MiniCheckbox = ({ checked = false, size = 24 }) => (
  <span style={{
    width: size, height: size, borderRadius: 6,
    border: `1.2px solid ${checked ? 'var(--accent)' : 'var(--border-emphasis)'}`,
    background: checked ? 'var(--accent)' : 'transparent',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    flexShrink: 0, transition: 'all 0.15s'
  }}>
    {checked && <Icon.Check size={size * 0.6} stroke="white" strokeWidth={2.5}/>}
  </span>
);

// ============================================================================
// HM-01 v1.5 — Dashboard with enriched habit display
// ============================================================================

// Enriched habit row used in HM-01's "Habitudes 6/9" section
const HM01HabitMicroRow = ({ name, color, done, objective, subtasks, timerRunning, timerTime }) => (
  <div style={{
    padding: '10px 0', display: 'flex', alignItems: 'center', gap: 12,
    borderBottom: '0.5px solid var(--border-default)'
  }}>
    <span className="dot" style={{ background: color, width: 6, height: 6 }}/>
    <span className="body" style={{ flex: 1, fontSize: 13 }}>{name}</span>
    {/* Right side: objective > timer > subtasks priority */}
    {objective && !timerRunning && (
      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-secondary)' }}>
        {objective.actual} / {objective.target} <span style={{ color: 'var(--text-tertiary)' }}>{objective.unit}</span>
      </span>
    )}
    {!objective && subtasks && !timerRunning && (
      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-secondary)' }}>
        {subtasks.done}/{subtasks.total}
      </span>
    )}
    {timerRunning ? (
      <button style={{
        height: 28, padding: '0 10px', borderRadius: 100,
        background: 'var(--accent-light)', border: '0.5px solid var(--accent-border)',
        display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer'
      }}>
        <V15Icon.Timer size={12} stroke="var(--accent)"/>
        <PulseDot/>
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--accent)', fontWeight: 500 }}>{timerTime}</span>
      </button>
    ) : (
      <button className={`salat-btn ${done ? 'ontime' : ''}`}>
        {done && <Icon.Check size={14} stroke="white" strokeWidth={2}/>}
      </button>
    )}
  </div>
);

const ScreenHM01v15 = () => (
  <Phone>
    <div className="app-header no-border">
      <div>
        <div className="label" style={{ letterSpacing: '1.5px' }}>ASSALAMU ALAYKUM</div>
        <div className="h1" style={{ fontSize: 22, marginTop: 2 }}>Cherif</div>
      </div>
      <button className="btn-icon" style={{ background: 'transparent' }}>
        <Icon.Bell size={20} stroke="var(--text-primary)"/>
      </button>
    </div>
    <div className="phone-scroll" style={{ top: 100, paddingTop: 0 }}>
      <div className="screen">
        <p className="caption" style={{ margin: '0 0 20px' }}>
          Vendredi 26 avril 2026 · 8 Dhul-Qa'dah 1447
        </p>

        {/* Score card (unchanged) */}
        <div className="card" style={{ padding: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            <ProgressRing value={70} size={84} stroke={4}/>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                <span className="display" style={{ fontSize: 44, color: 'var(--accent)' }}>42</span>
                <span className="caption" style={{ fontSize: 12 }}>/ 60</span>
              </div>
              <div className="caption" style={{ marginTop: 2 }}>pts aujourd'hui · objectif 60</div>
              <div style={{ marginTop: 10 }}>
                <span className="badge-level"><Icon.Star size={11} stroke="var(--accent)"/> Aspirant · Niveau 2</span>
              </div>
            </div>
          </div>
        </div>

        {/* Habitudes du jour — ENRICHED */}
        <div style={{ marginTop: 20, display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
          <span className="label">HABITUDES</span>
          <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>6 / 9</span>
        </div>
        <div className="card" style={{ padding: '4px 16px' }}>
          <HM01HabitMicroRow name="Lecture du Coran" color="var(--cat-religion)" done={false}
            objective={{ actual: 3, target: 5, unit: 'pages' }}/>
          <HM01HabitMicroRow name="Dhikr du matin" color="var(--cat-religion)" done={true}/>
          <HM01HabitMicroRow name="Méditation" color="var(--cat-mental)" timerRunning={true} timerTime="12:34"/>
          <HM01HabitMicroRow name="Routine du matin" color="var(--cat-religion)" done={false}
            subtasks={{ done: 3, total: 5 }}/>
          <HM01HabitMicroRow name="2L d'eau" color="var(--cat-sante)" done={false}
            objective={{ actual: 5, target: 8, unit: 'verres' }}/>
          <HM01HabitMicroRow name="Marche 30 min" color="var(--cat-sport)" done={true}/>
        </div>

        {/* Niyyah card */}
        <div className="card-video" style={{ marginTop: 16, minHeight: 130 }}>
          <video autoPlay muted loop playsInline poster="media/01_fallback.png">
            <source src="media/01.mp4" type="video/mp4"/>
          </video>
          <div className="video-overlay-light-85"/>
          <div className="video-content" style={{ padding: 20 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span className="label">INTENTION DU JOUR</span>
              <button style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-secondary)' }}>
                <Icon.Edit size={16}/>
              </button>
            </div>
            <p className="body italic" style={{ margin: '10px 0 0', color: 'var(--text-primary)' }}>
              "Aujourd'hui, je m'engage à prier à l'heure et à offrir une parole douce à un proche."
            </p>
          </div>
        </div>

        <div style={{ height: 16 }}/>
      </div>
    </div>
    <BottomNav active="home"/>
  </Phone>
);

// ============================================================================
// HB-01 v1.5 — Habit list with mini progress + timer badge
// ============================================================================

const HabitRowV15 = ({ name, freq, color, done, objective, timer }) => (
  <div className="card" style={{
    padding: 14, display: 'flex', alignItems: 'flex-start', gap: 14, marginBottom: 8
  }}>
    <span className="dot" style={{ background: color, marginTop: 6 }}/>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="h3">{name}</div>
      <div className="caption" style={{ marginTop: 1 }}>{freq}</div>
      {objective && (
        <div style={{ marginTop: 8 }}>
          <div className="caption" style={{ fontFamily: 'var(--font-mono)', fontSize: 11, marginBottom: 4 }}>
            <span style={{ color: 'var(--text-primary)', fontWeight: 500 }}>{objective.actual} / {objective.target}</span>
            <span style={{ color: 'var(--text-tertiary)' }}> {objective.unit}</span>
          </div>
          <MiniProgressBar actual={objective.actual} target={objective.target} width="60%"/>
        </div>
      )}
      {timer && (
        <div style={{ marginTop: 8 }}>
          <TimerBadge time={timer.time}/>
        </div>
      )}
    </div>
    <button className={`salat-btn ${done ? 'ontime' : ''}`} style={{ marginTop: 4 }}>
      {done && <Icon.Check size={14} stroke="white" strokeWidth={2}/>}
    </button>
  </div>
);

const ScreenHB01v15 = () => (
  <Phone>
    <HeaderTitle title="Mes Habitudes" action={
      <button className="btn-icon"><Icon.Plus size={20} stroke="var(--accent)"/></button>
    }/>
    <div className="phone-scroll" style={{ top: 100, paddingTop: 0 }}>
      <div className="screen">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <span className="caption">8 / 12 complétées aujourd'hui</span>
        </div>
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 8 }}>
          <span className="chip active">Toutes</span>
          <span className="chip">Aujourd'hui</span>
          <span className="chip">À faire</span>
        </div>

        <SectionHeader name="RELIGION" color="var(--cat-religion)" count="2 / 4"/>
        <HabitRowV15 name="Lecture du Coran" freq="Quotidien · 15 min"
          color="var(--cat-religion)" done={false}
          objective={{ actual: 3, target: 5, unit: 'pages' }}/>
        <HabitRowV15 name="Dhikr du matin" freq="Quotidien · 5 min"
          color="var(--cat-religion)" done={true}/>
        <HabitRowV15 name="Routine du matin" freq="Quotidien"
          color="var(--cat-religion)" done={false}/>
        <HabitRowV15 name="Prière surérogatoire" freq="3×/semaine"
          color="var(--cat-religion)" done={true}/>

        <SectionHeader name="MENTAL" color="var(--cat-mental)" count="0 / 2"/>
        <HabitRowV15 name="Méditation" freq="Quotidien · 20 min"
          color="var(--cat-mental)" done={false}
          timer={{ time: '12:34' }}/>
        <HabitRowV15 name="Journal du soir" freq="Quotidien" color="var(--cat-mental)" done={false}/>

        <SectionHeader name="SANTÉ" color="var(--cat-sante)" count="1 / 3"/>
        <HabitRowV15 name="Hydratation" freq="Quotidien"
          color="var(--cat-sante)" done={false}
          objective={{ actual: 5, target: 8, unit: 'verres' }}/>
        <HabitRowV15 name="Marche" freq="Quotidien"
          color="var(--cat-sante)" done={true}
          objective={{ actual: 6500, target: 5000, unit: 'pas' }}/>
        <HabitRowV15 name="Coucher avant 23h" freq="Quotidien" color="var(--cat-sante)" done={false}/>
      </div>
    </div>
    <BottomNav active="habits"/>
  </Phone>
);

// ============================================================================
// HB-02 v1.5 — Édition habitude with 3 new sections
// ============================================================================

const SubtaskItem = ({ title, onDelete }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0',
    borderBottom: '0.5px solid var(--border-default)'
  }}>
    <V15Icon.GripVertical size={16} stroke="var(--text-tertiary)"/>
    <input className="input" defaultValue={title} style={{
      flex: 1, padding: '8px 12px', minHeight: 36, fontSize: 14, background: 'var(--bg-input)'
    }}/>
    <button style={{
      background: 'none', border: 'none', cursor: 'pointer',
      color: 'var(--danger)', padding: 4, display: 'flex'
    }}>
      <V15Icon.Trash2 size={16} stroke="var(--danger)"/>
    </button>
  </div>
);

const ScreenHB02v15 = () => {
  const [objOn, setObjOn] = React.useState(true);
  const [timerOn, setTimerOn] = React.useState(true);
  const [subtasksOn, setSubtasksOn] = React.useState(true);
  const [unit, setUnit] = React.useState('Minutes');
  const [allRequired, setAllRequired] = React.useState(true);
  const timerCompatible = unit === 'Minutes' || unit === 'Heures';

  return (
    <Phone>
      <HeaderBack title="Modifier l'habitude"/>
      <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
        <div className="screen" style={{ paddingTop: 20, paddingBottom: 100 }}>
          <div style={{ marginBottom: 20 }}>
            <label className="field-label">Nom de l'habitude</label>
            <input className="input" defaultValue="Méditation matinale"/>
          </div>

          <div style={{ marginBottom: 20 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <span className="label">CATÉGORIE</span>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              <span className="chip"><span className="dot" style={{ background: 'var(--cat-religion)' }}/> Religion</span>
              <span className="chip active"><span className="dot" style={{ background: 'var(--cat-mental)' }}/> Mental</span>
              <span className="chip"><span className="dot" style={{ background: 'var(--cat-sport)' }}/> Sport</span>
              <span className="chip"><span className="dot" style={{ background: 'var(--cat-sante)' }}/> Santé</span>
            </div>
          </div>

          <div style={{ marginBottom: 20 }}>
            <div className="label" style={{ marginBottom: 10 }}>FRÉQUENCE</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
              <span className="chip active" style={{ justifyContent: 'center' }}>Quotidien</span>
              <span className="chip" style={{ justifyContent: 'center' }}>3×/sem</span>
              <span className="chip" style={{ justifyContent: 'center' }}>5×/sem</span>
            </div>
          </div>

          <div style={{ marginBottom: 20 }}>
            <div className="label" style={{ marginBottom: 10 }}>JOURS ACTIFS</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6 }}>
              {['L','M','M','J','V','S','D'].map((d, i) => (
                <button key={i} style={{
                  aspectRatio: 1,
                  background: 'var(--accent)',
                  color: 'var(--text-on-accent)',
                  border: '0.5px solid var(--accent)',
                  borderRadius: 8, fontWeight: 500, fontSize: 13, cursor: 'pointer'
                }}>{d}</button>
              ))}
            </div>
          </div>

          {/* ============== NEW SECTION 1 — OBJECTIF CHIFFRÉ ============== */}
          <CollapsibleSection
            label="OBJECTIF CHIFFRÉ"
            toggle={true} on={objOn} onToggle={setObjOn}
            defaultOpen={true}
          >
            <div style={{ display: 'grid', gridTemplateColumns: '110px 1fr', gap: 10, marginTop: 8 }}>
              <div>
                <label className="field-label" style={{ fontSize: 11 }}>Valeur</label>
                <input className="input" defaultValue="20" type="number"
                  style={{ fontFamily: 'var(--font-mono)', textAlign: 'center', minHeight: 44 }}/>
              </div>
              <div>
                <label className="field-label" style={{ fontSize: 11 }}>Unité</label>
                <div className="input-wrap">
                  <select value={unit} onChange={(e) => setUnit(e.target.value)} className="input with-icon-right"
                    style={{ appearance: 'none', minHeight: 44, cursor: 'pointer' }}>
                    {['Minutes','Heures','Pages','Verres','Répétitions','Séries','Kilomètres','Mètres','Pas','Personnalisé...'].map(u => (
                      <option key={u} value={u}>{u}</option>
                    ))}
                  </select>
                  <span className="input-icon-right"><Icon.ChevronDown size={16}/></span>
                </div>
              </div>
            </div>
            <p className="caption" style={{ marginTop: 10, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              L'utilisateur devra atteindre cette valeur pour valider l'habitude.
            </p>
          </CollapsibleSection>

          {/* ============== NEW SECTION 2 — SOUS-TÂCHES ============== */}
          <CollapsibleSection
            label="SOUS-TÂCHES"
            count="3 / 15"
            toggle={true} on={subtasksOn} onToggle={setSubtasksOn}
            defaultOpen={true}
          >
            <div style={{ marginTop: 4 }}>
              <SubtaskItem title="Trouver un endroit calme"/>
              <SubtaskItem title="Régler la posture"/>
              <SubtaskItem title="Respiration consciente 5 min"/>
            </div>
            <button className="btn-ghost" style={{ marginTop: 12, minHeight: 40, fontSize: 13 }}>
              <Icon.Plus size={14}/> Ajouter une sous-tâche
            </button>
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '14px 0 0', marginTop: 4
            }}>
              <div>
                <div className="h3" style={{ fontSize: 13 }}>Toutes obligatoires pour valider</div>
                <div className="caption" style={{ marginTop: 2 }}>
                  Si désactivé, juste un aide-mémoire
                </div>
              </div>
              <V15Toggle on={allRequired} onChange={setAllRequired}/>
            </div>
          </CollapsibleSection>

          {/* ============== NEW SECTION 3 — TIMER (conditional) ============== */}
          <CollapsibleSection
            label="TIMER IN-APP"
            toggle={true}
            on={timerCompatible ? timerOn : false}
            onToggle={(v) => timerCompatible && setTimerOn(v)}
            defaultOpen={true}
          >
            {timerCompatible ? (
              <>
                <p className="caption" style={{ marginTop: 4, lineHeight: 1.6, color: 'var(--text-secondary)' }}>
                  L'utilisateur pourra démarrer un compte à rebours
                  de <span className="mono" style={{ color: 'var(--text-primary)' }}>20 minutes</span>.
                  Le timer continue en background.
                </p>
                <div style={{
                  marginTop: 12, padding: 14, background: 'var(--bg-input)',
                  borderRadius: 12, display: 'flex', alignItems: 'center', gap: 14
                }}>
                  <div style={{
                    width: 56, height: 56, borderRadius: '50%',
                    border: '2px solid var(--accent)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontFamily: 'var(--font-mono)', fontSize: 13, fontWeight: 500,
                    color: 'var(--accent)'
                  }}>
                    20:00
                  </div>
                  <div style={{ flex: 1 }}>
                    <div className="caption" style={{ fontWeight: 500, color: 'var(--text-primary)', marginBottom: 2 }}>Aperçu Timer</div>
                    <div className="caption">Modal HB-EXECUTE</div>
                  </div>
                </div>
              </>
            ) : (
              <div style={{
                padding: 14, background: 'var(--bg-input)', borderRadius: 12,
                display: 'flex', alignItems: 'flex-start', gap: 10
              }}>
                <Icon.AlertTriangle size={16} stroke="var(--text-tertiary)" style={{ marginTop: 2, flexShrink: 0 }}/>
                <p className="caption" style={{ margin: 0, lineHeight: 1.5 }}>
                  Le timer n'est disponible qu'avec une unité de temps (minutes, heures).
                  L'unité actuelle <span className="mono" style={{ color: 'var(--text-primary)' }}>{unit}</span> n'est pas chronométrable.
                </p>
              </div>
            )}
          </CollapsibleSection>

          {/* Aperçu notification (existing) */}
          <div style={{ marginBottom: 24, marginTop: 24 }}>
            <div className="label" style={{ marginBottom: 10 }}>APERÇU NOTIFICATION</div>
            <div className="card" style={{ padding: 14, background: 'var(--bg-input)', border: 'none' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                <Logo size={18}/>
                <span className="caption" style={{ fontWeight: 500 }}>Murabbi</span>
                <span className="caption" style={{ marginLeft: 'auto', color: 'var(--text-tertiary)' }}>maintenant</span>
              </div>
              <div className="h3" style={{ marginBottom: 2 }}>Méditation matinale</div>
              <div className="caption" style={{ color: 'var(--text-secondary)' }}>
                C'est l'heure. 20 minutes pour ancrer la journée.
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="sticky-bottom no-nav">
        <button className="btn-primary">Enregistrer</button>
      </div>
    </Phone>
  );
};

// ============================================================================
// HB-DETAIL v1.5 — Detail screen with "Aujourd'hui" card + GitHub-style graph
// ============================================================================

// GitHub-style 30-day vertical bars
const Github30dGraph = ({ data, unit = 'pages' }) => (
  <div>
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 2, height: 40, marginBottom: 8 }}>
      {data.map((d, i) => {
        const ratio = d / 100;
        let bg = 'transparent';
        let fillH = 0;
        if (d === 0) { bg = 'transparent'; }
        else if (ratio < 0.5) { bg = 'rgba(107,140,107,0.30)'; fillH = 25; }
        else if (ratio < 1) { bg = 'rgba(107,140,107,0.60)'; fillH = 75; }
        else { bg = 'var(--success)'; fillH = 100; }
        return (
          <div key={i} style={{
            flex: 1, height: 40, position: 'relative',
            border: d === 0 ? '0.5px solid var(--text-tertiary)' : 'none',
            borderRadius: 2, background: 'var(--bg-input)', overflow: 'hidden'
          }}>
            <div style={{
              position: 'absolute', bottom: 0, left: 0, right: 0,
              height: `${fillH}%`, background: bg, borderRadius: 2
            }}/>
          </div>
        );
      })}
    </div>
    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
      <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>il y a 30j</span>
      <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>aujourd'hui</span>
    </div>
    <p className="caption" style={{ marginTop: 12, fontFamily: 'var(--font-mono)' }}>
      Moyenne 30j : <span style={{ color: 'var(--text-primary)' }}>4.2 {unit}</span>
    </p>
  </div>
);

const ScreenHBDetailV15 = () => {
  // Demo: Lecture du Coran with objectif chiffré (5 pages)
  const data30 = [80,100,40,100,100,60,100,100,30,100,80,100,100,0,100,60,100,80,100,100,100,40,100,100,80,100,100,100,80,60];
  return (
    <Phone>
      <HeaderBack title="Lecture du Coran"/>
      <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
        <div className="screen" style={{ paddingTop: 18, paddingBottom: 100 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 18 }}>
            <span className="dot" style={{ background: 'var(--cat-religion)' }}/>
            <span className="caption">Religion · Quotidien · 5 pts · 06:00–08:00</span>
          </div>

          {/* AUJOURD'HUI card — NEW */}
          <div style={{
            padding: 22, borderRadius: 16,
            background: 'var(--bg-surface)',
            border: '0.5px solid var(--border-default)',
            marginBottom: 22
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
              <span className="label">AUJOURD'HUI</span>
              <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>26 avr</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 4 }}>
              <span className="display" style={{ fontSize: 44, color: 'var(--accent)' }}>3</span>
              <span className="display" style={{ fontSize: 22, color: 'var(--text-tertiary)' }}>/ 5</span>
              <span className="caption" style={{ marginLeft: 8 }}>pages</span>
            </div>
            <div style={{ marginTop: 14, marginBottom: 18 }}>
              <MiniProgressBar actual={3} target={5} width="100%" height={6}/>
            </div>
            <button className="btn-primary">
              <V15Icon.Play size={16} stroke="white"/> Reprendre la lecture
            </button>
            <p className="caption" style={{ textAlign: 'center', marginTop: 10, color: 'var(--text-secondary)' }}>
              2 pages restantes pour valider
            </p>
          </div>

          {/* STATS GRID 2×2 */}
          <div className="label" style={{ marginBottom: 10 }}>STATISTIQUES</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 24 }}>
            <div className="card" style={{ padding: 16 }}>
              <div className="stat-label" style={{ fontSize: 10, textTransform: 'uppercase', color: 'var(--text-tertiary)', letterSpacing: 0.6 }}>STREAK</div>
              <div className="display" style={{ fontSize: 28, marginTop: 4 }}>14<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>j</span></div>
              <div className="caption" style={{ marginTop: 2, color: 'var(--success)' }}>+2 cette semaine</div>
            </div>
            <div className="card" style={{ padding: 16 }}>
              <div className="stat-label" style={{ fontSize: 10, textTransform: 'uppercase', color: 'var(--text-tertiary)', letterSpacing: 0.6 }}>RECORD</div>
              <div className="display" style={{ fontSize: 28, marginTop: 4 }}>32<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>j</span></div>
              <div className="caption" style={{ marginTop: 2 }}>il y a 2 mois</div>
            </div>
            <div className="card" style={{ padding: 16 }}>
              <div className="stat-label" style={{ fontSize: 10, textTransform: 'uppercase', color: 'var(--text-tertiary)', letterSpacing: 0.6 }}>TAUX 30J</div>
              <div className="display" style={{ fontSize: 28, marginTop: 4 }}>87<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>%</span></div>
              <div className="caption" style={{ marginTop: 2 }}>26 / 30 jours</div>
            </div>
            <div className="card" style={{ padding: 16 }}>
              <div className="stat-label" style={{ fontSize: 10, textTransform: 'uppercase', color: 'var(--text-tertiary)', letterSpacing: 0.6 }}>TOTAL</div>
              <div className="display" style={{ fontSize: 28, marginTop: 4 }}>284<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>p</span></div>
              <div className="caption" style={{ marginTop: 2 }}>depuis le 12 mars</div>
            </div>
          </div>

          {/* PROGRESSION 30 JOURS — NEW GitHub-style */}
          <div className="label" style={{ marginBottom: 12 }}>PROGRESSION 30 JOURS</div>
          <div className="card" style={{ padding: 16, marginBottom: 24 }}>
            <Github30dGraph data={data30} unit="pages"/>
          </div>

          {/* HISTORIQUE RÉCENT */}
          <div className="label" style={{ marginBottom: 10 }}>HISTORIQUE RÉCENT</div>
          <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 24 }}>
            {[
              ['Aujourd\'hui', '3 / 5 pages', 'partial'],
              ['Hier', '5 / 5 pages', 'ontime'],
              ['Mer. 24', '4 / 5 pages', 'late'],
              ['Mar. 23', '5 / 5 pages', 'ontime'],
              ['Lun. 22', '6 / 5 pages', 'ontime'],
              ['Dim. 21', '0 / 5 pages', 'missed'],
              ['Sam. 20', '5 / 5 pages', 'ontime'],
            ].map(([d, val, st], i, a) => (
              <div key={i} style={{
                padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12,
                borderBottom: i < a.length - 1 ? '0.5px solid var(--border-default)' : 'none'
              }}>
                <span className={`dot-status s-${st === 'partial' ? 'late' : st}`} style={{ width: 8, height: 8 }}/>
                <span className="body" style={{ flex: 1, fontSize: 13 }}>{d}</span>
                <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>{val}</span>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', gap: 10 }}>
            <button className="btn-secondary"><Icon.Edit size={16}/> Modifier</button>
            <button className="btn-destructive"><Icon.Trash size={16}/> Supprimer</button>
          </div>
        </div>
      </div>
    </Phone>
  );
};

// HB-DETAIL — variant with subtasks-only habit
const ScreenHBDetailV15Subtasks = () => (
  <Phone>
    <HeaderBack title="Routine du matin"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 18, paddingBottom: 100 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 18 }}>
          <span className="dot" style={{ background: 'var(--cat-religion)' }}/>
          <span className="caption">Religion · Quotidien · 8 pts · 06:00–07:30</span>
        </div>

        <div style={{
          padding: 22, borderRadius: 16,
          background: 'var(--bg-surface)', border: '0.5px solid var(--border-default)',
          marginBottom: 22
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <span className="label">AUJOURD'HUI</span>
            <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>3 / 5 cochées</span>
          </div>

          {/* Subtasks list */}
          <div style={{ marginBottom: 18 }}>
            {[
              ['Ablutions complètes', true],
              ['2 raka\'ats du Fajr', true],
              ['Dhikr du matin (33×)', true],
              ['Lecture des Mu\'awwidhat', false],
              ['Du\'a du matin', false],
            ].map(([title, done], i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0',
                borderBottom: i < 4 ? '0.5px solid var(--border-default)' : 'none'
              }}>
                <MiniCheckbox checked={done}/>
                <span style={{
                  flex: 1, fontSize: 14, color: done ? 'var(--text-tertiary)' : 'var(--text-primary)',
                  textDecoration: done ? 'line-through' : 'none'
                }}>{title}</span>
                <span className="caption" style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-tertiary)' }}>{i + 1}</span>
              </div>
            ))}
          </div>

          <button className="btn-primary" disabled>
            Cochez toutes les sous-tâches obligatoires
          </button>
        </div>

        <div className="label" style={{ marginBottom: 12 }}>PROGRESSION 30 JOURS</div>
        <div className="card" style={{ padding: 16, marginBottom: 16 }}>
          <Github30dGraph data={[100,100,40,100,100,60,100,100,0,100,80,100,100,40,100,60,100,80,100,100,100,40,100,100,80,100,100,100,80,60]} unit="cochées"/>
        </div>
      </div>
    </div>
  </Phone>
);

// HB-DETAIL — variant with timer-only habit
const ScreenHBDetailV15Timer = () => (
  <Phone>
    <HeaderBack title="Méditation"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 18, paddingBottom: 100 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 18 }}>
          <span className="dot" style={{ background: 'var(--cat-mental)' }}/>
          <span className="caption">Mental · Quotidien · 6 pts · 06:30–07:00</span>
        </div>

        <div style={{
          padding: 22, borderRadius: 16,
          background: 'var(--bg-surface)', border: '0.5px solid var(--border-default)',
          marginBottom: 22
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <span className="label">AUJOURD'HUI</span>
            <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>20 min</span>
          </div>

          <div style={{ textAlign: 'center', padding: '10px 0 18px' }}>
            <div className="display" style={{ fontSize: 56, color: 'var(--text-primary)', letterSpacing: '-1.5px' }}>20:00</div>
            <p className="caption" style={{ fontFamily: 'var(--font-mono)', marginTop: 4 }}>min · sec</p>
          </div>

          <button className="btn-primary">
            <V15Icon.Play size={16} stroke="white"/> Démarrer le timer (20 min)
          </button>
          <p className="caption" style={{ textAlign: 'center', marginTop: 10 }}>
            Le timer continue en background
          </p>
        </div>

        <div className="label" style={{ marginBottom: 12 }}>PROGRESSION 30 JOURS</div>
        <div className="card" style={{ padding: 16 }}>
          <Github30dGraph data={[100,100,100,80,100,60,100,100,40,100,100,100,80,0,100,60,100,80,100,100,100,40,100,100,80,100,100,100,80,0]} unit="min"/>
        </div>
      </div>
    </div>
  </Phone>
);

Object.assign(window, {
  V15Icon, MiniProgressBar, TimerBadge, PulseDot, V15Toggle,
  CollapsibleSection, MiniCheckbox, Github30dGraph,
  HM01HabitMicroRow, HabitRowV15,
  ScreenHM01v15, ScreenHB01v15, ScreenHB02v15,
  ScreenHBDetailV15, ScreenHBDetailV15Subtasks, ScreenHBDetailV15Timer,
});
