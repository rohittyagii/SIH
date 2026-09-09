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

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [s, t] = await Promise.all([api.getUnitSummary(), api.getTrends()]);
      setSummaries(s);
      setTrends(t);
    } catch (err) {
      console.error("Failed to load overview:", err);
    } finally {
      setLoading(false);
    }
  };

  const runBatchAssessment = async () => {
    setAssessing(true);
    try {
      for (const s of summaries) {
        await api.runUnitAssessment(s.unit_name);
      }
      await loadData();
    } catch (err) {
      console.error("Assessment failed:", err);
    } finally {
      setAssessing(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
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
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Unit Overview</h1>
          <p className="text-muted-foreground text-[13px] mt-1.5 leading-relaxed">
            Aggregated welfare indicators across {summaries.length} unit{summaries.length > 1 ? "s" : ""}
          </p>
        </div>
        <button
          onClick={runBatchAssessment}
          disabled={assessing}
          className="px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 cursor-pointer flex items-center gap-2"
        >
          {assessing ? (
            <>
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Running AI Assessment...
            </>
          ) : (
            <>
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.455 2.456L21.75 6l-1.036.259a3.375 3.375 0 0 0-2.455 2.456ZM16.894 20.567 16.5 21.75l-.394-1.183a2.25 2.25 0 0 0-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 0 0 1.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 0 0 1.423 1.423l1.183.394-1.183.394a2.25 2.25 0 0 0-1.423 1.423Z" />
              </svg>
              Run AI Assessment
            </>
          )}
        </button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <Card className="glass-card stat-card-glow animate-slide-up">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[13px] text-muted-foreground font-medium">Total Personnel</p>
                <p className="text-3xl font-bold mt-1.5">{totals.personnel}</p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
                <svg className="w-6 h-6 text-primary" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
                </svg>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card stat-card-glow animate-slide-up" style={{ animationDelay: "0.1s" }}>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[13px] text-muted-foreground font-medium">Avg Duty Hours/Week</p>
                <p className="text-3xl font-bold mt-1.5">{avgDuty}<span className="text-lg text-muted-foreground ml-0.5">h</span></p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-chart-3/10 flex items-center justify-center">
                <svg className="w-6 h-6 text-chart-3" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card stat-card-glow animate-slide-up" style={{ animationDelay: "0.2s" }}>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[13px] text-muted-foreground font-medium">Avg Days Since Leave</p>
                <p className="text-3xl font-bold mt-1.5">{avgLeave}<span className="text-lg text-muted-foreground ml-0.5">d</span></p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-chart-5/10 flex items-center justify-center">
                <svg className="w-6 h-6 text-chart-5" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
                </svg>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="glass-card stat-card-glow animate-slide-up" style={{ animationDelay: "0.3s" }}>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[13px] text-muted-foreground font-medium">Avg Mood Score</p>
                <p className="text-3xl font-bold mt-1.5">{avgMood}<span className="text-lg text-muted-foreground ml-0.5">/10</span></p>
              </div>
              <div className="w-12 h-12 rounded-xl bg-chart-2/10 flex items-center justify-center">
                <svg className="w-6 h-6 text-chart-2" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15.182 15.182a4.5 4.5 0 0 1-6.364 0M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM9.75 9.75c0 .414-.168.75-.375.75S9 10.164 9 9.75 9.168 9 9.375 9s.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Zm5.625 0c0 .414-.168.75-.375.75s-.375-.336-.375-.75.168-.75.375-.75.375.336.375.75Zm-.375 0h.008v.015h-.008V9.75Z" />
                </svg>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Risk Distribution + Trend Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-2">
        {/* Pie Chart */}
        <Card className="glass-card animate-slide-up" style={{ animationDelay: "0.4s" }}>
          <CardHeader>
            <CardTitle className="text-[15px] font-semibold">Risk Distribution</CardTitle>
          </CardHeader>
          <CardContent>
            {(() => {
              const total = pieData.reduce((s, d) => s + d.value, 0);
              if (total === 0) return <p className="text-muted-foreground text-center py-8">No data</p>;

              const svgW = 300, svgH = 180;
              const cxP = svgW / 2, cyP = 70;
              const rxP = 100, ryP = 55;
              const depthH = 24;

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
                <>
                  <div className="flex justify-center">
                    <svg width={svgW} height={svgH + depthH + 10} viewBox={`0 0 ${svgW} ${svgH + depthH + 10}`}
                      onMouseLeave={() => setHoveredSlice(null)}
                    >
                      {sorted.map((s) => {
                        const isH = hoveredSlice === s.i;
                        return (
                          <g
                            key={s.i}
                            onMouseEnter={() => setHoveredSlice(s.i)}
                            style={{ cursor: "pointer", transition: "opacity 0.15s" }}
                          >
                            <path d={sidePath(s)} fill={s.color} opacity={isH ? 0.7 : 0.45} />
                            <path
                              d={topPath(s)}
                              fill={s.color}
                              opacity={isH ? 1 : 0.85}
                              stroke={isH ? "rgba(255,255,255,0.4)" : "rgba(0,0,0,0.15)"}
                              strokeWidth={isH ? 2 : 1}
                            />
                          </g>
                        );
                      })}
                    </svg>
                  </div>
                  <div className="h-7 flex items-center justify-center">
                    {hoveredSlice !== null && pieData[hoveredSlice] && (
                      <p className="text-[14px] font-semibold animate-fade-in" style={{ color: pieData[hoveredSlice].color }}>
                        {pieData[hoveredSlice].name} = {pieData[hoveredSlice].value}
                      </p>
                    )}
                  </div>
                  <div className="flex flex-wrap gap-3 justify-center mt-1">
                    {pieData.map((d) => (
                      <div key={d.name} className="flex items-center gap-2 text-[13px]">
                        <div className="w-3 h-3 rounded-full" style={{ background: d.color }} />
                        <span className="text-muted-foreground">{d.name}</span>
                        <span className="font-semibold">{d.value}</span>
                      </div>
                    ))}
                  </div>
                </>
              );
            })()}
          </CardContent>
        </Card>

        {/* Trend Chart */}
        <Card className="glass-card lg:col-span-2 animate-slide-up" style={{ animationDelay: "0.5s" }}>
          <CardHeader>
            <CardTitle className="text-[15px] font-semibold">Wellness Trend (26 Weeks)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={trends}>
                  <defs>
                    <linearGradient id="gradMood" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#60a5fa" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                  <XAxis
                    dataKey="date"
                    tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }}
                    tickFormatter={(v: string) => v.slice(5)}
                  />
                  <YAxis tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} />
                  <Tooltip
                    contentStyle={{
                      background: "hsl(var(--card))",
                      border: "1px solid hsl(var(--border))",
                      borderRadius: "8px",
                      fontSize: "12px",
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="avg_mood"
                    stroke="#60a5fa"
                    fill="url(#gradMood)"
                    strokeWidth={2}
                    name="Avg Mood"
                  />
                  <Line type="monotone" dataKey="intervention" stroke={RISK_COLORS.intervention} strokeWidth={2} dot={false} name="Interventions" />
                  <Line type="monotone" dataKey="monitor" stroke={RISK_COLORS.monitor} strokeWidth={2} dot={false} name="Monitor" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Per-Unit Breakdown */}
      <div className="space-y-4">
        <h2 className="text-lg font-semibold">Unit Breakdown</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {summaries.map((s) => (
            <Card key={s.unit_name} className="glass-card animate-slide-up">
              <CardContent className="pt-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-semibold text-[14px]">{s.unit_name}</h3>
                  <Badge variant="secondary" className="text-[11px]">{s.total_personnel} personnel</Badge>
                </div>

                {/* Mini risk bar */}
                <div className="h-2 rounded-full bg-muted flex overflow-hidden mb-3">
                  {s.routine_count > 0 && (
                    <div
                      className="h-full"
                      style={{ width: `${(s.routine_count / s.total_personnel) * 100}%`, background: RISK_COLORS.routine }}
                    />
                  )}
                  {s.monitor_count > 0 && (
                    <div
                      className="h-full"
                      style={{ width: `${(s.monitor_count / s.total_personnel) * 100}%`, background: RISK_COLORS.monitor }}
                    />
                  )}
                  {s.intervention_count > 0 && (
                    <div
                      className="h-full"
                      style={{ width: `${(s.intervention_count / s.total_personnel) * 100}%`, background: RISK_COLORS.intervention }}
                    />
                  )}
                </div>

                <div className="grid grid-cols-3 gap-2 text-[13px] text-center">
                  <div>
                    <span className="block font-bold text-lg" style={{ color: RISK_COLORS.routine }}>{s.routine_count}</span>
                    <span className="text-muted-foreground">Routine</span>
                  </div>
                  <div>
                    <span className="block font-bold text-lg" style={{ color: RISK_COLORS.monitor }}>{s.monitor_count}</span>
                    <span className="text-muted-foreground">Monitor</span>
                  </div>
                  <div>
                    <span className="block font-bold text-lg" style={{ color: RISK_COLORS.intervention }}>{s.intervention_count}</span>
                    <span className="text-muted-foreground">Support</span>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-border/50 grid grid-cols-3 gap-2 text-[13px] text-muted-foreground">
                  <div>
                    <span className="block font-medium text-foreground">{s.avg_duty_hours.toFixed(1)}h</span>
                    Avg Duty
                  </div>
                  <div>
                    <span className="block font-medium text-foreground">{s.avg_days_since_leave.toFixed(0)}d</span>
                    Since Leave
                  </div>
                  <div>
                    <span className="block font-medium text-foreground">{s.avg_mood_score.toFixed(1)}</span>
                    Mood
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
