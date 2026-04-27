// Murabbi — Core App screens (HM-01, SL-01, HB-01..04, CO-01..02, LB-01)

const ScreenHM01 = () => (
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

        {/* Score card */}
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

        {/* Niyyah card with video */}
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

        {/* Stats grid 2x2 */}
        <div style={{
          marginTop: 16, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10
        }}>
          <StatCard label="Streak" value="14j" trend="up" trendText="+2"/>
          <StatCard label="Salat" value="3/5" trend="flat" trendText="à l'heure"/>
          <StatCard label="Habitudes" value="68%" trend="up" trendText="+4%"/>
          <StatCard label="Classement" value="#7" trend="up" trendText="↗ 2"/>
        </div>

        {/* Next reminder */}
        <button className="card" style={{
          marginTop: 16, width: '100%', display: 'flex', alignItems: 'center', gap: 14,
          textAlign: 'left', cursor: 'pointer', border: '0.5px solid var(--border-default)'
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: '50%',
            background: 'var(--accent-light)',
            display: 'flex', alignItems: 'center', justifyContent: 'center'
          }}>
            <Icon.Bell size={18} stroke="var(--accent)"/>
          </div>
          <div style={{ flex: 1 }}>
            <div className="h3">Prochain rappel · Asr</div>
            <div className="caption">15h42 — dans 1h 18min</div>
          </div>
          <Icon.ChevronRight size={18} stroke="var(--text-tertiary)"/>
        </button>
      </div>
    </div>
    <BottomNav active="home"/>
  </Phone>
);

const StatCard = ({ label, value, trend = 'flat', trendText }) => {
  const T = trend === 'up' ? Icon.TrendingUp : trend === 'down' ? Icon.TrendingDown : Icon.Minus;
  const color = trend === 'up' ? 'var(--success)' : trend === 'down' ? 'var(--danger)' : 'var(--text-tertiary)';
  return (
    <div className="stat-card">
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
      <div className="stat-trend" style={{ color }}>
        <T size={12} stroke={color}/> {trendText}
      </div>
    </div>
  );
};

// SL-01 Salat
const SalatRow = ({ icon: IconC, name, ar, time, status }) => (
  <div className="card" style={{
    padding: 14, display: 'flex', alignItems: 'center', gap: 14, marginBottom: 10
  }}>
    <div style={{
      width: 36, height: 36, borderRadius: '50%',
      background: 'var(--accent-light)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
    }}>
      <IconC size={18} stroke="var(--accent)"/>
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span style={{ fontFamily: 'var(--font-arabic)', fontSize: 17, fontWeight: 500 }}>{ar}</span>
        <span className="h3" style={{ fontWeight: 400, color: 'var(--text-secondary)' }}>{name}</span>
      </div>
      <div className="caption" style={{ fontFamily: 'var(--font-mono)', marginTop: 2 }}>{time}</div>
    </div>
    <button className={`salat-btn ${status === 'pending' ? '' : status}`}>
      {status === 'ontime' && <Icon.Check size={14} stroke="white" strokeWidth={2}/>}
      {status === 'late' && <Icon.Sun size={14} stroke="white"/>}
      {status === 'missed' && <Icon.X size={14} stroke="white" strokeWidth={2}/>}
      {status === 'pending' && <Icon.Circle size={10} stroke="var(--text-tertiary)"/>}
    </button>
  </div>
);

const ScreenSL01 = () => (
  <Phone>
    <div className="phone-scroll" style={{ top: 44, paddingTop: 0 }}>
      {/* Video header bandeau */}
      <div className="card-video" style={{
        height: 130, borderRadius: 0, border: 'none', position: 'relative'
      }}>
        <video autoPlay muted loop playsInline poster="media/09_fallback.png">
          <source src="media/09.mp4" type="video/mp4"/>
        </video>
        <div className="video-overlay-dark"/>
        <div className="video-content" style={{
          padding: '20px 24px',
          height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end'
        }}>
          <h1 className="h1" style={{ color: 'var(--text-on-dark)' }}>Prières du jour</h1>
          <div className="caption" style={{ color: 'rgba(253,251,248,0.75)', marginTop: 4 }}>
            Vendredi 26 avril · 3/5 complétées
          </div>
          <div style={{
            marginTop: 12, height: 3, borderRadius: 2,
            background: 'rgba(253,251,248,0.2)'
          }}>
            <div style={{
              width: '60%', height: '100%', borderRadius: 2,
              background: 'var(--text-on-dark)'
            }}/>
          </div>
        </div>
      </div>

      <div className="screen" style={{ paddingTop: 18 }}>
        <SalatRow icon={Icon.Sunrise} name="Fajr" ar="الفجر" time="06:14" status="ontime"/>
        <SalatRow icon={Icon.Sun} name="Dhuhr" ar="الظهر" time="13:28" status="ontime"/>
        <SalatRow icon={Icon.CloudSun} name="Asr" ar="العصر" time="15:42" status="late"/>
        <SalatRow icon={Icon.Sunset} name="Maghrib" ar="المغرب" time="20:34" status="pending"/>
        <SalatRow icon={Icon.Moon} name="Isha" ar="العشاء" time="22:08" status="pending"/>

        <div className="card" style={{
          marginTop: 18, padding: 14,
          background: 'var(--success-light)',
          borderColor: 'rgba(107,140,107,0.20)',
          display: 'flex', alignItems: 'center', gap: 12
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 14,
            background: 'var(--success)', color: 'white',
            display: 'flex', alignItems: 'center', justifyContent: 'center'
          }}>
            <Icon.Check size={14} stroke="white" strokeWidth={2}/>
          </div>
          <div style={{ flex: 1 }}>
            <div className="h3">2 à l'heure · 1 en retard</div>
            <div className="caption">+12 pts gagnés ce matin</div>
          </div>
        </div>
      </div>
    </div>
    <BottomNav active="salat"/>
  </Phone>
);

// HB-01 Habitudes
const HabitRow = ({ name, freq, color, done = false }) => (
  <div className="card" style={{
    padding: 14, display: 'flex', alignItems: 'center', gap: 14, marginBottom: 8
  }}>
    <span className="dot" style={{ background: color }}/>
    <div style={{ flex: 1 }}>
      <div className="h3">{name}</div>
      <div className="caption">{freq}</div>
    </div>
    <button className={`salat-btn ${done ? 'ontime' : ''}`}>
      {done && <Icon.Check size={14} stroke="white" strokeWidth={2}/>}
    </button>
  </div>
);

const SectionHeader = ({ name, color, count }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '20px 0 10px' }}>
    <span className="dot" style={{ background: color, width: 6, height: 6 }}/>
    <span className="label">{name}</span>
    <span className="caption" style={{ marginLeft: 'auto' }}>{count}</span>
  </div>
);

const ScreenHB01 = () => (
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

        <SectionHeader name="RELIGION" color="var(--cat-religion)" count="3 / 4"/>
        <HabitRow name="Lecture du Coran" freq="Quotidien · 15 min" color="var(--cat-religion)" done={true}/>
        <HabitRow name="Dhikr du matin" freq="Quotidien" color="var(--cat-religion)" done={true}/>
        <HabitRow name="Dhikr du soir" freq="Quotidien" color="var(--cat-religion)" done={false}/>
        <HabitRow name="Prière surérogatoire" freq="3×/semaine" color="var(--cat-religion)" done={true}/>

        <SectionHeader name="SPORT" color="var(--cat-sport)" count="2 / 3"/>
        <HabitRow name="Marche 30 min" freq="Quotidien" color="var(--cat-sport)" done={true}/>
        <HabitRow name="Renforcement" freq="3×/semaine" color="var(--cat-sport)" done={true}/>
        <HabitRow name="Étirements du soir" freq="Quotidien" color="var(--cat-sport)" done={false}/>

        <SectionHeader name="SANTÉ" color="var(--cat-sante)" count="2 / 3"/>
        <HabitRow name="2L d'eau" freq="Quotidien" color="var(--cat-sante)" done={true}/>
        <HabitRow name="Coucher avant 23h" freq="Quotidien" color="var(--cat-sante)" done={false}/>
        <HabitRow name="Pas d'écran après 22h" freq="Quotidien" color="var(--cat-sante)" done={true}/>

        <SectionHeader name="MENTAL" color="var(--cat-mental)" count="1 / 2"/>
        <HabitRow name="Journal du soir" freq="Quotidien" color="var(--cat-mental)" done={true}/>
        <HabitRow name="Méditation 10 min" freq="Quotidien" color="var(--cat-mental)" done={false}/>
      </div>
    </div>
    <BottomNav active="habits"/>
  </Phone>
);

// HB-02 Créer habitude
const ScreenHB02 = () => (
  <Phone>
    <HeaderBack title="Nouvelle habitude"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 20, paddingBottom: 100 }}>
        <div style={{ marginBottom: 24 }}>
          <label className="field-label">Nom de l'habitude</label>
          <input className="input" placeholder="Ex. Lecture du Coran" defaultValue="Dhikr du soir"/>
        </div>

        <div style={{ marginBottom: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <span className="label">CATÉGORIE</span>
            <button className="link-tertiary" style={{ fontSize: 12 }}>Gérer mes catégories</button>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            <span className="chip active"><span className="dot" style={{ background: 'var(--cat-religion)' }}/> Religion <span className="badge-system">Système</span></span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-sport)' }}/> Sport</span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-sante)' }}/> Santé</span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-mental)' }}/> Mental</span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-social)' }}/> Social</span>
          </div>
        </div>

        <div style={{ marginBottom: 24 }}>
          <div className="label" style={{ marginBottom: 10 }}>FRÉQUENCE</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
            <span className="chip active" style={{ justifyContent: 'center' }}>Quotidien</span>
            <span className="chip" style={{ justifyContent: 'center' }}>3×/semaine</span>
            <span className="chip" style={{ justifyContent: 'center' }}>5×/semaine</span>
            <span className="chip" style={{ justifyContent: 'center' }}>Hebdo</span>
            <span className="chip" style={{ justifyContent: 'center' }}>Mensuel</span>
            <span className="chip" style={{ justifyContent: 'center' }}>Custom</span>
          </div>
        </div>

        <div style={{ marginBottom: 24 }}>
          <div className="label" style={{ marginBottom: 10 }}>PLAGE HORAIRE</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div className="input-wrap">
              <input className="input with-icon-right" defaultValue="20:00" readOnly/>
              <span className="input-icon-right"><Icon.ChevronDown size={16}/></span>
            </div>
            <div className="input-wrap">
              <input className="input with-icon-right" defaultValue="22:00" readOnly/>
              <span className="input-icon-right"><Icon.ChevronDown size={16}/></span>
            </div>
          </div>
        </div>

        <div style={{ marginBottom: 24 }}>
          <div className="label" style={{ marginBottom: 10 }}>JOURS ACTIFS</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6 }}>
            {['L','M','M','J','V','S','D'].map((d, i) => (
              <button key={i} style={{
                aspectRatio: 1,
                background: i < 5 ? 'var(--accent)' : 'var(--bg-surface)',
                color: i < 5 ? 'var(--text-on-accent)' : 'var(--text-secondary)',
                border: '0.5px solid ' + (i < 5 ? 'var(--accent)' : 'var(--border-emphasis)'),
                borderRadius: 8, fontWeight: 500, fontSize: 13, cursor: 'pointer'
              }}>{d}</button>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 24 }}>
          <div className="label" style={{ marginBottom: 10 }}>APERÇU NOTIFICATION</div>
          <div className="card" style={{ padding: 14, background: 'var(--bg-input)', border: 'none' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
              <Logo size={18}/>
              <span className="caption" style={{ fontWeight: 500 }}>Murabbi</span>
              <span className="caption" style={{ marginLeft: 'auto', color: 'var(--text-tertiary)' }}>maintenant</span>
            </div>
            <div className="h3" style={{ marginBottom: 2 }}>Dhikr du soir</div>
            <div className="caption" style={{ color: 'var(--text-secondary)' }}>
              C'est l'heure. 5 minutes pour ancrer la journée.
            </div>
          </div>
        </div>
      </div>
    </div>
    <div className="sticky-bottom no-nav">
      <button className="btn-primary">Créer l'habitude</button>
    </div>
  </Phone>
);

// HB-03 Catégories
const CategoryRow = ({ name, color, count, system = false }) => (
  <button className="card" style={{
    width: '100%', padding: 14, display: 'flex', alignItems: 'center', gap: 14,
    marginBottom: 8, cursor: 'pointer', textAlign: 'left'
  }}>
    <span className="dot" style={{ background: color, width: 12, height: 12 }}/>
    <div style={{ flex: 1 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span className="h3">{name}</span>
        {system && <span className="badge-system">Système</span>}
      </div>
      <div className="caption" style={{ marginTop: 2 }}>{count} habitudes</div>
    </div>
    <Icon.ChevronRight size={18} stroke="var(--text-tertiary)"/>
  </button>
);

const ScreenHB03 = () => (
  <Phone>
    <HeaderBack title="Catégories" action={<button className="header-action"><Icon.Plus size={20}/></button>}/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 20 }}>
        <p className="caption" style={{ margin: '0 0 16px' }}>5 catégories · 12 habitudes au total</p>
        <CategoryRow name="Religion" color="var(--cat-religion)" count={4} system/>
        <CategoryRow name="Sport" color="var(--cat-sport)" count={3} system/>
        <CategoryRow name="Santé" color="var(--cat-sante)" count={3} system/>
        <CategoryRow name="Mental" color="var(--cat-mental)" count={2} system/>
        <CategoryRow name="Social" color="var(--cat-social)" count={0} system/>
        <div style={{ marginTop: 24 }}>
          <button className="btn-ghost"><Icon.Plus size={16}/> Nouvelle catégorie</button>
        </div>
      </div>
    </div>
  </Phone>
);

// HB-04 Créer catégorie
const ScreenHB04 = () => {
  const colors = ['#8B6F47','#6B8C6B','#5C7A8C','#7A6B8C','#9B7A4A','#9B5E3C','#8C3D3D','#A89880','#3F5A6B'];
  const [sel, setSel] = React.useState(2);
  return (
    <Phone>
      <HeaderBack title="Nouvelle catégorie"/>
      <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
        <div className="screen" style={{ paddingTop: 20, paddingBottom: 100 }}>
          <div style={{ marginBottom: 24 }}>
            <label className="field-label">Nom</label>
            <input className="input" placeholder="Ex. Lecture" defaultValue="Lecture"/>
          </div>

          <div style={{ marginBottom: 24 }}>
            <div className="label" style={{ marginBottom: 12 }}>COULEUR</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(9, 1fr)', gap: 8 }}>
              {colors.map((c, i) => (
                <button key={i} onClick={() => setSel(i)} style={{
                  aspectRatio: 1, borderRadius: '50%',
                  background: c, border: 'none', cursor: 'pointer',
                  boxShadow: i === sel ? '0 0 0 2px var(--bg-primary), 0 0 0 3.5px var(--accent)' : 'none',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                  {i === sel && <Icon.Check size={14} stroke="white" strokeWidth={2.5}/>}
                </button>
              ))}
            </div>
          </div>

          <div style={{ marginBottom: 24 }}>
            <div className="label" style={{ marginBottom: 12 }}>ICÔNE</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 8 }}>
              {[Icon.Book, Icon.Heart, Icon.Brain, Icon.Activity, Icon.Star,
                Icon.Coffee, Icon.Moon, Icon.Sun, Icon.Compass, Icon.Users].map((I, i) => (
                <button key={i} style={{
                  aspectRatio: 1,
                  background: i === 0 ? 'var(--accent-light)' : 'var(--bg-surface)',
                  border: '0.5px solid ' + (i === 0 ? 'var(--accent-border)' : 'var(--border-emphasis)'),
                  color: i === 0 ? 'var(--accent)' : 'var(--text-secondary)',
                  borderRadius: 10, cursor: 'pointer',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}><I size={20}/></button>
              ))}
            </div>
          </div>

          <div style={{ marginBottom: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12 }}>
              <span className="label">POINTS PAR COMPLÉTION</span>
              <span className="mono" style={{ fontSize: 18, fontWeight: 500, color: 'var(--accent)' }}>5</span>
            </div>
            <div style={{ position: 'relative', height: 6, background: 'var(--bg-input)', borderRadius: 3 }}>
              <div style={{ position: 'absolute', left: 0, top: 0, height: '100%', width: '50%', background: 'var(--accent)', borderRadius: 3 }}/>
              <div style={{
                position: 'absolute', left: 'calc(50% - 9px)', top: -7,
                width: 18, height: 18, borderRadius: '50%', background: 'var(--accent)',
                border: '3px solid var(--bg-primary)'
              }}/>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
              <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>1</span>
              <span className="caption" style={{ fontFamily: 'var(--font-mono)' }}>10</span>
            </div>
          </div>

          <div>
            <div className="label" style={{ marginBottom: 12 }}>APERÇU</div>
            <div className="card" style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: colors[sel] + '22',
                display: 'flex', alignItems: 'center', justifyContent: 'center'
              }}>
                <Icon.Book size={18} stroke={colors[sel]}/>
              </div>
              <div>
                <div className="h3">Lecture</div>
                <div className="caption">5 pts par habitude complétée</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="sticky-bottom no-nav">
        <button className="btn-primary">Créer la catégorie</button>
      </div>
    </Phone>
  );
};

// CO-01 Collections
const CollectionCard = ({ video, title, tags, active = false, fallback }) => (
  <div className="card" style={{ padding: 16, display: 'flex', gap: 14, marginBottom: 10 }}>
    <div style={{
      width: 60, height: 60, borderRadius: 12, overflow: 'hidden', flexShrink: 0,
      position: 'relative', background: 'var(--accent-light)'
    }}>
      <video autoPlay muted loop playsInline poster={fallback}
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}>
        <source src={video} type="video/mp4"/>
      </video>
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="h3">{title}</div>
      <div className="caption" style={{ marginTop: 4, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {tags.map((t, i) => (
          <span key={i} style={{
            padding: '2px 7px', borderRadius: 4, background: 'var(--bg-input)',
            color: 'var(--text-secondary)', fontSize: 10, fontWeight: 500
          }}>{t}</span>
        ))}
      </div>
      <div style={{ marginTop: 10 }}>
        {active
          ? <button style={{
              padding: '7px 14px', borderRadius: 8, background: 'transparent',
              border: '0.5px solid var(--success)', color: 'var(--success)',
              fontSize: 12, fontWeight: 500, cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', gap: 5
            }}><Icon.Check size={12} stroke="var(--success)" strokeWidth={2}/> Activée</button>
          : <button style={{
              padding: '7px 16px', borderRadius: 8, background: 'var(--accent)',
              color: 'var(--text-on-accent)', border: 'none',
              fontSize: 12, fontWeight: 500, cursor: 'pointer'
            }}>Activer</button>
        }
      </div>
    </div>
  </div>
);

const ScreenCO01 = () => (
  <Phone>
    <HeaderTitle title="Collections" action={
      <button className="btn-icon"><Icon.Plus size={20} stroke="var(--accent)"/></button>
    }/>
    <div className="phone-scroll" style={{ top: 100, paddingTop: 0 }}>
      <div className="screen">
        <p className="caption" style={{ margin: '0 0 18px' }}>
          Activez une collection en un tap. Les habitudes seront ajoutées à votre routine.
        </p>

        <div className="label" style={{ marginBottom: 10 }}>SYSTÈME</div>
        <CollectionCard video="media/06.mp4" fallback="media/06_fallback.png"
          title="Matin du musulman" tags={['Religion', '6 habitudes', '12 pts/jour']} active/>
        <CollectionCard video="media/10.mp4" fallback="media/10_fallback.png"
          title="Santé essentielle" tags={['Santé', '5 habitudes', '10 pts/jour']}/>
        <CollectionCard video="media/04.mp4" fallback="media/04_fallback.png"
          title="Clarté mentale" tags={['Mental', '4 habitudes', '8 pts/jour']}/>

        <div className="label" style={{ marginBottom: 10, marginTop: 28 }}>MES COLLECTIONS</div>
        <CollectionCard video="media/11.mp4" fallback="media/11_fallback.png"
          title="Routine du soir" tags={['Personnel', '3 habitudes', '6 pts/jour']}/>
      </div>
    </div>
    <BottomNav active="collections"/>
  </Phone>
);

// CO-02 Créer collection
const ScreenCO02 = () => (
  <Phone>
    <HeaderBack title="Nouvelle collection"/>
    <div className="phone-scroll" style={{ top: 56, paddingTop: 0 }}>
      <div className="screen" style={{ paddingTop: 20, paddingBottom: 140 }}>
        <div style={{ marginBottom: 18 }}>
          <label className="field-label">Titre</label>
          <input className="input" placeholder="Ex. Routine du matin"/>
        </div>
        <div style={{ marginBottom: 24 }}>
          <label className="field-label">Description</label>
          <textarea className="input" rows={3}
            style={{ minHeight: 96, resize: 'vertical', paddingTop: 12 }}
            placeholder="Quelques mots pour vous rappeler l'intention de cette collection..."/>
        </div>
        <div style={{ marginBottom: 24 }}>
          <div className="label" style={{ marginBottom: 10 }}>CATÉGORIE PRINCIPALE</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            <span className="chip active"><span className="dot" style={{ background: 'var(--cat-religion)' }}/> Religion</span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-sport)' }}/> Sport</span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-sante)' }}/> Santé</span>
            <span className="chip"><span className="dot" style={{ background: 'var(--cat-mental)' }}/> Mental</span>
          </div>
        </div>
        <div style={{ marginBottom: 24 }}>
          <div className="label" style={{ marginBottom: 10 }}>ICÔNE</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 8 }}>
            {[Icon.Sunrise, Icon.Book, Icon.Heart, Icon.Brain, Icon.Star].map((Ic, i) => (
              <button key={i} style={{
                aspectRatio: 1,
                background: i === 0 ? 'var(--accent-light)' : 'var(--bg-surface)',
                border: '0.5px solid ' + (i === 0 ? 'var(--accent-border)' : 'var(--border-emphasis)'),
                borderRadius: 10,
                color: i === 0 ? 'var(--accent)' : 'var(--text-secondary)',
                cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center'
              }}><Ic size={20}/></button>
            ))}
          </div>
        </div>
        <div>
          <div className="label" style={{ marginBottom: 10 }}>HABITUDES À INCLURE</div>
          <CheckboxRow checked label="Lecture du Coran" sub="Religion · Quotidien"/>
          <CheckboxRow checked label="Dhikr du matin" sub="Religion · Quotidien"/>
          <CheckboxRow label="Dhikr du soir" sub="Religion · Quotidien"/>
          <CheckboxRow checked label="Marche 30 min" sub="Sport · Quotidien"/>
          <CheckboxRow label="2L d'eau" sub="Santé · Quotidien"/>
        </div>
      </div>
    </div>
    <div className="sticky-bottom no-nav">
      <div className="card" style={{
        padding: 12, marginBottom: 12, display: 'flex',
        justifyContent: 'space-between', alignItems: 'center',
        background: 'var(--accent-light)', borderColor: 'var(--accent-border)'
      }}>
        <span className="caption" style={{ color: 'var(--accent)', fontWeight: 500 }}>3 habitudes sélectionnées</span>
        <span className="mono" style={{ color: 'var(--accent)', fontWeight: 500 }}>+8 pts/jour</span>
      </div>
      <button className="btn-primary">Créer la collection</button>
    </div>
  </Phone>
);

const CheckboxRow = ({ checked = false, label, sub }) => (
  <div className="card" style={{
    padding: 12, marginBottom: 8, display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer'
  }}>
    <div style={{
      width: 22, height: 22, borderRadius: 6,
      background: checked ? 'var(--accent)' : 'var(--bg-surface)',
      border: '0.5px solid ' + (checked ? 'var(--accent)' : 'var(--border-emphasis)'),
      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
    }}>{checked && <Icon.Check size={14} stroke="white" strokeWidth={2.5}/>}</div>
    <div>
      <div className="h3" style={{ fontSize: 14 }}>{label}</div>
      <div className="caption">{sub}</div>
    </div>
  </div>
);

// LB-01 Classement
const PodiumCol = ({ rank, name, score, height, initial }) => (
  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10, flex: 1 }}>
    <div style={{
      width: 48, height: 48, borderRadius: 12,
      background: rank === 1 ? 'var(--accent)' : 'var(--bg-surface)',
      border: '0.5px solid ' + (rank === 1 ? 'var(--accent)' : 'var(--border-emphasis)'),
      color: rank === 1 ? 'var(--text-on-accent)' : 'var(--text-primary)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontWeight: 500, fontSize: 16
    }}>{initial}</div>
    <div className="h3" style={{ fontSize: 13, textAlign: 'center' }}>{name}</div>
    <div className="mono" style={{ fontSize: 14, fontWeight: 500, color: 'var(--accent)' }}>{score}</div>
    <div style={{
      width: '100%', height,
      background: rank === 1 ? 'var(--accent)' : 'var(--accent-light)',
      opacity: rank === 1 ? 1 : (rank === 2 ? 0.7 : 0.5),
      borderRadius: '8px 8px 0 0',
      display: 'flex', alignItems: 'flex-start', justifyContent: 'center', paddingTop: 10,
      color: rank === 1 ? 'var(--text-on-accent)' : 'var(--accent)',
      fontFamily: 'var(--font-mono)', fontWeight: 500, fontSize: 18
    }}>{rank}</div>
  </div>
);

const LeaderRow = ({ rank, name, score, initial, you = false }) => (
  <div style={{
    padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
    background: you ? 'var(--accent-light)' : 'transparent',
    borderRadius: you ? 12 : 0,
    border: you ? '0.5px solid var(--accent-border)' : 'none',
    borderBottom: you ? '0.5px solid var(--accent-border)' : '0.5px solid var(--border-default)'
  }}>
    <span className="mono" style={{
      width: 28, fontSize: 13, fontWeight: 500,
      color: you ? 'var(--accent)' : 'var(--text-tertiary)'
    }}>#{rank}</span>
    <div style={{
      width: 32, height: 32, borderRadius: 8,
      background: you ? 'var(--accent)' : 'var(--bg-input)',
      color: you ? 'var(--text-on-accent)' : 'var(--text-secondary)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 12, fontWeight: 500
    }}>{initial}</div>
    <span className="h3" style={{ flex: 1, fontSize: 14, color: you ? 'var(--accent)' : 'var(--text-primary)' }}>{name}</span>
    <span className="mono" style={{ fontSize: 14, fontWeight: 500, color: you ? 'var(--accent)' : 'var(--text-primary)' }}>{score}</span>
  </div>
);

const ScreenLB01 = () => (
  <Phone>
    <HeaderTitle title="Classement"/>
    <div className="phone-scroll" style={{ top: 100, paddingTop: 0 }}>
      <div className="screen">
        <p className="caption" style={{ margin: '0 0 24px' }}>
          Semaine du 21 au 27 avril · 47 participants
        </p>

        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, marginBottom: 28 }}>
          <PodiumCol rank={2} name="Yacine" initial="Y" score="284" height={70}/>
          <PodiumCol rank={1} name="Aïcha" initial="A" score="312" height={100}/>
          <PodiumCol rank={3} name="Omar" initial="O" score="261" height={50}/>
        </div>

        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <LeaderRow rank={4} name="Khadija" score="248" initial="K"/>
          <LeaderRow rank={5} name="Ibrahim" score="231" initial="I"/>
          <LeaderRow rank={6} name="Fatima" score="218" initial="F"/>
          <LeaderRow rank={7} name="Cherif" score="204" initial="C" you/>
          <LeaderRow rank={8} name="Bilal" score="197" initial="B"/>
          <LeaderRow rank={9} name="Sarah" score="184" initial="S"/>
        </div>
      </div>
    </div>
    <BottomNav active="leaderboard"/>
  </Phone>
);

Object.assign(window, {
  ScreenHM01, ScreenSL01, ScreenHB01, ScreenHB02, ScreenHB03, ScreenHB04,
  ScreenCO01, ScreenCO02, ScreenLB01, StatCard, SalatRow, HabitRow,
  SectionHeader, CategoryRow, CollectionCard, CheckboxRow, PodiumCol, LeaderRow
});
