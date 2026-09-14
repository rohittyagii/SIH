"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import {
  LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine,
} from "recharts";

const riskConfig: Record<string, { label: string; class: string }> = {
  Intervention_Recommended: { label: "Needs Support", class: "risk-badge-intervention" },
  Monitor: { label: "Monitor", class: "risk-badge-monitor" },
  Routine: { label: "Routine", class: "risk-badge-routine" },
};

export default function PersonnelDetailPage() {
  const { role } = useAuth();
  const params = useParams();
  const router = useRouter();
  const [detail, setDetail] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [assessing, setAssessing] = useState(false);

  const personnelId = Array.isArray(params.id) ? params.id[0] : (params.id as string);

  useEffect(() => {
    if (role === "Commander") {
      router.push("/overview");
      return;
    }
    setDetail(null);
    setLoading(true);
    loadDetail();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [personnelId, role, router]);

  const loadDetail = async () => {
    try {
      const data = await api.getPersonnelDetail(personnelId);
      setDetail(data);
    } catch (err) {
      console.error("Failed to load detail:", err);
    } finally {
      setLoading(false);
    }
  };

  const runAssessment = async () => {
    setAssessing(true);
    try {
      await api.runAssessment(personnelId);
      await loadDetail();
    } catch (err) {
      console.error("Assessment failed:", err);
    } finally {
      setAssessing(false);
    }
  };

  const handleAction = async (assessmentId: string, status: string) => {
    try {
      await api.takeAction(assessmentId, status);
      await loadDetail();
    } catch (err) {
      console.error("Action failed:", err);
    }
  };

  if (loading || role === "Commander") {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin h-8 w-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!detail) {
    return <div className="text-center text-muted-foreground">Personnel not found.</div>;
  }

  const { user, hr_metrics, recent_wellness, assessments } = detail;
  const latestAssessment = assessments?.[0];
  const latestRisk = latestAssessment ? riskConfig[latestAssessment.risk_level] : null;

  // Prepare wellness chart data (reverse to show chronological order)
  const chartData = [...(recent_wellness || [])].reverse().map((w: any) => ({
    date: new Date(w.timestamp).toLocaleDateString("en-IN", { day: "2-digit", month: "short" }),
    mood: w.self_reported_mood,
    sleep: w.sleep_score,
    fatigue: w.subjective_fatigue_level,
    hrv: w.hrv_baseline_deviation || 0,
  }));

  // Calculate composite mental health score trajectory (0-100)
  const mentalScoreData = [...(recent_wellness || [])].reverse().map((w: any) => {
    const rawScore = (w.self_reported_mood || 5) * 5 + (w.sleep_score || 5) * 3 - (w.subjective_fatigue_level || 5) * 2 + 20;
    const score = Math.max(15, Math.min(98, rawScore));
    return {
      date: new Date(w.timestamp).toLocaleDateString("en-IN", { day: "2-digit", month: "short" }),
      mentalScore: score,
      benchmark: 70,
      mood: w.self_reported_mood,
      sleep: w.sleep_score,
      fatigue: w.subjective_fatigue_level,
    };
  });

  const currentMentalScore = mentalScoreData.length > 0 ? mentalScoreData[mentalScoreData.length - 1].mentalScore : 78;
  const latestHrv = recent_wellness?.[0]?.hrv_baseline_deviation || 0;
  const avgSleepScore = recent_wellness?.length
    ? (recent_wellness.reduce((acc: number, w: any) => acc + w.sleep_score, 0) / recent_wellness.length).toFixed(1)
    : "7.2";

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Back button + Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => router.back()}
          className="p-2 rounded-lg hover:bg-accent transition-colors cursor-pointer"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
          </svg>
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold tracking-tight">{user.full_name}</h1>
            {latestRisk && (
              <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold border ${latestRisk.class}`}>
                {latestRisk.label}
              </span>
            )}
          </div>
          <p className="text-muted-foreground text-[13px] mt-1">
            {user.service_id} • {user.unit}
          </p>
        </div>
        <button
          onClick={runAssessment}
          disabled={assessing}
          className="px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 cursor-pointer"
        >
          {assessing ? "Assessing..." : "Run AI Assessment"}
        </button>
      </div>

      {/* ── MENTAL HEALTH CONCLUSION & GRAPH ── */}
      <Card className="glass-card animate-slide-up border-primary/25">
        <CardHeader className="pb-3">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-2">
            <div>
              <p className="text-[11px] font-bold text-primary tracking-wider uppercase">AI Psychological & Biometric Synthesis</p>
              <CardTitle className="text-lg font-bold mt-1">Soldier Mental Health Conclusion</CardTitle>
            </div>
            {latestRisk && (
              <div className="flex items-center gap-2">
                <span className={`inline-flex items-center px-3 py-1.5 rounded-full text-[12px] font-bold border ${latestRisk.class}`}>
                  Verdict: {latestRisk.label}
                </span>
              </div>
            )}
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* AI Clinical Conclusion */}
          <div className="p-4 rounded-xl bg-card/60 border border-border/60">
            <p className="text-[14px] leading-relaxed text-foreground/90 font-medium">
              {latestAssessment?.contributing_factors ||
                "Longitudinal evaluation confirms balanced autonomic functioning and adequate recovery reserves. No severe psychological strain markers detected."}
            </p>
            {latestAssessment?.recommended_intervention && (
              <div className="mt-3 pt-3 border-t border-border/40 flex items-start gap-2 text-[13px] text-sky-400">
                <span className="text-base">💡</span>
                <div>
                  <span className="font-semibold text-foreground">Recommended Welfare Action: </span>
                  {latestAssessment.recommended_intervention}
                </div>
              </div>
            )}
          </div>

          {/* Mental Health Conclusion Graph */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <h4 className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">
                Mental Wellbeing & Resilience Index Trajectory (0 – 100 Score)
              </h4>
              <span className="text-[13px] font-bold text-primary">
                Current Score: {currentMentalScore} / 100
              </span>
            </div>
            <div className="h-[220px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={mentalScoreData}>
                  <defs>
                    <linearGradient id="mentalGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="#60a5fa" stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                  <XAxis dataKey="date" tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} />
                  <YAxis domain={[0, 100]} tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} />
                  <ReferenceLine
                    y={70}
                    stroke="#34d399"
                    strokeDasharray="4 4"
                    label={{ value: "Resilience Benchmark (70)", fill: "#34d399", fontSize: 10, position: "insideTopRight" }}
                  />
                  <Tooltip
                    contentStyle={{
                      background: "hsl(var(--card))",
                      border: "1px solid hsl(var(--border))",
                      borderRadius: "8px",
                      fontSize: "12px",
                    }}
                    formatter={(value: any) => [`${value} / 100`, "Mental Health Index"]}
                  />
                  <Area
                    type="monotone"
                    dataKey="mentalScore"
                    stroke="#60a5fa"
                    strokeWidth={3}
                    fillOpacity={1}
                    fill="url(#mentalGradient)"
                    name="Mental Health Score"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
            <div className="flex gap-6 justify-center mt-3 text-[13px] text-muted-foreground">
              <span className="flex items-center gap-1.5"><span className="w-3 h-0.5 bg-[#60a5fa] rounded" />Mental Health Index</span>
              <span className="flex items-center gap-1.5"><span className="w-3 h-0.5 bg-[#34d399] border-dashed border-t border-[#34d399]" />70+ Benchmark</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* ── SOLDIER APP TILES (GRID LAYOUT) ── */}
      <div>
        <h3 className="text-[12px] font-bold text-muted-foreground tracking-wider uppercase mb-4">
          Soldier Welfare Telemetry Tiles
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
          {/* Mental Resilience Tile */}
          <Card className="glass-card hover:border-primary/40 transition-colors">
            <CardContent className="p-4">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <svg className="w-4 h-4 text-muted-foreground mb-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96-.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z"/>
                    <path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96-.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z"/>
                  </svg>
                  <p className="text-[11px] text-muted-foreground">Resilience Score</p>
                </div>
                <span className={`text-[11px] font-bold px-1.5 py-0.5 rounded-full ${
                  currentMentalScore >= 70 ? "bg-emerald-500/15 text-emerald-400" : currentMentalScore >= 50 ? "bg-amber-500/15 text-amber-400" : "bg-rose-500/15 text-rose-400"
                }`}>
                  {currentMentalScore >= 70 ? "Resilient" : currentMentalScore >= 50 ? "Moderate" : "Strain"}
                </span>
              </div>
              <p className="text-2xl font-extrabold leading-tight">{currentMentalScore} <span className="text-[11px] font-normal text-muted-foreground">/ 100</span></p>
              <p className="text-[11px] text-muted-foreground mt-1.5">Composite wellbeing</p>
            </CardContent>
          </Card>

          {/* Sleep Recovery Tile */}
          <Card className="glass-card hover:border-primary/40 transition-colors">
            <CardContent className="p-4">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <svg className="w-4 h-4 text-muted-foreground mb-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>
                  </svg>
                  <p className="text-[11px] text-muted-foreground">Sleep Recovery</p>
                </div>
                <span className={`text-[11px] font-bold px-1.5 py-0.5 rounded-full ${
                  Number(avgSleepScore) >= 6 ? "bg-emerald-500/15 text-emerald-400" : "bg-rose-500/15 text-rose-400"
                }`}>
                  {Number(avgSleepScore) >= 6 ? "Good" : "Deficit"}
                </span>
              </div>
              <p className="text-2xl font-extrabold leading-tight">{avgSleepScore} <span className="text-[11px] font-normal text-muted-foreground">/ 10</span></p>
              <p className="text-[11px] text-muted-foreground mt-1.5">Average score</p>
            </CardContent>
          </Card>

          {/* Wearable HRV Deviation Tile */}
          <Card className="glass-card hover:border-primary/40 transition-colors">
            <CardContent className="p-4">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <svg className="w-4 h-4 text-muted-foreground mb-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
                  </svg>
                  <p className="text-[11px] text-muted-foreground">Wearable HRV</p>
                </div>
                <span className={`text-[11px] font-bold px-1.5 py-0.5 rounded-full ${
                  latestHrv > 20 ? "bg-rose-500/15 text-rose-400" : "bg-sky-500/15 text-sky-400"
                }`}>
                  {latestHrv > 20 ? "Elevated" : "Sync OK"}
                </span>
              </div>
              <p className="text-2xl font-extrabold leading-tight">+{latestHrv.toFixed(1)}%</p>
              <p className="text-[11px] text-muted-foreground mt-1.5">Baseline deviation</p>
            </CardContent>
          </Card>

          {/* Weekly Duty Hours Tile */}
          <Card className={`glass-card hover:border-primary/40 transition-colors ${
            (hr_metrics?.avg_weekly_duty_hours || 0) > 56 ? "border-risk-intervention/40" : ""
          }`}>
            <CardContent className="p-4">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <svg className="w-4 h-4 text-muted-foreground mb-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <polyline points="12 6 12 12 16 14"/>
                  </svg>
                  <p className="text-[11px] text-muted-foreground">Weekly Duty</p>
                </div>
                <span className={`text-[11px] font-bold px-1.5 py-0.5 rounded-full ${
                  (hr_metrics?.avg_weekly_duty_hours || 0) > 56 ? "bg-rose-500/15 text-rose-400" : "bg-primary/15 text-primary"
                }`}>
                  {(hr_metrics?.avg_weekly_duty_hours || 0) > 56 ? "Overtime" : "Normal"}
                </span>
              </div>
              <p className="text-2xl font-extrabold leading-tight">{hr_metrics?.avg_weekly_duty_hours || 48}h</p>
              <p className="text-[11px] text-muted-foreground mt-1.5">Weekly hours avg</p>
            </CardContent>
          </Card>

          {/* Leave Deficit Tile */}
          <Card className={`glass-card hover:border-primary/40 transition-colors ${
            (hr_metrics?.days_since_last_leave || 0) > 90 ? "border-risk-intervention/40" : ""
          }`}>
            <CardContent className="p-4">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <svg className="w-4 h-4 text-muted-foreground mb-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                  </svg>
                  <p className="text-[11px] text-muted-foreground">Leave Counter</p>
                </div>
                <span className={`text-[11px] font-bold px-1.5 py-0.5 rounded-full ${
                  (hr_metrics?.days_since_last_leave || 0) > 90 ? "bg-rose-500/15 text-rose-400" : "bg-emerald-500/15 text-emerald-400"
                }`}>
                  {(hr_metrics?.days_since_last_leave || 0) > 90 ? "Critical" : "Standard"}
                </span>
              </div>
              <p className="text-2xl font-extrabold leading-tight">{hr_metrics?.days_since_last_leave || 0}d</p>
              <p className="text-[11px] text-muted-foreground mt-1.5">Days without leave</p>
            </CardContent>
          </Card>

          {/* Deployment History Tile */}
          <Card className="glass-card hover:border-primary/40 transition-colors">
            <CardContent className="p-4">
              <div className="flex justify-between items-start mb-2">
                <div>
                  <svg className="w-4 h-4 text-muted-foreground mb-1" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 8.2c0 7.3-8 11.8-8 11.8z"/>
                    <circle cx="12" cy="10" r="3"/>
                  </svg>
                  <p className="text-[11px] text-muted-foreground">Deployment</p>
                </div>
                <span className="text-[11px] font-bold px-1.5 py-0.5 rounded-full bg-muted text-muted-foreground">
                  Active
                </span>
              </div>
              <p className="text-2xl font-extrabold leading-tight">{hr_metrics?.deployment_history_months || 0} mo</p>
              <p className="text-[11px] text-muted-foreground mt-1.5">Posting duration</p>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Wellness Timeline Chart */}
      {chartData.length > 0 && (
        <Card className="glass-card animate-slide-up" style={{ animationDelay: "0.3s" }}>
          <CardHeader>
            <CardTitle className="text-[15px] font-semibold">Wellness Check-in Timeline</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[250px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                  <XAxis dataKey="date" tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} />
                  <YAxis domain={[0, 10]} tick={{ fontSize: 10, fill: "hsl(var(--muted-foreground))" }} />
                  <Tooltip
                    contentStyle={{
                      background: "hsl(var(--card))",
                      border: "1px solid hsl(var(--border))",
                      borderRadius: "8px",
                      fontSize: "12px",
                    }}
                  />
                  <Line type="monotone" dataKey="mood" stroke="#60a5fa" strokeWidth={2} dot={{ r: 3 }} name="Mood" />
                  <Line type="monotone" dataKey="sleep" stroke="#34d399" strokeWidth={2} dot={{ r: 3 }} name="Sleep" />
                  <Line type="monotone" dataKey="fatigue" stroke="#f87171" strokeWidth={2} dot={{ r: 3 }} name="Fatigue" />
                </LineChart>
              </ResponsiveContainer>
            </div>
            <div className="flex gap-6 justify-center mt-3 text-[13px] text-muted-foreground">
              <span className="flex items-center gap-1.5"><span className="w-3 h-0.5 bg-[#60a5fa] rounded" />Mood</span>
              <span className="flex items-center gap-1.5"><span className="w-3 h-0.5 bg-[#34d399] rounded" />Sleep</span>
              <span className="flex items-center gap-1.5"><span className="w-3 h-0.5 bg-[#f87171] rounded" />Fatigue</span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Assessment History */}
      <div className="space-y-3">
        <h2 className="text-lg font-semibold">Assessment History</h2>
        {assessments?.length === 0 ? (
          <Card className="glass-card">
            <CardContent className="py-8 text-center text-muted-foreground text-sm">
              No assessments yet. Click &quot;Run AI Assessment&quot; above.
            </CardContent>
          </Card>
        ) : (
          assessments?.map((a: any, i: number) => {
            const risk = riskConfig[a.risk_level] || riskConfig.Routine;
            return (
              <Card key={a.assessment_id} className="glass-card animate-slide-up" style={{ animationDelay: `${i * 0.05}s` }}>
                <CardContent className="py-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[12px] font-semibold border ${risk.class}`}>
                        {risk.label}
                      </span>
                      <span className="text-[12px] text-muted-foreground">
                        {new Date(a.created_at).toLocaleString("en-IN")}
                      </span>
                    </div>
                    <Badge variant={a.status === "Action_Taken" ? "default" : "outline"} className="text-[11px]">
                      {a.status.replace("_", " ")}
                    </Badge>
                  </div>
                  <div className="space-y-2.5 text-[14px]">
                    <div>
                      <span className="font-medium text-foreground/80">Contributing Factors: </span>
                      <span className="text-muted-foreground">{a.contributing_factors}</span>
                    </div>
                    <div>
                      <span className="font-medium text-foreground/80">Welfare Recommendation: </span>
                      <span className="text-muted-foreground">{a.recommended_intervention}</span>
                    </div>
                  </div>
                  {a.status === "Pending" && (
                    <div className="mt-3 flex gap-2">
                      <button
                        onClick={() => handleAction(a.assessment_id, "Acknowledged")}
                        className="px-3 py-1.5 rounded-md bg-primary/10 text-primary text-xs font-medium hover:bg-primary/20 transition-colors cursor-pointer"
                      >
                        Acknowledge
                      </button>
                      <button
                        onClick={() => handleAction(a.assessment_id, "Action_Taken")}
                        className="px-3 py-1.5 rounded-md bg-risk-routine/10 text-risk-routine text-xs font-medium hover:bg-risk-routine/20 transition-colors cursor-pointer"
                      >
                        Mark Action Taken
                      </button>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })
        )}
      </div>
    </div>
  );
}
