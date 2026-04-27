// Murabbi — Onboarding & Auth screens (OB-01..04, AU-01..03, SETUP-01..02)

const ScreenOB01 = () => (
  <Phone dark={false} time="6:14">
    <div style={{ position: 'absolute', inset: 0, zIndex: 0 }}>
      <video autoPlay muted loop playsInline poster="media/02_fallback.png"
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}>
        <source src="media/02.mp4" type="video/mp4" />
      </video>
    </div>
    <div style={{
      position: 'absolute', inset: 0, zIndex: 2,
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center',
      gap: 18
    }}>
      <Logo size={64} color="#FDFBF8" />
      <div style={{ fontFamily: 'var(--font-sans)', fontWeight: 500,
        fontSize: 28, letterSpacing: '0.4px', color: '#FDFBF8' }}>
        Murabbi
      </div>
      <div className="label" style={{ color: 'rgba(253,251,248,0.85)', letterSpacing: '2px' }}>
        FORMATEUR DE SOI
      </div>
    </div>
  </Phone>
);

const Dots = ({ active = 0, total = 3 }) => (
  <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
    {Array.from({ length: total }).map((_, i) => (
      <span key={i} style={{
        width: i === active ? 18 : 6, height: 6, borderRadius: 3,
        background: i === active ? 'var(--accent)' : 'rgba(28,26,22,0.18)',
        transition: 'all 0.2s'
      }} />
    ))}
  </div>
);

const PentagonIllo = () => (
  <svg width="160" height="160" viewBox="0 0 160 160" fill="none">
    <polygon points="80,20 142,64 118,138 42,138 18,64"
      stroke="var(--accent)" strokeWidth="0.8" strokeOpacity="0.4" fill="none"/>
    {[
      [80, 20], [142, 64], [118, 138], [42, 138], [18, 64]
    ].map(([x, y], i) => (
      <g key={i}>
        <circle cx={x} cy={y} r="14" fill="var(--accent-light)" stroke="var(--accent-border)" strokeWidth="0.5"/>
        <circle cx={x} cy={y} r="4" fill="var(--accent)"/>
      </g>
    ))}
    <circle cx="80" cy="80" r="3" fill="var(--text-tertiary)"/>
  </svg>
);

const StackIllo = () => (
  <svg width="180" height="160" viewBox="0 0 180 160" fill="none">
    {[0,1,2,3,4,5,6].map(row => (
      [0,1,2,3,4,5,6,7].map(col => {
        const fill = (row + col) % 3 === 0
          ? 'var(--accent)' : (row + col) % 3 === 1
          ? 'var(--cat-sport)' : 'var(--bg-input)';
        const opacity = row > 4 ? 1 : 0.4 + row * 0.12;
        return (
          <rect key={`${row}-${col}`} x={col*20+8} y={row*16+24} width="14" height="10"
            rx="2" fill={fill} opacity={opacity}/>
        );
      })
    ))}
  </svg>
);

const HorizonIllo = () => (
  <svg width="200" height="140" viewBox="0 0 200 140" fill="none">
    <line x1="10" y1="120" x2="190" y2="120" stroke="var(--border-emphasis)" strokeWidth="0.5"/>
    {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(y => (
      <g key={y}>
        <line x1={10 + y*18} y1="118" x2={10 + y*18} y2="124" stroke="var(--text-tertiary)" strokeWidth="0.5"/>
        <text x={10 + y*18} y="136" fontSize="8" fill="var(--text-tertiary)" textAnchor="middle"
          fontFamily="var(--font-mono)">Y{y}</text>
      </g>
    ))}
    <path d="M10 110 Q60 100, 100 70 T190 20" stroke="var(--accent)" strokeWidth="1.5" fill="none"/>
    <circle cx="10" cy="110" r="4" fill="var(--accent)"/>
    <circle cx="100" cy="70" r="6" fill="var(--bg-surface)" stroke="var(--accent)" strokeWidth="1.5"/>
    <text x="100" y="56" fontSize="9" fill="var(--accent)" textAnchor="middle"
      fontFamily="var(--font-sans)" fontWeight="500" letterSpacing="0.6">VOUS</text>
  </svg>
);

const OnboardSlide = ({ index, total, video, overlayClass, illo, title, body, cta }) => (
  <Phone>
    <div style={{ position: 'absolute', inset: 0, zIndex: 0 }}>
      <video autoPlay muted loop playsInline poster={`media/${video}_fallback.png`}
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}>
        <source src={`media/${video}.mp4`} type="video/mp4" />
      </video>
    </div>
    <div className={overlayClass} style={{ position: 'absolute', inset: 0, zIndex: 1 }} />
    <div style={{
      position: 'absolute', top: 44, left: 0, right: 0, bottom: 0, zIndex: 3,
      display: 'flex', flexDirection: 'column', padding: '12px 24px 32px'
    }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <button className="link-tertiary">Passer</button>
      </div>
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 32
      }}>
        {illo}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <h1 className="h1" style={{ textWrap: 'balance' }}>{title}</h1>
          <p className="body body-secondary" style={{ margin: 0, textWrap: 'pretty' }}>{body}</p>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <Dots active={index} total={total} />
        <button className="btn-primary">
          {cta} <Icon.ArrowRight size={16} stroke="#FDFBF8"/>
        </button>
      </div>
    </div>
  </Phone>
);

const ScreenOB02 = () => (
  <OnboardSlide index={0} total={3}
    video="06" overlayClass="video-overlay-light-78"
    illo={<PentagonIllo />}
    title="Cinq prières. Un rythme pour tenir l'intention du jour."
    body="Suivez Fajr, Dhuhr, Asr, Maghrib et Isha sans ostentation — à l'heure, en retard, ou manquée."
    cta="Continuer"
  />
);

const ScreenOB03 = () => (
  <OnboardSlide index={1} total={3}
    video="04" overlayClass="video-overlay-light-80"
    illo={<StackIllo />}
    title="Des habitudes qui s'empilent, jour après jour."
    body="Sport, santé, mental, social. Créez vos rituels ou activez une collection pré-configurée en un tap."
    cta="Continuer"
  />
);

const ScreenOB04 = () => (
  <Phone>
    <div style={{ position: 'absolute', inset: 0, zIndex: 0 }}>
      <video autoPlay muted loop playsInline poster="media/03_fallback.png"
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}>
        <source src="media/03.mp4" type="video/mp4" />
      </video>
    </div>
    <div className="video-overlay-light-75" style={{ position: 'absolute', inset: 0, zIndex: 1 }} />
    <div style={{
      position: 'absolute', top: 44, left: 0, right: 0, bottom: 0, zIndex: 3,
      display: 'flex', flexDirection: 'column', padding: '12px 24px 32px'
    }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <button className="link-tertiary">Passer</button>
      </div>
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 32
      }}>
        <HorizonIllo />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <h1 className="h1" style={{ textWrap: 'balance' }}>Un horizon de dix ans. Pas une semaine, pas un mois.</h1>
          <p className="body body-secondary" style={{ margin: 0 }}>
            Murabbi mesure votre progression sur l'échelle d'une vie. Patience, régularité, ancrage.
          </p>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <Dots active={2} total={3} />
        <button className="btn-primary">Commencer</button>
      </div>
    </div>
  </Phone>
);

// AU-01 Connexion
const ScreenAU01 = () => (
  <Phone>
    <div className="screen" style={{ paddingTop: 16, paddingBottom: 24 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 36 }}>
        <Logo size={28} />
        <Wordmark size={18} />
      </div>
      <h1 className="h1" style={{ marginBottom: 8 }}>Bon retour.</h1>
      <p className="body body-secondary" style={{ marginTop: 0, marginBottom: 28 }}>
        Reprenez votre pratique là où vous l'aviez laissée.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <label className="field-label">Email</label>
          <div className="input-wrap">
            <span className="input-icon"><Icon.Mail size={16} /></span>
            <input className="input with-icon-left" placeholder="vous@exemple.com" />
          </div>
        </div>
        <div>
          <label className="field-label">Mot de passe</label>
          <div className="input-wrap">
            <span className="input-icon"><Icon.Lock size={16} /></span>
            <input className="input with-icon-left with-icon-right" type="password" placeholder="••••••••" />
            <button className="input-icon-right"><Icon.Eye size={16} /></button>
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 8 }}>
            <button className="link-tertiary" style={{ fontSize: 13 }}>Mot de passe oublié ?</button>
          </div>
        </div>
        <button className="btn-primary" style={{ marginTop: 8 }}>Se connecter</button>

        <div className="divider-text">OU</div>

        <button className="btn-ghost">
          <svg width="16" height="16" viewBox="0 0 24 24" style={{ flexShrink: 0 }}>
            <path d="M21.6 12.227c0-.709-.064-1.39-.182-2.045H12v3.868h5.382a4.6 4.6 0 0 1-1.996 3.018v2.51h3.232c1.891-1.741 2.982-4.305 2.982-7.351z" fill="#4285F4"/>
            <path d="M12 22c2.7 0 4.964-.895 6.618-2.422l-3.232-2.51c-.895.6-2.04.955-3.386.955-2.605 0-4.81-1.76-5.595-4.122H3.064v2.59A9.997 9.997 0 0 0 12 22z" fill="#34A853"/>
            <path d="M6.405 13.9a6.005 6.005 0 0 1 0-3.8V7.51H3.064a9.998 9.998 0 0 0 0 8.98l3.341-2.59z" fill="#FBBC05"/>
            <path d="M12 5.977c1.468 0 2.786.504 3.823 1.495l2.868-2.868C16.96 2.99 14.696 2 12 2A9.997 9.997 0 0 0 3.064 7.51l3.341 2.59C7.19 7.737 9.395 5.977 12 5.977z" fill="#EA4335"/>
          </svg>
          Continuer avec Google
        </button>

        <div style={{ textAlign: 'center', marginTop: 20 }}>
          <span className="caption">Pas encore de compte ? </span>
          <button className="link-tertiary">Créer</button>
        </div>
      </div>
    </div>
  </Phone>
);

// AU-02 Inscription
const ScreenAU02 = () => (
  <Phone>
    <div className="app-header no-border">
      <button className="header-back"><Icon.ChevronLeft size={22} /></button>
      <div />
    </div>
    <div className="screen">
      <h1 className="h1" style={{ marginBottom: 8 }}>Commencer.</h1>
      <p className="body body-secondary" style={{ marginTop: 0, marginBottom: 28 }}>
        Trois minutes pour poser les fondations.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <label className="field-label">Nom complet</label>
          <input className="input" placeholder="Cherif Benkacem" />
        </div>
        <div>
          <label className="field-label">Email</label>
          <input className="input" placeholder="vous@exemple.com" />
        </div>
        <div>
          <label className="field-label">Mot de passe</label>
          <input className="input" type="password" placeholder="8 caractères minimum" />
        </div>
        <div>
          <label className="field-label">Confirmer le mot de passe</label>
          <input className="input" type="password" placeholder="Confirmez" />
        </div>

        <button className="btn-primary" style={{ marginTop: 8 }}>Créer mon compte</button>

        <div className="divider-text">OU</div>

        <button className="btn-ghost">
          <svg width="16" height="16" viewBox="0 0 24 24">
            <path d="M21.6 12.227c0-.709-.064-1.39-.182-2.045H12v3.868h5.382a4.6 4.6 0 0 1-1.996 3.018v2.51h3.232c1.891-1.741 2.982-4.305 2.982-7.351z" fill="#4285F4"/>
            <path d="M12 22c2.7 0 4.964-.895 6.618-2.422l-3.232-2.51c-.895.6-2.04.955-3.386.955-2.605 0-4.81-1.76-5.595-4.122H3.064v2.59A9.997 9.997 0 0 0 12 22z" fill="#34A853"/>
            <path d="M6.405 13.9a6.005 6.005 0 0 1 0-3.8V7.51H3.064a9.998 9.998 0 0 0 0 8.98l3.341-2.59z" fill="#FBBC05"/>
            <path d="M12 5.977c1.468 0 2.786.504 3.823 1.495l2.868-2.868C16.96 2.99 14.696 2 12 2A9.997 9.997 0 0 0 3.064 7.51l3.341 2.59C7.19 7.737 9.395 5.977 12 5.977z" fill="#EA4335"/>
          </svg>
          Continuer avec Google
        </button>

        <p className="caption" style={{ textAlign: 'center', marginTop: 12, color: 'var(--text-tertiary)' }}>
          En créant un compte, vous acceptez les{' '}
          <a className="link-tertiary" style={{ fontSize: 11, padding: 0 }}>conditions d'utilisation</a>{' '}
          et la{' '}
          <a className="link-tertiary" style={{ fontSize: 11, padding: 0 }}>politique de confidentialité</a>.
        </p>
      </div>
    </div>
  </Phone>
);

// AU-03 Mot de passe oublié
const ScreenAU03 = ({ success = false }) => (
  <Phone>
    <div className="app-header app-header-rel">
      <div className="header-left"><button className="header-back"><Icon.ChevronLeft size={22} /></button></div>
      <div className="header-title-center">Mot de passe oublié</div>
      <div className="header-right" />
    </div>
    <div className="screen" style={{ paddingTop: 24 }}>
      <h1 className="h1" style={{ marginBottom: 8 }}>On envoie un lien.</h1>
      <p className="body body-secondary" style={{ marginTop: 0, marginBottom: 28 }}>
        Entrez votre email. Nous vous enverrons un lien valable 15 minutes pour réinitialiser votre mot de passe.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <label className="field-label">Email</label>
          <div className="input-wrap">
            <span className="input-icon"><Icon.Mail size={16} /></span>
            <input className="input with-icon-left" placeholder="vous@exemple.com" defaultValue="cherif@exemple.com"/>
          </div>
        </div>

        {!success && <button className="btn-primary" style={{ marginTop: 8 }}>Envoyer le lien</button>}

        {success && (
          <div className="card" style={{
            background: 'var(--success-light)',
            borderColor: 'rgba(107, 140, 107, 0.25)',
            display: 'flex', gap: 12, alignItems: 'flex-start'
          }}>
            <div style={{
              width: 32, height: 32, borderRadius: 16,
              background: 'var(--success)', color: 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
            }}>
              <Icon.Check size={18} stroke="white"/>
            </div>
            <div>
              <div className="h3" style={{ marginBottom: 4 }}>Lien envoyé</div>
              <p className="caption" style={{ margin: 0 }}>
                Vérifiez votre boîte. Le lien expire dans 15 minutes.
              </p>
            </div>
          </div>
        )}

        <div style={{ textAlign: 'center', marginTop: 20 }}>
          <span className="caption">Vous vous en souvenez ? </span>
          <button className="link-tertiary">Se connecter</button>
        </div>
      </div>
    </div>
  </Phone>
);

// SETUP-01 Prière config
const ScreenSETUP01 = () => (
  <Phone>
    <div className="app-header no-border" />
    <div className="screen">
      <h1 className="h1" style={{ marginBottom: 8 }}>Vos prières.</h1>
      <p className="body body-secondary" style={{ marginTop: 0, marginBottom: 28 }}>
        Pour calculer les horaires précis selon votre position et votre école.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <div>
          <label className="field-label">Localisation</label>
          <div className="input-wrap">
            <span className="input-icon"><Icon.MapPin size={16} /></span>
            <input className="input with-icon-left" placeholder="Rechercher une ville..." defaultValue="Paris, France"/>
          </div>
        </div>

        <div>
          <label className="field-label">Méthode de calcul</label>
          <div className="input-wrap">
            <input className="input with-icon-right" defaultValue="Muslim World League (MWL)" readOnly/>
            <span className="input-icon-right"><Icon.ChevronDown size={16} /></span>
          </div>
          <p className="caption" style={{ margin: '6px 0 0', color: 'var(--text-tertiary)' }}>
            ISNA, Egyptian, Karachi, Umm al-Qura, Tehran, Jafari disponibles.
          </p>
        </div>

        <div className="card" style={{
          padding: 16, display: 'flex', alignItems: 'center', justifyContent: 'space-between'
        }}>
          <div>
            <div className="h3">Heure d'été automatique</div>
            <p className="caption" style={{ margin: '4px 0 0' }}>Ajuste les horaires en mars et octobre.</p>
          </div>
          <Toggle on={true} />
        </div>
      </div>

      <div style={{ marginTop: 32, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <button className="btn-primary">Continuer</button>
        <div style={{ textAlign: 'center' }}>
          <button className="link-tertiary">Configurer plus tard</button>
        </div>
      </div>
    </div>
  </Phone>
);

const Toggle = ({ on = false }) => (
  <div style={{
    width: 44, height: 26, borderRadius: 13,
    background: on ? 'var(--accent)' : 'var(--bg-input)',
    border: '0.5px solid ' + (on ? 'var(--accent)' : 'var(--border-emphasis)'),
    position: 'relative', flexShrink: 0
  }}>
    <span style={{
      position: 'absolute', top: 2, left: on ? 20 : 2,
      width: 21, height: 21, borderRadius: '50%',
      background: '#FDFBF8',
      transition: 'left 0.2s'
    }}/>
  </div>
);

// SETUP-02 Notifications
const ScreenSETUP02 = () => (
  <Phone>
    <div className="app-header no-border" />
    <div className="screen" style={{ paddingTop: 32 }}>
      <div style={{
        display: 'flex', flexDirection: 'column',
        alignItems: 'center', textAlign: 'center', gap: 24, marginTop: 32, marginBottom: 40
      }}>
        <div style={{
          width: 96, height: 96, borderRadius: '50%',
          background: 'var(--accent-light)',
          border: '0.5px solid var(--accent-border)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative'
        }}>
          <div style={{
            position: 'absolute', inset: -12, borderRadius: '50%',
            border: '0.5px solid var(--accent-border)', opacity: 0.5
          }}/>
          <Icon.Bell size={40} stroke="var(--accent)"/>
        </div>
        <div>
          <h1 className="h1" style={{ marginBottom: 10 }}>Restez sur le rythme.</h1>
          <p className="body body-secondary" style={{ margin: 0, textWrap: 'pretty' }}>
            Pour vous rappeler vos prières et vos habitudes au bon moment, autorisez les notifications.
          </p>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <button className="btn-primary">Activer les notifications</button>
        <div style={{ textAlign: 'center' }}>
          <button className="link-tertiary">Plus tard</button>
        </div>
        <p className="caption" style={{ textAlign: 'center', marginTop: 12, color: 'var(--text-tertiary)' }}>
          Vous pouvez modifier ce choix à tout moment dans les paramètres.
        </p>
      </div>
    </div>
  </Phone>
);

Object.assign(window, {
  ScreenOB01, ScreenOB02, ScreenOB03, ScreenOB04,
  ScreenAU01, ScreenAU02, ScreenAU03,
  ScreenSETUP01, ScreenSETUP02, Toggle, Dots
});
