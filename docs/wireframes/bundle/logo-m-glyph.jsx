// Murabbi — Custom sculpted M (v3 brief)
// Three iterations of ONE M: V1 brouillon, V2 raffiné, V3 finalisé.
// All glyphs are filled paths on a 120×100 viewBox.
//
// Construction model: M = outer rectangle MINUS a top valley triangle
// MINUS a bottom rectangular notch between the two posts.
// Variables per version: post width, valley apex Y, valley plateau width,
// bottom-notch ceiling Y, asymmetric base step (V3 only), inner micro-curve.

function buildMpath(version) {
  const W = 120;
  let Lw, Rw, apexY, apexX_L, apexX_R, Y_notch, Y_right_bottom, useCurve;

  if (version === 1) {
    // V1 brouillon: thinner posts, sharp V valley, symmetric, flush bottom
    Lw = 28; Rw = 28;
    apexY = 60; apexX_L = 60; apexX_R = 60;
    Y_notch = 36;
    Y_right_bottom = 100;
    useCurve = false;
  } else if (version === 2) {
    // V2 raffiné: heavier posts, 2u plateau at valley, slightly raised notch
    Lw = 32; Rw = 32;
    apexY = 56; apexX_L = 59; apexX_R = 61;
    Y_notch = 32;
    Y_right_bottom = 100;
    useCurve = false;
  } else {
    // V3 finalisé: 30u posts, 6u plateau with subtle inner micro-curve,
    // ASYMMETRIC STEP (right post 6u short of baseline → "ascension")
    Lw = 30; Rw = 30;
    apexY = 54; apexX_L = 57; apexX_R = 63;
    Y_notch = 28;
    Y_right_bottom = 94;       // signature step
    useCurve = true;
  }

  const apexCmd = useCurve
    ? `Q 60 53 ${apexX_R} ${apexY}`     // tiny upward kiss at valley plateau
    : `L ${apexX_R} ${apexY}`;

  return [
    'M 0 100',
    'L 0 0',
    `L ${Lw} 0`,
    `L ${apexX_L} ${apexY}`,
    apexCmd,
    `L ${W - Rw} 0`,
    `L ${W} 0`,
    `L ${W} ${Y_right_bottom}`,
    `L ${W - Rw} ${Y_right_bottom}`,
    `L ${W - Rw} ${Y_notch}`,
    `L ${Lw} ${Y_notch}`,
    'L ' + Lw + ' 100',
    'Z',
  ].join(' ');
}

function GlyphMfinal({ size = 100, color = '#1C1A16', version = 3, showGrid = false, gridColor = 'rgba(139,111,71,0.28)' }) {
  const d = buildMpath(version);
  const Lw = version === 1 ? 28 : version === 2 ? 32 : 30;
  const apexY = version === 1 ? 60 : version === 2 ? 56 : 54;
  const w = size * 1.2;
  return (
    <svg width={w} height={size} viewBox="0 0 120 100" style={{ display: 'block', overflow: 'visible' }}>
      {showGrid && (
        <g>
          {[10,20,30,40,50,60,70,80,90,100,110].map(x => (
            <line key={'vx'+x} x1={x} y1="0" x2={x} y2="100" stroke={gridColor} strokeWidth="0.2"/>
          ))}
          {[10,20,30,40,50,60,70,80,90].map(y => (
            <line key={'hy'+y} x1="0" y1={y} x2="120" y2={y} stroke={gridColor} strokeWidth="0.2"/>
          ))}
          <rect x="0" y="0" width="120" height="100" fill="none" stroke={gridColor} strokeWidth="0.4"/>
          <circle cx="60" cy={apexY} r="3" fill="none" stroke={gridColor} strokeWidth="0.4"/>
          <line x1={Lw} y1="0" x2={Lw} y2="100" stroke={gridColor} strokeWidth="0.35" strokeDasharray="2 2"/>
          <line x1={120-Lw} y1="0" x2={120-Lw} y2="100" stroke={gridColor} strokeWidth="0.35" strokeDasharray="2 2"/>
          {version === 3 && (
            <line x1="0" y1="94" x2="120" y2="94" stroke="rgba(139,111,71,0.5)" strokeWidth="0.4" strokeDasharray="3 2"/>
          )}
        </g>
      )}
      <path d={d} fill={color}/>
    </svg>
  );
}

function GlyphM_V1({ size, color }) { return <GlyphMfinal size={size} color={color} version={1}/>; }
function GlyphM_V2({ size, color }) { return <GlyphMfinal size={size} color={color} version={2}/>; }
function GlyphM_V3({ size, color }) { return <GlyphMfinal size={size} color={color} version={3}/>; }
function GlyphM({ size, color }) { return <GlyphMfinal size={size} color={color} version={3}/>; }

function symbolPathM(version = 3) { return buildMpath(version); }

Object.assign(window, {
  GlyphMfinal, GlyphM_V1, GlyphM_V2, GlyphM_V3, GlyphM,
  buildMpath, symbolPathM,
});
