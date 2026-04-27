// Murabbi — Logo glyphs (v2: incomplete circle).
// Three explorations of ONE direction: a single circle whose tracing is not closed.
// All glyphs are a single geometric form. No letters, no inner elements.
// Drawn on a 100×100 viewBox. Stroke-based circles for thin/elegant tracing,
// plus filled-path equivalents (for app icons / favicons that prefer fills).

// ── Exploration A — Le croissant minimal ────────────────────────────────
// Wide opening (~95° = ~26% of the circle absent). Opening tilted toward
// the top-right. Reads as a moon in ascending phase. Constant stroke.
function GlyphA({ size = 100, color = '#8B6F47', strokeScale = 1 }) {
  const sw = 9 * strokeScale;
  // Outer arc from start angle to end angle. Opening centered at 35° (top-right).
  // Use SVG arc: from one endpoint of the gap to the other, going the long way around.
  // Gap spans from −12° to +82° (i.e. 94° opening centered at top-right).
  // We compute endpoints on a circle r=40 around (50,50).
  const r = 40;
  const a1 = -12 * Math.PI / 180; // end of arc
  const a2 = 82  * Math.PI / 180; // start of arc
  const p1 = { x: 50 + r * Math.cos(a2), y: 50 + r * Math.sin(a2) };
  const p2 = { x: 50 + r * Math.cos(a1), y: 50 + r * Math.sin(a1) };
  // Going the long way: large-arc-flag = 1, sweep = 1 (clockwise)
  const d = `M ${p1.x.toFixed(2)} ${p1.y.toFixed(2)} A ${r} ${r} 0 1 0 ${p2.x.toFixed(2)} ${p2.y.toFixed(2)}`;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block' }}>
      <path d={d} fill="none" stroke={color} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
}

// ── Exploration B — La boucle interrompue ───────────────────────────────
// Very fine opening (~6% / ~22°). Opening at the top.
// Stroke ends are flat (butt) — two clean breaks, geometric, not calligraphic.
// This is the most "Things-3-adjacent but distinct" reading.
function GlyphB({ size = 100, color = '#8B6F47', strokeScale = 1 }) {
  const sw = 9 * strokeScale;
  const r = 40;
  // Opening centered at top (-90°), spanning 22° total (-101° to -79°).
  const a1 = -101 * Math.PI / 180;
  const a2 = -79  * Math.PI / 180;
  const p1 = { x: 50 + r * Math.cos(a2), y: 50 + r * Math.sin(a2) };
  const p2 = { x: 50 + r * Math.cos(a1), y: 50 + r * Math.sin(a1) };
  // Long way around (large-arc=1, sweep=0 → counter-clockwise from p1 to p2)
  const d = `M ${p1.x.toFixed(2)} ${p1.y.toFixed(2)} A ${r} ${r} 0 1 1 ${p2.x.toFixed(2)} ${p2.y.toFixed(2)}`;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block' }}>
      <path d={d} fill="none" stroke={color} strokeWidth={sw} strokeLinecap="butt"/>
    </svg>
  );
}

// ── Exploration C — Le tracé en mouvement ───────────────────────────────
// Same circle, but built as a closed filled path with variable thickness:
// thicker at the bottom-left (apex of the gesture) and thinning as it
// approaches the opening at the top. Opening ~14°. Geometric, not florid.
function GlyphC({ size = 100, color = '#8B6F47' }) {
  // Outer radius 44, inner radius varies from 33 (thick) to 39 (thin near gap).
  // Built as: outer arc (long way, clockwise from p1_out to p2_out)
  //         + thin end cap at gap right side
  //         + inner arc (long way, counter-clockwise from p2_in to p1_in)
  //         + thin end cap at gap left side
  // Opening centered at top, spans 14°.
  const a1 = -97 * Math.PI / 180; // left of gap
  const a2 = -83 * Math.PI / 180; // right of gap
  const rOut = 44;
  const rInThin  = 39; // near the gap (thin)
  const rInThick = 33; // opposite the gap (thick)
  const cx = 50, cy = 50;
  // Outer endpoints
  const p1o = { x: cx + rOut * Math.cos(a1), y: cy + rOut * Math.sin(a1) };
  const p2o = { x: cx + rOut * Math.cos(a2), y: cy + rOut * Math.sin(a2) };
  // Inner endpoints (thin near gap)
  const p1i = { x: cx + rInThin * Math.cos(a1), y: cy + rInThin * Math.sin(a1) };
  const p2i = { x: cx + rInThin * Math.cos(a2), y: cy + rInThin * Math.sin(a2) };
  // For the inner arc, we use an ellipse with two different radii to create
  // the variable thickness effect. We'll approximate by using the same arc
  // but with rInThick as the radius — SVG arc lets us set rx ≠ ry but that
  // would tilt; instead we go with a single inner radius ~36 (compromise).
  // True variable thickness via SVG requires a B-spline or two arcs.
  // We'll do TWO inner arcs meeting at the bottom (180°/270° area).
  const aBot = 90 * Math.PI / 180; // bottom of circle
  const pBotIn = { x: cx + rInThick * Math.cos(aBot), y: cy + rInThick * Math.sin(aBot) };
  // Outer arc: from p2o (right of gap) clockwise around to p1o (left of gap), long way
  // Inner arc: from p1i (left of gap, thin) → bottom (thick) → p2i (right of gap, thin)
  const d = [
    `M ${p2o.x.toFixed(2)} ${p2o.y.toFixed(2)}`,
    `A ${rOut} ${rOut} 0 1 1 ${p1o.x.toFixed(2)} ${p1o.y.toFixed(2)}`, // outer long way (CCW)
    `L ${p1i.x.toFixed(2)} ${p1i.y.toFixed(2)}`, // close the left gap edge
    // inner: two arcs meeting at bottom — each ~135° of a circle. Use rInThick.
    `A ${rInThick} ${rInThick} 0 0 0 ${pBotIn.x.toFixed(2)} ${pBotIn.y.toFixed(2)}`, // CW ish
    `A ${rInThick} ${rInThick} 0 0 0 ${p2i.x.toFixed(2)} ${p2i.y.toFixed(2)}`,
    'Z',
  ].join(' ');
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block' }}>
      <path d={d} fill={color}/>
    </svg>
  );
}

// ── Recommended (Direction B) — Filled equivalent for app icons ─────────
// Same geometry as GlyphB but as a closed ring with a wedge cut out of the top.
// This is what we ship for app icons / favicons — a filled shape avoids
// stroke-rasterization issues at small sizes.
function GlyphBFilled({ size = 100, color = '#8B6F47' }) {
  const rOut = 44.5;
  const rIn  = 35.5;
  const cx = 50, cy = 50;
  // Same opening as GlyphB
  const a1 = -101 * Math.PI / 180;
  const a2 = -79  * Math.PI / 180;
  const p1o = { x: cx + rOut * Math.cos(a1), y: cy + rOut * Math.sin(a1) };
  const p2o = { x: cx + rOut * Math.cos(a2), y: cy + rOut * Math.sin(a2) };
  const p1i = { x: cx + rIn * Math.cos(a1), y: cy + rIn * Math.sin(a1) };
  const p2i = { x: cx + rIn * Math.cos(a2), y: cy + rIn * Math.sin(a2) };
  // Outer: long way from p2o to p1o (CCW). Inner: short way back from p1i to p2i (CW).
  const d = [
    `M ${p2o.x.toFixed(2)} ${p2o.y.toFixed(2)}`,
    `A ${rOut} ${rOut} 0 1 1 ${p1o.x.toFixed(2)} ${p1o.y.toFixed(2)}`,
    `L ${p1i.x.toFixed(2)} ${p1i.y.toFixed(2)}`,
    `A ${rIn} ${rIn} 0 1 0 ${p2i.x.toFixed(2)} ${p2i.y.toFixed(2)}`,
    'Z',
  ].join(' ');
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" style={{ display: 'block' }}>
      <path d={d} fill={color}/>
    </svg>
  );
}

// ── Glyph picker — central registry ─────────────────────────────────────
const GLYPHS = {
  A: { id: 'A', name: 'Croissant minimal',    component: GlyphA, tagline: 'La lune en ascension' },
  B: { id: 'B', name: 'Boucle interrompue',   component: GlyphB, tagline: 'Le trait qui ne se referme pas' },
  C: { id: 'C', name: 'Tracé en mouvement',   component: GlyphC, tagline: 'Le geste posé du calame' },
};

// Canonical SVG strings for export — derived from GlyphBFilled geometry.
function symbolPathB() {
  const rOut = 44.5, rIn = 35.5, cx = 50, cy = 50;
  const a1 = -101 * Math.PI / 180;
  const a2 = -79  * Math.PI / 180;
  const p1o = { x: cx + rOut * Math.cos(a1), y: cy + rOut * Math.sin(a1) };
  const p2o = { x: cx + rOut * Math.cos(a2), y: cy + rOut * Math.sin(a2) };
  const p1i = { x: cx + rIn * Math.cos(a1), y: cy + rIn * Math.sin(a1) };
  const p2i = { x: cx + rIn * Math.cos(a2), y: cy + rIn * Math.sin(a2) };
  return `M ${p2o.x.toFixed(2)} ${p2o.y.toFixed(2)} A ${rOut} ${rOut} 0 1 1 ${p1o.x.toFixed(2)} ${p1o.y.toFixed(2)} L ${p1i.x.toFixed(2)} ${p1i.y.toFixed(2)} A ${rIn} ${rIn} 0 1 0 ${p2i.x.toFixed(2)} ${p2i.y.toFixed(2)} Z`;
}

Object.assign(window, { GlyphA, GlyphB, GlyphC, GlyphBFilled, GLYPHS, symbolPathB });
