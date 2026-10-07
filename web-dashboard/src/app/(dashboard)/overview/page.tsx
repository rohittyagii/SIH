"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, AreaChart, Area
} from "recharts";

interface UnitSummary {
  total_personnel: number;
  routine_count: number;
  monitor_count: number;
  intervention_count: number;
  unassessed_count: number;
  avg_duty_hours: number;
  avg_days_since_leave: number;
  avg_mood_score: number;
  unit_name: string;
}

interface Recommendation {
  id: string;
  welfare_officer_name: string;
  commander_name: string;
  soldier_id: string;
  soldier_name: string;
  soldier_service_id: string;
  unit_name: string;
  note: string;
  risk_level: string;
  status: string;
  commander_response: string | null;
  created_at: string;
  reviewed_at: string | null;
}

const recStatusConfig: Record<string, { label: string; color: string; bgColor: string }> = {
  Pending: { label: "Pending", color: "text-amber-400", bgColor: "bg-amber-500/10 border-amber-500/20" },
  Reviewed: { label: "Reviewed", color: "text-sky-400", bgColor: "bg-sky-500/10 border-sky-500/20" },
  Actioned: { label: "Actioned", color: "text-emerald-400", bgColor: "bg-emerald-500/10 border-emerald-500/20" },
};

const RISK_COLORS = {
  routine: "#34d399",
  monitor: "#fbbf24",
  intervention: "#f87171",
};

export default function OverviewPage() {
  const { role } = useAuth();
  const [summaries, setSummaries] = useState<UnitSummary[]>([]);
  const [trends, setTrends] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [assessing, setAssessing] = useState(false);
  const [hoveredSlice, setHoveredSlice] = useState<number | null>(null);
  const [recommendations, setRecommendations] = useState<Recommendation[]>([]);
  const [respondingTo, setRespondingTo] = useState<string | null>(null);
  const [responseNote, setResponseNote] = useState("");

  const [assessResult, setAssessResult] = useState<{
    assessed: number;
    skipped: number;
    errors: number;
    used_ml: boolean;
  } | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [s, t] = await Promise.all([api.getUnitSummary(), api.getTrends()]);
      setSummaries(s);
      setTrends(t);

      // Load recommendations for commanders
      if (role === "Commander") {
        try {
          const recs = await api.getIncomingRecommendations();
          setRecommendations(recs);
        } catch {
          // Endpoint may not exist yet; silently ignore
        }
      }
    } catch (err) {
      console.error("Failed to load overview:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleRecAction = async (recId: string, status: string) => {
    try {
      await api.updateRecommendation(recId, {
        status,
        commander_response: respondingTo === recId ? responseNote.trim() || undefined : undefined,
      });
      setRespondingTo(null);
      setResponseNote("");
      // Reload recommendations
      const recs = await api.getIncomingRecommendations();
      setRecommendations(recs);
    } catch (err) {
      console.error("Failed to update recommendation:", err);
    }
  };

  const runBatchAssessment = async () => {
    setAssessing(true);
    setAssessResult(null);
    try {
      let assessed = 0;
      let skipped = 0;
      let errors = 0;
      let usedMl = false;

      try {
        const result = await api.runAllAssessments();
        assessed = result.assessed;
        skipped = result.skipped ?? 0;
        errors = result.errors;
        usedMl = result.results.some((r: any) => r.used_ml);
      } catch (runAllErr: any) {
        for (const s of summaries) {
          if (s.unassessed_count === 0) {
            skipped += s.total_personnel;
            continue;
          }
          try {
            const unitResults = await api.runUnitAssessment(s.unit_name);
            assessed += unitResults.length;
            skipped += s.total_personnel - unitResults.length;
          } catch {
            errors += s.total_personnel;
          }
        }
      }

      setAssessResult({ assessed, skipped, errors, used_ml: usedMl });
      await loadData();
    } catch (err) {
      console.error("Assessment failed:", err);
    } finally {
      setAssessing(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin h-8 w-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  // Aggregate across all units
  const totals = summaries.reduce(
    (acc, s) => ({
      personnel: acc.personnel + s.total_personnel,
      routine: acc.routine + s.routine_count,
      monitor: acc.monitor + s.monitor_count,
      intervention: acc.intervention + s.intervention_count,
      unassessed: acc.unassessed + s.unassessed_count,
      dutyHours: acc.dutyHours + s.avg_duty_hours * s.total_personnel,
      leaveDays: acc.leaveDays + s.avg_days_since_leave * s.total_personnel,
      mood: acc.mood + s.avg_mood_score * s.total_personnel,
    }),
    { personnel: 0, routine: 0, monitor: 0, intervention: 0, unassessed: 0, dutyHours: 0, leaveDays: 0, mood: 0 }
  );

  const avgDuty = totals.personnel ? (totals.dutyHours / totals.personnel).toFixed(1) : "0";
  const avgLeave = totals.personnel ? (totals.leaveDays / totals.personnel).toFixed(0) : "0";
  const avgMood = totals.personnel ? (totals.mood / totals.personnel).toFixed(1) : "0";

  const pieData = [
    { name: "Routine", value: totals.routine, color: RISK_COLORS.routine },
    { name: "Monitor", value: totals.monitor, color: RISK_COLORS.monitor },
    { name: "Needs Support", value: totals.intervention, color: RISK_COLORS.intervention },
    { name: "Unassessed", value: totals.unassessed, color: "#64748b" },
  ].filter((d) => d.value > 0);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header Area */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-2">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Unit Overview</h1>
          <p className="text-muted-foreground text-[13px] mt-1">
            Aggregated welfare indicators across {summaries.length} unit{summaries.length > 1 ? "s" : ""}
          </p>
        </div>
        {role === "Welfare_Officer" && (
          <button
            onClick={runBatchAssessment}
            disabled={assessing}
            className="px-5 py-2.5 rounded-lg border border-border bg-secondary/50 text-foreground text-[13px] font-medium hover:bg-secondary transition-all disabled:opacity-50 cursor-pointer flex items-center gap-2 shadow-sm"
          >
            {assessing ? (
              <>
                <svg className="animate-spin h-4 w-4 text-primary" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Running AI Assessment...
              </>
            ) : (
              <>
                <svg className="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.455 2.456L21.75 6l-1.036.259a3.375 3.375 0 0 0-2.455 2.456ZM16.894 20.567 16.5 21.75l-.394-1.183a2.25 2.25 0 0 0-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 0 0 1.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 0 0 1.423 1.423l1.183.394-1.183.394a2.25 2.25 0 0 0-1.423 1.423Z" />
                </svg>
                Run AI Assessment
              </>
            )}
          </button>
        )}
      </div>

      {assessResult && (
        <div className={`flex items-center gap-3 px-4 py-3 rounded-xl border text-[13px] animate-fade-in ${
          assessResult.errors > 0
            ? "bg-amber-500/10 border-amber-500/20 text-amber-400"
            : assessResult.assessed === 0
            ? "bg-sky-500/10 border-sky-500/20 text-sky-400"
            : "bg-emerald-500/10 border-emerald-500/20 text-emerald-400"
        }`}>
          <span className="text-base">
            {assessResult.errors > 0 ? "⚠️" : assessResult.assessed === 0 ? "ℹ️" : "✅"}
          </span>
          <span className="font-medium">
            {assessResult.assessed === 0
              ? `Already up to date — all ${assessResult.skipped} personnel were assessed today.`
              : `AI Assessment complete — ${assessResult.assessed} assessed. ${assessResult.skipped > 0 ? `(${assessResult.skipped} up to date)` : ""}`
            }
          </span>
          <button
            onClick={() => setAssessResult(null)}
            className="ml-auto text-current opacity-60 hover:opacity-100 transition-opacity cursor-pointer p-1"
          >
            ✕
          </button>
        </div>
      )}

      {/* Main KPI Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6">
        <Card className="glass-card stat-card-glow animate-slide-up">
          <CardContent className="p-5 lg:p-6 flex flex-col justify-between h-full">
            <div className="flex items-center gap-2 mb-3 text-muted-foreground">
              <svg className="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
              </svg>
              <p className="text-[12px] font-medium tracking-wide uppercase">Total Personnel</p>
            </div>
            <div>
              <p className="text-4xl font-bold tracking-tight text-foreground">{totals.personnel}</p>
              <p className="text-[12px] text-emerald-400 mt-2 font-medium flex items-center gap-1">
                <span className="bg-emerald-500/20 text-emerald-500 rounded-full w-4 h-4 flex items-center justify-center text-[10px] leading-none">+</span>
                Active Duty
              </p>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card stat-card-glow animate-slide-up" style={{ animationDelay: "0.1s" }}>
          <CardContent className="p-5 lg:p-6 flex flex-col justify-between h-full">
            <div className="flex items-center gap-2 mb-3 text-muted-foreground">
              <svg className="w-4 h-4 text-chart-3" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
              </svg>
              <p className="text-[12px] font-medium tracking-wide uppercase">Avg Duty (Wk)</p>
            </div>
            <div>
              <p className="text-4xl font-bold tracking-tight text-foreground">{avgDuty}</p>
              <p className="text-[12px] text-amber-400 mt-2 font-medium">Hours per week</p>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card stat-card-glow animate-slide-up" style={{ animationDelay: "0.2s" }}>
          <CardContent className="p-5 lg:p-6 flex flex-col justify-between h-full">
            <div className="flex items-center gap-2 mb-3 text-muted-foreground">
              <svg className="w-4 h-4 text-chart-5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
              </svg>
              <p className="text-[12px] font-medium tracking-wide uppercase">Avg Since Leave</p>
            </div>
            <div>
              <p className="text-4xl font-bold tracking-tight text-foreground">{avgLeave}</p>
              <p className="text-[12px] text-sky-400 mt-2 font-medium">Days operational</p>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card stat-card-glow animate-slide-up" style={{ animationDelay: "0.3s" }}>
          <CardContent className="p-5 lg:p-6 flex flex-col justify-between h-full">
            <div className="flex items-center gap-2 mb-3 text-muted-foreground">
              <svg className="w-4 h-4 text-chart-2" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.182 15.182a4.5 4.5 0 0 1-6.364 0M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM9.75 9.75c0 .414-.168.75-.375.75S9 10.164 9 9.75 9.168 9 9.375 9s.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Zm5.625 0c0 .414-.168.75-.375.75s-.375-.336-.375-.75.168-.75.375-.75.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Z" />
              </svg>
              <p className="text-[12px] font-medium tracking-wide uppercase">Avg Mood Score</p>
            </div>
            <div>
              <p className="text-4xl font-bold tracking-tight text-foreground">{avgMood}</p>
              <p className="text-[12px] text-chart-2 mt-2 font-medium">Out of 10.0</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Analytics Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:gap-6">
        {/* Risk Distribution Chart */}
        <Card className="glass-card animate-slide-up" style={{ animationDelay: "0.4s" }}>
          <CardHeader className="p-5 pb-0">
            <CardTitle className="text-[14px] font-semibold text-foreground">Risk Distribution</CardTitle>
            <p className="text-[12px] text-muted-foreground mt-0.5">Current unit status</p>
          </CardHeader>
          <CardContent className="p-5 pt-4">
            {(() => {
              const total = pieData.reduce((s, d) => s + d.value, 0);
              if (total === 0) return <p className="text-muted-foreground text-center py-12 text-[13px]">No data</p>;

              const svgW = 300, svgH = 180;
              const cxP = svgW / 2, cyP = 70;
              const rxP = 90, ryP = 45;
              const depthH = 20;

              let acc = -Math.PI / 2;
              const slices = pieData.map((d, i) => {
                const a = (d.value / total) * Math.PI * 2;
                const s = { ...d, i, sa: acc, ea: acc + a, ma: acc + a / 2 };
                acc += a;
                return s;
              });

              const sorted = [...slices].sort((a, b) => Math.sin(a.ma) - Math.sin(b.ma));

              const ex = (a: number) => cxP + rxP * Math.cos(a);
              const ey = (a: number, yo = 0) => cyP + ryP * Math.sin(a) + yo;
              const lf = (sa: number, ea: number) => (ea - sa > Math.PI ? 1 : 0);

              const topPath = (s: typeof slices[0]) =>
                `M${cxP},${cyP} L${ex(s.sa)},${ey(s.sa)} A${rxP},${ryP} 0 ${lf(s.sa, s.ea)} 1 ${ex(s.ea)},${ey(s.ea)} Z`;

              const sidePath = (s: typeof slices[0]) => {
                const x1 = ex(s.sa), y1t = ey(s.sa), y1b = ey(s.sa, depthH);
                const x2 = ex(s.ea), y2t = ey(s.ea), y2b = ey(s.ea, depthH);
                return `M${x1},${y1t} A${rxP},${ryP} 0 ${lf(s.sa, s.ea)} 1 ${x2},${y2t} L${x2},${y2b} A${rxP},${ryP} 0 ${lf(s.sa, s.ea)} 0 ${x1},${y1b} Z`;
              };

              return (
                <div className="flex flex-col items-center">
                  <div className="relative h-[180px] flex items-center justify-center">
                    <svg width={svgW} height={svgH + depthH + 10} viewBox={`0 0 ${svgW} ${svgH + depthH + 10}`}
                      onMouseLeave={() => setHoveredSlice(null)}
                      className="absolute"
                    >
                      {sorted.map((s) => {
                        const isH = hoveredSlice === s.i;
                        return (
                          <g
                            key={s.i}
                            onMouseEnter={() => setHoveredSlice(s.i)}
                            style={{ cursor: "pointer", transition: "all 0.2s ease" }}
                          >
                            <path d={sidePath(s)} fill={s.color} opacity={isH ? 0.7 : 0.45} />
                            <path
                              d={topPath(s)}
                              fill={s.color}
                              opacity={isH ? 1 : 0.85}
                              stroke={isH ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.2)"}
                              strokeWidth={isH ? 2 : 1}
                            />
                          </g>
                        );
                      })}
                    </svg>
                  </div>
                  
                  <div className="w-full mt-4 grid grid-cols-2 gap-y-3 gap-x-2">
                    {pieData.map((d) => (
                      <div key={d.name} className="flex items-center justify-between text-[12px] bg-secondary/30 rounded-md px-2 py-1.5 border border-border/50">
                        <div className="flex items-center gap-2">
                          <div className="w-2.5 h-2.5 rounded-sm" style={{ background: d.color }} />
                          <span className="text-muted-foreground">{d.name}</span>
                        </div>
                        <span className="font-semibold text-foreground">{d.value}</span>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })()}
          </CardContent>
        </Card>

        {/* Trend Area Chart */}
        <Card className="glass-card lg:col-span-2 animate-slide-up flex flex-col" style={{ animationDelay: "0.5s" }}>
          <CardHeader className="p-5 pb-0 flex-row items-center justify-between">
            <div>
              <CardTitle className="text-[14px] font-semibold text-foreground">Wellness Trend</CardTitle>
              <p className="text-[12px] text-muted-foreground mt-0.5">Last 26 weeks</p>
            </div>
            <div className="flex items-center gap-4 text-[11px] font-medium text-muted-foreground">
              <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-blue-400"></div> Mood</div>
              <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full" style={{background: RISK_COLORS.monitor}}></div> Monitor</div>
              <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full" style={{background: RISK_COLORS.intervention}}></div> Support</div>
            </div>
          </CardHeader>
          <CardContent className="p-5 flex-1 min-h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trends} margin={{ top: 10, right: 0, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="gradMood" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#60a5fa" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="hsl(var(--border))" opacity={0.5} />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }}
                  tickFormatter={(v: string) => v.slice(5)}
                  axisLine={false}
                  tickLine={false}
                  dy={10}
                />
                <YAxis 
                  tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} 
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  contentStyle={{
                    background: "hsl(var(--card))",
                    border: "1px solid hsl(var(--border))",
                    borderRadius: "8px",
                    fontSize: "12px",
                    boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)"
                  }}
                  itemStyle={{ color: "hsl(var(--foreground))" }}
                />
                <Area
                  type="monotone"
                  dataKey="avg_mood"
                  stroke="#60a5fa"
                  fill="url(#gradMood)"
                  strokeWidth={3}
                  name="Avg Mood"
                />
                <Line type="monotone" dataKey="intervention" stroke={RISK_COLORS.intervention} strokeWidth={2} dot={{ r: 0 }} activeDot={{ r: 4 }} name="Interventions" />
                <Line type="monotone" dataKey="monitor" stroke={RISK_COLORS.monitor} strokeWidth={2} dot={{ r: 0 }} activeDot={{ r: 4 }} name="Monitor" />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Per-Unit Breakdown Table/Cards */}
      <div className="space-y-4 animate-slide-up" style={{ animationDelay: "0.6s" }}>
        <h2 className="text-[16px] font-bold tracking-tight text-foreground px-1">Unit Detail Breakdown</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 lg:gap-6">
          {summaries.map((s) => (
            <Card key={s.unit_name} className="glass-card hover:border-border/100 transition-colors">
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-5">
                  <h3 className="font-bold text-[14px] text-foreground">{s.unit_name}</h3>
                  <Badge variant="secondary" className="text-[10px] font-semibold bg-secondary/80 text-foreground rounded-md px-2 py-0.5 border border-border">
                    {s.total_personnel} pax
                  </Badge>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center mb-5">
                  <div className="bg-secondary/20 rounded-lg py-2 border border-border/30">
                    <span className="block font-bold text-[16px]" style={{ color: RISK_COLORS.routine }}>{s.routine_count}</span>
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground mt-0.5 block">Routine</span>
                  </div>
                  <div className="bg-secondary/20 rounded-lg py-2 border border-border/30">
                    <span className="block font-bold text-[16px]" style={{ color: RISK_COLORS.monitor }}>{s.monitor_count}</span>
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground mt-0.5 block">Monitor</span>
                  </div>
                  <div className="bg-secondary/20 rounded-lg py-2 border border-border/30">
                    <span className="block font-bold text-[16px]" style={{ color: RISK_COLORS.intervention }}>{s.intervention_count}</span>
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground mt-0.5 block">Support</span>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2 text-[12px] pt-4 border-t border-border/60">
                  <div className="flex flex-col">
                    <span className="text-muted-foreground mb-1">Avg Duty</span>
                    <span className="font-semibold text-foreground">{s.avg_duty_hours.toFixed(1)}h</span>
                  </div>
                  <div className="flex flex-col">
                    <span className="text-muted-foreground mb-1">Leave Gap</span>
                    <span className="font-semibold text-foreground">{s.avg_days_since_leave.toFixed(0)}d</span>
                  </div>
                  <div className="flex flex-col">
                    <span className="text-muted-foreground mb-1">Mood</span>
                    <span className="font-semibold text-foreground">{s.avg_mood_score.toFixed(1)}/10</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Welfare Recommendations List (Commander) */}
      {role === "Commander" && recommendations.length > 0 && (
        <div className="space-y-4 pt-4 animate-slide-up" style={{ animationDelay: "0.7s" }}>
          <div className="flex items-center gap-3 px-1">
            <h2 className="text-[16px] font-bold tracking-tight text-foreground">Welfare Action Items</h2>
            <Badge variant="outline" className="text-[10px] text-amber-400 border-amber-500/30 bg-amber-500/10">
              {recommendations.filter((r) => r.status === "Pending").length} pending
            </Badge>
          </div>

          <div className="grid grid-cols-1 gap-3">
            {recommendations.map((rec, i) => {
              const riskCfg: Record<string, { label: string; class: string }> = {
                Intervention_Recommended: { label: "Needs Support", class: "risk-badge-intervention" },
                Monitor: { label: "Monitor", class: "risk-badge-monitor" },
                Routine: { label: "Routine", class: "risk-badge-routine" },
              };
              const risk = riskCfg[rec.risk_level] || riskCfg.Routine;
              const statusCfg = recStatusConfig[rec.status] || recStatusConfig.Pending;
              const isResponding = respondingTo === rec.id;
              const timeAgo = getTimeAgo(rec.created_at);

              return (
                <Card
                  key={rec.id}
                  className={`glass-card transition-all duration-300 ${
                    rec.status === "Pending" ? "border-amber-500/30 shadow-[0_0_15px_rgba(245,158,11,0.05)]" : ""
                  }`}
                >
                  <CardContent className="p-4 lg:p-5">
                    <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                      
                      {/* Left: Identity & Badges */}
                      <div className="flex items-center gap-4 lg:w-[35%]">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center text-[14px] font-bold border shrink-0 ${risk.class}`}>
                          {rec.soldier_name.charAt(0)}
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-[14px] text-foreground truncate">{rec.soldier_name}</p>
                          <p className="text-[11px] text-muted-foreground truncate">{rec.soldier_service_id} • {rec.unit_name}</p>
                        </div>
                      </div>

                      {/* Middle: Note & Context */}
                      <div className="flex-1 min-w-0 bg-secondary/30 rounded-lg p-3 border border-border/50">
                        <div className="flex items-center gap-2 mb-1">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider border ${risk.class}`}>
                            {risk.label}
                          </span>
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider border ${statusCfg.bgColor} ${statusCfg.color}`}>
                            {statusCfg.label}
                          </span>
                        </div>
                        <p className="text-[12px] text-muted-foreground line-clamp-2 leading-snug">
                          <span className="font-semibold text-foreground/80">{rec.welfare_officer_name}:</span> {rec.note}
                        </p>
                      </div>

                      {/* Right: Actions */}
                      <div className="flex items-center gap-3 shrink-0 lg:w-[25%] lg:justify-end">
                        <span className="text-[11px] text-muted-foreground hidden lg:block">{timeAgo}</span>
                        {rec.status === "Pending" && (
                          <div className="flex gap-2">
                            <button
                              onClick={() => {
                                if (isResponding) {
                                  setRespondingTo(null);
                                  setResponseNote("");
                                } else {
                                  setRespondingTo(rec.id);
                                  setResponseNote("");
                                }
                              }}
                              className="px-3 py-1.5 rounded bg-secondary text-[11px] font-semibold text-foreground hover:bg-secondary/80 transition-colors border border-border"
                            >
                              {isResponding ? "Cancel" : "Reply"}
                            </button>
                            <button
                              onClick={() => handleRecAction(rec.id, "Reviewed")}
                              className="px-3 py-1.5 rounded bg-primary text-[11px] font-semibold text-primary-foreground hover:bg-primary/90 transition-colors"
                            >
                              Acknowledge
                            </button>
                          </div>
                        )}
                        {rec.status === "Reviewed" && (
                          <button
                            onClick={() => handleRecAction(rec.id, "Actioned")}
                            className="px-3 py-1.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-[11px] font-semibold hover:bg-emerald-500/30 transition-colors"
                          >
                            Mark Actioned
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Inline Reply Box */}
                    {isResponding && (
                      <div className="mt-4 animate-fade-in pl-[3.5rem]">
                        <textarea
                          value={responseNote}
                          onChange={(e) => setResponseNote(e.target.value)}
                          placeholder="Add a commander's note (optional)..."
                          className="w-full h-16 px-3 py-2 rounded-lg bg-background border border-border text-[12px] placeholder:text-muted-foreground/50 resize-none focus:outline-none focus:border-primary/50 transition-colors"
                        />
                        <div className="flex justify-end mt-2">
                           <button
                             onClick={() => handleRecAction(rec.id, "Reviewed")}
                             className="px-4 py-1.5 rounded bg-primary text-[11px] font-semibold text-primary-foreground hover:bg-primary/90 transition-colors"
                           >
                             Submit & Mark Reviewed
                           </button>
                        </div>
                      </div>
                    )}

                    {/* Existing Note */}
                    {rec.commander_response && (
                      <div className="mt-3 ml-0 lg:ml-[3.5rem] p-2.5 rounded-lg bg-sky-500/10 border border-sky-500/20 flex gap-2">
                        <svg className="w-3.5 h-3.5 text-sky-400 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" strokeWidth="2" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                        </svg>
                        <div>
                          <p className="text-[10px] font-bold uppercase tracking-wider text-sky-400">Commander's Note</p>
                          <p className="text-[12px] text-muted-foreground mt-0.5">{rec.commander_response}</p>
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

function getTimeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}
