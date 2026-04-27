// Murabbi — Shared icons & primitives
// Lucide-style strokes, 1.5px, round caps

const I = ({ children, size = 20, stroke = 'currentColor', strokeWidth = 1.5 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
    stroke={stroke} strokeWidth={strokeWidth}
    strokeLinecap="round" strokeLinejoin="round">
    {children}
  </svg>
);

const Icon = {
  ChevronLeft: (p) => <I {...p}><path d="M15 18l-6-6 6-6"/></I>,
  ChevronRight: (p) => <I {...p}><path d="M9 18l6-6-6-6"/></I>,
  ChevronDown: (p) => <I {...p}><path d="M6 9l6 6 6-6"/></I>,
  Plus: (p) => <I {...p}><path d="M12 5v14M5 12h14"/></I>,
  Check: (p) => <I {...p}><path d="M20 6L9 17l-5-5"/></I>,
  X: (p) => <I {...p}><path d="M18 6L6 18M6 6l12 12"/></I>,
  Edit: (p) => <I {...p}><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></I>,
  Bell: (p) => <I {...p}><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></I>,
  Search: (p) => <I {...p}><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></I>,
  Eye: (p) => <I {...p}><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></I>,
  Lock: (p) => <I {...p}><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></I>,
  Mail: (p) => <I {...p}><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><path d="M22 6l-10 7L2 6"/></I>,
  Home: (p) => <I {...p}><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/></I>,
  Compass: (p) => <I {...p}><circle cx="12" cy="12" r="10"/><path d="M16.24 7.76L14.12 14.12 7.76 16.24l2.12-6.36 6.36-2.12z"/></I>,
  Layers: (p) => <I {...p}><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></I>,
  Trophy: (p) => <I {...p}><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2z"/></I>,
  Settings: (p) => <I {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></I>,
  MapPin: (p) => <I {...p}><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></I>,
  Sun: (p) => <I {...p}><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></I>,
  Moon: (p) => <I {...p}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></I>,
  Sunrise: (p) => <I {...p}><path d="M17 18a5 5 0 0 0-10 0"/><path d="M12 2v7M4.22 10.22l1.42 1.42M1 18h2M21 18h2M18.36 11.64l1.42-1.42M23 22H1M8 6l4-4 4 4"/></I>,
  Sunset: (p) => <I {...p}><path d="M17 18a5 5 0 0 0-10 0"/><path d="M12 9V2M4.22 10.22l1.42 1.42M1 18h2M21 18h2M18.36 11.64l1.42-1.42M23 22H1M16 5l-4 4-4-4"/></I>,
  CloudSun: (p) => <I {...p}><path d="M12 2v2M5.22 5.22l1.42 1.42M20 8h2M15.97 8.03A4 4 0 0 0 8 9v.5"/><path d="M12.5 22a4.5 4.5 0 1 1 0-9h7.5a3.5 3.5 0 0 1 0 7H12.5"/></I>,
  TrendingUp: (p) => <I {...p}><path d="M23 6l-9.5 9.5-5-5L1 18"/><path d="M17 6h6v6"/></I>,
  TrendingDown: (p) => <I {...p}><path d="M23 18l-9.5-9.5-5 5L1 6"/><path d="M17 18h6v-6"/></I>,
  ArrowRight: (p) => <I {...p}><path d="M5 12h14M12 5l7 7-7 7"/></I>,
  Trash: (p) => <I {...p}><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></I>,
  LogOut: (p) => <I {...p}><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5M21 12H9"/></I>,
  ExternalLink: (p) => <I {...p}><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><path d="M15 3h6v6M10 14L21 3"/></I>,
  AlertTriangle: (p) => <I {...p}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4M12 17h.01"/></I>,
  Heart: (p) => <I {...p}><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78z"/></I>,
  Brain: (p) => <I {...p}><path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2z"/><path d="M14.5 2a2.5 2.5 0 0 0-2.5 2.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2z"/></I>,
  Users: (p) => <I {...p}><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/></I>,
  Activity: (p) => <I {...p}><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></I>,
  Star: (p) => <I {...p}><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></I>,
  Calendar: (p) => <I {...p}><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></I>,
  Flame: (p) => <I {...p}><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></I>,
  Droplet: (p) => <I {...p}><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></I>,
  Coffee: (p) => <I {...p}><path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/></I>,
  Book: (p) => <I {...p}><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></I>,
  Camera: (p) => <I {...p}><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></I>,
  Globe: (p) => <I {...p}><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></I>,
  ArrowUpRight: (p) => <I {...p}><path d="M7 17L17 7M7 7h10v10"/></I>,
  ArrowDownRight: (p) => <I {...p}><path d="M7 7l10 10M17 7v10H7"/></I>,
  Minus: (p) => <I {...p}><path d="M5 12h14"/></I>,
  Circle: (p) => <I {...p}><circle cx="12" cy="12" r="9"/></I>,
  Crescent: (p) => <I {...p}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></I>,
};

// Status bar
const StatusBar = ({ time = '6:14', dark = false }) => (
  <div className={`status-bar ${dark ? 'dark' : ''}`}>
    <div>{time}</div>
    <div className="status-icons">
      {/* signal */}
      <svg width="16" height="10" viewBox="0 0 16 10" fill="currentColor"><rect x="0" y="7" width="2.5" height="3" rx="0.5"/><rect x="3.5" y="5" width="2.5" height="5" rx="0.5"/><rect x="7" y="3" width="2.5" height="7" rx="0.5"/><rect x="10.5" y="0" width="2.5" height="10" rx="0.5"/></svg>
      {/* wifi */}
      <svg width="14" height="10" viewBox="0 0 14 10" fill="none" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round"><path d="M1 3.2a9 9 0 0 1 12 0"/><path d="M3 5.5a6 6 0 0 1 8 0"/><path d="M5 7.8a3 3 0 0 1 4 0"/><circle cx="7" cy="9.3" r="0.6" fill="currentColor"/></svg>
      {/* battery */}
      <svg width="22" height="10" viewBox="0 0 22 10" fill="none" stroke="currentColor" strokeWidth="0.8"><rect x="0.5" y="0.5" width="18" height="9" rx="2"/><rect x="2" y="2" width="14" height="6" rx="1" fill="currentColor"/><rect x="19.5" y="3" width="1.5" height="4" rx="0.5" fill="currentColor"/></svg>
    </div>
  </div>
);

// Phone shell
const Phone = ({ children, dark = false, time = '6:14' }) => (
  <div className="phone">
    <StatusBar time={time} dark={dark} />
    {children}
  </div>
);

// Bottom nav
const BottomNav = ({ active = 'home' }) => (
  <div className="bottom-nav">
    <button className={`nav-item ${active === 'home' ? 'active' : ''}`}>
      <Icon.Home size={20} />
      <span>Accueil</span>
    </button>
    <button className={`nav-item ${active === 'salat' ? 'active' : ''}`}>
      <Icon.Compass size={20} />
      <span>Salat</span>
    </button>
    <button className={`nav-item ${active === 'habits' ? 'active' : ''}`}>
      <Icon.Activity size={20} />
      <span>Habitudes</span>
    </button>
    <button className={`nav-item ${active === 'collections' ? 'active' : ''}`}>
      <Icon.Layers size={20} />
      <span>Collections</span>
    </button>
    <button className={`nav-item ${active === 'leaderboard' ? 'active' : ''}`}>
      <Icon.Trophy size={20} />
      <span>Classement</span>
    </button>
  </div>
);

// Header
const HeaderBack = ({ title, action = null, onBack = () => {} }) => (
  <div className="app-header app-header-rel">
    <div className="header-left">
      <button className="header-back" onClick={onBack}>
        <Icon.ChevronLeft size={22} />
      </button>
    </div>
    {title && <div className="header-title-center">{title}</div>}
    <div className="header-right">{action}</div>
  </div>
);

const HeaderTitle = ({ title, action = null }) => (
  <div className="app-header no-border">
    <h1 className="h1">{title}</h1>
    <div className="header-right">{action}</div>
  </div>
);

// Logo (original abstract mark — circle with inner crescent-of-dots)
const Logo = ({ size = 40, color = 'var(--accent)' }) => (
  <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
    <circle cx="20" cy="20" r="18" stroke={color} strokeWidth="1.2"/>
    <circle cx="20" cy="9" r="1.6" fill={color}/>
    <circle cx="29.5" cy="14.5" r="1.6" fill={color}/>
    <circle cx="29.5" cy="25.5" r="1.6" fill={color}/>
    <circle cx="20" cy="31" r="1.6" fill={color}/>
    <circle cx="10.5" cy="25.5" r="1.6" fill={color}/>
    <circle cx="10.5" cy="14.5" r="1.6" fill={color}/>
    <circle cx="20" cy="20" r="2.5" fill={color}/>
  </svg>
);

const Wordmark = ({ size = 22 }) => (
  <span style={{
    fontFamily: 'var(--font-sans)',
    fontWeight: 500,
    fontSize: size,
    letterSpacing: '0.5px',
    color: 'var(--text-primary)'
  }}>Murabbi</span>
);

// Progress ring
const ProgressRing = ({ value = 70, size = 80, stroke = 4 }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c * (1 - value / 100);
  return (
    <div className="ring" style={{ width: size, height: size }}>
      <svg width={size} height={size}>
        <circle cx={size/2} cy={size/2} r={r} stroke="var(--bg-input)" strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke="var(--accent)" strokeWidth={stroke} fill="none"
          strokeDasharray={c} strokeDashoffset={off} strokeLinecap="round"/>
      </svg>
      <div className="ring-text">{value}%</div>
    </div>
  );
};

// Video wrapper
const Video = ({ src, poster }) => (
  <video autoPlay muted loop playsInline poster={poster}>
    <source src={src} type="video/mp4" />
  </video>
);

// Inline arabic name (for Salat)
const Ar = ({ children }) => (
  <span style={{ fontFamily: 'var(--font-arabic)', fontWeight: 500 }}>{children}</span>
);

Object.assign(window, {
  Icon, StatusBar, Phone, BottomNav, HeaderBack, HeaderTitle,
  Logo, Wordmark, ProgressRing, Video, Ar
});
