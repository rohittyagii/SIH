import { useState, createContext, useContext } from 'react'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer,
} from 'recharts'

// ── Types ──────────────────────────────────────────────────────────────────
type Screen         = 'stepDemo' | 'pin' | 'activation' | 'consent' | 'app'
type Tab            = 'home' | 'trend' | 'support' | 'settings'
type DimKey         = 'overall' | 'sleep' | 'physical' | 'focus'
type PinState       = 'idle' | 'checking' | 'error' | 'success'
type ActivateStatus = 'idle' | 'loading'

interface Dim   { key: DimKey; label: string; hint: string; icon: React.ReactNode }
interface Entry { date: string; overall: number; sleep: number; physical: number; focus: number; note: string }

// ── App context ────────────────────────────────────────────────────────────
const ThemeCtx = createContext<{
  theme:'dark'|'light'
  setTheme:(t:'dark'|'light')=>void
  onLogout:()=>void
}>({
  theme: 'dark',
  setTheme: () => {},
  onLogout: () => {},
})

// ── Score colours ──────────────────────────────────────────────────────────
const SCORE_COLORS = ['#D55E00','#C07830','#56B4E9','#3EC4A0','#34D399']
const SCORE_GLOWS  = ['rgba(213,94,0,0.20)','rgba(192,120,48,0.20)','rgba(86,180,233,0.20)','rgba(62,196,160,0.20)','rgba(52,211,153,0.20)']
const sc     = (n: number) => SCORE_COLORS[Math.min(Math.max(n,1),5)-1]
const sg     = (n: number) => SCORE_GLOWS[Math.min(Math.max(n,1),5)-1]
const slabel = (n: number) => ['Not ready','Low','Moderate','Good','Fully ready'][n-1] ?? ''

// ── Step check-in pill options ─────────────────────────────────────────────
const STEP_PILLS = [
  { value: 1, label: 'Very hard',  color: '#D55E00', glow: 'rgba(213,94,0,0.18)'   },
  { value: 2, label: 'Hard',       color: '#C07830', glow: 'rgba(192,120,48,0.18)' },
  { value: 3, label: 'Neutral',    color: '#56B4E9', glow: 'rgba(86,180,233,0.18)' },
  { value: 4, label: 'Easy',       color: '#3EC4A0', glow: 'rgba(62,196,160,0.18)' },
  { value: 5, label: 'Very easy',  color: '#34D399', glow: 'rgba(52,211,153,0.18)' },
]

const STEP_ECHO = [
  'Struggled to stay on task',
  'Often pulled off focus',
  'Mixed — some good, some not',
  'Mostly stayed on track',
  'Locked in throughout',
]

// ── Icons ──────────────────────────────────────────────────────────────────
const SvgWrap = ({ size, children }: { size: number; children: React.ReactNode }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">{children}</svg>
)

function IconShield({ size=15 }: { size?: number }) { return <SvgWrap size={size}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></SvgWrap> }
function IconMoon({ size=15 }: { size?: number }) { return <SvgWrap size={size}><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></SvgWrap> }
function IconActivity({ size=15 }: { size?: number }) { return <SvgWrap size={size}><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></SvgWrap> }
function IconTarget({ size=15 }: { size?: number }) { return <SvgWrap size={size}><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></SvgWrap> }
function IconFlame({ size=12 }: { size?: number }) { return <SvgWrap size={size}><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3A2.5 2.5 0 0 0 8.5 14.5z"/></SvgWrap> }
function IconCheck({ size=30 }: { size?: number }) { return <SvgWrap size={size}><polyline points="20 6 9 17 4 12"/></SvgWrap> }
function IconCalendar({ size=15 }: { size?: number }) { return <SvgWrap size={size}><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></SvgWrap> }
function IconLock({ size=16 }: { size?: number }) { return <SvgWrap size={size}><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></SvgWrap> }
function IconEyeOff({ size=16 }: { size?: number }) { return <SvgWrap size={size}><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></SvgWrap> }
function IconCircleCheck({ size=16 }: { size?: number }) { return <SvgWrap size={size}><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></SvgWrap> }
function IconDelete({ size=21 }: { size?: number }) { return <SvgWrap size={size}><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z"/><line x1="18" y1="9" x2="13" y2="14"/><line x1="13" y1="9" x2="18" y2="14"/></SvgWrap> }

function IconFingerprint({ size=28 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7.864 4.243A7.5 7.5 0 0 1 19.5 10.5c0 2.92-.556 5.709-1.568 8.268"/>
      <path d="M5.742 6.364A7.459 7.459 0 0 0 4.5 10.5a7.464 7.464 0 0 1-1.15 3.993m1.989 3.559A11.209 11.209 0 0 0 8.25 10.5a3.75 3.75 0 1 1 7.5 0c0 .527-.021 1.049-.064 1.565"/>
      <path d="M12 10.5a14.94 14.94 0 0 1-3.6 9.75m6.633-4.596a18.666 18.666 0 0 1-2.485 5.33"/>
    </svg>
  )
}

function IconHome({ size=20 }: { size?: number }) { return <SvgWrap size={size}><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></SvgWrap> }
function IconTrend({ size=20 }: { size?: number }) { return <SvgWrap size={size}><polyline points="22 7 13.5 15.5 8.5 10.5 1 18"/><polyline points="16 7 22 7 22 13"/></SvgWrap> }
function IconMessageCircle({ size=20 }: { size?: number }) { return <SvgWrap size={size}><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></SvgWrap> }
function IconSliders({ size=20 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <line x1="4"  y1="21" x2="4"  y2="14"/><line x1="4"  y1="10" x2="4"  y2="3"/>
      <line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8"  x2="12" y2="3"/>
      <line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/>
      <line x1="1"  y1="14" x2="7"  y2="14"/>
      <line x1="9"  y1="8"  x2="15" y2="8"/>
      <line x1="17" y1="16" x2="23" y2="16"/>
    </svg>
  )
}
function IconChevronRight({ size=14 }: { size?: number }) { return <SvgWrap size={size}><polyline points="9 18 15 12 9 6"/></SvgWrap> }

function IconSun({ size=15 }: { size?: number }) {
  return <SvgWrap size={size}><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></SvgWrap>
}
function IconGlobe({ size=15 }: { size?: number }) {
  return <SvgWrap size={size}><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></SvgWrap>
}
function IconBell({ size=15 }: { size?: number }) {
  return <SvgWrap size={size}><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></SvgWrap>
}
function IconAlertTriangle({ size=14 }: { size?: number }) {
  return <SvgWrap size={size}><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></SvgWrap>
}
function IconLogOut({ size=15 }: { size?: number }) {
  return <SvgWrap size={size}><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></SvgWrap>
}
function IconCloudQueue({ size=30 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 30 30" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round" strokeLinejoin="round">
      <path d="M8.5 22a5 5 0 0 1-.5-9.97A7 7 0 0 1 22 13a4.5 4.5 0 0 1 .5 8.97"/>
      <polyline points="11.5 18.5 15 15 18.5 18.5"/>
      <line x1="15" y1="15" x2="15" y2="25"/>
    </svg>
  )
}

function IconNoWifi({ size=12 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="1" y1="1" x2="23" y2="23"/>
      <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/>
      <path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/>
      <path d="M10.71 5.05A16 16 0 0 1 22.56 9"/>
      <path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/>
      <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
      <circle cx="12" cy="20" r="1.2" fill="currentColor" stroke="none"/>
    </svg>
  )
}

// ── Data ───────────────────────────────────────────────────────────────────
const DIMS: Dim[] = [
  { key:'overall',  label:'Overall readiness',  hint:'How ready do you feel for duty today?',   icon:<IconShield /> },
  { key:'sleep',    label:'Sleep quality',       hint:'How well did you rest last night?',       icon:<IconMoon /> },
  { key:'physical', label:'Physical status',     hint:'Any physical limitations right now?',     icon:<IconActivity /> },
  { key:'focus',    label:'Focus and alertness', hint:'How sharp and attentive do you feel?',    icon:<IconTarget /> },
]

// Line color per dimension — distinct from the score semantic palette
const DIM_COLORS: Record<DimKey, string> = {
  overall:  '#818CF8',
  sleep:    '#56B4E9',
  physical: '#34D399',
  focus:    '#C4A870',
}

const SEED: Entry[] = [
  { date:'Wed, Sep 3', overall:4, sleep:3, physical:5, focus:4, note:'' },
  { date:'Tue, Sep 2', overall:3, sleep:2, physical:4, focus:3, note:'Long shift yesterday' },
  { date:'Mon, Sep 1', overall:5, sleep:5, physical:5, focus:5, note:'' },
  { date:'Fri, Aug 29', overall:4, sleep:4, physical:4, focus:4, note:'' },
  { date:'Thu, Aug 28', overall:2, sleep:2, physical:3, focus:2, note:'Poor night — headache through the morning' },
  { date:'Wed, Aug 27', overall:4, sleep:4, physical:4, focus:4, note:'' },
  { date:'Tue, Aug 26', overall:3, sleep:3, physical:4, focus:3, note:'' },
]

// Deterministic wave — produces stable, plausible-looking data without randomness
const wave = (day: number, phase: number) =>
  Math.max(1, Math.min(5, Math.round(3 + Math.sin(day * 0.29 + phase) * 1.3 + Math.sin(day * 0.08 + phase * 0.3) * 0.6)))

// Seed overlay: actual known data stitched in at the correct day offsets
// Day 1 = Aug 5 2026, Day 30 = Sep 3 2026
const SEED_OVERLAY: Record<number, [number, number, number, number]> = {
  22: [3,3,4,3],  // Aug 26
  23: [4,4,4,4],  // Aug 27
  24: [2,2,3,2],  // Aug 28
  25: [4,4,4,4],  // Aug 29
  28: [5,5,5,5],  // Sep 1
  29: [3,2,4,3],  // Sep 2
  30: [4,3,5,4],  // Sep 3
}

const X_LABELS: Record<number, string> = { 1:'Aug 5', 8:'Aug 12', 15:'Aug 19', 22:'Aug 26', 30:'Sep 3' }

const THIRTY_DAY = Array.from({ length: 30 }, (_, i) => {
  const day = i + 1
  const ov = SEED_OVERLAY[day]
  return {
    day,
    overall:  ov ? ov[0] : wave(day, 0),
    sleep:    ov ? ov[1] : wave(day, 1.6),
    physical: ov ? ov[2] : wave(day, 2.9),
    focus:    ov ? ov[3] : wave(day, 4.2),
  }
})

// ── Suggested resources ────────────────────────────────────────────────────
const RESOURCES = [
  { dimIcon: <IconMoon size={14}/>,           title: 'Sleep tips',           body: 'Strategies for better rest before long shifts',    color: '#56B4E9' },
  { dimIcon: <IconMessageCircle size={14}/>,  title: 'Talk to peer support', body: 'Speak with a trained colleague, any time',          color: '#818CF8' },
  { dimIcon: <IconTarget size={14}/>,         title: 'Focus techniques',     body: 'Short exercises to stay sharp on shift',            color: '#C4A870' },
]

// ── Chart tooltip ──────────────────────────────────────────────────────────
function ChartTooltip({ active, payload }: { active?: boolean; payload?: Array<{ dataKey: string; value: number; stroke: string }> }) {
  if (!active || !payload?.length) return null
  return (
    <div style={{
      background: 'var(--rr-bgc)', borderRadius: 10, padding: '8px 12px',
      border: '1px solid var(--rr-b2)',
      boxShadow: '0 4px 20px rgba(0,0,0,0.5)',
    }}>
      {payload.map(p => {
        const dim = DIMS.find(d => d.key === p.dataKey)
        return (
          <div key={p.dataKey} style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 3 }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: p.stroke, flexShrink: 0 }}/>
            <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 11, color: 'var(--rr-t2b)' }}>
              {dim?.label.split(' ')[0]}:
            </span>
            <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 11, fontWeight: 600, color: p.stroke }}>
              {p.value}
            </span>
          </div>
        )
      })}
    </div>
  )
}

// ── 30-day line chart ──────────────────────────────────────────────────────
function TrendChart() {
  const { theme } = useContext(ThemeCtx)
  const tickFill  = theme === 'light' ? '#8898A8' : '#384C5E'
  const tickFill2 = theme === 'light' ? '#9EAEBB' : '#253545'
  const cursorStroke = theme === 'light' ? 'rgba(0,0,0,0.08)' : 'var(--rr-dv2)'
  return (
    <div className="rr-card" style={{ padding: '16px 10px 10px 6px', marginBottom: 12 }}>
      {/* Header row: label + legend */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12, padding: '0 6px' }}>
        <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 10, fontWeight: 600, color: 'var(--rr-t6)', letterSpacing: '0.10em' }}>
          30-DAY OVERVIEW
        </span>
        <div style={{ display: 'flex', gap: 10 }}>
          {DIMS.map(d => (
            <div key={d.key} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <div style={{ width: 14, height: 2, borderRadius: 1, background: DIM_COLORS[d.key] }}/>
              <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 10, color: 'var(--rr-t4)' }}>
                {d.label.split(' ')[0]}
              </span>
            </div>
          ))}
        </div>
      </div>

      <ResponsiveContainer width="100%" height={172}>
        <LineChart data={THIRTY_DAY} margin={{ top: 4, right: 6, bottom: 0, left: -18 }}>
          <CartesianGrid
            stroke="var(--rr-in)"
            strokeDasharray="0"
            vertical={false}
          />
          <XAxis
            dataKey="day"
            ticks={[1, 8, 15, 22, 30]}
            tickFormatter={(d: number) => X_LABELS[d] ?? ''}
            tick={{ fill: tickFill, fontSize: 10, fontFamily: 'Outfit,sans-serif' }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis
            domain={[1, 5]}
            ticks={[1, 2, 3, 4, 5]}
            tick={{ fill: tickFill2, fontSize: 10, fontFamily: 'Outfit,sans-serif' }}
            axisLine={false}
            tickLine={false}
          />
          <Tooltip
            content={<ChartTooltip/>}
            cursor={{ stroke: cursorStroke, strokeWidth: 1 }}
          />
          {DIMS.map(d => (
            <Line
              key={d.key}
              type="monotone"
              dataKey={d.key}
              stroke={DIM_COLORS[d.key]}
              strokeWidth={1.75}
              dot={false}
              activeDot={{ r: 3.5, fill: DIM_COLORS[d.key], strokeWidth: 0 }}
            />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

// ── Suggested resources ────────────────────────────────────────────────────
function ResourceList() {
  return (
    <div className="rr-card" style={{ marginBottom: 12 }}>
      <div style={{ fontFamily: 'Outfit,sans-serif', fontSize: 10, fontWeight: 600, color: 'var(--rr-t6)', letterSpacing: '0.10em', marginBottom: 14 }}>
        SUGGESTED FOR YOU
      </div>
      {RESOURCES.map((r, i) => (
        <button
          key={r.title}
          style={{
            display: 'flex', alignItems: 'center', gap: 12,
            width: '100%', background: 'none', border: 'none', cursor: 'pointer',
            textAlign: 'left', padding: 0,
            ...(i > 0 ? { borderTop: '1px solid var(--rr-dv)', paddingTop: 12, marginTop: 12 } : {}),
          }}
        >
          <div style={{
            width: 34, height: 34, borderRadius: 10, flexShrink: 0,
            background: `${r.color}18`, color: r.color,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {r.dimIcon}
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: 'Outfit,sans-serif', fontSize: 14, fontWeight: 500, color: 'var(--rr-t2)' }}>
              {r.title}
            </div>
            <div style={{ fontFamily: 'Outfit,sans-serif', fontSize: 12, color: 'var(--rr-t3)', lineHeight: 1.4, marginTop: 1 }}>
              {r.body}
            </div>
          </div>
          <span style={{ color: 'var(--rr-t6)', flexShrink: 0 }}>
            <IconChevronRight size={13}/>
          </span>
        </button>
      ))}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// CHECK-IN STEP SCREEN  (new single-question flow)
// ══════════════════════════════════════════════════════════════════════════
function CheckinStepScreen({
  step = 3, totalSteps = 5,
  question = "How easy has it been to stay focused during your shifts this week?",
  dimension = "Focus & alertness",
  selected,
  onSelect,
  onBack,
  onNext,
}: {
  step?: number; totalSteps?: number; question?: string; dimension?: string
  selected: number; onSelect: (v: number) => void; onBack: () => void; onNext: () => void
}) {
  const canNext = selected > 0
  const selPill = selected > 0 ? STEP_PILLS[selected - 1] : null

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: 'var(--rr-bg)', position: 'relative', overflow: 'hidden', height: '100%' }}>

      {/* Atmospheric glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(ellipse 130% 38% at 50% -6%, rgba(129,140,248,0.08) 0%, transparent 58%)',
      }}/>

      {/* Progress area */}
      <div style={{ padding: '52px 20px 28px', position: 'relative', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 10, fontWeight: 600, color: 'var(--rr-t4)', letterSpacing: '0.13em' }}>
            STEP {step} OF {totalSteps}
          </span>
          <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 11, color: 'var(--rr-t6)' }}>{dimension}</span>
        </div>
        {/* Segmented progress bar */}
        <div style={{ display: 'flex', gap: 5 }}>
          {Array.from({ length: totalSteps }).map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: i < step
                ? 'linear-gradient(90deg,#818CF8,#6D7FE8)'
                : 'var(--rr-dv3)',
              boxShadow: i < step ? '0 0 6px rgba(129,140,248,0.28)' : 'none',
            }}/>
          ))}
        </div>
      </div>

      {/* Main content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '0 20px', position: 'relative', minHeight: 0 }}>

        <div style={{ flex: 1, minHeight: 0 }}>
          <h2 style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 22, fontWeight: 600,
            lineHeight: 1.32, letterSpacing: '-0.01em', color: 'var(--rr-t1)', marginBottom: 11,
          }}>
            {question}
          </h2>
          <p style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 13, color: 'var(--rr-t4)',
            lineHeight: 1.6, marginBottom: 38,
          }}>
            Think across your whole week, not just today.
          </p>

          {/* Pill row */}
          <div style={{ display: 'flex', gap: 7 }}>
            {STEP_PILLS.map(pill => {
              const on = selected === pill.value
              return (
                <button
                  key={pill.value}
                  onClick={() => onSelect(pill.value)}
                  style={{
                    flex: 1,
                    padding: '11px 0',
                    borderRadius: 999,
                    fontFamily: 'Outfit,sans-serif',
                    fontSize: 11,
                    fontWeight: 500,
                    lineHeight: 1,
                    cursor: 'pointer',
                    transition: 'all 0.18s cubic-bezier(.4,0,.2,1)',
                    background: on ? pill.glow : 'var(--rr-pl)',
                    border: `1.5px solid ${on ? pill.color : 'var(--rr-plb)'}`,
                    color: on ? pill.color : 'var(--rr-t5)',
                    boxShadow: on ? `0 0 16px ${pill.glow}, 0 0 0 1px ${pill.color}18 inset` : 'none',
                    transform: on ? 'translateY(-1px)' : 'translateY(0)',
                  }}
                >
                  {pill.label}
                </button>
              )
            })}
          </div>

          {/* Selection echo badge */}
          <div style={{ height: 44, marginTop: 22, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {selPill && (
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 8,
                padding: '8px 16px', borderRadius: 999,
                background: selPill.glow,
                border: `1px solid ${selPill.color}38`,
              }}>
                <div style={{
                  width: 6, height: 6, borderRadius: '50%',
                  background: selPill.color,
                  boxShadow: `0 0 6px ${selPill.color}`,
                  flexShrink: 0,
                }}/>
                <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 12, fontWeight: 500, color: selPill.color }}>
                  {STEP_ECHO[selected - 1]}
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Back / Next */}
        <div style={{ display: 'flex', gap: 12, paddingBottom: 44, paddingTop: 12, flexShrink: 0 }}>
          <button
            onClick={onBack}
            style={{
              flex: 1, padding: '15px 0', borderRadius: 13,
              fontFamily: 'Outfit,sans-serif', fontSize: 15, fontWeight: 500,
              background: 'var(--rr-in)', color: 'var(--rr-t3)',
              border: '1px solid var(--rr-dv3)', cursor: 'pointer',
              transition: 'opacity 0.15s',
            }}
          >
            Back
          </button>
          <button
            onClick={onNext}
            disabled={!canNext}
            style={{
              flex: 2.5, padding: '15px 0', borderRadius: 13,
              fontFamily: 'Outfit,sans-serif', fontSize: 15, fontWeight: 600,
              border: 'none', cursor: canNext ? 'pointer' : 'default',
              transition: 'all 0.2s cubic-bezier(.4,0,.2,1)',
              background: canNext ? '#818CF8' : 'rgba(129,140,248,0.12)',
              color: canNext ? '#0C1220' : 'rgba(129,140,248,0.35)',
              boxShadow: canNext
                ? '0 4px 24px rgba(129,140,248,0.32), 0 1px 0 var(--rr-b5) inset'
                : 'none',
              transform: canNext ? 'translateY(0)' : 'translateY(0)',
            }}
          >
            Next
          </button>
        </div>
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// STEP DEMO  (two-phone side-by-side showcase)
// ══════════════════════════════════════════════════════════════════════════
function StepDemo({ onOpenApp }: { onOpenApp: () => void }) {
  const [selA, setSelA] = useState(0)
  const [selB, setSelB] = useState(4)
  const [view, setView] = useState<'step' | 'offline'>('step')

  const SCALE = 0.72
  const W = 390
  const H = 844
  const SW = Math.round(W * SCALE)
  const SH = Math.round(H * SCALE)

  function PhoneShell({ label, accent = false, children }: { label: string; accent?: boolean; children: React.ReactNode }) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
        <span style={{
          fontFamily: 'Outfit,sans-serif', fontSize: 10, fontWeight: 600,
          letterSpacing: '0.12em',
          color: accent ? '#C4A870' : 'var(--rr-t6)',
        }}>
          {label}
        </span>
        <div style={{
          width: SW, height: SH,
          borderRadius: Math.round(40 * SCALE),
          overflow: 'hidden',
          boxShadow: '0 28px 80px rgba(0,0,0,0.72), 0 0 0 1px var(--rr-b1)',
          background: 'var(--rr-bg)',
        }}>
          <div style={{
            width: W, height: H,
            transform: `scale(${SCALE})`,
            transformOrigin: '0 0',
            display: 'flex',
            flexDirection: 'column',
          }}>
            {children}
          </div>
        </div>
      </div>
    )
  }

  /* ── Tab button ──────────────────────────────────────────────────────── */
  function Tab({ id, label }: { id: 'step' | 'offline'; label: string }) {
    const active = view === id
    return (
      <button
        onClick={() => setView(id)}
        style={{
          fontFamily: 'Outfit,sans-serif', fontSize: 12, fontWeight: 500,
          padding: '6px 14px', borderRadius: 8, border: 'none', cursor: 'pointer',
          transition: 'all 0.15s',
          background: active ? 'var(--rr-dv3)' : 'transparent',
          color: active ? 'var(--rr-t2)' : 'var(--rr-t6)',
        }}
      >
        {label}
      </button>
    )
  }

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--rr-bgd)', overflow: 'hidden' }}>

      {/* ── Header ───────────────────────────────────────────────────────── */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '16px 28px',
        borderBottom: '1px solid var(--rr-dv)',
        flexShrink: 0, gap: 16,
      }}>
        {/* Left: wordmark + tab nav */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          <div>
            <div style={{ fontFamily: 'Outfit,sans-serif', fontSize: 10, fontWeight: 600, color: 'var(--rr-t7)', letterSpacing: '0.12em', marginBottom: 3 }}>
              READINESS
            </div>
            <h1 style={{ fontFamily: 'Outfit,sans-serif', fontSize: 16, fontWeight: 600, color: 'var(--rr-t2)', margin: 0 }}>
              Design preview
            </h1>
          </div>

          {/* Separator */}
          <div style={{ width: 1, height: 28, background: 'var(--rr-dv3)', flexShrink: 0 }}/>

          {/* Tab switcher */}
          <div style={{
            display: 'flex', gap: 2,
            background: 'var(--rr-ov)',
            border: '1px solid var(--rr-dv2)',
            borderRadius: 10, padding: 3,
          }}>
            <Tab id="step"    label="Step screen"/>
            <Tab id="offline" label="Offline confirmation"/>
          </div>
        </div>

        {/* Right: open app */}
        <button
          onClick={onOpenApp}
          style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 13, fontWeight: 500,
            color: '#818CF8', background: 'rgba(129,140,248,0.09)',
            border: '1px solid rgba(129,140,248,0.22)',
            borderRadius: 9, padding: '8px 16px',
            cursor: 'pointer', flexShrink: 0,
          }}
        >
          Open full app →
        </button>
      </div>

      {/* ── Step screen view: two phones ─────────────────────────────────── */}
      {view === 'step' && (
        <>
          <div style={{
            flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
            gap: 36, padding: '0 32px 20px', overflow: 'auto',
          }}>
            <PhoneShell label="DEFAULT STATE">
              <CheckinStepScreen selected={selA} onSelect={setSelA} onBack={() => {}} onNext={() => {}}/>
            </PhoneShell>

            <div style={{
              width: 1, height: 260, flexShrink: 0,
              background: 'linear-gradient(180deg, transparent, var(--rr-dv2) 25%, var(--rr-dv2) 75%, transparent)',
            }}/>

            <PhoneShell label="ANSWER SELECTED">
              <CheckinStepScreen selected={selB} onSelect={setSelB} onBack={() => {}} onNext={() => {}}/>
            </PhoneShell>
          </div>

          <div style={{ textAlign: 'center', paddingBottom: 16, fontFamily: 'Outfit,sans-serif', fontSize: 11, color: 'var(--rr-t7)', flexShrink: 0 }}>
            Both screens are interactive — tap the pills to explore states
          </div>
        </>
      )}

      {/* ── Offline confirmation view: single centred phone ───────────────── */}
      {view === 'offline' && (
        <>
          <div style={{
            flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
            padding: '0 32px 20px', gap: 20, overflow: 'auto',
          }}>
            {/* Context label above the phone */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 8,
              padding: '8px 16px', borderRadius: 999,
              background: 'rgba(196,168,100,0.07)',
              border: '1px solid rgba(196,168,100,0.18)',
            }}>
              <span style={{ color: '#C4A870', display: 'flex', alignItems: 'center' }}>
                <IconNoWifi size={11}/>
              </span>
              <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 11, fontWeight: 500, color: '#C4A870' }}>
                Shown immediately after submitting while offline
              </span>
            </div>

            <PhoneShell label="OFFLINE CONFIRMATION" accent>
              <OfflineSubmittedView/>
            </PhoneShell>
          </div>

          <div style={{ textAlign: 'center', paddingBottom: 16, fontFamily: 'Outfit,sans-serif', fontSize: 11, color: 'var(--rr-t7)', flexShrink: 0 }}>
            Honest status · no false success · reassuring copy
          </div>
        </>
      )}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// PIN SCREEN
// ══════════════════════════════════════════════════════════════════════════
const PIN_LENGTH = 6

function PinDots({ filled, total, state }: { filled: number; total: number; state: PinState }) {
  const color = state==='success' ? '#34D399' : state==='error' ? '#D55E00' : '#818CF8'
  const glow  = state==='success' ? 'rgba(52,211,153,0.55)' : state==='error' ? 'none' : 'rgba(129,140,248,0.55)'
  return (
    <div className={`flex items-center gap-[18px] ${state==='error' ? 'rr-shake' : ''}`}>
      {Array.from({ length:total }).map((_,i) => {
        const on = i < filled
        return (
          <div key={i} className="rounded-full transition-all duration-150" style={{
            width:12, height:12,
            background: on ? color : 'transparent',
            border:     on ? 'none' : '1.5px solid var(--rr-b7)',
            boxShadow:  on && state!=='error' ? `0 0 10px ${glow}` : 'none',
            transform:  on ? 'scale(1.1)' : 'scale(1)',
          }}/>
        )
      })}
    </div>
  )
}

function KeypadBtn({ children, onClick, disabled }: { children: React.ReactNode; onClick:()=>void; disabled:boolean }) {
  return (
    <button className="flex-1 group flex items-center justify-center py-[9px]" style={{ opacity:disabled?0.45:1 }} onClick={onClick} disabled={disabled}>
      <div className="w-[74px] h-[74px] rounded-full flex items-center justify-center transition-colors duration-75 group-active:bg-white/[.07]">
        {children}
      </div>
    </button>
  )
}

function Keypad({ onDigit, onDelete, disabled }: { onDigit:(d:string)=>void; onDelete:()=>void; disabled:boolean }) {
  const rows = [['1','2','3'],['4','5','6'],['7','8','9'],['','0','del']]
  return (
    <div className="w-full select-none">
      {rows.map((row,ri) => (
        <div key={ri} className="flex">
          {row.map((key,ki) => {
            if (key==='') return <div key={ki} className="flex-1"/>
            if (key==='del') return <KeypadBtn key={ki} onClick={onDelete} disabled={disabled}><div style={{color:'var(--rr-t5)'}}><IconDelete/></div></KeypadBtn>
            return (
              <KeypadBtn key={ki} onClick={() => onDigit(key)} disabled={disabled}>
                <span style={{ fontFamily:'Outfit, sans-serif', fontSize:32, fontWeight:300, color:'var(--rr-t1)', lineHeight:1 }}>{key}</span>
              </KeypadBtn>
            )
          })}
        </div>
      ))}
    </div>
  )
}

function PinScreen({ onUnlocked, onSetupNew }: { onUnlocked:()=>void; onSetupNew:()=>void }) {
  const [pin,     setPin]     = useState('')
  const [state,   setState]   = useState<PinState>('idle')
  const [attempt, setAttempt] = useState(0)

  const verify = (_full: string) => {
    setState('checking')
    setTimeout(() => {
      if (attempt===0) {
        setState('error')
        setTimeout(() => { setPin(''); setState('idle'); setAttempt(1) }, 750)
      } else {
        setState('success')
        setTimeout(onUnlocked, 650)
      }
    }, 380)
  }

  const handleDigit  = (d: string) => { if (state!=='idle'||pin.length>=PIN_LENGTH) return; const n=pin+d; setPin(n); if(n.length===PIN_LENGTH) verify(n) }
  const handleDelete = () => { if (state!=='idle') return; setPin(p=>p.slice(0,-1)) }

  return (
    <div className="flex-1 flex flex-col px-4">
      <div className="flex flex-col items-center pt-[60px]">
        <div className="text-[10px] font-[500] mb-8" style={{ color:'var(--rr-t7)', letterSpacing:'0.12em' }}>READINESS</div>
        <div className="w-14 h-14 rounded-full flex items-center justify-center mb-4"
          style={{ background:'rgba(129,140,248,0.08)', border:'1.5px solid rgba(129,140,248,0.20)' }}>
          <span style={{ fontFamily:'Outfit,sans-serif', fontSize:22, fontWeight:500, color:'#818CF8' }}>F</span>
        </div>
        <div className="text-[20px] font-[500] mb-1" style={{ color:'var(--rr-t2)' }}>Welcome back</div>
        <div className="text-[14px] mb-10" style={{ color:'var(--rr-t5)' }}>Foxtrot-42</div>
        <PinDots filled={pin.length} total={PIN_LENGTH} state={state}/>
        <div className="h-8 flex items-center mt-4">
          {state==='error'    && <span className="text-[13px]" style={{ color:'#D55E00' }}>Incorrect PIN — try again</span>}
          {state==='checking' && <span className="text-[13px]" style={{ color:'var(--rr-t6)' }}>Verifying…</span>}
          {state==='success'  && <span className="text-[13px]" style={{ color:'#34D399' }}>Unlocked</span>}
        </div>
      </div>
      <div className="flex-1"/>
      <Keypad onDigit={handleDigit} onDelete={handleDelete} disabled={state!=='idle'}/>
      <div className="flex flex-col items-center gap-1.5 py-5">
        <button onClick={() => { setState('success'); setTimeout(onUnlocked,600) }} disabled={state!=='idle'}
          className="flex flex-col items-center gap-2 px-8 py-2 rounded-2xl transition-opacity active:opacity-40"
          style={{ color:'var(--rr-t6)', opacity:state!=='idle'?0.4:1 }}>
          <IconFingerprint size={28}/>
          <span className="text-[12px]" style={{ color:'var(--rr-t5)' }}>Use biometrics</span>
        </button>
      </div>
      <div className="flex justify-center pb-8">
        <button onClick={onSetupNew} className="text-[11px] transition-opacity active:opacity-40" style={{ color:'var(--rr-t7)' }}>
          New device? Set up this device
        </button>
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// ACTIVATION SCREEN
// ══════════════════════════════════════════════════════════════════════════
function ActivationScreen({ onActivated }: { onActivated:()=>void }) {
  const [code,   setCode]   = useState('')
  const [status, setStatus] = useState<ActivateStatus>('idle')
  const rawCode = code.replace(/-/g,'')
  const isReady = rawCode.length===8
  const active  = isReady && status!=='loading'

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g,'').slice(0,8)
    setCode(raw.length>4 ? raw.slice(0,4)+'-'+raw.slice(4) : raw)
  }
  const handleActivate = async () => {
    if (!isReady||status==='loading') return
    setStatus('loading')
    await new Promise<void>(r=>setTimeout(r,1600))
    onActivated()
  }

  return (
    <div className="flex-1 overflow-y-auto flex flex-col px-6 pb-8">
      <div className="flex justify-center pt-16 pb-8">
        <div className="w-16 h-16 rounded-[18px] flex items-center justify-center"
          style={{ background:'rgba(129,140,248,0.10)', border:'1px solid rgba(129,140,248,0.24)', boxShadow:'0 0 48px rgba(129,140,248,0.10)', color:'#818CF8' }}>
          <IconShield size={28}/>
        </div>
      </div>
      <div className="mb-10">
        <div className="text-[10px] font-[500] mb-2.5" style={{ color:'var(--rr-t6)', letterSpacing:'0.10em' }}>READINESS</div>
        <h1 className="text-[27px] font-[600] leading-[1.25] mb-3.5" style={{ color:'var(--rr-t1)' }}>Activate this device</h1>
        <p className="text-[14px]" style={{ color:'var(--rr-t3)', lineHeight:1.65 }}>
          Your unit welfare office issued you a one-time activation code. Enter it here to link your personal readiness tracker.
        </p>
      </div>
      <div className="rr-card cursor-text transition-opacity duration-300" style={{ opacity:status==='loading'?0.55:1 }}
        onClick={() => document.getElementById('rr-act-input')?.focus()}>
        <div className="text-[12px] mb-5" style={{ color:'var(--rr-t4)' }}>Activation code</div>
        <input id="rr-act-input" type="text" inputMode="text" autoComplete="off" autoCorrect="off" autoCapitalize="characters" spellCheck={false}
          disabled={status==='loading'} value={code} onChange={handleChange} onKeyDown={e=>{ if(e.key==='Enter') handleActivate() }}
          placeholder="XXXX-XXXX" maxLength={9} className="rr-code-input w-full text-center bg-transparent outline-none"
          style={{ fontFamily:"'JetBrains Mono', monospace", fontSize:30, letterSpacing:'0.22em', color:'var(--rr-t1)', caretColor:'#818CF8' }}/>
        <div className="mx-6 mt-3 mb-5" style={{ height:1.5, borderRadius:1, background:'var(--rr-dv2)' }}>
          <div className="h-full rounded-sm transition-all duration-300"
            style={{ width:`${(rawCode.length/8)*100}%`, background:rawCode.length===8?'#818CF8':'rgba(129,140,248,0.45)' }}/>
        </div>
        <p className="text-[12px] text-center leading-relaxed" style={{ color:'var(--rr-t5)' }}>
          Printed on the letter from your welfare office.{' '}
          <span style={{ color:'var(--rr-t4)' }}>Single-use. Not connected to your service record.</span>
        </p>
      </div>
      <div className="flex-1" style={{ minHeight:24 }}/>
      <button onClick={handleActivate} disabled={!isReady||status==='loading'}
        className="w-full py-4 rounded-[14px] text-[15px] font-[600] mb-4 transition-all duration-200 active:scale-[0.98] flex items-center justify-center gap-2.5"
        style={{ background:active?'#818CF8':status==='loading'?'rgba(129,140,248,0.22)':'rgba(129,140,248,0.14)', color:active?'#0C1220':'rgba(129,140,248,0.45)', boxShadow:active?'0 4px 28px rgba(129,140,248,0.28), 0 1px 0 var(--rr-b2) inset':'none' }}>
        {status==='loading' && <span className="rr-spinner"/>}
        {status==='loading' ? 'Verifying…' : 'Activate device'}
      </button>
      <button className="w-full text-[14px] active:opacity-50 pb-2" style={{ color:'var(--rr-t4)' }}>
        Need a code? Contact your welfare office
      </button>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// CONSENT SCREEN
// ══════════════════════════════════════════════════════════════════════════
const ASSURANCES = [
  { icon:<IconLock/>,        title:'Private by design',        body:"Your entries live only on this device — no server, no database, no one but you.",                              color:'#818CF8' },
  { icon:<IconEyeOff/>,      title:'Never shared with command', body:"Nothing you log is reported to your chain of command, HR, or any disciplinary process. Ever.",               color:'#56B4E9' },
  { icon:<IconCircleCheck/>, title:'Entirely your choice',      body:'Skip any day or any question. No record is kept of what you choose not to log.',                              color:'#34D399' },
]
const LEARN_MORE = [
  "Check-ins are stored locally on your device using encrypted storage.",
  "No automatic alerts or flags are generated from your responses.",
  "There is no integration with personnel, medical, or command systems.",
  "You can review or delete all your data at any time through Settings.",
  "Questions? Reach out to your unit's wellness program coordinator.",
]

function ConsentScreen({ onAgree }: { onAgree:()=>void }) {
  const [expanded, setExpanded] = useState(false)
  return (
    <div className="flex-1 overflow-y-auto flex flex-col px-6 pb-8">
      <div className="flex justify-center pt-16 pb-9">
        <div className="w-[68px] h-[68px] rounded-[18px] flex items-center justify-center"
          style={{ background:'rgba(129,140,248,0.10)', border:'1px solid rgba(129,140,248,0.24)', boxShadow:'0 0 48px rgba(129,140,248,0.10)', color:'#818CF8' }}>
          <IconShield size={30}/>
        </div>
      </div>
      <div className="mb-7">
        <div className="text-[10px] font-[500] mb-2.5" style={{ color:'var(--rr-t6)', letterSpacing:'0.10em' }}>READINESS</div>
        <h1 className="text-[27px] font-[600] leading-[1.25] mb-3.5" style={{ color:'var(--rr-t1)' }}>Your check-ins,<br/>your call</h1>
        <p className="text-[14px]" style={{ color:'var(--rr-t3)', lineHeight:1.65 }}>
          This is a personal readiness tool — not an assessment, and not a record that goes anywhere else. You decide what you log, and you stay in control of it.
        </p>
      </div>
      <div className="rr-card mb-5">
        {ASSURANCES.map((a,i) => (
          <div key={a.title} className="flex gap-3.5" style={i>0 ? { borderTop:'1px solid var(--rr-dv)', paddingTop:16, marginTop:16 } : {}}>
            <div className="w-9 h-9 rounded-[10px] flex items-center justify-center shrink-0 mt-0.5" style={{ background:`${a.color}1C`, color:a.color }}>{a.icon}</div>
            <div>
              <div className="text-[14px] font-[500] leading-tight mb-1" style={{ color:'var(--rr-t2)' }}>{a.title}</div>
              <div className="text-[13px] leading-relaxed" style={{ color:'var(--rr-t3)', lineHeight:1.6 }}>{a.body}</div>
            </div>
          </div>
        ))}
      </div>
      {expanded && (
        <div className="rounded-[12px] px-4 py-4 mb-4" style={{ background:'var(--rr-ov)', border:'1px solid var(--rr-dv2)' }}>
          <div className="text-[12px] font-[500] mb-3" style={{ color:'var(--rr-t6)', letterSpacing:'0.06em' }}>A few more details</div>
          <div className="space-y-2.5">
            {LEARN_MORE.map((item,i) => (
              <div key={i} className="flex gap-2.5">
                <div className="w-1 h-1 rounded-full shrink-0" style={{ background:'var(--rr-t6)', marginTop:7 }}/>
                <span className="text-[13px] leading-relaxed" style={{ color:'var(--rr-t3)' }}>{item}</span>
              </div>
            ))}
          </div>
        </div>
      )}
      <div className="flex-1" style={{ minHeight:16 }}/>
      <button onClick={onAgree} className="w-full py-4 rounded-[14px] text-[15px] font-[600] mb-4 transition-all duration-200 active:scale-[0.98]"
        style={{ background:'#818CF8', color:'#0C1220', boxShadow:'0 4px 28px rgba(129,140,248,0.28), 0 1px 0 var(--rr-b4) inset' }}>
        I agree, continue
      </button>
      <button onClick={() => setExpanded(v=>!v)} className="w-full text-[14px] transition-opacity active:opacity-50 pb-2" style={{ color:'var(--rr-t3)' }}>
        {expanded ? 'Show less' : 'Learn more about data handling'}
      </button>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════
function HomeScreen({ onStartCheckin, onTab, todayDone }: {
  onStartCheckin: () => void
  onTab:          (t: Tab) => void
  todayDone:      boolean
}) {
  const hour     = new Date().getHours()
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'

  return (
    <div className="flex-1 flex flex-col relative overflow-hidden">
      <div className="absolute inset-0 pointer-events-none" style={{
        background: 'radial-gradient(ellipse 130% 44% at 50% -4%, rgba(129,140,248,0.09) 0%, transparent 60%)',
      }}/>

      <div className="relative flex-1 flex flex-col px-5 pt-[52px]">
        <div className="pt-2">
          <p className="text-[14px] font-[400] mb-0.5" style={{ color:'var(--rr-t4)' }}>{greeting},</p>
          <h1 className="text-[32px] font-[600] leading-tight tracking-[-0.01em]" style={{ color:'var(--rr-t1)' }}>
            Foxtrot-42
          </h1>
          <div className="flex items-center gap-2.5 mt-2">
            <span className="text-[13px]" style={{ color:'var(--rr-t5)' }}>Thursday, 4 Sep 2026</span>
            <span className="w-[3px] h-[3px] rounded-full" style={{ background:'var(--rr-t7)' }}/>
            <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full"
              style={{ background:'rgba(129,140,248,0.10)', border:'1px solid rgba(129,140,248,0.20)' }}>
              <span style={{ color:'#818CF8' }}><IconFlame/></span>
              <span className="text-[11px] font-[600]" style={{ color:'#818CF8' }}>Day 13</span>
            </div>
          </div>
        </div>

        <div className="flex-1" style={{ minHeight:40 }}/>

        <div className="pb-6">
          <div className="flex items-center justify-center gap-2 mb-5">
            <span className="w-[5px] h-[5px] rounded-full" style={{ background: todayDone ? '#34D399' : 'var(--rr-t6)' }}/>
            <span className="text-[13px]" style={{ color: todayDone ? '#3EC4A0' : 'var(--rr-t4)' }}>
              {todayDone ? "Checked in today" : "Not yet checked in today"}
            </span>
          </div>

          <button
            onClick={onStartCheckin}
            className="w-full rounded-[16px] font-[600] transition-all duration-200 active:scale-[0.98] mb-6"
            style={{
              padding:    '20px 24px',
              fontSize:   17,
              background: todayDone ? 'rgba(62,196,160,0.12)'  : '#818CF8',
              color:      todayDone ? '#3EC4A0'                : '#0C1220',
              border:     todayDone ? '1px solid rgba(62,196,160,0.25)' : 'none',
              boxShadow:  todayDone ? 'none' : '0 6px 36px rgba(129,140,248,0.34), 0 1px 0 var(--rr-b6) inset',
              letterSpacing: '-0.01em',
            }}
          >
            {todayDone ? "View today's entry" : "Start today's check-in"}
          </button>

          <div className="flex flex-col items-center gap-[18px]">
            <button
              onClick={() => onTab('trend')}
              className="flex items-center gap-1 transition-opacity active:opacity-50"
              style={{ color:'#818CF8' }}
            >
              <span className="text-[15px] font-[400]">View my trend</span>
              <IconChevronRight size={13}/>
            </button>

            <button
              onClick={() => onTab('support')}
              className="flex items-center gap-1 transition-opacity active:opacity-50"
              style={{ color:'var(--rr-t4)' }}
            >
              <span className="text-[15px] font-[400]">Resources &amp; support</span>
              <IconChevronRight size={13}/>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// SUPPORT SCREEN
// ══════════════════════════════════════════════════════════════════════════
function SupportScreen() {
  return (
    <div className="flex-1 overflow-y-auto px-4 pt-6 pb-6">
      <h2 className="text-[20px] font-[600] mb-1" style={{ color:'var(--rr-t1)' }}>Resources &amp; support</h2>
      <p className="text-[13px] mb-6" style={{ color:'var(--rr-t4)' }}>Confidential support, available any time</p>

      <div className="rr-card mb-3">
        <div className="flex items-start gap-3 mb-4">
          <div className="w-8 h-8 rounded-[9px] flex items-center justify-center shrink-0 mt-0.5"
            style={{ background:'rgba(129,140,248,0.12)', color:'#818CF8' }}><IconShield size={14}/></div>
          <div>
            <div className="text-[15px] font-[500] mb-1" style={{ color:'var(--rr-t1)' }}>Talk to your welfare officer</div>
            <div className="text-[13px] leading-relaxed" style={{ color:'var(--rr-t3)' }}>
              Conversations are confidential unless you decide otherwise. No formal record is created.
            </div>
          </div>
        </div>
        <button className="w-full py-3 rounded-[10px] text-[14px] font-[500] transition-all active:scale-[0.98]"
          style={{ background:'rgba(129,140,248,0.12)', color:'#818CF8', border:'1px solid rgba(129,140,248,0.20)' }}>
          Contact welfare office
        </button>
      </div>

      <div className="rr-card mb-3">
        <div className="text-[15px] font-[500] mb-1" style={{ color:'var(--rr-t1)' }}>24-hour support line</div>
        <div className="text-[13px] mb-4 leading-relaxed" style={{ color:'var(--rr-t3)' }}>
          Free and confidential — any time, any day.
        </div>
        <div className="grid grid-cols-2 gap-2">
          <button className="py-2.5 rounded-[10px] text-[13px] font-[500] transition-all active:scale-[0.98]"
            style={{ background:'rgba(52,211,153,0.10)', color:'#34D399', border:'1px solid rgba(52,211,153,0.20)' }}>
            0800 323 4444
          </button>
          <button className="py-2.5 rounded-[10px] text-[13px] font-[500] transition-all active:scale-[0.98]"
            style={{ background:'rgba(86,180,233,0.10)', color:'#56B4E9', border:'1px solid rgba(86,180,233,0.20)' }}>
            Text BLUE to 85258
          </button>
        </div>
      </div>

      <div className="rr-card">
        <div className="text-[14px] font-[500] mb-2" style={{ color:'var(--rr-t2)' }}>About this service</div>
        <div className="text-[13px] leading-relaxed" style={{ color:'var(--rr-t3)' }}>
          Your check-ins are stored locally on this device and are never shared without your consent. This app is provided by your unit welfare office as a voluntary wellbeing tool.
        </div>
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════
// ── Shared primitives ──────────────────────────────────────────────────────
function SettingRow({ label, value='', first=false, arrow=false, danger=false }: {
  label: string; value?: string; first?: boolean; arrow?: boolean; danger?: boolean
}) {
  return (
    <div className="flex items-center justify-between" style={!first ? { borderTop:'1px solid var(--rr-dv)', paddingTop:14, marginTop:12 } : {}}>
      <span className="text-[14px]" style={{ color: danger ? '#D55E00' : 'var(--rr-t2)' }}>{label}</span>
      {(value||arrow) && (
        <div className="flex items-center gap-1">
          {value && <span className="text-[13px]" style={{ color:'var(--rr-t4)' }}>{value}</span>}
          {arrow && <span style={{ color:'var(--rr-t6)' }}><IconChevronRight size={13}/></span>}
        </div>
      )}
    </div>
  )
}

function Toggle({ on, onToggle }: { on: boolean; onToggle: () => void }) {
  return (
    <button
      onClick={onToggle}
      className="relative shrink-0 transition-all duration-200"
      style={{ width:44, height:26, borderRadius:999, border:'none', cursor:'pointer',
        background: on ? '#818CF8' : 'var(--rr-b2)' }}
    >
      <div className="absolute top-[3px] w-5 h-5 rounded-full bg-white transition-all duration-200"
        style={{ left: on ? 'calc(100% - 23px)' : 3 }}/>
    </button>
  )
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <div className="text-[11px] font-[500] mb-2 px-0.5" style={{ color:'var(--rr-t6)', letterSpacing:'0.07em' }}>
      {children}
    </div>
  )
}

// ── Language data ──────────────────────────────────────────────────────────
const LANGUAGES = [
  { code:'en-GB', label:'English (UK)',  native:'English'   },
  { code:'en-US', label:'English (US)',  native:'English'   },
  { code:'fr',    label:'French',        native:'Français'  },
  { code:'de',    label:'German',        native:'Deutsch'   },
  { code:'es',    label:'Spanish',       native:'Español'   },
  { code:'cy',    label:'Welsh',         native:'Cymraeg'   },
  { code:'pl',    label:'Polish',        native:'Polski'    },
]

// ══════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════
function SettingsScreen() {
  // Appearance — sourced from root App via context
  const { theme, setTheme, onLogout } = useContext(ThemeCtx)
  // Language
  const [lang,  setLang]        = useState('en-GB')
  const [langOpen, setLangOpen] = useState(false)
  // Notifications
  const [reminder,      setReminder]      = useState(true)
  const [syncAlerts,    setSyncAlerts]    = useState(true)
  const [weeklySummary, setWeeklySummary] = useState(false)
  // Logout
  const [logout, setLogout] = useState<'idle'|'confirm'>('idle')
  // Deactivate
  const [deactivate, setDeactivate] = useState<'idle'|'confirm'>('idle')

  const currentLang = LANGUAGES.find(l => l.code === lang)!

  return (
    <div className="flex-1 overflow-y-auto px-4 pt-6 pb-10">
      <h2 className="text-[20px] font-[600] mb-6" style={{ color:'var(--rr-t1)' }}>Settings</h2>

      {/* ── Appearance ─────────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Appearance</SectionLabel>
        <div className="rr-card">
          <div className="flex items-center justify-between mb-3">
            <div>
              <div className="text-[14px]" style={{ color:'var(--rr-t2)' }}>Theme</div>
              <div className="text-[12px] mt-0.5" style={{ color:'var(--rr-t4)' }}>
                {theme === 'dark' ? 'Low-light interface' : 'High-contrast interface'}
              </div>
            </div>
          </div>
          {/* Segmented theme picker */}
          <div style={{
            display:'flex', gap:6, padding:4, borderRadius:10,
            background:'var(--rr-in)',
            border:'1px solid var(--rr-dv2)',
          }}>
            {(['dark','light'] as const).map(t => {
              const active = theme === t
              return (
                <button
                  key={t}
                  onClick={() => setTheme(t)}
                  style={{
                    flex:1, display:'flex', alignItems:'center', justifyContent:'center', gap:7,
                    padding:'9px 0', borderRadius:7, border:'none', cursor:'pointer',
                    transition:'all 0.18s',
                    background: active ? 'var(--rr-b1)' : 'transparent',
                    boxShadow: active ? '0 1px 0 var(--rr-dv3) inset' : 'none',
                  }}
                >
                  <span style={{ color: active ? 'var(--rr-t2)' : 'var(--rr-t6)' }}>
                    {t === 'dark' ? <IconMoon size={14}/> : <IconSun size={14}/>}
                  </span>
                  <span style={{
                    fontFamily:'Outfit,sans-serif', fontSize:13, fontWeight: active ? 500 : 400,
                    color: active ? 'var(--rr-t2)' : 'var(--rr-t4)',
                  }}>
                    {t === 'dark' ? 'Dark' : 'Light'}
                  </span>
                </button>
              )
            })}
          </div>
        </div>
      </div>

      {/* ── Your account ───────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Your account</SectionLabel>
        <div className="rr-card">
          <SettingRow label="Your ID"          value="Foxtrot-42"  first />
          <SettingRow label="PIN & biometrics" value="Configured"  arrow />
        </div>
      </div>

      {/* ── Language & region ───────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Language &amp; region</SectionLabel>
        <div className="rr-card">
          {/* Language row — tapping expands the picker inline */}
          <button
            onClick={() => setLangOpen(v => !v)}
            style={{ display:'flex', alignItems:'center', justifyContent:'space-between',
              width:'100%', background:'none', border:'none', cursor:'pointer', padding:0, textAlign:'left' }}
          >
            <div style={{ display:'flex', alignItems:'center', gap:10 }}>
              <span style={{ color:'var(--rr-t4)' }}><IconGlobe size={15}/></span>
              <div>
                <div className="text-[14px]" style={{ color:'var(--rr-t2)' }}>Language</div>
                <div className="text-[12px] mt-0.5" style={{ color:'var(--rr-t4)' }}>
                  {currentLang.label} · {currentLang.native}
                </div>
              </div>
            </div>
            <span style={{ color:'var(--rr-t6)', transform: langOpen ? 'rotate(90deg)' : 'rotate(0deg)', transition:'transform 0.2s' }}>
              <IconChevronRight size={13}/>
            </span>
          </button>

          {/* Inline language list */}
          {langOpen && (
            <div style={{ marginTop:14, paddingTop:14, borderTop:'1px solid var(--rr-dv2)' }}>
              {LANGUAGES.map(l => {
                const selected = lang === l.code
                return (
                  <button
                    key={l.code}
                    onClick={() => { setLang(l.code); setLangOpen(false) }}
                    style={{
                      display:'flex', alignItems:'center', justifyContent:'space-between',
                      width:'100%', border:'none', cursor:'pointer',
                      padding:'9px 10px', borderRadius:9, textAlign:'left', transition:'background 0.12s',
                      background: selected ? 'rgba(129,140,248,0.10)' : 'transparent',
                      marginBottom:2,
                    }}
                  >
                    <div>
                      <span className="text-[13px]" style={{ fontWeight: selected ? 500 : 400,
                        color: selected ? 'var(--rr-t2)' : 'var(--rr-t2b)' }}>
                        {l.label}
                      </span>
                      {l.native !== 'English' && (
                        <span className="text-[12px] ml-2" style={{ color:'var(--rr-t4)' }}>{l.native}</span>
                      )}
                    </div>
                    {selected && (
                      <div style={{ width:7, height:7, borderRadius:'50%', background:'#818CF8', boxShadow:'0 0 6px rgba(129,140,248,0.6)', flexShrink:0 }}/>
                    )}
                  </button>
                )
              })}
            </div>
          )}
        </div>
      </div>

      {/* ── Notifications ───────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Notifications</SectionLabel>
        <div className="rr-card">
          {/* Icon + label row helper */}
          {([
            { icon:<IconBell size={14}/>,     label:'Check-in reminder', sub:'07:30 daily',              on:reminder,      set:setReminder      },
            { icon:<IconCloudQueue size={14}/>,label:'Sync alerts',       sub:'When offline data syncs',  on:syncAlerts,    set:setSyncAlerts    },
            { icon:<IconCalendar size={14}/>,  label:'Weekly summary',    sub:'Mondays at 08:00',         on:weeklySummary, set:setWeeklySummary },
          ] as const).map(({ icon, label, sub, on, set }, i) => (
            <div key={label}
              style={i > 0 ? { borderTop:'1px solid var(--rr-dv)', paddingTop:14, marginTop:12 } : {}}>
              <div className="flex items-center justify-between">
                <div style={{ display:'flex', alignItems:'center', gap:10 }}>
                  <span style={{ color: on ? '#818CF8' : 'var(--rr-t6)' }}>{icon}</span>
                  <div>
                    <div className="text-[14px]" style={{ color:'var(--rr-t2)' }}>{label}</div>
                    <div className="text-[12px] mt-0.5" style={{ color:'var(--rr-t4)' }}>{sub}</div>
                  </div>
                </div>
                <Toggle on={on} onToggle={() => set((v: boolean) => !v)}/>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── Data & privacy ─────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Data &amp; privacy</SectionLabel>
        <div className="rr-card">
          <SettingRow label="Data handling"    arrow  first />
          <SettingRow label="Delete all my data" danger />
        </div>
      </div>

      {/* ── Session ────────────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Session</SectionLabel>
        <div className="rr-card">
          {logout === 'idle' ? (
            <button
              onClick={() => setLogout('confirm')}
              style={{ display:'flex', alignItems:'center', gap:10,
                background:'none', border:'none', cursor:'pointer', padding:0, textAlign:'left', width:'100%' }}
            >
              <span style={{ color:'#EF6B6B' }}><IconLogOut size={15}/></span>
              <span className="text-[14px]" style={{ color:'var(--rr-t2)' }}>Sign out</span>
            </button>
          ) : (
            <div>
              <div style={{
                display:'flex', alignItems:'flex-start', gap:10, marginBottom:14,
                padding:'12px 14px', borderRadius:10,
                background:'rgba(239,107,107,0.07)', border:'1px solid rgba(239,107,107,0.20)',
              }}>
                <span style={{ color:'#EF6B6B', flexShrink:0, marginTop:1 }}><IconLogOut size={14}/></span>
                <div>
                  <div className="text-[13px] font-[500] mb-1" style={{ color:'#EF6B6B' }}>
                    Sign out of READINESS?
                  </div>
                  <div className="text-[12px] leading-relaxed" style={{ color:'var(--rr-t5)' }}>
                    The app will lock. Your data stays on this device — sign back in with your PIN to continue.
                  </div>
                </div>
              </div>
              <div style={{ display:'flex', gap:10 }}>
                <button
                  onClick={() => setLogout('idle')}
                  style={{
                    flex:1, padding:'11px 0', borderRadius:10, border:'none', cursor:'pointer',
                    fontFamily:'Outfit,sans-serif', fontSize:13, fontWeight:500,
                    background:'var(--rr-dv)', color:'var(--rr-t2b)',
                  }}
                >
                  Cancel
                </button>
                <button
                  onClick={onLogout}
                  style={{
                    flex:1.5, padding:'11px 0', borderRadius:10, cursor:'pointer',
                    fontFamily:'Outfit,sans-serif', fontSize:13, fontWeight:600,
                    background:'rgba(239,107,107,0.14)', color:'#EF6B6B',
                    border:'1px solid rgba(239,107,107,0.28)',
                  }}
                >
                  Sign out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── Device ─────────────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>Device</SectionLabel>
        <div className="rr-card">
          {deactivate === 'idle' ? (
            <button
              onClick={() => setDeactivate('confirm')}
              style={{ display:'flex', alignItems:'center', gap:10,
                background:'none', border:'none', cursor:'pointer', padding:0, textAlign:'left', width:'100%' }}
            >
              <span style={{ color:'#C07830' }}><IconAlertTriangle size={14}/></span>
              <span className="text-[14px]" style={{ color:'var(--rr-t2)' }}>Deactivate this device</span>
            </button>
          ) : (
            /* Confirmation state */
            <div>
              <div style={{
                display:'flex', alignItems:'flex-start', gap:10, marginBottom:14,
                padding:'12px 14px', borderRadius:10,
                background:'rgba(192,120,48,0.08)', border:'1px solid rgba(192,120,48,0.22)',
              }}>
                <span style={{ color:'#C07830', flexShrink:0, marginTop:1 }}><IconAlertTriangle size={14}/></span>
                <div>
                  <div className="text-[13px] font-[500] mb-1" style={{ color:'#C4A870' }}>
                    Deactivate this device?
                  </div>
                  <div className="text-[12px] leading-relaxed" style={{ color:'#7A8A6A' }}>
                    This will unlink the device from your unit. Your check-in history will be removed locally. {"You'll"} need a new activation code to use the app again.
                  </div>
                </div>
              </div>
              <div style={{ display:'flex', gap:10 }}>
                <button
                  onClick={() => setDeactivate('idle')}
                  style={{
                    flex:1, padding:'11px 0', borderRadius:10, border:'none', cursor:'pointer',
                    fontFamily:'Outfit,sans-serif', fontSize:13, fontWeight:500,
                    background:'var(--rr-dv)', color:'var(--rr-t2b)',
                  }}
                >
                  Cancel
                </button>
                <button
                  style={{
                    flex:1.5, padding:'11px 0', borderRadius:10, cursor:'pointer',
                    fontFamily:'Outfit,sans-serif', fontSize:13, fontWeight:600,
                    background:'rgba(192,120,48,0.18)', color:'#C4A870',
                    border:'1px solid rgba(192,120,48,0.30)',
                  }}
                >
                  Deactivate
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── About ──────────────────────────────────────────────────────── */}
      <div className="mb-5">
        <SectionLabel>About</SectionLabel>
        <div className="rr-card">
          <SettingRow label="App version"    value="1.0.0"       first />
          <SettingRow label="Unit programme" value="Bravo Wing"        />
        </div>
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// CHECK-IN COMPONENTS
// ══════════════════════════════════════════════════════════════════════════
function ScalePicker({ value, onChange }: { value:number; onChange:(n:number)=>void }) {
  return (
    <div className="space-y-2">
      <div className="flex justify-between">
        {[1,2,3,4,5].map(n => {
          const on = value===n
          return (
            <button key={n} onClick={() => onChange(n)} className="w-12 h-12 rounded-full flex items-center justify-center transition-all duration-200 active:scale-95"
              style={{ border:on?`2px solid ${sc(n)}`:'1.5px solid var(--rr-b3)', background:on?sg(n):'var(--rr-ov)', boxShadow:on?`0 0 18px ${sg(n)}`:'none' }}>
              {on && <div className="w-2.5 h-2.5 rounded-full" style={{ background:sc(n), boxShadow:`0 0 8px ${sc(n)}` }}/>}
            </button>
          )
        })}
      </div>
      <div className="flex justify-between">
        <span className="text-[11px]" style={{ color:'var(--rr-t4)' }}>Not ready</span>
        <span className="text-[11px]" style={{ color:'var(--rr-t4)' }}>Fully ready</span>
      </div>
    </div>
  )
}

function DimCard({ dim, value, onChange }: { dim:Dim; value:number; onChange:(n:number)=>void }) {
  return (
    <div className="rr-card">
      <div className="flex items-start gap-2.5 mb-4">
        <div className="mt-0.5 shrink-0" style={{ color:value>0?sc(value):'var(--rr-t4)' }}>{dim.icon}</div>
        <div className="flex-1">
          <div className="text-[15px] font-[500] leading-tight" style={{ color:'var(--rr-t1)' }}>{dim.label}</div>
          <div className="text-[12px] mt-0.5" style={{ color:'var(--rr-t3)' }}>{dim.hint}</div>
        </div>
        {value>0 && <div className="text-[12px] font-[500] shrink-0 mt-0.5" style={{ color:sc(value) }}>{slabel(value)}</div>}
      </div>
      <ScalePicker value={value} onChange={onChange}/>
    </div>
  )
}

function ScoreDots({ score }: { score:number }) {
  return (
    <div className="flex gap-1">
      {[1,2,3,4,5].map(n => <div key={n} className="rounded-full" style={{ width:6, height:6, background:n<=score?sc(score):'var(--rr-ib)' }}/>)}
    </div>
  )
}

function CheckinView({ scores, setScore, note, setNote, onSubmit, onBack }: {
  scores:Record<DimKey,number>; setScore:(k:DimKey,n:number)=>void
  note:string; setNote:(s:string)=>void; onSubmit:()=>void; onBack:()=>void
}) {
  const filled  = DIMS.filter(d=>scores[d.key]>0).length
  const allDone = filled===4
  return (
    <div className="flex-1 overflow-y-auto px-4 py-5 space-y-3">
      <button onClick={onBack} className="flex items-center gap-1 -ml-1 mb-1 transition-opacity active:opacity-50" style={{ color:'var(--rr-t4)' }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        <span className="text-[13px]">Home</span>
      </button>
      <div className="pb-1">
        <div className="text-[13px] mb-1" style={{ color:'var(--rr-t4)' }}>Thursday, 4 Sep 2026</div>
        <h1 className="text-[21px] font-[600] leading-tight" style={{ color:'var(--rr-t1)' }}>Daily readiness check-in</h1>
        <p className="text-[13px] mt-1.5" style={{ color:'var(--rr-t3)' }}>Private to you and your unit lead. Takes about a minute.</p>
      </div>
      {DIMS.map(dim => <DimCard key={dim.key} dim={dim} value={scores[dim.key]} onChange={n=>setScore(dim.key,n)}/>)}
      <div className="rr-card">
        <div className="text-[14px] font-[500] mb-3" style={{ color:'var(--rr-t2)' }}>
          Anything to add?{' '}<span className="font-[400]" style={{ color:'var(--rr-t4)' }}>(optional)</span>
        </div>
        <textarea className="rr-textarea" rows={3} maxLength={200} placeholder="Brief note for your record..." value={note} onChange={e=>setNote(e.target.value)}/>
        {note.length>160 && <div className="text-[11px] mt-1.5 text-right" style={{ color:'var(--rr-t4)' }}>{200-note.length} remaining</div>}
      </div>
      <button onClick={onSubmit} disabled={!allDone} className="w-full py-4 rounded-[14px] text-[15px] font-[600] transition-all duration-200 active:scale-[0.98]"
        style={{ background:allDone?'#818CF8':'rgba(129,140,248,0.14)', color:allDone?'#0C1220':'rgba(129,140,248,0.45)', boxShadow:allDone?'0 4px 28px rgba(129,140,248,0.28), 0 1px 0 var(--rr-b2) inset':'none' }}>
        {allDone ? "Log today's readiness" : `${filled} of 4 complete`}
      </button>
      <div className="h-6"/>
    </div>
  )
}

function SubmittedView({ scores, note, onDone }: { scores:Record<DimKey,number>; note:string; onDone:()=>void }) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center px-6 py-10 overflow-y-auto">
      <div className="w-20 h-20 rounded-full flex items-center justify-center mb-7"
        style={{ background:'rgba(52,211,153,0.10)', border:'1.5px solid rgba(52,211,153,0.28)', boxShadow:'0 0 48px rgba(52,211,153,0.12)', color:'#34D399' }}>
        <IconCheck/>
      </div>
      <h2 className="text-[22px] font-[600] text-center mb-1.5" style={{ color:'var(--rr-t1)' }}>Readiness logged</h2>
      <p className="text-[14px] text-center mb-8" style={{ color:'var(--rr-t3)', lineHeight:1.6 }}>Thursday, 4 Sep 2026 · See you tomorrow</p>
      <div className="rr-card w-full mb-5 space-y-4">
        {DIMS.map(d => (
          <div key={d.key} className="flex items-center gap-3">
            <div className="shrink-0" style={{ color:sc(scores[d.key]) }}>{d.icon}</div>
            <span className="text-[13px] flex-1" style={{ color:'var(--rr-t3)' }}>{d.label}</span>
            <ScoreDots score={scores[d.key]}/>
            <span className="text-[12px] font-[500] w-[72px] text-right" style={{ color:sc(scores[d.key]) }}>{slabel(scores[d.key])}</span>
          </div>
        ))}
        {note && <div className="pt-4" style={{ borderTop:'1px solid var(--rr-dv2)' }}>
          <div className="text-[11px] mb-1" style={{ color:'var(--rr-t6)' }}>Note</div>
          <div className="text-[13px] leading-relaxed" style={{ color:'var(--rr-t2b)' }}>{note}</div>
        </div>}
      </div>
      <div className="flex items-center gap-2 px-4 py-2.5 rounded-full mb-8"
        style={{ background:'rgba(129,140,248,0.09)', border:'1px solid rgba(129,140,248,0.20)' }}>
        <span style={{ color:'#818CF8' }}><IconFlame size={13}/></span>
        <span className="text-[13px] font-[500]" style={{ color:'#818CF8' }}>13-day streak — well done</span>
      </div>
      <button onClick={onDone} className="text-[14px] font-[500] transition-opacity active:opacity-60" style={{ color:'#818CF8' }}>
        Back to home
      </button>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// OFFLINE SUBMITTED VIEW
// ══════════════════════════════════════════════════════════════════════════
const OFFLINE_SCORES: Record<DimKey, number> = { overall: 4, sleep: 3, physical: 4, focus: 4 }

function OfflineSubmittedView({ onDone = () => {} }: { onDone?: () => void }) {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: 'var(--rr-bg)', position: 'relative', overflow: 'hidden' }}>

      {/* Subtle warm atmospheric wash — distinct from the green success glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(ellipse 110% 36% at 50% -2%, rgba(196,168,100,0.055) 0%, transparent 55%)',
      }}/>

      <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', padding: '0 24px 36px', position: 'relative' }}>

        {/* ── Icon area ─────────────────────────────────────────────────────── */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 56, paddingBottom: 28 }}>

          {/* Rounded-square container — deliberately NOT a circle, which reads as "complete" */}
          <div style={{
            position: 'relative',
            width: 72, height: 72,
            borderRadius: 20,
            background: 'rgba(196,168,100,0.07)',
            border: '1.5px solid rgba(196,168,100,0.24)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 22,
          }}>
            <span style={{ color: '#C4A870' }}>
              <IconCloudQueue size={30}/>
            </span>

            {/* Small "queued" badge — bottom-right corner */}
            <div style={{
              position: 'absolute', bottom: -9, right: -9,
              width: 22, height: 22, borderRadius: 8,
              background: 'var(--rr-bg)',
              border: '1.5px solid rgba(196,168,100,0.28)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <span style={{ color: '#C4A870', fontSize: 10, fontFamily: 'Outfit,sans-serif', fontWeight: 700, letterSpacing: '0.04em', lineHeight: 1 }}>
                ···
              </span>
            </div>
          </div>

          {/* Headline */}
          <h2 style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 22, fontWeight: 600,
            color: 'var(--rr-t1)', textAlign: 'center', marginBottom: 10, lineHeight: 1.25,
          }}>
            Saved on your device
          </h2>

          {/* Timestamp — reassures data was captured */}
          <p style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 13, color: 'var(--rr-t4)',
            textAlign: 'center', marginBottom: 14,
          }}>
            Thu, 4 Sep 2026 · 14:32
          </p>

          {/* Body copy — honest, calm */}
          <p style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 14, color: 'var(--rr-t3)',
            textAlign: 'center', lineHeight: 1.65, marginBottom: 20, maxWidth: 300,
          }}>
            {"You're offline right now. This check-in is stored locally and will sync automatically when your connection is restored."}
          </p>

          {/* Offline status chip */}
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 7,
            padding: '7px 14px', borderRadius: 999,
            background: 'rgba(196,168,100,0.08)',
            border: '1px solid rgba(196,168,100,0.22)',
          }}>
            <span style={{ color: '#C4A870', display: 'flex', alignItems: 'center' }}>
              <IconNoWifi size={11}/>
            </span>
            <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 12, fontWeight: 500, color: '#C4A870' }}>
              Offline · Syncs when reconnected
            </span>
          </div>
        </div>

        {/* ── Score summary ──────────────────────────────────────────────────── */}
        <div className="rr-card" style={{ marginBottom: 12 }}>
          <div style={{
            fontFamily: 'Outfit,sans-serif', fontSize: 10, fontWeight: 600,
            color: 'var(--rr-t6)', letterSpacing: '0.10em', marginBottom: 14,
          }}>
            WHAT YOU LOGGED
          </div>

          {DIMS.map((d, i) => (
            <div key={d.key} style={i > 0 ? { borderTop: '1px solid var(--rr-dv)', paddingTop: 12, marginTop: 12 } : {}}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ color: sc(OFFLINE_SCORES[d.key]), flexShrink: 0 }}>{d.icon}</div>
                <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 13, color: 'var(--rr-t3)', flex: 1 }}>{d.label}</span>
                <ScoreDots score={OFFLINE_SCORES[d.key]}/>
                <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 12, fontWeight: 500, color: sc(OFFLINE_SCORES[d.key]), width: 68, textAlign: 'right' }}>
                  {slabel(OFFLINE_SCORES[d.key])}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* ── Reassurance note ───────────────────────────────────────────────── */}
        <div style={{
          borderRadius: 10, padding: '12px 14px', marginBottom: 28,
          background: 'var(--rr-ov)',
          border: '1px solid var(--rr-dv)',
        }}>
          <p style={{ fontFamily: 'Outfit,sans-serif', fontSize: 12, color: 'var(--rr-t4)', lineHeight: 1.65, margin: 0 }}>
            Nothing is lost. Your data is on this device and will appear in your trend as soon as the sync completes.
          </p>
        </div>

        {/* ── Back to home ───────────────────────────────────────────────────── */}
        <button
          onClick={onDone}
          style={{
            width: '100%', padding: '15px 0', borderRadius: 13, border: 'none',
            fontFamily: 'Outfit,sans-serif', fontSize: 15, fontWeight: 500,
            color: '#818CF8', background: 'rgba(129,140,248,0.09)',
            cursor: 'pointer', transition: 'opacity 0.15s',
          }}
        >
          Back to home
        </button>
      </div>
    </div>
  )
}

function TrendView({ history }: { history:Entry[] }) {
  const avg = (key:DimKey) => Math.round((history.reduce((a,e)=>a+e[key],0)/history.length)*10)/10
  return (
    <div className="flex-1 overflow-y-auto px-4 pt-6 pb-6">
      {/* Heading row */}
      <h2 className="text-[20px] font-[600] mb-1" style={{ color:'var(--rr-t1)' }}>My trend</h2>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <p className="text-[13px]" style={{ color:'var(--rr-t4)' }}>Last 7 entries · 13-day streak</p>
        {/* Privacy note — one line, low-key */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
          <span style={{ color: 'var(--rr-t7)', display: 'flex', alignItems: 'center' }}><IconLock size={10}/></span>
          <span style={{ fontFamily: 'Outfit,sans-serif', fontSize: 11, color: 'var(--rr-t6)' }}>Visible only to you</span>
        </div>
      </div>

      {/* 30-day chart */}
      <TrendChart/>

      {/* 7-day averages (existing) */}
      <div className="rr-card mb-4">
        <div className="text-[12px] font-[500] mb-4" style={{ color:'var(--rr-t6)', letterSpacing:'0.06em' }}>7-day average</div>
        <div className="grid grid-cols-2 gap-y-4 gap-x-3">
          {DIMS.map(d => { const a=avg(d.key); const col=sc(Math.round(a)); return (
            <div key={d.key} className="flex items-center gap-2.5">
              <div style={{ color:col }}>{d.icon}</div>
              <div>
                <div className="text-[11px]" style={{ color:'var(--rr-t4)' }}>{d.label}</div>
                <div className="text-[19px] font-[600] leading-tight" style={{ color:col }}>
                  {a}<span className="text-[11px] font-[400] ml-0.5" style={{ color:'var(--rr-t6)' }}>/5</span>
                </div>
              </div>
            </div>
          )})}
        </div>
      </div>
      {/* Suggested resources */}
      <ResourceList/>

      {/* Entry history (existing) */}
      <div className="space-y-2.5 pb-2">
        {history.map((entry,i) => (
          <div key={i} className="rr-card-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-1.5">
                <span style={{ color:'var(--rr-t4)' }}><IconCalendar size={12}/></span>
                <span className="text-[13px] font-[500]" style={{ color:'var(--rr-t2)' }}>{entry.date}</span>
              </div>
              <span className="text-[12px] font-[500]" style={{ color:sc(entry.overall) }}>{slabel(entry.overall)}</span>
            </div>
            <div className="flex gap-2">
              {DIMS.map(d => <div key={d.key} className="flex-1 flex flex-col items-center gap-1.5">
                <div style={{ color:sc(entry[d.key]) }}>{d.icon}</div>
                <div className="w-1.5 h-1.5 rounded-full" style={{ background:sc(entry[d.key]) }}/>
              </div>)}
            </div>
            {entry.note && <div className="mt-3 pt-3 text-[12px] leading-relaxed" style={{ borderTop:'1px solid var(--rr-dv)', color:'var(--rr-t3)' }}>{entry.note}</div>}
          </div>
        ))}
      </div>
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// BOTTOM NAV
// ══════════════════════════════════════════════════════════════════════════
function BottomNav({ active, onTab }: { active:Tab; onTab:(t:Tab)=>void }) {
  const tabs: { key: Tab; label: string; icon: React.ReactNode }[] = [
    { key:'home',     label:'Home',     icon:<IconHome/> },
    { key:'trend',    label:'Trend',    icon:<IconTrend/> },
    { key:'support',  label:'Support',  icon:<IconMessageCircle/> },
    { key:'settings', label:'Settings', icon:<IconSliders/> },
  ]
  return (
    <div className="flex shrink-0" style={{ background:'var(--rr-bgn)', borderTop:'1px solid var(--rr-dv2)' }}>
      {tabs.map(({ key, label, icon }) => (
        <button key={key} onClick={() => onTab(key)}
          className="flex-1 flex flex-col items-center gap-[3px] py-3 transition-all duration-150 active:opacity-70"
          style={{ color: active===key ? '#818CF8' : 'var(--rr-t6)' }}>
          {icon}
          <span className="text-[10px] font-[500]">{label}</span>
        </button>
      ))}
    </div>
  )
}

// ══════════════════════════════════════════════════════════════════════════
// ROOT
// ══════════════════════════════════════════════════════════════════════════
export default function App() {
  const [theme,      setTheme]      = useState<'dark'|'light'>('dark')
  const [screen,     setScreen]     = useState<Screen>('stepDemo')
  const [tab,        setTab]        = useState<Tab>('home')
  const [inCheckin,  setInCheckin]  = useState(false)
  const [submitted,  setSubmitted]  = useState(false)
  const [todayDone,  setTodayDone]  = useState(false)
  const [scores,     setScores]     = useState<Record<DimKey,number>>({ overall:0, sleep:0, physical:0, focus:0 })
  const [note,       setNote]       = useState('')
  const [history,    setHistory]    = useState<Entry[]>(SEED)

  const setScore = (k:DimKey, n:number) => setScores(p=>({...p,[k]:n}))

  const handleSubmit = () => {
    setHistory(p=>[{ date:'Thu, Sep 4', ...scores, note }, ...p])
    setInCheckin(false)
    setSubmitted(true)
    setTodayDone(true)
  }

  const handleDoneViewing = () => {
    setSubmitted(false)
    setTab('home')
  }

  const handleStartCheckin = () => {
    if (todayDone) { setSubmitted(true); return }
    setScores({ overall:0, sleep:0, physical:0, focus:0 })
    setNote('')
    setInCheckin(true)
  }

  const handleLogout = () => {
    setInCheckin(false)
    setSubmitted(false)
    setTab('home')
    setScreen('pin')
  }

  // Step demo view — full width, two phones side by side
  if (screen === 'stepDemo') {
    return (
      <ThemeCtx.Provider value={{ theme, setTheme, onLogout: handleLogout }}>
        <div data-theme={theme} style={{ height:'100%' }}>
          <StepDemo onOpenApp={() => setScreen('pin')} />
        </div>
      </ThemeCtx.Provider>
    )
  }

  return (
    <ThemeCtx.Provider value={{ theme, setTheme, onLogout: handleLogout }}>
    <div data-theme={theme} className="h-full flex items-center justify-center" style={{ background:'var(--rr-bgd)' }}>
      <div className="flex flex-col overflow-hidden" style={{ width:'100%', maxWidth:390, height:'100%', maxHeight:844, background:'var(--rr-bg)' }}>

        {screen==='pin' && (
          <PinScreen onUnlocked={()=>setScreen('app')} onSetupNew={()=>setScreen('activation')}/>
        )}

        {screen==='activation' && (
          <ActivationScreen onActivated={()=>setScreen('consent')}/>
        )}

        {screen==='consent' && (
          <ConsentScreen onAgree={()=>setScreen('app')}/>
        )}

        {screen==='app' && (
          <>
            {inCheckin && !submitted && (
              <CheckinView
                scores={scores} setScore={setScore}
                note={note} setNote={setNote}
                onSubmit={handleSubmit}
                onBack={() => setInCheckin(false)}
              />
            )}

            {submitted && (
              <SubmittedView scores={scores} note={note} onDone={handleDoneViewing}/>
            )}

            {!inCheckin && !submitted && (
              <>
                {tab==='home'     && <HomeScreen onStartCheckin={handleStartCheckin} onTab={setTab} todayDone={todayDone}/>}
                {tab==='trend'    && <TrendView history={history}/>}
                {tab==='support'  && <SupportScreen/>}
                {tab==='settings' && <SettingsScreen/>}
                <BottomNav active={tab} onTab={setTab}/>
              </>
            )}
          </>
        )}

      </div>
    </div>
    </ThemeCtx.Provider>
  )
}
