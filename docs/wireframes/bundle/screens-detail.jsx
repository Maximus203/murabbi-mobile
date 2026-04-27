// Murabbi — Detail, Settings, Special, Empty (HB-DETAIL, CO-DETAIL, SL-DETAIL, NIYYAH-EDIT, ST-01..03, LEVEL-UP, CAL-01, EMPTY)

const ScreenHBDetail = () => (
  <Phone>
    <HeaderBack title="Lecture du Coran"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 18 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 18 }}>
          <span className="dot" style={{ background: 'var(--cat-religion)' }}/>
          <span className="caption">Religion · Quotidien · 5 pts</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 24 }}>
          <div className="card" style={{ padding: 14 }}>
            <div className="stat-label">STREAK</div>
            <div className="display" style={{ fontSize: 28, marginTop: 4 }}>14<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>j</span></div>
          </div>
          <div className="card" style={{ padding: 14 }}>
            <div className="stat-label">RECORD</div>
            <div className="display" style={{ fontSize: 28, marginTop: 4 }}>32<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>j</span></div>
          </div>
          <div className="card" style={{ padding: 14 }}>
            <div className="stat-label">TAUX 30J</div>
            <div className="display" style={{ fontSize: 28, marginTop: 4 }}>87<span style={{ fontSize: 14, color: 'var(--text-tertiary)' }}>%</span></div>
          </div>
        </div>

        <div className="label" style={{ marginBottom: 12 }}>30 DERNIERS JOURS</div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(10, 1fr)', gap: 5, marginBottom: 12 }}>
          {Array.from({ length: 30 }).map((_, i) => {
            const r = (i * 7) % 11;
            const c = r < 6 ? 'var(--success)' : r < 8 ? 'var(--warning)' : r < 9 ? 'var(--danger)' : 'var(--bg-input)';
            return <div key={i} style={{ aspectRatio: 1, background: c, borderRadius: 4 }}/>;
          })}
        </div>
        <div style={{ display: 'flex', gap: 14, marginBottom: 24 }}>
          <span className="caption" style={{ display: 'flex', alignItems: 'center', gap: 5 }}><span className="dot-status s-ontime" style={{ width: 8, height: 8 }}/> Fait</span>
          <span className="caption" style={{ display: 'flex', alignItems: 'center', gap: 5 }}><span className="dot-status s-late" style={{ width: 8, height: 8 }}/> En retard</span>
          <span className="caption" style={{ display: 'flex', alignItems: 'center', gap: 5 }}><span className="dot-status s-missed" style={{ width: 8, height: 8 }}/> Manqué</span>
        </div>

        <div className="label" style={{ marginBottom: 10 }}>HISTORIQUE</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 24 }}>
          {[
            ['Aujourd\'hui', 'À l\'heure', 'ontime'],
            ['Hier', 'À l\'heure', 'ontime'],
            ['Mer. 24', 'En retard', 'late'],
            ['Mar. 23', 'À l\'heure', 'ontime'],
            ['Lun. 22', 'À l\'heure', 'ontime'],
            ['Dim. 21', 'Manqué', 'missed'],
            ['Sam. 20', 'À l\'heure', 'ontime'],
          ].map(([d, s, st], i, a) => (
            <div key={i} style={{
              padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
              borderBottom: i < a.length - 1 ? '0.5px solid var(--border-default)' : 'none'
            }}>
              <span className={`dot-status s-${st}`} style={{ width: 8, height: 8 }}/>
              <span className="body" style={{ flex: 1 }}>{d}</span>
              <span className="caption">{s}</span>
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

const ScreenCODetail = () => (
  <Phone>
    <HeaderBack title="Matin du musulman"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 18, paddingBottom: 100 }}>
        <p className="body body-secondary" style={{ marginTop: 0, marginBottom: 24 }}>
          Une routine sobre pour ancrer le matin : Coran, dhikr, deux raka'ats, et l'eau du jour.
        </p>

        <div className="label" style={{ marginBottom: 10 }}>HABITUDES INCLUSES</div>
        <HabitItemSimple name="Lecture du Coran" freq="Quotidien · 15 min" pts={5} color="var(--cat-religion)"/>
        <HabitItemSimple name="Dhikr du matin" freq="Quotidien · 5 min" pts={3} color="var(--cat-religion)"/>
        <HabitItemSimple name="Deux raka'ats" freq="Quotidien" pts={4} color="var(--cat-religion)"/>
        <HabitItemSimple name="Premier verre d'eau" freq="Quotidien" pts={2} color="var(--cat-sante)"/>

        <div style={{ marginTop: 22, padding: '14px 16px', borderRadius: 12,
          background: 'var(--accent-light)', border: '0.5px solid var(--accent-border)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div className="label" style={{ color: 'var(--accent)' }}>POTENTIEL JOURNALIER</div>
            <h2 className="h2" style={{ marginTop: 4, color: 'var(--accent)' }}>14 points</h2>
          </div>
          <span className="mono" style={{ fontSize: 28, color: 'var(--accent)' }}>+14</span>
        </div>
      </div>
    </div>
    <div className="sticky-bottom no-nav">
      <button className="btn-primary">Activer cette collection</button>
    </div>
  </Phone>
);

const HabitItemSimple = ({ name, freq, pts, color }) => (
  <div className="card" style={{ padding: 14, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 12 }}>
    <span className="dot" style={{ background: color }}/>
    <div style={{ flex: 1 }}>
      <div className="h3">{name}</div>
      <div className="caption">{freq}</div>
    </div>
    <span className="mono" style={{ fontSize: 14, color: 'var(--accent)', fontWeight: 500 }}>+{pts}</span>
  </div>
);

const ScreenSLDetail = () => (
  <Phone>
    <div style={{ position: 'relative', height: 200 }}>
      <video autoPlay muted loop playsInline poster="media/07_fallback.png"
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', zIndex: 1 }}>
        <source src="media/07.mp4" type="video/mp4"/>
      </video>
      <div className="video-overlay-dark" style={{ zIndex: 2 }}/>
      <div style={{ position: 'absolute', inset: 0, zIndex: 3, padding: '20px 24px',
        display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <div className="status-bar dark" style={{ padding: 0, height: 'auto', flex: 1 }}>
            <div>6:14</div>
          </div>
          <button style={{ background: 'rgba(253,251,248,0.15)', border: 'none', borderRadius: '50%',
            width: 32, height: 32, color: 'var(--text-on-dark)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon.X size={16} stroke="var(--text-on-dark)"/>
          </button>
        </div>
        <div>
          <div style={{ fontFamily: 'var(--font-arabic)', fontSize: 32, fontWeight: 500, color: 'var(--text-on-dark)' }}>العصر</div>
          <h1 className="h1" style={{ color: 'var(--text-on-dark)', marginTop: 6 }}>Asr</h1>
          <div className="caption" style={{ color: 'rgba(253,251,248,0.8)', fontFamily: 'var(--font-mono)', marginTop: 2 }}>15:42 · dans 1h 18min</div>
        </div>
      </div>
    </div>

    <div className="screen" style={{ paddingTop: 22 }}>
      <div className="card" style={{ padding: 14, background: 'var(--warning-light)',
        borderColor: 'rgba(155,94,60,0.25)', display: 'flex', alignItems: 'center', gap: 12, marginBottom: 22 }}>
        <span className="dot-status s-late"/>
        <div className="h3" style={{ color: 'var(--warning)' }}>Statut actuel : En retard</div>
      </div>

      <div className="label" style={{ marginBottom: 10 }}>MARQUER COMME</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 14 }}>
        <StatusBtn icon={<span className="dot-status s-ontime"/>} label="À l'heure" active/>
        <StatusBtn icon={<span className="dot-status s-late"/>} label="En retard"/>
        <StatusBtn icon={<span className="dot-status s-missed"/>} label="Manquée"/>
        <StatusBtn icon={<Icon.X size={12} stroke="var(--text-tertiary)"/>} label="Réinitialiser"/>
      </div>

      <div className="card" style={{ padding: 14, display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
        <div>
          <div className="h3" style={{ fontSize: 13 }}>Marquer comme rattrapée</div>
          <div className="caption">À effectuer plus tard</div>
        </div>
        <Toggle on={false}/>
      </div>

      <div className="label" style={{ marginBottom: 10 }}>CETTE SEMAINE</div>
      <div style={{ display: 'flex', gap: 8 }}>
        {['L','M','M','J','V','S','D'].map((d, i) => {
          const st = [0,2,4].includes(i) ? 'ontime' : i === 1 ? 'late' : i === 3 ? 'missed' : 'pending';
          return (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <span className="caption" style={{ fontSize: 10 }}>{d}</span>
              <span className={`dot-status s-${st}`} style={{ width: 12, height: 12 }}/>
            </div>
          );
        })}
      </div>
    </div>
  </Phone>
);

const StatusBtn = ({ icon, label, active }) => (
  <button style={{
    padding: '14px 12px', borderRadius: 10,
    background: active ? 'var(--accent-light)' : 'var(--bg-surface)',
    border: '0.5px solid ' + (active ? 'var(--accent-border)' : 'var(--border-emphasis)'),
    color: active ? 'var(--accent)' : 'var(--text-primary)',
    display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, fontWeight: 500, cursor: 'pointer'
  }}>{icon} {label}</button>
);

const ScreenNiyyahEdit = () => (
  <Phone>
    <div style={{ position: 'relative', height: 100 }}>
      <video autoPlay muted loop playsInline poster="media/01_fallback.png"
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', zIndex: 1 }}>
        <source src="media/01.mp4" type="video/mp4"/>
      </video>
      <div className="video-overlay-dark" style={{ zIndex: 2 }}/>
      <div style={{ position: 'absolute', inset: 0, zIndex: 3, padding: '14px 24px',
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div className="label" style={{ color: 'rgba(253,251,248,0.85)', letterSpacing: '1.5px' }}>INTENTION DU JOUR</div>
        <button style={{ background: 'rgba(253,251,248,0.15)', border: 'none', borderRadius: '50%',
          width: 28, height: 28, color: 'var(--text-on-dark)', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon.X size={14} stroke="var(--text-on-dark)"/>
        </button>
      </div>
    </div>
    <div className="screen" style={{ paddingTop: 28, paddingBottom: 100 }}>
      <h1 className="h1">Votre intention du jour.</h1>
      <p className="body body-secondary" style={{ marginTop: 8, marginBottom: 24 }}>
        Une phrase. Pour vous rappeler à quoi vous tenez.
      </p>
      <textarea className="input" rows={6}
        style={{ minHeight: 180, resize: 'vertical', paddingTop: 16, fontStyle: 'italic', fontSize: 16, lineHeight: 1.5 }}
        placeholder="Aujourd'hui, je m'engage à..."
        defaultValue={"Aujourd'hui, je m'engage à prier à l'heure et à offrir une parole douce à un proche."}/>
      <div className="caption" style={{ textAlign: 'right', marginTop: 6, fontFamily: 'var(--font-mono)' }}>87 / 200</div>
    </div>
    <div className="sticky-bottom no-nav">
      <button className="btn-primary">Confirmer cette intention</button>
    </div>
  </Phone>
);

// ST-01 Settings
const SettingRow = ({ icon: Ic, label, value, danger = false, external = false, last = false }) => (
  <div style={{
    padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer',
    borderBottom: last ? 'none' : '0.5px solid var(--border-default)',
    color: danger ? 'var(--danger)' : 'var(--text-primary)'
  }}>
    {Ic && <Ic size={18} stroke={danger ? 'var(--danger)' : 'var(--text-secondary)'}/>}
    <span className="body" style={{ flex: 1, color: danger ? 'var(--danger)' : 'var(--text-primary)' }}>{label}</span>
    {value && <span className="caption">{value}</span>}
    {external ? <Icon.ExternalLink size={16} stroke="var(--text-tertiary)"/>
      : <Icon.ChevronRight size={16} stroke="var(--text-tertiary)"/>}
  </div>
);

const SectionLabel = ({ children }) => (
  <div className="label" style={{ margin: '24px 4px 8px' }}>{children}</div>
);

const ScreenST01 = () => (
  <Phone>
    <HeaderTitle title="Paramètres"/>
    <div className="phone-scroll" style={{ top: 100, paddingTop: 0 }}>
      <div className="screen">
        {/* profile card */}
        <div className="card" style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: 'var(--accent)', color: 'var(--text-on-accent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 20, fontWeight: 500, flexShrink: 0
          }}>C</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="h3">Cherif Benkacem</div>
            <div className="caption" style={{ marginTop: 2 }}>cherif@exemple.com</div>
            <div style={{ marginTop: 6 }}>
              <span className="badge-level"><Icon.Star size={11} stroke="var(--accent)"/> Niveau 2 · Aspirant</span>
            </div>
          </div>
          <Icon.ChevronRight size={18} stroke="var(--text-tertiary)"/>
        </div>

        <SectionLabel>COMPTE</SectionLabel>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <SettingRow icon={Icon.Edit} label="Modifier le profil"/>
          <SettingRow icon={Icon.Bell} label="Notifications" value="Activées"/>
          <SettingRow icon={Icon.Sun} label="Apparence" value="Clair" last/>
        </div>

        <SectionLabel>PRATIQUE</SectionLabel>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <SettingRow icon={Icon.Compass} label="Horaires de prière" value="MWL · Paris"/>
          <SettingRow icon={Icon.Star} label="Objectif quotidien" value="60 pts"/>
          <SettingRow icon={Icon.Calendar} label="Démarrage de semaine" value="Lundi"/>
          <SettingRow icon={Icon.Globe} label="Langue" value="Français" last/>
        </div>

        <SectionLabel>CONFIDENTIALITÉ</SectionLabel>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <SettingRow icon={Icon.Lock} label="Politique de confidentialité" external/>
          <SettingRow icon={Icon.Book} label="Conditions d'utilisation" external last/>
        </div>

        <SectionLabel>À PROPOS</SectionLabel>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
            borderBottom: '0.5px solid var(--border-default)' }}>
            <Icon.Circle size={18} stroke="var(--text-secondary)"/>
            <span className="body" style={{ flex: 1 }}>Version</span>
            <span className="caption mono">v1.0.0 (1)</span>
          </div>
          <SettingRow icon={Icon.Heart} label="Contact / Support" last/>
        </div>

        <div style={{ height: 24 }}/>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <div style={{
            padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer',
            color: 'var(--text-secondary)'
          }}>
            <Icon.LogOut size={18} stroke="var(--text-secondary)"/>
            <span className="body body-secondary" style={{ flex: 1 }}>Se déconnecter</span>
          </div>
        </div>

        <SectionLabel>ZONE SENSIBLE</SectionLabel>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 24 }}>
          <SettingRow icon={Icon.Trash} label="Supprimer mon compte" danger last/>
        </div>
      </div>
    </div>
    <BottomNav active="home"/>
  </Phone>
);

// ST-02 Modifier profil
const ScreenST02 = () => (
  <Phone>
    <HeaderBack title="Mon profil"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 28, paddingBottom: 40 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10, marginBottom: 32 }}>
          <div style={{
            width: 88, height: 88, borderRadius: '50%',
            background: 'var(--accent)', color: 'var(--text-on-accent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 32, fontWeight: 500
          }}>C</div>
          <button className="link-tertiary">Modifier la photo</button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div>
            <label className="field-label">Nom complet</label>
            <input className="input" defaultValue="Cherif Benkacem"/>
          </div>
          <div>
            <label className="field-label">Email</label>
            <div className="input-wrap">
              <input className="input with-icon-right" defaultValue="cherif@exemple.com" disabled/>
              <span className="input-icon-right"><Icon.Lock size={14}/></span>
            </div>
          </div>
          <div>
            <label className="field-label">Pseudonyme (classement)</label>
            <input className="input" defaultValue="Cherif"/>
            <p className="caption" style={{ margin: '6px 0 0' }}>Apparaîtra publiquement sur le classement.</p>
          </div>
        </div>
        <div style={{ marginTop: 28 }}>
          <button className="btn-primary">Enregistrer</button>
        </div>
      </div>
    </div>
  </Phone>
);

// ST-03 Supprimer compte
const ScreenST03 = () => {
  const [val, setVal] = React.useState('');
  return (
    <Phone>
      <HeaderBack title="Supprimer le compte"/>
      <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
        <div className="screen" style={{ paddingTop: 28, paddingBottom: 40 }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 16, marginBottom: 24 }}>
            <div style={{
              width: 56, height: 56, borderRadius: 14,
              background: 'var(--danger-light)',
              border: '0.5px solid rgba(140,61,61,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <Icon.AlertTriangle size={26} stroke="var(--danger)"/>
            </div>
            <h1 className="h1" style={{ textWrap: 'balance' }}>Cette action est irréversible.</h1>
            <p className="body body-secondary" style={{ margin: 0 }}>
              Votre compte et l'ensemble de vos données seront supprimés sous 30 jours. Aucune restauration ne sera possible.
            </p>
          </div>

          <div className="card" style={{ padding: 16, background: 'var(--danger-light)',
            borderColor: 'rgba(140,61,61,0.20)', marginBottom: 24 }}>
            <div className="label" style={{ color: 'var(--danger)', marginBottom: 10 }}>DONNÉES SUPPRIMÉES</div>
            <ul style={{ margin: 0, padding: '0 0 0 16px', color: 'var(--text-primary)', fontSize: 13, lineHeight: 1.8 }}>
              <li>Profil, identifiants, photo</li>
              <li>Historique des prières et habitudes</li>
              <li>Collections personnelles</li>
              <li>Score, streaks et classements</li>
            </ul>
          </div>

          <div>
            <label className="field-label">Saisissez DELETE pour confirmer</label>
            <input className="input" placeholder="DELETE" value={val} onChange={(e) => setVal(e.target.value)}/>
          </div>

          <div style={{ marginTop: 24 }}>
            <button className="btn-destructive" disabled={val !== 'DELETE'}>
              <Icon.Trash size={16}/> Supprimer définitivement
            </button>
          </div>
        </div>
      </div>
    </Phone>
  );
};

// LEVEL-UP
const ScreenLevelUp = () => (
  <Phone dark>
    <div style={{ position: 'absolute', inset: 0, zIndex: 0 }}>
      <video autoPlay muted loop playsInline poster="media/08_fallback.png"
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}>
        <source src="media/08.mp4" type="video/mp4"/>
      </video>
    </div>
    <div className="video-overlay-dark-70" style={{ position: 'absolute', inset: 0, zIndex: 1 }}/>
    <div style={{
      position: 'absolute', inset: 0, zIndex: 3, padding: '60px 24px 40px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'space-between',
      color: 'var(--text-on-dark)', textAlign: 'center'
    }}>
      <div style={{ flex: 1 }}/>
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20 }}>
        <div className="label" style={{ color: 'rgba(253,251,248,0.7)', letterSpacing: '2.5px' }}>NOUVEAU NIVEAU</div>
        <div style={{
          fontFamily: 'var(--font-mono)', fontWeight: 500, fontSize: 48, letterSpacing: '-1.5px',
          color: 'var(--text-on-dark)', lineHeight: 1
        }}>Aspirant</div>
        <div className="h2" style={{ color: 'rgba(253,251,248,0.85)' }}>Niveau 2</div>
        <div style={{
          width: 56, height: 0.5, background: 'rgba(253,251,248,0.4)', margin: '6px 0'
        }}/>
        <p className="body" style={{ color: 'rgba(253,251,248,0.85)', maxWidth: 280, textWrap: 'balance' }}>
          Vous progressez sur l'échelle d'une vie. Patience et régularité.
        </p>
      </div>
      <div style={{ flex: 1 }}/>
      <button className="btn-primary">Continuer</button>
    </div>
  </Phone>
);

// CAL-01 Calendrier
const ScreenCAL01 = () => (
  <Phone>
    <HeaderBack title="Mon historique"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 18 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}>
            <Icon.ChevronLeft size={20} stroke="var(--text-secondary)"/>
          </button>
          <h2 className="h2">Avril 2026</h2>
          <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}>
            <Icon.ChevronRight size={20} stroke="var(--text-secondary)"/>
          </button>
        </div>

        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
          <span className="chip active">Tout</span>
          <span className="chip">Salat</span>
          <span className="chip">Habitudes</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4, marginBottom: 6 }}>
          {['L','M','M','J','V','S','D'].map((d, i) => (
            <div key={i} className="caption" style={{ textAlign: 'center', padding: 6, color: 'var(--text-tertiary)' }}>{d}</div>
          ))}
        </div>

        <div className="cal-grid" style={{ marginBottom: 22 }}>
          {Array.from({ length: 30 }).map((_, i) => {
            const day = i + 1;
            const r = (i * 11 + 3) % 13;
            const cls = day === 26 ? 'selected' : '';
            const mark = r < 6 ? 'var(--success)' : r < 8 ? 'var(--warning)' : r < 9 ? 'var(--danger)' : null;
            return (
              <div key={i} className={`cal-cell ${cls}`} style={{
                background: day === 26 ? 'var(--accent-light)' : 'var(--bg-surface)',
                border: '0.5px solid var(--border-default)'
              }}>
                <div className="cal-num" style={{ color: day === 26 ? 'var(--accent)' : 'var(--text-primary)' }}>{day}</div>
                {mark && <div className="cal-mark" style={{ background: mark }}/>}
              </div>
            );
          })}
        </div>

        <div className="card">
          <div className="label" style={{ marginBottom: 8 }}>VENDREDI 26 AVRIL</div>
          <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap' }}>
            <Stat label="Salat" value="3/5"/>
            <Stat label="Habitudes" value="8/12"/>
            <Stat label="Score" value="42"/>
          </div>
          <p className="body" style={{ marginTop: 12, marginBottom: 0, color: 'var(--text-secondary)' }}>
            Belle régularité. Asr en retard, Maghrib et Isha à venir.
          </p>
        </div>
      </div>
    </div>
    <BottomNav active="home"/>
  </Phone>
);

const Stat = ({ label, value }) => (
  <div>
    <div className="stat-label">{label}</div>
    <div className="stat-value" style={{ fontSize: 18 }}>{value}</div>
  </div>
);

// EMPTY STATES — combined display
const EmptyHabits = () => (
  <Phone>
    <HeaderTitle title="Mes Habitudes" action={
      <button className="btn-icon"><Icon.Plus size={20} stroke="var(--accent)"/></button>}/>
    <div className="screen" style={{ paddingTop: 60, display: 'flex', flexDirection: 'column',
      alignItems: 'center', textAlign: 'center', gap: 18 }}>
      <svg width="120" height="120" viewBox="0 0 120 120" fill="none">
        <circle cx="60" cy="60" r="46" stroke="var(--text-tertiary)" strokeWidth="0.8" strokeDasharray="2 4"/>
        <circle cx="60" cy="60" r="20" stroke="var(--accent)" strokeWidth="0.8"/>
        <circle cx="60" cy="60" r="3" fill="var(--accent)"/>
      </svg>
      <div>
        <h2 className="h2" style={{ marginBottom: 8 }}>Aucune habitude pour l'instant</h2>
        <p className="body body-secondary" style={{ margin: 0 }}>
          Créez votre première ou activez une collection pré-configurée.
        </p>
      </div>
      <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 10, marginTop: 12 }}>
        <button className="btn-primary">Créer une habitude</button>
        <button className="btn-secondary">Voir les collections</button>
      </div>
    </div>
    <BottomNav active="habits"/>
  </Phone>
);

const EmptyCollections = () => (
  <Phone>
    <HeaderTitle title="Collections" action={
      <button className="btn-icon"><Icon.Plus size={20} stroke="var(--accent)"/></button>}/>
    <div className="screen" style={{ paddingTop: 32 }}>
      <div className="card" style={{ padding: 28, textAlign: 'center', marginBottom: 24 }}>
        <h2 className="h2" style={{ marginBottom: 8 }}>Aucune collection activée</h2>
        <p className="body body-secondary" style={{ margin: 0 }}>
          Activez une collection système ou créez la vôtre pour structurer votre pratique.
        </p>
      </div>
      <div className="label" style={{ marginBottom: 10 }}>SUGGESTIONS · SYSTÈME</div>
      <CollectionCard video="media/06.mp4" fallback="media/06_fallback.png"
        title="Matin du musulman" tags={['Religion', '6 habitudes']}/>
      <CollectionCard video="media/10.mp4" fallback="media/10_fallback.png"
        title="Santé essentielle" tags={['Santé', '5 habitudes']}/>
    </div>
    <BottomNav active="collections"/>
  </Phone>
);

const EmptyLeaderboard = () => (
  <Phone>
    <HeaderTitle title="Classement"/>
    <div className="screen" style={{ paddingTop: 80, textAlign: 'center' }}>
      <svg width="100" height="100" viewBox="0 0 100 100" fill="none" style={{ margin: '0 auto 22px', display: 'block' }}>
        <rect x="20" y="50" width="18" height="30" rx="2" fill="var(--accent-light)" stroke="var(--accent-border)" strokeWidth="0.5"/>
        <rect x="42" y="30" width="18" height="50" rx="2" fill="var(--accent-light)" stroke="var(--accent-border)" strokeWidth="0.5"/>
        <rect x="64" y="60" width="18" height="20" rx="2" fill="var(--accent-light)" stroke="var(--accent-border)" strokeWidth="0.5"/>
      </svg>
      <h2 className="h2" style={{ marginBottom: 8 }}>Pas encore assez de données</h2>
      <p className="body body-secondary" style={{ margin: 0 }}>
        Le classement sera disponible en fin de semaine, dimanche soir.
      </p>
    </div>
    <BottomNav active="leaderboard"/>
  </Phone>
);

const EmptyCalendar = () => (
  <Phone>
    <HeaderBack title="Mon historique"/>
    <div className="screen" style={{ paddingTop: 80, textAlign: 'center' }}>
      <svg width="100" height="100" viewBox="0 0 100 100" fill="none" style={{ margin: '0 auto 22px', display: 'block' }}>
        <rect x="14" y="22" width="72" height="64" rx="6" stroke="var(--text-tertiary)" strokeWidth="0.8" fill="var(--bg-surface)"/>
        <line x1="14" y1="38" x2="86" y2="38" stroke="var(--text-tertiary)" strokeWidth="0.8"/>
        <line x1="32" y1="14" x2="32" y2="28" stroke="var(--text-tertiary)" strokeWidth="0.8" strokeLinecap="round"/>
        <line x1="68" y1="14" x2="68" y2="28" stroke="var(--text-tertiary)" strokeWidth="0.8" strokeLinecap="round"/>
        <circle cx="50" cy="60" r="4" fill="var(--accent)"/>
      </svg>
      <h2 className="h2" style={{ marginBottom: 8 }}>Votre journée commence ici</h2>
      <p className="body body-secondary" style={{ margin: 0 }}>
        Validez votre première prière pour démarrer votre historique.
      </p>
    </div>
  </Phone>
);

Object.assign(window, {
  ScreenHBDetail, ScreenCODetail, ScreenSLDetail, ScreenNiyyahEdit,
  ScreenST01, ScreenST02, ScreenST03, ScreenLevelUp, ScreenCAL01,
  EmptyHabits, EmptyCollections, EmptyLeaderboard, EmptyCalendar,
  HabitItemSimple, StatusBtn, SettingRow, SectionLabel, Stat
});
